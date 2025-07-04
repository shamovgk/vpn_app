const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const path = require('path');
const { exec } = require('child_process');
const nodemailer = require('nodemailer');

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
        email_verified INTEGER DEFAULT 1,
        is_paid INTEGER DEFAULT 0,
        vpn_key TEXT,
        trial_end_date TEXT,
        device_count INTEGER DEFAULT 0,
        auth_token TEXT,
        token_expiry TEXT
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
  console.log('Executing script at:', scriptPath);

  const { spawn } = require('child_process');
  const child = spawn('bash', [scriptPath], {
    maxBuffer: 1024 * 1024,
    encoding: 'utf8',
  });

  let stdout = '';
  let stderr = '';

  child.stdout.on('data', (data) => {
    stdout += data;
    console.log('Spawn stdout chunk:', data);
  });

  child.stderr.on('data', (data) => {
    stderr += data;
    console.error('Spawn stderr chunk:', data);
  });

  child.on('error', (error) => {
    throw new Error(`Spawn error: ${error.message}`);
  });

  const exitCode = await new Promise((resolve) => {
    child.on('close', (code) => resolve(code));
  });

  if (exitCode !== 0 || stderr) {
    throw new Error(`Script execution failed: exit code ${exitCode}, stderr=${stderr}`);
  }

  console.log('Spawn stdout:', stdout);
  const result = JSON.parse(stdout);
  const privateKey = result.privateKey;

  return new Promise((resolve, reject) => {
    db.run(
      `UPDATE Users SET vpn_key = ? WHERE id = ?`,
      [privateKey, userId],
      async (err) => {
        if (err) {
          console.error('Error updating vpn_key:', err.message);
          reject(new Error('Failed to update vpn_key'));
        } else {
          const configScriptPath = '/root/vpn-server/add_to_wg_conf.sh';
          const childConfig = spawn('bash', [configScriptPath, privateKey, userId], {
            maxBuffer: 1024 * 1024,
            encoding: 'utf8',
          });

          let configStdout = '';
          let configStderr = '';

          childConfig.stdout.on('data', (data) => {
            configStdout += data;
            console.log('Config stdout chunk:', data);
          });

          childConfig.stderr.on('data', (data) => {
            configStderr += data;
            console.error('Config stderr chunk:', data);
          });

          childConfig.on('error', (error) => {
            console.error('Config script error:', error.message);
          });

          const configExitCode = await new Promise((resolve) => {
            childConfig.on('close', (code) => resolve(code));
          });

          if (configExitCode !== 0 || configStderr) {
            console.error('Config generation failed:', `exit code ${configExitCode}, stderr=${configStderr}`);
          } else {
            console.log('Config updated:', configStdout);
          }
          resolve();
        }
      }
    );
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
    from: 'UgbuganVPN" <UgbuganSoft@gmail.com>',
    to: email,
    subject: 'Verify your email',
    text: `Your verification code is: ${verificationCode}. Please enter it in the app to verify your account.`,
  };

  return transporter.sendMail(mailOptions);
}

function sendResetEmail(email, resetCode) {
  const mailOptions = {
    from: '"UgbuganVPN" <UgbuganSoft@gmail.com>', 
    to: email,
    subject: 'Password Reset',
    text: `Your password reset code is: ${resetCode}. It is valid for 24 hours. Please use it in the app to reset your password.`,
  };

  return transporter.sendMail(mailOptions);
}

