function addDevice(req, res) {
  const { user_id, device_token, device_model, device_os } = req.body;
  req.db.get(
    `SELECT device_count, subscription_level FROM Users WHERE id = ?`,
    [user_id],
    (err, user) => {
      if (err || !user) return res.status(404).json({ error: 'User not found' });
      const maxDevices = user.subscription_level === 1 ? 6 : 3;
      if (user.device_count >= maxDevices) return res.status(400).json({ error: `Maximum device limit (${maxDevices}) reached` });

      req.db.run(
        `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
        [user_id, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
        (err) => {
          if (err) return res.status(400).json({ error: err.message });
          req.db.run(
            `UPDATE Users SET device_count = device_count + 1 WHERE id = ?`,
            [user_id],
            (err) => {
              if (err) return res.status(500).json({ error: err.message });
              res.json({ message: 'Device added successfully' });
            }
          );
        }
      );
    }
  );
}

function removeDevice(req, res) {
  const { user_id, device_token, trigger_logout } = req.body;
  if (!user_id || !device_token) return res.status(400).json({ error: 'user_id and device_token are required' });

  req.db.get(
    `SELECT device_count, subscription_level FROM Users WHERE id = ?`,
    [user_id],
    (err, user) => {
      if (err || !user) return res.status(404).json({ error: 'User not found' });

      req.db.run(
        `DELETE FROM Devices WHERE user_id = ? AND device_token = ?`,
        [user_id, device_token],
        (err) => {
          if (err) return res.status(400).json({ error: err.message });
          if (this.changes === 0) return res.status(404).json({ error: 'Device not found' });
          req.db.run(
            `UPDATE Users SET device_count = device_count - 1 WHERE id = ?`,
            [user_id],
            (err) => {
              if (err) return res.status(500).json({ error: err.message });
              if (trigger_logout) {
                req.db.get(
                  `SELECT auth_token FROM Users WHERE id = ?`,
                  [user_id],
                  (err, userData) => {
                    if (err || !userData || !userData.auth_token) console.error('Error fetching auth token for logout:', err?.message);
                    else {
                      req.db.run(
                        `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
                        [userData.auth_token],
                        (err) => { if (err) console.error('Logout error during device removal:', err.message); }
                      );
                    }
                  }
                );
              }
              res.json({ message: 'Device removed successfully' });
            }
          );
        }
      );
    }
  );
}

function getDevices(req, res) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) return res.status(400).json({ error: 'Token is required' });

  const token = authHeader.split(' ')[1];
  req.db.get(
    `SELECT id FROM Users WHERE auth_token = ? AND token_expiry > ?`,
    [token, new Date().toISOString()],
    (err, user) => {
      if (err || !user) return res.status(401).json({ error: 'Invalid or expired token' });

      req.db.all(
        `SELECT id, device_token, device_model, device_os, last_seen FROM Devices WHERE user_id = ?`,
        [user.id],
        (err, devices) => {
          if (err) return res.status(500).json({ error: 'Internal server error' });
          res.json(devices);
        }
      );
    }
  );
}

module.exports = { addDevice, removeDevice, getDevices };