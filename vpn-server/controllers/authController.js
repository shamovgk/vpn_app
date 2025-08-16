const nodemailer = require('nodemailer');
const config = require('../config/config');
const logger = require('../utils/logger.js');
const authService = require('../services/authService');
const subscriptionService = require('../services/subscriptionService');

const transporter = nodemailer.createTransport(config.smtp);

exports.register = async (req, res) => {
  const { username, password, email } = req.body;
  const db = req.db;

  try {
    const { pendingId, username: u, normalizedEmail, verificationCode } = await authService.registerUser({ username, password, email, db });

    await transporter.sendMail({
      from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
      to: normalizedEmail,
      subject: 'Verify your email',
      text: `Your verification code is: ${verificationCode}. Please enter it in the app to verify your account.`,
    });

    logger.info('Verification code sent to user', { username: u, email: normalizedEmail, pendingId });
    res.json({ username: u, email: normalizedEmail, message: 'Код верификации отправлен на ваш email' });

  } catch (e) {
    if (e.message === 'USER_EXISTS') return res.status(400).json({ error: 'Пользователь с таким логином или email уже существует' });
    if (e.message === 'PENDING_EXISTS') return res.status(400).json({ error: 'Уже есть заявка с этим логином или email (проверьте email)' });
    logger.error('Failed to register', { error: e.message });
    res.status(500).json({ error: 'Ошибка регистрации' });
  }
};

exports.verifyEmail = async (req, res) => {
  const { username, email, verificationCode } = req.body;
  const db = req.db;

  try {
    const { userId, username: u, email: em, clientIp } = await authService.verifyEmail({ username, email, verificationCode, db });

    logger.info('User successfully verified and created', { username: u, email: em, clientIp });

    await subscriptionService.startTrial({ userId, db });

    res.json({ message: 'Email успешно верифицирован, аккаунт создан' });
  } catch (e) {
    if (e.message === 'PENDING_NOT_FOUND') return res.status(400).json({ error: 'Заявка не найдена' });
    if (e.message === 'CODE_INVALID') return res.status(400).json({ error: 'Неверный код верификации' });
    if (e.message === 'CODE_EXPIRED') return res.status(400).json({ error: 'Срок действия кода истёк' });
    logger.error('Failed to create user after verification', { error: e.message });
    res.status(500).json({ error: 'Не удалось завершить верификацию: ' + e.message });
  }
};

exports.login = async (req, res) => {
  const { username, password } = req.body;
  const db = req.db;
  try {
    const result = await authService.loginUser({ username, password, db });
    logger.info('User logged in', { userId: result.user.id, username: result.user.username });
    res.json(result);
  } catch (e) {
    if (e.message === 'USER_NOT_FOUND') return res.status(400).json({ error: 'Пользователь не найден' });
    if (e.message === 'PASSWORD_INVALID') return res.status(400).json({ error: 'Неверный пароль' });
    logger.error('Login error', { error: e.message });
    res.status(500).json({ error: 'Ошибка входа' });
  }
};

exports.validateToken = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer '))
    return res.status(401).json({ error: 'Token is required' });
  const token = authHeader.split(' ')[1];
  const db = req.db;
  try {
    const user = await authService.validateToken({ token, db });
    logger.info('Token validated', { userId: user.id, username: user.username });
    res.json(user);
  } catch (e) {
    if (e.message === 'TOKEN_INVALID')
      return res.status(401).json({ error: 'Invalid or expired token' });
    logger.error('Token validation error', { error: e.message });
    res.status(500).json({ error: 'Ошибка проверки токена' });
  }
};

exports.logout = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer '))
    return res.status(401).json({ error: 'Token is required' });
  const token = authHeader.split(' ')[1];
  const db = req.db;
  try {
    const result = await authService.logout({ token, db });
    logger.info('User logged out', { userId: result.userId, username: result.username, token });
    res.json({ message: 'Logged out successfully' });
  } catch (e) {
    if (e.message === 'TOKEN_NOT_FOUND')
      return res.status(400).json({ error: 'Token not found' });
    logger.error('Logout error', { error: e.message });
    res.status(500).json({ error: 'Ошибка выхода' });
  }
};

exports.forgotPassword = async (req, res) => {
  const { username } = req.body;
  if (!username)
    return res.status(400).json({ error: 'Логин обязателен для восстановления пароля' });
  const db = req.db;

  try {
    await authService.forgotPassword({
      username,
      db,
      sendEmail: async ({ email, resetCode }) => {
        await transporter.sendMail({
          from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
          to: email,
          subject: 'Password Reset',
          text: `Your password reset code is: ${resetCode}. Please use it in the app to reset your password.`,
        });
        logger.info('Password reset instructions sent', { username, email });
      },
    });
    res.json({ message: 'Инструкции по восстановлению отправлены на ваш email' });
  } catch (e) {
    if (e.message === 'USER_NOT_FOUND')
      return res.status(400).json({ error: 'Пользователь с таким логином не найден' });
    logger.error('Failed to send password reset email', { error: e.message });
    res.status(500).json({ error: 'Не удалось отправить email с инструкциями' });
  }
};

exports.resetPassword = async (req, res) => {
  const { username, resetCode, newPassword } = req.body;
  if (!username || !resetCode || !newPassword)
    return res.status(400).json({ error: 'Все поля (логин, код восстановления и новый пароль) обязательны' });
  const db = req.db;

  try {
    await authService.resetPassword({ username, resetCode, newPassword, db });
    logger.info('Password reset successful', { username });
    res.json({ message: 'Пароль успешно сброшен' });
  } catch (e) {
    if (e.message === 'USER_NOT_FOUND')
      return res.status(400).json({ error: 'Пользователь не найден' });
    if (e.message === 'RESET_INVALID')
      return res.status(400).json({ error: 'Неверный или истёкший код восстановления' });
    logger.error('Password reset error', { error: e.message });
    res.status(500).json({ error: 'Не удалось сбросить пароль' });
  }
};
