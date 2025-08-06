const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
const config = require('../config/config');
const logger = require('../utils/logger.js');
const { getCurrentDatePlusDays, generateToken, generateVerificationCode, generateVpnKey } = require('../utils/utils');

const transporter = nodemailer.createTransport(config.smtp);

exports.register = async (req, res) => {
  const { username, password, email } = req.body;
  const normalizedEmail = email.toLowerCase();
  const db = req.db;

  await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM PendingUsers WHERE verification_expiry < ?`,
      [new Date().toISOString()],
      err => err ? reject(err) : resolve()
    )
  );

  const existingUser = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Users WHERE username = ? OR email = ?`, [username, normalizedEmail],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (existingUser) {
    logger.warn('Registration attempt with existing username/email', { username, email: normalizedEmail });
    throw new Error('Пользователь с таким логином или email уже существует');
  }

  const existingPending = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM PendingUsers WHERE username = ? OR email = ?`, [username, normalizedEmail],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (existingPending) {
    logger.warn('Repeat registration attempt (pending)', { username, email: normalizedEmail });
    throw new Error('Уже есть заявка с этим логином или email (проверьте email)');
  }

  const hashedPassword = bcrypt.hashSync(password, 10);
  const trialEndDate = getCurrentDatePlusDays(3, { username });
  const verificationCode = generateVerificationCode({ username });
  const verificationExpiry = getCurrentDatePlusDays(1 / 96, { username });

  const pendingId = await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO PendingUsers (username, password, email, trial_end_date, verification_code, verification_expiry)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [username, hashedPassword, normalizedEmail, trialEndDate, verificationCode, verificationExpiry],
      function (err) { err ? reject(err) : resolve(this.lastID); }
    )
  );

  try {
    await transporter.sendMail({
      from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
      to: normalizedEmail,
      subject: 'Verify your email',
      text: `Your verification code is: ${verificationCode}. Please enter it in the app to verify your account.`,
    });
    logger.info('Verification code sent to user', { username, email: normalizedEmail, pendingId });
  } catch (emailError) {
    await new Promise((resolve, reject) =>
      db.run(
        `DELETE FROM PendingUsers WHERE id = ?`, [pendingId],
        err => err ? reject(err) : resolve()
      )
    );
    logger.error('Failed to send registration verification email', { error: emailError, username, email: normalizedEmail });
    throw new Error('Не удалось отправить email с кодом верификации');
  }

  res.json({ username, email: normalizedEmail, message: 'Код верификации отправлен на ваш email' });
};

exports.verifyEmail = async (req, res) => {
  const { username, email, verificationCode } = req.body;
  const db = req.db;

  const pendingUser = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, verification_code, verification_expiry, password, trial_end_date FROM PendingUsers WHERE username = ? AND email = ?`,
      [username, email],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!pendingUser) {
    logger.warn('Verification attempt for non-existent pending user', { username, email });
    throw new Error('Заявка не найдена');
  }
  if (pendingUser.verification_code !== verificationCode) {
    logger.warn('Verification attempt with wrong code', { username, email, inputCode: verificationCode, realCode: pendingUser.verification_code });
    throw new Error('Неверный код верификации');
  }
  if (new Date(pendingUser.verification_expiry) < new Date()) {
    logger.warn('Verification attempt with expired code', { username, email });
    throw new Error('Срок действия кода истёк');
  }

  try {
    const { privateKey, clientIp } = await generateVpnKey(pendingUser.id, db);
    await new Promise((resolve, reject) =>
      db.run(
        `INSERT INTO Users (username, password, email, trial_end_date, vpn_key, client_ip, paid_until) VALUES (?, ?, ?, ?, ?, ?, NULL)`,
        [username, pendingUser.password, email, pendingUser.trial_end_date, privateKey, clientIp],
        function (err) { err ? reject(err) : resolve(this.lastID); }
      )
    );
    await new Promise((resolve, reject) =>
      db.run(
        `DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id],
        err => err ? reject(err) : resolve()
      )
    );
    logger.info('User successfully verified and created', { username, email, clientIp });
    res.json({ message: 'Email успешно верифицирован, аккаунт создан' });
  } catch (e) {
    await new Promise((resolve, reject) =>
      db.run(
        `DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id],
        err => err ? reject(err) : resolve()
      )
    );
    logger.error('Failed to create user after verification', { username, email, error: e.message });
    throw new Error('Не удалось завершить верификацию: ' + e.message);
  }
};

