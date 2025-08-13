// controllers/deviceController.js
const deviceService = require('../services/deviceService');
const logger = require('../utils/logger.js');

exports.addDevice = async (req, res) => {
  const { device_token, device_model, device_os } = req.body;
  const userId = req.user.id;
  const db = req.db;

  // Проверяем — не добавлен ли уже девайс
  const exists = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Devices WHERE device_token = ? AND user_id = ?`,
      [device_token, userId],
      (err, row) => err ? reject(err) : resolve(row))
  );
  if (exists) {
    logger.info('Device already exists for user', { userId, device_token });
    return res.json({ message: 'Device already exists' });
  }

  // Считаем лимиты через сервисы
  const devicesCount = await deviceService.getUserDevicesCount({ userId, db });
  const maxDevices = await deviceService.getUserDeviceLimit();

  if (devicesCount >= maxDevices) {
    logger.warn('Device add failed: limit reached', { userId, device_token });
    return res.status(400).json({ error: `Maximum device limit (${maxDevices}) reached` });
  }

  // Добавляем
  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Devices (user_id, device_token, device_model, device_os, last_seen) VALUES (?, ?, ?, ?, ?)`,
      [userId, device_token, device_model || 'Unknown Model', device_os || 'Unknown OS', new Date().toISOString()],
      err => err ? reject(err) : resolve()
    )
  );
  logger.info('Device added', { userId, device_token });
  res.json({ message: 'Device added successfully' });
};

exports.removeDevice = async (req, res) => {
  const { device_token, trigger_logout } = req.body;
  const userId = req.user.id;
  const db = req.db;

  const result = await new Promise((resolve, reject) =>
    db.run(
      `DELETE FROM Devices WHERE user_id = ? AND device_token = ?`,
      [userId, device_token],
      function (err) { err ? reject(err) : resolve(this.changes); }
    )
  );
  if (result === 0) {
    logger.warn('Remove non-existent device', { userId, device_token });
    return res.status(404).json({ error: 'Device not found' });
  }

  if (trigger_logout) {
    await new Promise((resolve, reject) =>
      db.run(
        `UPDATE Users SET auth_token = NULL, token_expiry = NULL WHERE id = ?`,
        [userId],
        err => err ? reject(err) : resolve()
      )
    );
    logger.info('Device removed with forced logout', { userId });
  }
  logger.info('Device removed', { userId, device_token });
  res.json({ message: 'Device removed successfully' });
};

exports.getDevices = async (req, res) => {
  const userId = req.user.id;
  const db = req.db;

  const devices = await new Promise((resolve, reject) =>
    db.all(
      `SELECT id, device_token, device_model, device_os, last_seen FROM Devices WHERE user_id = ?`,
      [userId],
      (err, devices) => err ? reject(err) : resolve(devices))
  );
  logger.info('Device list retrieved', { userId, deviceCount: devices.length });
  res.json(devices);
};

exports.updateLastSeen = async (req, res) => {
  const { device_token } = req.body;
  const userId = req.user.id;
  const db = req.db;

  if (!device_token) return res.status(400).json({ error: 'device_token is required' });

  const device = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id FROM Devices WHERE device_token = ? AND user_id = ?`,
      [device_token, userId],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );

  if (!device) return res.status(404).json({ error: 'Device not found' });

  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Devices SET last_seen = ? WHERE device_token = ? AND user_id = ?`,
      [new Date().toISOString(), device_token, userId],
      err => err ? reject(err) : resolve()
    )
  );

  res.json({ message: 'lastSeen updated successfully' });
};