app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get(`SELECT id FROM PendingUsers WHERE email = ?`, [email], (err, row) => {
    if (row) return res.status(400).json({ error: 'Email already pending verification' });

    const hashedPassword = bcrypt.hashSync(password, 10);
    const trialEndDate = getCurrentDatePlusDays(3);
    const verificationCode = generateVerificationCode();
    const verificationExpiry = getCurrentDatePlusDays(1 / 24); // 1 час

    if (!username.trim()) {
      return res.status(400).json({ error: 'Username cannot be empty' });
    }

    console.log(`Executing: INSERT INTO PendingUsers (username, password, email, trial_end_date, verification_code, verification_expiry) VALUES (?, ?, ?, ?, ?, ?) with values [${username}, ${hashedPassword}, ${email}, ${trialEndDate}, ${verificationCode}, ${verificationExpiry}]`);
    db.run(
      `INSERT INTO PendingUsers (username, password, email, trial_end_date, verification_code, verification_expiry) VALUES (?, ?, ?, ?, ?, ?)`,
      [username, hashedPassword, email, trialEndDate, verificationCode, verificationExpiry],
      async function (err) {
        if (err) {
          console.error('Registration error:', err.message);
          return res.status(400).json({ error: err.message });
        }

        console.log(`Inserted verification_expiry: ${verificationExpiry} for user ${username}`);
        try {
          await sendVerificationEmail(email, verificationCode);
          res.json({ id: this.lastID, username, email, message: 'Verification email sent' });
        } catch (emailError) {
          console.error('Email sending error:', emailError.message);
          db.run(`DELETE FROM PendingUsers WHERE id = ?`, [this.lastID], (deleteErr) => {
            if (deleteErr) console.error('Cleanup error:', deleteErr.message);
          });
          return res.status(500).json({ error: 'Failed to send verification email' });
        }
      }
    );
  });
});

app.post('/verify-email', (req, res) => {
  const { username, email, verificationCode } = req.body;
  if (!username || !email || !verificationCode) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get(
    `SELECT id, verification_code, verification_expiry FROM PendingUsers WHERE username = ? AND email = ?`,
    [username, email],
    (err, pendingUser) => {
      if (err) {
        console.error('Verification error:', err.message);
        return res.status(500).json({ error: err.message });
      }
      if (!pendingUser) {
        return res.status(404).json({ error: 'User or email not found in pending' });
      }
      if (pendingUser.verification_code !== verificationCode) {
        return res.status(400).json({ error: 'Invalid verification code' });
      }
      const currentTime = new Date().toISOString(); // UTC
      const expiryTime = new Date(pendingUser.verification_expiry).toISOString(); // UTC
      console.log(`Current time (UTC): ${currentTime}, Expiry time (UTC): ${expiryTime}`);
      if (new Date(pendingUser.verification_expiry) < new Date()) {
        return res.status(400).json({ error: 'Verification code expired' });
      }

      db.get(
        `SELECT username, password, trial_end_date FROM PendingUsers WHERE id = ?`,
        [pendingUser.id],
        (err, fullPendingUser) => {
          if (err) {
            console.error('Error fetching full pending user:', err.message);
            return res.status(500).json({ error: 'Internal server error' });
          }
          if (!fullPendingUser) {
            console.error('No full pending user found for id:', pendingUser.id);
            return res.status(500).json({ error: 'Invalid user data' });
          }
          if (!fullPendingUser.username || !fullPendingUser.password || !fullPendingUser.trial_end_date) {
            console.error('Missing required fields in PendingUsers for id:', pendingUser.id, fullPendingUser);
            return res.status(500).json({ error: 'Invalid user data' });
          }

          console.log(`Executing: INSERT INTO Users (username, password, email, trial_end_date) VALUES (?, ?, ?, ?) with values [${fullPendingUser.username}, ${fullPendingUser.password}, ${email}, ${fullPendingUser.trial_end_date}]`);
          db.run(
            `INSERT INTO Users (username, password, email, trial_end_date) VALUES (?, ?, ?, ?)`,
            [fullPendingUser.username, fullPendingUser.password, email, fullPendingUser.trial_end_date],
            async function (err) {
              if (err) {
                console.error('User creation error:', err.message);
                return res.status(500).json({ error: err.message });
              }

              try {
                await generateVpnKey(this.lastID, db);
                console.log(`Executing: DELETE FROM PendingUsers WHERE id = ? with value [${pendingUser.id}]`);
                db.run(`DELETE FROM PendingUsers WHERE id = ?`, [pendingUser.id], (deleteErr) => {
                  if (deleteErr) console.error('Cleanup error:', deleteErr.message);
                });
                res.json({ message: 'Email verified successfully, account created' });
              } catch (e) {
                console.error('Key generation error:', e.message);
                db.run(`DELETE FROM Users WHERE id = ?`, [this.lastID], (deleteErr) => {
                  if (deleteErr) console.error('Cleanup error:', deleteErr.message);
                });
                return res.status(500).json({ error: 'Failed to generate VPN key' });
              }
            }
          );
        }
      );
    }
  );
});