// ------- Главное изменение: Разрешаем логин всегда, статус даём через can_use ---------
exports.login = async (req, res) => {
  const { username, password, device_token, device_model, device_os } = req.body;
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT * FROM Users WHERE username = ?`,
      [username],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) {
    logger.warn('Login attempt: user not found', { username });
    throw new Error('Пользователь не найден');
  }
  if (!bcrypt.compareSync(password, user.password)) {
    logger.warn('Login attempt: wrong password', { username, userId: user.id });
    throw new Error('Неверный пароль');
  }

  // Теперь логика "can_use" на сервере, но не блокируем логин
  const now = new Date();
  const isTrial = user.trial_end_date && new Date(user.trial_end_date) > now;
  const isPaid = user.is_paid && user.paid_until && new Date(user.paid_until) > now;
  const canUse = isTrial || isPaid;

  let currentDeviceCount = 0;
  if (device_token) {
    const result = await new Promise((resolve, reject) =>
      db.get(
        `SELECT COUNT(*) as device_count FROM Devices WHERE user_id = ?`,
        [user.id],
        (err, row) => err ? reject(err) : resolve(row)
      )
    );
    currentDeviceCount = result.device_count;
    const maxDevices = user.subscription_level === 1 ? 6 : 3;
    const existingDevice = await new Promise((resolve, reject) =>
      db.get(
        `SELECT id FROM Devices WHERE user_id = ? AND device_token = ?`,
        [user.id, device_token],
        (err, device) => err ? reject(err) : resolve(device)
      )
    );
    if (!existingDevice) {
      if (currentDeviceCount >= maxDevices) {
        logger.warn('Login attempt: device limit exceeded', { username, userId: user.id, device_token });
        throw new Error(`Достигнут лимит устройств (${maxDevices})`);
      }
      await new Promise((resolve, reject) =>
        db.run(
          `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
          [user.id, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
          err => err ? reject(err) : resolve()
        )
      );
      currentDeviceCount++;
    } else {
      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Devices SET last_seen = ? WHERE user_id = ? AND device_token = ?`,
          [new Date().toISOString(), user.id, device_token],
          err => err ? reject(err) : resolve()
        )
      );
    }
  }

  const token = generateToken({ userId: user.id, username });
  const tokenExpiry = getCurrentDatePlusDays(30, { userId: user.id, username });
  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET auth_token = ?, token_expiry = ?, device_count = ? WHERE id = ?`,
      [token, tokenExpiry, currentDeviceCount, user.id],
      err => err ? reject(err) : resolve()
    )
  );

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT OR REPLACE INTO UserStats (user_id, login_count, last_login, device_count)
       VALUES (?, COALESCE((SELECT login_count + 1 FROM UserStats WHERE user_id = ?), 1), ?, ?)`,
      [user.id, user.id, new Date().toISOString(), currentDeviceCount],
      err => err ? reject(err) : resolve()
    )
  );

  logger.info('User logged in', { userId: user.id, username, device_token });
  res.json({
    token: token,
    user: {
      id: user.id,
      username: user.username,
      email_verified: user.email_verified,
      is_paid: isPaid,
      paid_until: user.paid_until,
      subscription_level: user.subscription_level,
      vpn_key: user.vpn_key || null,
      trial_end_date: user.trial_end_date,
      device_count: currentDeviceCount,
      is_trial: isTrial,
      can_use: canUse
    }
  });
};

exports.validateToken = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error('Token is required');
  const token = authHeader.split(' ')[1];
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username, email_verified, is_paid, paid_until, subscription_level, vpn_key, trial_end_date, device_count
       FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) {
    logger.warn('Token validation failed: token not found or expired', { token });
    throw new Error('Invalid or expired token');
  }

  const now = new Date();
  const isTrial = user.trial_end_date && new Date(user.trial_end_date) > now;
  const isPaid = user.is_paid && user.paid_until && new Date(user.paid_until) > now;
  const canUse = isTrial || isPaid;

  logger.info('Token validated', { userId: user.id, username: user.username, token });
  res.json({
    id: user.id,
    username: user.username,
    email_verified: user.email_verified,
    is_paid: isPaid,
    paid_until: user.paid_until,
    subscription_level: user.subscription_level,
    vpn_key: user.vpn_key || null,
    trial_end_date: user.trial_end_date,
    device_count: user.device_count,
    is_trial: isTrial,
    can_use: canUse
  });
};

exports.logout = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error('Token is required');
  const token = authHeader.split(' ')[1];
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username FROM Users WHERE auth_token = ?`,
      [token],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  const result = await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
      [token],
      function (err) { err ? reject(err) : resolve(this.changes); }
    )
  );
  if (result === 0) {
    logger.warn('Logout failed: token not found', { token });
    throw new Error('Token not found');
  }
  logger.info('User logged out', { userId: user?.id, username: user?.username, token });
  res.json({ message: 'Logged out successfully' });
};

