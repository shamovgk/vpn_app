const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const path = require('path');
const { exec } = require('child_process');
const nodemailer = require('nodemailer');
const session = require('express-session');
const YooKassa = require('yookassa');

const yooKassa = new YooKassa({
  shopId: '1122441',
  secretKey: 'test_F74pib2GSiKTfXymHkFmazWj9pLyS8-Sd2pzg-p9H2c'
});

const app = express();
app.set('view engine', 'ejs');
app.set('views', __dirname); 
app.use(express.json());
app.use(session({
  secret: 'your_secret_key',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
}));

const dbPath = path.join(__dirname, 'vpn.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database', err.message);
  } else {
    console.log('Connected to the SQLite database at', dbPath);
    createTables();
  }
});

function createTables() {
  db.serialize(() => {
    db.run(`
      CREATE TABLE IF NOT EXISTS Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        email_verified INTEGER DEFAULT 1,
        is_paid INTEGER DEFAULT 0,
        vpn_key TEXT,
        trial_end_date TEXT,
        device_count INTEGER DEFAULT 0,
        auth_token TEXT,
        token_expiry TEXT,
        client_ip TEXT,
        is_admin INTEGER DEFAULT 0
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS PendingUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        trial_end_date TEXT,
        verification_code TEXT,
        verification_expiry TEXT
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS Devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        device_token TEXT NOT NULL UNIQUE,
        FOREIGN KEY (user_id) REFERENCES Users(id)
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS PasswordReset (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        reset_code TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        FOREIGN KEY (email) REFERENCES Users(email)
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS UserStats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        login_count INTEGER DEFAULT 0,
        last_login TEXT,
        device_count INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        total_traffic INTEGER DEFAULT 0,
        active_duration INTEGER DEFAULT 0,
        payment_count INTEGER DEFAULT 0,
        last_payment_date TEXT,
        FOREIGN KEY (user_id) REFERENCES Users(id)
      )
    `);
  });
}

function getCurrentDatePlusDays(days) {
  const date = new Date();
  const milliseconds = days * 24 * 60 * 60 * 1000 + 1000;
  date.setTime(date.getTime() + milliseconds);
  const result = date.toISOString();
  console.log(`getCurrentDatePlusDays(${days}) = ${result}`);
  return result;
}

function generateToken() {
  return crypto.randomBytes(16).toString('hex');
}

function generateVerificationCode() {
  return crypto.randomBytes(3).toString('hex').toUpperCase();
}

async function generateVpnKey(userId, db) {
  const scriptPath = '/root/vpn-server/generate_vpn_key.sh';
  const configScriptPath = '/root/vpn-server/add_to_wg_conf.sh';

  try {
    const { privateKey } = await executeScript(scriptPath);
    console.log(`Generated VPN private key for user ID ${userId}`);

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE Users SET vpn_key = ? WHERE id = ?`,
        [privateKey, userId],
        (err) => (err ? reject(err) : resolve())
      );
    });

    const { clientIp } = await executeScript(configScriptPath, [privateKey, userId.toString()]);
    console.log(`Assigned client IP ${clientIp} to user ID ${userId}`);

    await new Promise((resolve, reject) => {
      db.run(
        `UPDATE Users SET client_ip = ? WHERE id = ?`,
        [clientIp, userId],
        (err) => (err ? reject(err) : resolve())
      );
    });

    return { privateKey, clientIp };
  } catch (error) {
    console.error(`VPN key generation failed for user ID ${userId}: ${error.message}`);
    throw new Error(`Failed to generate VPN key: ${error.message}`);
  }
}

function executeScript(scriptPath, args = []) {
  return new Promise((resolve, reject) => {
    const { spawn } = require('child_process');
    const child = spawn('bash', [scriptPath, ...args], { maxBuffer: 1024 * 1024, encoding: 'utf8' });

    let stdout = '';
    let stderr = '';

    child.stdout.on('data', (data) => (stdout += data));
    child.stderr.on('data', (data) => (stderr += data));

    child.on('error', (error) => reject(new Error(`Script execution error: ${error.message}`)));
    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Script failed: exit code ${code}, stderr=${stderr}`));
      } else {
        try {
          resolve(JSON.parse(stdout));
        } catch (e) {
          reject(new Error(`Invalid JSON output: ${stdout}, stderr=${stderr}`));
        }
      }
    });
  });
}

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: 'UgbuganSoft@gmail.com',
    pass: 'ohkr jgtg unce hjuc',
  },
});

function sendVerificationEmail(email, verificationCode) {
  const mailOptions = {
    from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
    to: email,
    subject: 'Verify your email',
    text: `Your verification code is: ${verificationCode}. Please enter it in the app to verify your account.`,
  };

  return transporter.sendMail(mailOptions);
}

