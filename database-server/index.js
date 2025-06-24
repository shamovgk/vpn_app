const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const path = require('path');
const nodemailer = require('nodemailer');
const Brevo = require('@getbrevo/brevo');

const app = express();
app.use(express.json());

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
        email_verified INTEGER DEFAULT 0,
        is_paid INTEGER DEFAULT 0,
        vpn_key TEXT,
        trial_end_date TEXT,
        device_count INTEGER DEFAULT 0,
        family_group_id INTEGER,
        auth_token TEXT,
        token_expiry TEXT,
        verification_token TEXT
      )
    `);

    db.run(`
      CREATE TABLE IF NOT EXISTS FamilyGroups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        max_users INTEGER DEFAULT 5,
        is_paid INTEGER DEFAULT 0
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
  });
}

function getCurrentDatePlusDays(days) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString();
}

function generateToken() {
  return crypto.randomBytes(16).toString('hex');
}

function generateVpnKey() {
  return crypto.randomBytes(32).toString('base64');
}

// Настройка Brevo
const apiKey = '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'; // Замени на твой API-ключ
const apiInstance = new Brevo.TransactionalEmailsApi(); // Создаём экземпляр API
let apiKeyAuth = apiInstance.authentications['apiKey']; // Получаем объект аутентификации
apiKeyAuth.apiKey = apiKey; // Устанавливаем API-ключ

function sendVerificationEmail(email, verificationToken) {
  const verificationLink = `http://smtp-relay.brevo.com/verify-email?token=${verificationToken}`;
  const sendSmtpEmail = new Brevo.SendSmtpEmail();

  sendSmtpEmail.subject = 'Verify Your Email for UgbuganVPN';
  sendSmtpEmail.sender = {
    name: 'UgbuganVPN',
    email: '9063a2002@smtp-brevo.com', // Замени на подтверждённый отправителя
  };
  sendSmtpEmail.to = [{ email }];
  sendSmtpEmail.htmlContent = `<p>Please verify your email by clicking <a href="${verificationLink}">this link</a>.</p>`;
  sendSmtpEmail.textContent = `Please verify your email by clicking this link: ${verificationLink}`;

  return apiInstance.sendTransacEmail(sendSmtpEmail).then(
    (data) => console.log('Email sent: ' + JSON.stringify(data)),
    (error) => console.error('Email error: ', error)
  );
}


app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get(`SELECT id FROM Users WHERE email = ?`, [email], (err, row) => {
    if (row) return res.status(400).json({ error: 'Email already in use' });

    const hashedPassword = bcrypt.hashSync(password, 10);
    const trialEndDate = getCurrentDatePlusDays(3);
    const vpnKey = generateVpnKey();
    const verificationToken = generateToken();

    db.run(
      `INSERT INTO Users (username, password, email, trial_end_date, vpn_key, verification_token, email_verified) VALUES (?, ?, ?, ?, ?, ?, 0)`,
      [username, hashedPassword, email, trialEndDate, vpnKey, verificationToken],
      function (err) {
        if (err) {
          console.error('Registration error:', err.message);
          return res.status(400).json({ error: err.message });
        }
        sendVerificationEmail(email, verificationToken);
        res.json({ id: this.lastID, username, email, trial_end_date: trialEndDate, vpn_key: vpnKey });
      }
    );
  });
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  db.get(
    `SELECT id, username, password, email_verified, is_paid, vpn_key, trial_end_date, device_count, family_group_id 
     FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) {
        console.error('Login error:', err.message);
        return res.status(500).json({ error: err.message });
      }
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }
      if (!bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Invalid password' });
      }
      if (user.email_verified === 0) {
        return res.status(403).json({ error: 'Email not verified. Please verify your email first.' });
      }
      const token = generateToken();
      const tokenExpiry = getCurrentDatePlusDays(30);
      db.run(
        `UPDATE Users SET auth_token = ?, token_expiry = ? WHERE id = ?`,
        [token, tokenExpiry, user.id],
        (err) => {
          if (err) {
            console.error('Token update error:', err.message);
            return res.status(500).json({ error: err.message });
          }
          res.json({
            id: user.id,
            username: user.username,
            email_verified: user.email_verified,
            is_paid: user.is_paid,
            vpn_key: user.vpn_key,
            device_count: user.device_count,
            family_group_id: user.family_group_id,
            auth_token: token,
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
    `SELECT id, username, email_verified, is_paid, vpn_key, trial_end_date, device_count, family_group_id 
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
        vpn_key: user.vpn_key,
        device_count: user.device_count,
        family_group_id: user.family_group_id,
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

app.put('/pay', (req, res) => {
  const { token } = req.headers.authorization?.split(' ')[1];
  const { is_family } = req.body;
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }
  if (is_family) {
    db.run(
      `UPDATE FamilyGroups SET is_paid = 1 WHERE id = (SELECT family_group_id FROM Users WHERE auth_token = ?)`,
      [token],
      function (err) {
        if (err || this.changes === 0) {
          return res.status(404).json({ error: 'Family group not found' });
        }
        res.json({ message: 'Family plan paid' });
      }
    );
  } else {
    db.run(
      `UPDATE Users SET is_paid = 1 WHERE auth_token = ?`,
      [token],
      function (err) {
        if (err || this.changes === 0) {
          return res.status(404).json({ error: 'User not found' });
        }
        res.json({ message: 'Individual plan paid' });
      }
    );
  }
});

