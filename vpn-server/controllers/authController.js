const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
const { config } = require('../config/config');
const { getCurrentDatePlusDays, generateToken, generateVerificationCode, generateVpnKey } = require('../utils/utils');

const transporter = nodemailer.createTransport(config.smtp);

async function register(req, res) {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ error: 'Все поля обязательны для заполнения' });
  }

  const normalizedEmail = email.toLowerCase();

  req.db.run(
    `DELETE FROM PendingUsers WHERE verification_expiry < ?`,
    [new Date().toISOString()],
    (err) => { if (err) console.error('Error cleaning expired pending users:', err.message); }
  );

  req.db.get(`SELECT id FROM Users WHERE username = ?`, [username], (err, existingUsername) => {
    if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    if (existingUsername) return res.status(400).json({ error: 'Такой логин уже существует' });

    req.db.get(`SELECT id FROM Users WHERE email = ?`, [normalizedEmail], (err, existingEmail) => {
      if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
      if (existingEmail) return res.status(400).json({ error: 'Этот email уже используется' });

      req.db.get(`SELECT id FROM PendingUsers WHERE username = ?`, [username], (err, pendingUsername) => {
        if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
        if (pendingUsername) return res.status(400).json({ error: 'Этот логин уже ожидает верификации' });

        req.db.get(`SELECT id FROM PendingUsers WHERE email = ?`, [normalizedEmail], (err, pendingEmail) => {
          if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
          if (pendingEmail) return res.status(400).json({ error: 'Этот email уже ожидает верификации' });

          const hashedPassword = bcrypt.hashSync(password, 10);
          const trialEndDate = getCurrentDatePlusDays(3);
          const verificationCode = generateVerificationCode();
          const verificationExpiry = getCurrentDatePlusDays(1 / 96);

          if (!username.trim()) return res.status(400).json({ error: 'Логин не может быть пустым' });

          req.db.run(
            `INSERT INTO PendingUsers (username, password, email, trial_end_date, verification_code, verification_expiry) VALUES (?, ?, ?, ?, ?, ?)`,
            [username, hashedPassword, normalizedEmail, trialEndDate, verificationCode, verificationExpiry],
            async function (err) {
              if (err) return res.status(400).json({ error: 'Ошибка регистрации: ' + err.message });

              try {
                await transporter.sendMail({
                  from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
                  to: normalizedEmail,
                  subject: 'Verify your email',
                  text: `Your verification code is: ${verificationCode}. Please enter it in the app to verify your account.`,
                });
                res.json({ id: this.lastID, username, email: normalizedEmail, message: 'Код верификации отправлен на ваш email' });
              } catch (emailError) {
                console.error('Email sending error:', emailError.message);
                req.db.run(`DELETE FROM PendingUsers WHERE id = ?`, [this.lastID], (deleteErr) => { if (deleteErr) console.error('Cleanup error:', deleteErr.message); });
                return res.status(500).json({ error: 'Не удалось отправить email с кодом верификации' });
              }
            }
          );
        });
      });
    });
  });
}

async function verifyEmail(req, res) {
  const { username, email, verificationCode } = req.body;
  if (!username || !email || !verificationCode) return res.status(400).json({ error: 'Все поля (логин, email и код верификации) обязательны' });

  req.db.get(
    `SELECT id, verification_code, verification_expiry, password, trial_end_date FROM PendingUsers WHERE username = ? AND email = ?`,
    [username, email],
    async (err, pendingUser) => {
      if (err || !pendingUser) return res.status(500).json({ error: 'Внутренняя ошибка сервера при проверке верификации' });
      if (pendingUser.verification_code !== verificationCode) return res.status(400).json({ error: 'Неверный код верификации' });
      if (new Date(pendingUser.verification_expiry) < new Date()) return res.status(400).json({ error: 'Срок действия кода верификации истёк' });

      try {
        const { privateKey, clientIp } = await generateVpnKey(pendingUser.id, req.db);
        await new Promise((resolve, reject) =>
          req.db.run(
            `INSERT INTO Users (username, password, email, trial_end_date, vpn_key, client_ip) VALUES (?, ?, ?, ?, ?, ?)`,
            [username, pendingUser.password, email, pendingUser.trial_end_date, privateKey, clientIp],
            (err) => (err ? reject(err) : resolve())
          )
        );
        req.db.run(`DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id], (err) => { if (err) console.error('Cleanup error:', err.message); });
        res.json({ message: 'Email успешно верифицирован, аккаунт создан' });
      } catch (e) {
        console.error('Verification setup failed:', e.message);
        req.db.run(`DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id], (deleteErr) => { if (deleteErr) console.error('Cleanup error:', deleteErr.message); });
        res.status(500).json({ error: 'Не удалось завершить верификацию: ' + e.message });
      }
    }
  );
}