function sendResetEmail(email, resetCode) {
  const mailOptions = {
    from: 'UgbuganVPN <UgbuganSoft@gmail.com>',
    to: email,
    subject: 'Password Reset',
    text: `Your password reset code is: ${resetCode}. Please use it in the app to reset your password.`,
  };

  return transporter.sendMail(mailOptions);
}

app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ error: 'Все поля обязательны для заполнения' });
  }

  const normalizedEmail = email.toLowerCase();

  db.run(
    `DELETE FROM PendingUsers WHERE verification_expiry < ?`,
    [new Date().toISOString()],
    (err) => {
      if (err) console.error('Error cleaning expired pending users:', err.message);
    }
  );

  db.get(`SELECT id FROM Users WHERE username = ?`, [username], (err, existingUsername) => {
    if (err) {
      console.error('Database error:', err.message);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
    }
    if (existingUsername) {
      return res.status(400).json({ error: 'Такой логин уже существует' });
    }

    db.get(`SELECT id FROM Users WHERE email = ?`, [normalizedEmail], (err, existingEmail) => {
      if (err) {
        console.error('Database error:', err.message);
        return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
      }
      if (existingEmail) {
        return res.status(400).json({ error: 'Этот email уже используется' });
      }

      db.get(`SELECT id FROM PendingUsers WHERE username = ?`, [username], (err, pendingUsername) => {
        if (err) {
          console.error('Database error:', err.message);
          return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
        }
        if (pendingUsername) {
          return res.status(400).json({ error: 'Этот логин уже ожидает верификации' });
        }

        db.get(`SELECT id FROM PendingUsers WHERE email = ?`, [normalizedEmail], (err, pendingEmail) => {
          if (err) {
            console.error('Database error:', err.message);
            return res.status(500).json({ error: 'Внутренняя ошибка сервера' });
          }
          if (pendingEmail) {
            return res.status(400).json({ error: 'Этот email уже ожидает верификации' });
          }

          const hashedPassword = bcrypt.hashSync(password, 10);
          const trialEndDate = getCurrentDatePlusDays(3);
          const verificationCode = generateVerificationCode();
          const verificationExpiry = getCurrentDatePlusDays(1 / 96); // 15 минут

          if (!username.trim()) {
            return res.status(400).json({ error: 'Логин не может быть пустым' });
          }

          db.run(
            `INSERT INTO PendingUsers (username, password, email, trial_end_date, verification_code, verification_expiry) VALUES (?, ?, ?, ?, ?, ?)`,
            [username, hashedPassword, normalizedEmail, trialEndDate, verificationCode, verificationExpiry],
            async function (err) {
              if (err) {
                console.error('Registration error:', err.message);
                return res.status(400).json({ error: 'Ошибка регистрации: ' + err.message });
              }

              try {
                await sendVerificationEmail(normalizedEmail, verificationCode);
                res.json({ id: this.lastID, username, email: normalizedEmail, message: 'Код верификации отправлен на ваш email' });
              } catch (emailError) {
                console.error('Email sending error:', emailError.message);
                db.run(`DELETE FROM PendingUsers WHERE id = ?`, [this.lastID], (deleteErr) => {
                  if (deleteErr) console.error('Cleanup error:', deleteErr.message);
                });
                return res.status(500).json({ error: 'Не удалось отправить email с кодом верификации' });
              }
            }
          );
        });
      });
    });
  });
});

app.post('/verify-email', (req, res) => {
  const { username, email, verificationCode } = req.body;
  if (!username || !email || !verificationCode) {
    return res.status(400).json({ error: 'Все поля (логин, email и код верификации) обязательны' });
  }

  db.get(
    `SELECT id, verification_code, verification_expiry, password, trial_end_date FROM PendingUsers WHERE username = ? AND email = ?`,
    [username, email],
    async (err, pendingUser) => {
      if (err || !pendingUser) {
        return res.status(500).json({ error: 'Внутренняя ошибка сервера при проверке верификации' });
      }
      if (pendingUser.verification_code !== verificationCode) {
        return res.status(400).json({ error: 'Неверный код верификации' });
      }
      if (new Date(pendingUser.verification_expiry) < new Date()) {
        return res.status(400).json({ error: 'Срок действия кода верификации истёк' });
      }

      try {
        const { privateKey, clientIp } = await generateVpnKey(pendingUser.id, db);
        await new Promise((resolve, reject) =>
          db.run(
            `INSERT INTO Users (username, password, email, trial_end_date, vpn_key, client_ip) VALUES (?, ?, ?, ?, ?, ?)`,
            [username, pendingUser.password, email, pendingUser.trial_end_date, privateKey, clientIp],
            (err) => (err ? reject(err) : resolve())
          )
        );
        db.run(`DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id], (err) => {
          if (err) console.error('Cleanup error:', err.message);
        });
        res.json({ message: 'Email успешно верифицирован, аккаунт создан' });
      } catch (e) {
        console.error('Verification setup failed:', e.message);
        db.run(`DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id], (err) => {
          if (err) console.error('Cleanup error:', err.message);
        });
        res.status(500).json({ error: 'Не удалось завершить верификацию: ' + e.message });
      }
    }
  );
});

