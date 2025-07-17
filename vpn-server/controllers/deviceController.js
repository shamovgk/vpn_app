const logger = require('../logger');

exports.addDevice = async (req, res) => {
  const { user_id, device_token, device_model, device_os } = req.body;
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT device_count, subscription_level FROM Users WHERE id = ?`, [user_id],
      (err, user) => err ? reject(err) : resolve(user))
  );
  if (!user) {
    logger.warn('Add device to non-existent user', { userId: user_id });
    throw new Error('User not found');
  }
  const maxDevices = user.subscription_level === 1 ? 6 : 3;
  if (user.device_count >= maxDevices) {
    logger.warn('Device add failed: limit reached', { userId: user_id, device_token });
    throw new Error(`Maximum device limit (${maxDevices}) reached`);
  }

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
      [user_id, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
      err => err ? reject(err) : resolve()
    )
  );
  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET device_count = device_count + 1 WHERE id = ?`,
      [user_id],
      err => err ? reject(err) : resolve()
    )
  );
  logger.info('Device added', { userId: user_id, device_token });
  res.json({ message: 'Device added successfully' });
};

exports.removeDevice = async (req, res) => {
  const { user_id, device_token, trigger_logout } = req.body;
  if (!user_id || !device_token) throw new Error('user_id and device_token are required');
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT device_count, subscription_level FROM Users WHERE id = ?`, [user_id],
      (err, user) => err ? reject(err) : resolve(user))
  );
  if (!user) {
    logger.warn('Remove device from non-existent user', { userId: user_id });
    throw new Error('User not found');
  }

  const result = await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM Devices WHERE user_id = ? AND device_token = ?`,
      [user_id, device_token],
      function (err) { err ? reject(err) : resolve(this.changes); }
    )
  );
  if (result === 0) {
    logger.warn('Remove non-existent device', { userId: user_id, device_token });
    throw new Error('Device not found');
  }

  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET device_count = device_count - 1 WHERE id = ?`,
      [user_id],
      err => err ? reject(err) : resolve()
    )
  );

  if (trigger_logout) {
    const userData = await new Promise((resolve, reject) =>
      db.get(
        `SELECT auth_token FROM Users WHERE id = ?`,
        [user_id],
        (err, row) => err ? reject(err) : resolve(row)
      )
    );
    if (userData && userData.auth_token) {
      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE auth_token = ?`,
          [userData.auth_token],
          err => err ? reject(err) : resolve()
        )
      );
      logger.info('Device removed with forced logout', { userId: user_id });
    }
  }
  logger.info('Device removed', { userId: user_id, device_token });
  res.json({ message: 'Device removed successfully' });
};

exports.getDevices = async (req, res) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error('Token is required');
  const token = authHeader.split(' ')[1];
  const db = req.db;

  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Users WHERE auth_token = ? AND token_expiry > ?`,
      [token, new Date().toISOString()],
      (err, user) => err ? reject(err) : resolve(user))
  );
  if (!user) {
    logger.warn('Get devices failed: invalid/expired token', { token });
    throw new Error('Invalid or expired token');
  }

  const devices = await new Promise((resolve, reject) =>
    db.all(
      `SELECT id, device_token, device_model, device_os, last_seen FROM Devices WHERE user_id = ?`,
      [user.id],
      (err, devices) => err ? reject(err) : resolve(devices))
  );
  logger.info('Device list retrieved', { userId: user.id, deviceCount: devices.length });
  res.json(devices);
};