exports.forgotPassword = async (req, res) => {
  const { username } = req.body;
  if (!username) throw new Error('Логин обязателен для восстановления пароля');
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT id, email FROM Users WHERE username = ?`, [username], (err, user) =>
      err ? reject(err) : resolve(user))
  );
  if (!user) {
    logger.warn('Password reset requested for non-existent user', { username });
    throw new Error('Пользователь с таким логином не найден');
  }

  const resetCode = generateVerificationCode({ userId: user.id, username });
  const expiryDate = getCurrentDatePlusDays(1 / 96, { userId: user.id, username });

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO PasswordReset (email, reset_code, expiry_date) VALUES (?, ?, ?)`,
      [user.email, resetCode, expiryDate],
      err => err ? reject(err) : resolve()
    )
  );

  try {
    await transporter.sendMail({
      from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
      to: user.email,
      subject: 'Password Reset',
      text: `Your password reset code is: ${resetCode}. Please use it in the app to reset your password.`,
    });
    logger.info('Password reset instructions sent', { userId: user.id, username, email: user.email });
  } catch (emailError) {
    await new Promise((resolve, reject) =>
      db.run(
        `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
        [user.email, resetCode],
        err => err ? reject(err) : resolve()
      )
    );
    logger.error('Failed to send password reset email', { error: emailError, userId: user.id, username });
    throw new Error('Не удалось отправить email с инструкциями');
  }

  res.json({ message: 'Инструкции по восстановлению отправлены на ваш email' });
};

exports.resetPassword = async (req, res) => {
  const { username, resetCode, newPassword } = req.body;
  if (!username || !resetCode || !newPassword) throw new Error('Все поля (логин, код восстановления и новый пароль) обязательны');
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, email FROM Users WHERE username = ?`,
      [username],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user) {
    logger.warn('Password reset attempt for non-existent user', { username });
    throw new Error('Пользователь не найден');
  }
  const email = user.email;

  const reset = await new Promise((resolve, reject) =>
    db.get(
      `SELECT * FROM PasswordReset WHERE email = ? AND reset_code = ? AND expiry_date > ?`,
      [email, resetCode, new Date().toISOString()],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );
  if (!reset) {
    logger.warn('Password reset attempt with invalid or expired code', { username, email });
    throw new Error('Неверный или истёкший код восстановления');
  }

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET password = ? WHERE username = ?`,
      [hashedPassword, username],
      err => err ? reject(err) : resolve()
    )
  );
  await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
      [email, resetCode],
      err => err ? reject(err) : resolve()
    )
  );
  logger.info('Password reset successful', { userId: user.id, username });
  res.json({ message: 'Пароль успешно сброшен' });
};

// Новый endpoint: получить полный статус подписки
exports.subscriptionStatus = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error('Token is required');
  const token = authHeader.split(' ')[1];
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT id, trial_end_date, is_paid, paid_until, subscription_level, device_count FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => err ? reject(err) : resolve(user))
  );
  if (!user) throw new Error('Invalid or expired token');

  const now = new Date();
  let isTrial = false;
  let trialEnd = user.trial_end_date ? new Date(user.trial_end_date) : null;
  if (trialEnd && trialEnd > now) isTrial = true;

  let isPaid = false;
  let paidUntil = user.paid_until ? new Date(user.paid_until) : null;
  if (user.is_paid && paidUntil && paidUntil > now) isPaid = true;

  res.json({
    is_trial: isTrial,
    trial_end_date: trialEnd ? trialEnd.toISOString() : null,
    is_paid: isPaid,
    paid_until: paidUntil ? paidUntil.toISOString() : null,
    can_use: isTrial || isPaid,
    subscription_level: user.subscription_level,
    device_count: user.device_count,
    max_devices: user.subscription_level === 1 ? 6 : 3,
  });
};