app.post('/cancel-registration', (req, res) => {
  const { username, email } = req.body;
  if (!username || !email) {
    return res.status(400).json({ error: 'Логин и email обязательны для отмены регистрации' });
  }

  db.run(
    `DELETE FROM PendingUsers WHERE username = ? AND email = ?`,
    [username, email],
    (err) => {
      if (err) {
        console.error('Error canceling registration:', err.message);
        return res.status(500).json({ error: 'Не удалось отменить регистрацию из-за ошибки сервера' });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Регистрация с указанными данными не найдена' });
      }
      res.json({ message: 'Регистрация успешно отменена' });
    }
  );
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Логин и пароль обязательны' });
  }

  db.get(
    `SELECT id, username, password, email_verified, is_paid, vpn_key, trial_end_date, device_count
     FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) {
        console.error('Login error:', err.message);
        return res.status(500).json({ error: 'Внутренняя ошибка сервера при входе' });
      }
      if (!user) {
        return res.status(404).json({ error: 'Пользователь не найден' });
      }
      if (!bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Неверный пароль' });
      }
      const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
      if (!user.is_paid && trialExpired) {
        return res.status(403).json({ error: 'Срок действия пробного периода истёк' });
      }

      const token = generateToken();
      const tokenExpiry = getCurrentDatePlusDays(30);
      db.run(
        `UPDATE Users SET auth_token = ?, token_expiry = ? WHERE id = ?`,
        [token, tokenExpiry, user.id],
        (err) => {
          if (err) {
            console.error('Token update error:', err.message);
            return res.status(500).json({ error: 'Не удалось обновить токен авторизации' });
          }
          db.run(
            `INSERT OR REPLACE INTO UserStats (user_id, login_count, last_login, device_count)
             VALUES (?, COALESCE((SELECT login_count + 1 FROM UserStats WHERE user_id = ?), 1), ?, (SELECT device_count FROM Users WHERE id = ?))`,
            [user.id, user.id, new Date().toISOString(), user.id],
            (err) => {
              if (err) console.error('Stats update error:', err.message);
            }
          );
          res.json({
            id: user.id,
            username: user.username,
            email_verified: user.email_verified,
            is_paid: user.is_paid,
            vpn_key: user.vpn_key || null,
            trial_end_date: user.trial_end_date,
            device_count: user.device_count,
            auth_token: token
          });
        }
      );
    }
  );
});

app.get('/validate-token', (req, res) => {
  const { token } = req.query;
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  db.get(
    `SELECT id, username, email_verified, is_paid, vpn_key, trial_end_date, device_count
     FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err) {
        console.error('Token validation error:', err.message);
        return res.status(500).json({ error: err.message });
      }
      if (!user) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      res.json({
        id: user.id,
        username: user.username,
        email_verified: user.email_verified,
        is_paid: user.is_paid,
        vpn_key: user.vpn_key || null,
        device_count: user.device_count,
      });
    }
  );
});