function login(req, res) {
  const { username, password, device_token, device_model, device_os } = req.body;
  if (!username || !password) return res.status(400).json({ error: 'Логин и пароль обязательны' });

  req.db.get(
    `SELECT id, username, password, email_verified, is_paid, subscription_level, vpn_key, trial_end_date, device_count FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера при входе' });
      if (!user) return res.status(404).json({ error: 'Пользователь не найден' });
      if (!bcrypt.compareSync(password, user.password)) return res.status(401).json({ error: 'Неверный пароль' });
      const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
      if (!user.is_paid && trialExpired) return res.status(403).json({ error: 'Срок действия пробного периода истёк' });

      const maxDevices = user.subscription_level === 1 ? 6 : 3;
      req.db.get(`SELECT COUNT(*) as device_count FROM Devices WHERE user_id = ?`, [user.id], (err, result) => {
        if (err) return res.status(500).json({ error: 'Ошибка при подсчёте устройств' });
        let currentDeviceCount = result.device_count;

        if (device_token) {
          req.db.get(
            `SELECT id FROM Devices WHERE user_id = ? AND device_token = ?`,
            [user.id, device_token],
            (err, existingDevice) => {
              if (err) return res.status(500).json({ error: 'Ошибка проверки устройства' });
              if (!existingDevice) {
                if (currentDeviceCount >= maxDevices) return res.status(403).json({ error: `Достигнут лимит устройств (${maxDevices}). Удалите одно устройство или обновите подписку.` });
                req.db.run(
                  `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
                  [user.id, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
                  (err) => { if (err) console.error('Device registration error:', err.message); currentDeviceCount++; }
                );
              } else {
                req.db.run(
                  `UPDATE Devices SET last_seen = ? WHERE user_id = ? AND device_token = ?`,
                  [new Date().toISOString(), user.id, device_token],
                  (err) => { if (err) console.error('Device update error:', err.message); }
                );
              }

              const token = generateToken();
              const tokenExpiry = getCurrentDatePlusDays(30);
              req.db.run(
                `UPDATE Users SET auth_token = ?, token_expiry = ?, device_count = ? WHERE id = ?`,
                [token, tokenExpiry, currentDeviceCount, user.id],
                (err) => {
                  if (err) return res.status(500).json({ error: 'Не удалось обновить токен авторизации' });
                  req.db.run(
                    `INSERT OR REPLACE INTO UserStats (user_id, login_count, last_login, device_count) VALUES (?, COALESCE((SELECT login_count + 1 FROM UserStats WHERE user_id = ?), 1), ?, ?)`,
                    [user.id, user.id, new Date().toISOString(), currentDeviceCount],
                    (err) => { if (err) console.error('Stats update error:', err.message); }
                  );
                  res.json({
                    id: user.id,
                    username: user.username,
                    email_verified: user.email_verified,
                    is_paid: user.is_paid,
                    subscription_level: user.subscription_level,
                    vpn_key: user.vpn_key || null,
                    trial_end_date: user.trial_end_date,
                    device_count: currentDeviceCount,
                    auth_token: token
                  });
                }
              );
            }
          );
        } else {
          const token = generateToken();
          const tokenExpiry = getCurrentDatePlusDays(30);
          req.db.run(
            `UPDATE Users SET auth_token = ?, token_expiry = ? WHERE id = ?`,
            [token, tokenExpiry, user.id],
            (err) => {
              if (err) return res.status(500).json({ error: 'Не удалось обновить токен авторизации' });
              req.db.run(
                `INSERT OR REPLACE INTO UserStats (user_id, login_count, last_login, device_count) VALUES (?, COALESCE((SELECT login_count + 1 FROM UserStats WHERE user_id = ?), 1), ?, ?)`,
                [user.id, user.id, new Date().toISOString(), currentDeviceCount],
                (err) => { if (err) console.error('Stats update error:', err.message); }
              );
              res.json({
                id: user.id,
                username: user.username,
                email_verified: user.email_verified,
                is_paid: user.is_paid,
                subscription_level: user.subscription_level,
                vpn_key: user.vpn_key || null,
                trial_end_date: user.trial_end_date,
                device_count: currentDeviceCount,
                auth_token: token
              });
            }
          );
        }
      });
    }
  );
}

