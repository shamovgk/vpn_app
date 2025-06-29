const sqlite3 = require('sqlite3').verbose();
const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const path = require('path');
const { exec } = require('child_process'); // Для выполнения скриптов

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
        vpn_key TEXT, -- Сохраняем privateKey
        trial_end_date TEXT,
        device_count INTEGER DEFAULT 0,
        family_group_id INTEGER,
        auth_token TEXT,
        token_expiry TEXT,
        FOREIGN KEY (family_group_id) REFERENCES FamilyGroups(id)
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

// Удаляем функцию generateVpnKey(), так как используем скрипт

app.post('/register', (req, res) => {
  const { username, password, email } = req.body;
  if (!username || !password || !email) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get(`SELECT id FROM Users WHERE email = ?`, [email], (err, row) => {
    if (row) return res.status(400).json({ error: 'Email already in use' });

    const hashedPassword = bcrypt.hashSync(password, 10); 
    const trialEndDate = getCurrentDatePlusDays(3);

    db.run(
      `INSERT INTO Users (username, password, email, trial_end_date) VALUES (?, ?, ?, ?)`,
      [username, hashedPassword, email, trialEndDate],
      async function (err) {
        if (err) {
          console.error('Registration error:', err.message);
          return res.status(400).json({ error: err.message });
        }

        try {
          const scriptPath = '/root/vpn-server/generate_vpn_key.sh';
          console.log('Executing script at:', scriptPath);

          const { spawn } = require('child_process');
          const child = spawn('bash', [scriptPath], { 
            maxBuffer: 1024 * 1024,
            encoding: 'utf8'
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

          db.run(
            `UPDATE Users SET vpn_key = ? WHERE id = ?`,
            [privateKey, this.lastID],
            async (err) => {
              if (err) {
                console.error('Error updating vpn_key:', err.message);
                return res.status(500).json({ error: 'Failed to update vpn_key' });
              }

              // Запуск скрипта для обновления wg0.conf
              const configScriptPath = '/root/vpn-server/add_to_wg_conf.sh';
              const childConfig = spawn('bash', [configScriptPath, privateKey, this.lastID], {
                maxBuffer: 1024 * 1024,
                encoding: 'utf8'
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

              res.json({ id: this.lastID, username, email, trial_end_date: trialEndDate });
            }
          );
        } catch (e) {
          console.error('Key generation error:', e.message);
          return res.status(500).json({ error: 'Failed to generate VPN key' });
        }
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
//      if (user.email_verified === 0) {
  //      return res.status(403).json({ error: 'Email not verified' });
    //  }
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
            family_group_id: user.family_group_id,
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
        vpn_key: user.vpn_key || null,
        device_count: user.device_count,
        family_group_id: user.family_group_id
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
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.error('Invalid or missing Authorization header:', req.headers.authorization);
    return res.status(400).json({ error: 'Token is required' });
  }
  const token = authHeader.split(' ')[1];

  const { is_family } = req.body;
  if (is_family === undefined) {
    return res.status(400).json({ error: 'is_family is required' });
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
});


app.post('/verify-email', (req, res) => {
  const { username, email } = req.body;
  db.run(
    `UPDATE Users SET email_verified = 1 WHERE username = ? AND email = ?`,
    [username, email],
    function (err) {
      if (err) {
        console.error('Email verification error:', err.message);
        return res.status(400).json({ error: err.message });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'User or email not found' });
      }
      res.json({ message: 'Email verified successfully' });
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

      const serverAddress = '95.214.10.8:51820'; // Замени на реальный адрес
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