app.post('/logout', (req, res) => {
  const { token } = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  db.run(
    `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
    [token],
    function (err) {
      if (err) {
        console.error('Logout error:', err.message);
        return res.status(500).json({ error: err.message });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Token not found' });
      }
      res.json({ message: 'Logged out successfully' });
    }
  );
});

app.post('/forgot-password', (req, res) => {
  const { username } = req.body;
  if (!username) {
    return res.status(400).json({ error: 'Логин обязателен для восстановления пароля' });
  }

  db.get(`SELECT id, email FROM Users WHERE username = ?`, [username], (err, user) => {
    if (err) {
      console.error('Database error:', err.message);
      return res.status(500).json({ error: 'Внутренняя ошибка сервера при запросе восстановления' });
    }
    if (!user) {
      return res.status(404).json({ error: 'Пользователь с таким логином не найден' });
    }

    const resetCode = generateVerificationCode();
    const expiryDate = getCurrentDatePlusDays(1 / 96); // Код действителен 15 минут

    db.run(
      `INSERT INTO PasswordReset (email, reset_code, expiry_date) VALUES (?, ?, ?)`,
      [user.email, resetCode, expiryDate],
      async (err) => {
        if (err) {
          console.error('Error saving reset code:', err.message);
          return res.status(500).json({ error: 'Не удалось сгенерировать код восстановления' });
        }

        try {
          await sendResetEmail(user.email, resetCode);
          res.json({ message: 'Инструкции по восстановлению отправлены на ваш email' });
        } catch (emailError) {
          console.error('Email sending error:', emailError.message);
          db.run(`DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`, [user.email, resetCode], (deleteErr) => {
            if (deleteErr) console.error('Cleanup error:', deleteErr.message);
          });
          return res.status(500).json({ error: 'Не удалось отправить email с инструкциями' });
        }
      }
    );
  });
});

app.post('/reset-password', (req, res) => {
  const { username, resetCode, newPassword } = req.body;
  if (!username || !resetCode || !newPassword) {
    return res.status(400).json({ error: 'Все поля (логин, код восстановления и новый пароль) обязательны' });
  }

  db.get(
    `SELECT email FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) {
        console.error('Database error:', err.message);
        return res.status(500).json({ error: 'Внутренняя ошибка сервера при сбросе пароля' });
      }
      if (!user) {
        return res.status(404).json({ error: 'Пользователь не найден' });
      }

      const email = user.email;

      db.get(
        `SELECT * FROM PasswordReset WHERE email = ? AND reset_code = ? AND expiry_date > ?`,
        [email, resetCode, new Date().toISOString()],
        (err, reset) => {
          if (err) {
            console.error('Database error:', err.message);
            return res.status(500).json({ error: 'Внутренняя ошибка сервера при проверке кода' });
          }
          if (!reset) {
            return res.status(400).json({ error: 'Неверный или истёкший код восстановления' });
          }

          const hashedPassword = bcrypt.hashSync(newPassword, 10);
          db.run(
            `UPDATE Users SET password = ? WHERE username = ?`,
            [hashedPassword, username],
            (err) => {
              if (err) {
                console.error('Error updating password:', err.message);
                return res.status(500).json({ error: 'Не удалось обновить пароль' });
              }

              db.run(
                `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
                [email, resetCode],
                (deleteErr) => {
                  if (deleteErr) console.error('Cleanup error:', deleteErr.message);
                }
              );
              res.json({ message: 'Пароль успешно сброшен' });
            }
          );
        }
      );
    }
  );
});

app.post('/add-device', (req, res) => {
  const { user_id, device_token } = req.body;
  db.get(
    `SELECT device_count FROM Users WHERE id = ?`,
    [user_id],
    (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: 'User not found' });
      }
      if (user.device_count >= 3) {
        return res.status(400).json({ error: 'Maximum device limit (3) reached' });
      }

      db.run(
        `INSERT INTO Devices (user_id, device_token) VALUES (?, ?)`,
        [user_id, device_token],
        (err) => {
          if (err) {
            console.error('Device add error:', err.message);
            return res.status(400).json({ error: err.message });
          }
          db.run(
            `UPDATE Users SET device_count = device_count + 1 WHERE id = ?`,
            [user_id],
            (err) => {
              if (err) {
                console.error('Device count update error:', err.message);
                return res.status(500).json({ error: err.message });
              }
              res.json({ message: 'Device added successfully' });
            }
          );
        }
      );
    }
  );
});

app.get('/get-vpn-config', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(400).json({ error: 'Token is required' });
  }

  const token = authHeader.split(' ')[1];
  db.get(
    `SELECT id, username, vpn_key, client_ip, is_paid, trial_end_date, email_verified FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err) {
        return res.status(500).json({ error: 'Internal server error' });
      }
      if (!user) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      if (!user.email_verified) {
        return res.status(403).json({ error: 'Email not verified' });
      }
      const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
      if (!user.is_paid && trialExpired) {
        return res.status(403).json({ error: 'Trial period expired' });
      }

      const config = {
        serverPublicKey: 'yrDYPAHQ3+2sdvCzQ+WHErdh0dNt+5fgJbukEMw6Fg0=',
        serverAddress: '95.214.10.8:51820',
        clientPrivateKey: user.vpn_key,
        clientIp: user.client_ip,
      };
      res.json(config);
    }
  );
});

app.post('/pay-yookassa', async (req, res) => {
  const { token, amount, method } = req.body;
  console.log('Получен запрос на /pay-yookassa:', req.body);
  console.log('Перед вызовом createPayment');
  try {
    const payment = await yooKassa.createPayment({
      amount: { value: amount, currency: 'RUB' },
      payment_method_data: {
        type: method || 'bank_card',
        payment_token: token,
      },
      confirmation: { type: 'redirect', return_url: 'myvpn://payment-success' },
      capture: true,
      description: 'Оплата VPN',
    });
    console.log('Ответ от YooKassa:', payment);
    if (payment.status === 'succeeded') {
      db.run(
        `UPDATE Users SET is_paid = 1 WHERE id = ?`,
        [userId],
        (err) => {
          if (err) console.error('Error updating is_paid:', err.message);
        }
      );
      db.run(
        `INSERT OR REPLACE INTO UserStats (user_id, payment_count, last_payment_date)
         VALUES (?, COALESCE((SELECT payment_count + 1 FROM UserStats WHERE user_id = ?), 1), ?)`,
        [userId, userId, new Date().toISOString()],
        (err) => {
          if (err) console.error('Stats payment update error:', err.message);
        }
      );
    }
    res.json({
      status: payment.status,
      paymentId: payment.id,
      confirmationUrl: payment.confirmation && payment.confirmation.confirmation_url
    });
  } catch (e) {
    console.error('Ошибка при создании платежа:', e.message, e);
    res.status(500).json({ error: e.message });
  }
});

// Админская часть

function adminAuth(req, res, next) {
  if (!req.session.admin) {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
}

app.post('/admin/login', (req, res) => {
  const { username, password } = req.body;
  db.get(
    `SELECT id, username, password, is_admin FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err || !user || user.is_admin !== 1 || !bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Invalid credentials or not an admin' });
      }
      req.session.admin = true;
      req.session.userId = user.id;
      res.json({ message: 'Admin login successful' });
    }
  );
});

app.post('/admin/logout', (req, res) => {
  req.session.destroy((err) => err ? res.status(500).json({ error: 'Failed to logout' }) : res.json({ message: 'Logged out' }));
});

app.get('/admin/login', (req, res) => {
  if (req.session.admin) return res.redirect('/admin');
  res.render('login', { title: 'Admin Login' });
});

app.get('/admin', adminAuth, (req, res) => {
  db.all(`SELECT id, username, email, email_verified, is_paid, trial_end_date, device_count FROM Users WHERE is_admin = 0`, [], (err, users) => {
    if (err) {
      console.error('Admin page error:', err.message);
      return res.status(500).render('admin', { title: 'Admin Panel', users: [], error: 'Failed to load users' });
    }
    res.render('admin', { title: 'Admin Panel', users: users || [] });
  });
});

app.put('/admin/users/:id', adminAuth, (req, res) => {
  const { id } = req.params;
  const { is_paid, trial_end_date } = req.body;
  db.run(
    `UPDATE Users SET is_paid = ?, trial_end_date = ? WHERE id = ?`,
    [is_paid ? 1 : 0, trial_end_date, id],
    (err) => {
      if (err) {
        console.error('User update error:', err.message);
        return res.status(500).json({ error: 'Update failed' });
      }
      res.json({ message: 'User updated' });
    }
  );
});

app.get('/admin/users/search', adminAuth, (req, res) => {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Username is required' });
  db.all(
    `SELECT id, username, email, email_verified, is_paid, trial_end_date, device_count FROM Users WHERE username LIKE ? AND is_admin = 0`,
    [`%${username}%`],
    (err, users) => {
      if (err) {
        console.error('Search error:', err.message);
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(users || []);
    }
  );
});

app.get('/admin/stats', adminAuth, (req, res) => {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  db.all(`
    SELECT 
      u.username,
      COUNT(CASE WHEN s.last_login >= ? THEN 1 END) as active_users,
      SUM(CASE WHEN u.is_paid = 1 THEN 1 ELSE 0 END) as paid_users,
      SUM(CASE WHEN u.trial_end_date > ? AND u.is_paid = 0 THEN 1 ELSE 0 END) as trial_users,
      COUNT(CASE WHEN u.created_at >= ? THEN 1 END) as registrations,
      ROUND((SUM(CASE WHEN u.email_verified = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as email_verified_pct
    FROM Users u
    LEFT JOIN UserStats s ON u.id = s.user_id
    WHERE u.is_admin = 0
    GROUP BY u.username
  `, [thirtyDaysAgo, new Date().toISOString(), thirtyDaysAgo], (err, userActivity) => {
    if (err) {
      console.error('Stats error:', err.message);
      return res.status(500).render('stats', { title: 'Admin Statistics', userActivity: [], error: 'Failed to load stats' });
    }
    res.render('stats', { title: 'Admin Statistics', userActivity: userActivity || [] });
  });
});

const PORT = 3000;
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));