app.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  db.get(
    `SELECT id, username, password, email_verified, is_paid, vpn_key, trial_end_date, device_count
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
      const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
      if (!user.is_paid && trialExpired) {
        return res.status(403).json({ error: 'Trial period expired' });
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
            vpn_key: user.vpn_key || null,
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
  const { username } = req.body; // Берем только username
  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  db.get(`SELECT id, email FROM Users WHERE username = ?`, [username], (err, user) => {
    if (err) {
      console.error('Database error:', err.message);
      return res.status(500).json({ error: 'Internal server error' });
    }
    if (!user) {
      return res.status(404).json({ error: 'User with this username not found' });
    }

    const resetCode = generateVerificationCode();
    const expiryDate = getCurrentDatePlusDays(1); // Код действителен 1 день

    db.run(
      `INSERT INTO PasswordReset (email, reset_code, expiry_date) VALUES (?, ?, ?)`,
      [user.email, resetCode, expiryDate],
      async (err) => {
        if (err) {
          console.error('Error saving reset code:', err.message);
          return res.status(500).json({ error: 'Failed to generate reset code' });
        }

        try {
          await sendResetEmail(user.email, resetCode);
          res.json({ message: 'Reset instructions sent to your email' });
        } catch (emailError) {
          console.error('Email sending error:', emailError.message);
          db.run(`DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`, [user.email, resetCode], (deleteErr) => {
            if (deleteErr) console.error('Cleanup error:', deleteErr.message);
          });
          return res.status(500).json({ error: 'Failed to send reset email' });
        }
      }
    );
  });
});

app.post('/reset-password', (req, res) => {
  const { username, resetCode, newPassword } = req.body;
  if (!username || !resetCode || !newPassword) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get(
    `SELECT email FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err) {
        console.error('Database error:', err.message);
        return res.status(500).json({ error: 'Internal server error' });
      }
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      const email = user.email;

      db.get(
        `SELECT * FROM PasswordReset WHERE email = ? AND reset_code = ? AND expiry_date > ?`,
        [email, resetCode, new Date().toISOString()],
        (err, reset) => {
          if (err) {
            console.error('Database error:', err.message);
            return res.status(500).json({ error: 'Internal server error' });
          }
          if (!reset) {
            return res.status(400).json({ error: 'Invalid or expired reset code' });
          }

          const hashedPassword = bcrypt.hashSync(newPassword, 10);
          db.run(
            `UPDATE Users SET password = ? WHERE username = ?`, 
            [hashedPassword, username],
            (err) => {
              if (err) {
                console.error('Error updating password:', err.message);
                return res.status(500).json({ error: 'Failed to update password' });
              }

              db.run(
                `DELETE FROM PasswordReset WHERE email = ? AND reset_code = ?`,
                [email, resetCode],
                (deleteErr) => {
                  if (deleteErr) console.error('Cleanup error:', deleteErr.message);
                }
              );
              res.json({ message: 'Password reset successfully' });
            }
          );
        }
      );
    }
  );
});

app.put('/pay', (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.error('Invalid or missing Authorization header:', req.headers.authorization);
    return res.status(400).json({ error: 'Token is required' });
  }
  const token = authHeader.split(' ')[1];
  
    db.get(
      `SELECT id, username, vpn_key, is_paid, trial_end_date FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => {
        if (err || !user) {
          return res.status(401).json({ error: 'Invalid or expired token' });
        }
        const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
        if (!user.is_paid && trialExpired) {
          return res.status(403).json({ error: 'Trial period expired' });
        }

        db.run(
          `UPDATE Users SET is_paid = 1 WHERE id = ?`,
          [user.id],
          (err) => {
            if (err) {
              console.error('Error updating is_paid:', err.message);
              return res.status(500).json({ error: err.message });
            }
            res.json({ message: 'Individual plan paid' });
          }
        );
      }
    );
  }
);

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
  const { token } = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(400).json({ error: 'Token is required' });
  }

  db.get(
    `SELECT id, username, vpn_key, is_paid, trial_end_date FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err || !user) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      const trialExpired = user.trial_end_date && new Date(user.trial_end_date) < new Date();
      if (!user.is_paid && trialExpired) {
        return res.status(403).json({ error: 'Trial period expired' });
      }

      const serverAddress = '95.214.10.8:51820';
      res.json({
        privateKey: user.vpn_key || 'Key not generated yet',
        serverAddress: serverAddress
      });
    }
  );
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