function validateToken(req, res) {
  const { token } = req.query;
  if (!token) return res.status(400).json({ error: 'Token is required' });

  req.db.get(
    `SELECT id, username, email_verified, is_paid, subscription_level, vpn_key, trial_end_date, device_count FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err) return res.status(500).json({ error: err.message });
      if (!user) return res.status(401).json({ error: 'Invalid or expired token' });
      res.json({
        id: user.id,
        username: user.username,
        email_verified: user.email_verified,
        is_paid: user.is_paid,
        subscription_level: user.subscription_level,
        vpn_key: user.vpn_key || null,
        device_count: user.device_count,
      });
    }
  );
}

function logout(req, res) {
  const { token } = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(400).json({ error: 'Token is required' });

  req.db.run(
    `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
    [token],
    function (err) {
      if (err) return res.status(500).json({ error: err.message });
      if (this.changes === 0) return res.status(404).json({ error: 'Token not found' });
      res.json({ message: 'Logged out successfully' });
    }
  );
}

function forgotPassword(req, res) {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Логин обязателен для восстановления пароля' });

  req.db.get(`SELECT id, email FROM Users WHERE username = ?`, [username], (err, user) => {
    if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера при запросе восстановления' });
    if (!user) return res.status(404).json({ error: 'Пользователь с таким логином не найден' });

    const resetCode = generateVerificationCode();
    const expiryDate = getCurrentDatePlusDays(1 / 96);

    req.db.run(
      `INSERT INTO PasswordReset (email, reset_code, expiry_date) VALUES (?, ?, ?)`,
      [user.email, resetCode, expiryDate],
      async (err) => {
        if (err) return res.status(500).json({ error: 'Не удалось сгенерировать код восстановления' });

        try {
          await transporter.sendMail({
            from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
            to: user.email,
            subject: 'Password Reset',
            text: `Your password reset code is: ${resetCode}. Please use it in the app to reset your password.`,
          });
          res.json({ message: 'Инструкции по восстановлению отправлены на ваш email' });
        } catch (emailError) {
          console.error('Email sending error:', emailError.message);
          req.db.run(`DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`, [user.email, resetCode], (deleteErr) => { if (deleteErr) console.error('Cleanup error:', deleteErr.message); });
          return res.status(500).json({ error: 'Не удалось отправить email с инструкциями' });
        }
      }
    );
  });
}

function resetPassword(req, res) {
  const { username, resetCode, newPassword } = req.body;
  if (!username || !resetCode || !newPassword) return res.status(400).json({ error: 'Все поля (логин, код восстановления и новый пароль) обязательны' });

  req.db.get(
    `SELECT email FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера при сбросе пароля' });
      if (!user) return res.status(404).json({ error: 'Пользователь не найден' });

      const email = user.email;

      req.db.get(
        `SELECT * FROM PasswordReset WHERE email = ? AND reset_code = ? AND expiry_date > ?`,
        [email, resetCode, new Date().toISOString()],
        (err, reset) => {
          if (err) return res.status(500).json({ error: 'Внутренняя ошибка сервера при проверке кода' });
          if (!reset) return res.status(400).json({ error: 'Неверный или истёкший код восстановления' });

          const hashedPassword = bcrypt.hashSync(newPassword, 10);
          req.db.run(
            `UPDATE Users SET password = ? WHERE username = ?`,
            [hashedPassword, username],
            (err) => {
              if (err) return res.status(500).json({ error: 'Не удалось обновить пароль' });

              req.db.run(
                `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
                [email, resetCode],
                (deleteErr) => { if (deleteErr) console.error('Cleanup error:', deleteErr.message); }
              );
              res.json({ message: 'Пароль успешно сброшен' });
            }
          );
        }
      );
    }
  );
}

module.exports = { register, verifyEmail, login, validateToken, logout, forgotPassword, resetPassword };