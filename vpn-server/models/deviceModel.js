// models/deviceModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Devices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      device_token TEXT NOT NULL UNIQUE,
      device_model TEXT,
      device_os TEXT,
      last_seen TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  db.run(`CREATE INDEX IF NOT EXISTS idx_devices_user ON Devices(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_devices_os ON Devices(device_os)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON Devices(last_seen)`);
};