app.get('/verify-email', (req, res) => {
  const { token } = req.query;
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  db.get(
    `SELECT id, email_verified FROM Users WHERE verification_token = ?`,
    [token],
    (err, user) => {
      if (err || !user) {
        return res.status(401).json({ error: 'Invalid verification token' });
      }
      if (user.email_verified) {
        return res.status(400).json({ error: 'Email already verified' });
      }

      db.run(
        `UPDATE Users SET email_verified = 1, verification_token = NULL WHERE id = ?`,
        [user.id],
        (err) => {
          if (err) {
            console.error('Verification update error:', err.message);
            return res.status(500).json({ error: err.message });
          }
          res.json({ message: 'Email verified successfully' });
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

app.post('/create-family-group', (req, res) => {
  const { user_id } = req.body;
  db.run(
    `INSERT INTO FamilyGroups (is_paid) VALUES (0)`,
    [],
    function (err) {
      if (err) {
        console.error('Family group creation error:', err.message);
        return res.status(400).json({ error: err.message });
      }
      const groupId = this.lastID;
      db.run(
        `UPDATE Users SET family_group_id = ? WHERE id = ?`,
        [groupId, user_id],
        (err) => {
          if (err) {
            console.error('Family group update error:', err.message);
            return res.status(500).json({ error: err.message });
          }
          res.json({ id: groupId, message: 'Family group created' });
        }
      );
    }
  );
});

app.post('/add-to-family-group', (req, res) => {
  const { group_id, user_id } = req.body;
  db.get(
    `SELECT max_users, is_paid FROM FamilyGroups WHERE id = ?`,
    [group_id],
    (err, group) => {
      if (err || !group) {
        return res.status(404).json({ error: 'Family group not found' });
      }
      db.get(
        `SELECT COUNT(*) as count FROM Users WHERE family_group_id = ?`,
        [group_id],
        (err, result) => {
          if (err) {
            return res.status(500).json({ error: err.message });
          }
          if (result.count >= group.max_users) {
            return res.status(400).json({ error: 'Maximum users (5) reached in family group' });
          }
          db.run(
            `UPDATE Users SET family_group_id = ? WHERE id = ?`,
            [group_id, user_id],
            (err) => {
              if (err) {
                return res.status(400).json({ error: err.message });
              }
              res.json({ message: 'User added to family group' });
            }
          );
        }
      );
    }
  );
});

app.get('/get-vpn-config', (req, res) => {
  const { token } = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  db.get(
    `SELECT id, vpn_key FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err || !user) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      const serverAddress = '95.214.10.8:51820'; // Замени на реальный адрес сервера
      res.json({
        privateKey: user.vpn_key,
        serverAddress: serverAddress,
      });
    }
  );
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});