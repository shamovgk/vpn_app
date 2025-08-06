// controllers/deviceController.js
const logger = require('../utils/logger.js');

// Добавление устройства
exports.addDevice = async (req, res) => {
  const { device_token, device_model, device_os } = req.body;
  const user_id = req.user.id;
  const db = req.db;

    // Проверяем, есть ли такой девайс уже у юзера
  const exists = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Devices WHERE device_token = ? AND user_id = ?`,
      [device_token, user_id],
      (err, row) => err ? reject(err) : resolve(row))
  );
  if (exists) {
    logger.info('Device already exists for user', { userId: user_id, device_token });
    return res.json({ message: 'Device already exists' });
  }
  
  // Считаем реальное количество устройств
  const devicesCount = await new Promise((resolve, reject) =>
    db.get(`SELECT COUNT(*) as cnt FROM Devices WHERE user_id = ?`, [user_id],
      (err, row) => err ? reject(err) : resolve(row.cnt))
  );
  const user = await new Promise((resolve, reject) =>
    db.get(`SELECT subscription_level FROM Users WHERE id = ?`, [user_id],
      (err, user) => err ? reject(err) : resolve(user))
  );
  if (!user) {
    logger.warn('Add device to non-existent user', { userId: user_id });
    throw new Error('User not found');
  }
  const maxDevices = user.subscription_level === 1 ? 6 : 3;
  if (devicesCount >= maxDevices) {
    logger.warn('Device add failed: limit reached', { userId: user_id, device_token });
    return res.status(400).json({ error: `Maximum device limit (${maxDevices}) reached` });
  }

  // Добавляем устройство
  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
      [user_id, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
      err => err ? reject(err) : resolve()
    )
  );
  logger.info('Device added', { userId: user_id, device_token });
  res.json({ message: 'Device added successfully' });
};

// Удаление устройства
exports.removeDevice = async (req, res) => {
  const { device_token, trigger_logout } = req.body;
  const user_id = req.user.id;
  const db = req.db;

  const result = await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM Devices WHERE user_id = ? AND device_token = ?`,
      [user_id, device_token],
      function (err) { err ? reject(err) : resolve(this.changes); }
    )
  );
  if (result === 0) {
    logger.warn('Remove non-existent device', { userId: user_id, device_token });
    return res.status(404).json({ error: 'Device not found' });
  }

  if (trigger_logout) {
    await new Promise((resolve, reject) =>
      db.run(
        `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE id = ?`,
        [user_id],
        err => err ? reject(err) : resolve()
      )
    );
    logger.info('Device removed with forced logout', { userId: user_id });
  }
  logger.info('Device removed', { userId: user_id, device_token });
  res.json({ message: 'Device removed successfully' });
};

// Получение списка устройств
exports.getDevices = async (req, res) => {
  const user_id = req.user.id;
  const db = req.db;

  const devices = await new Promise((resolve, reject) =>
    db.all(
      `SELECT id, device_token, device_model, device_os, last_seen FROM Devices WHERE user_id = ?`,
      [user_id],
      (err, devices) => err ? reject(err) : resolve(devices))
  );
  logger.info('Device list retrieved', { userId: user_id, deviceCount: devices.length });
  res.json(devices);
};
