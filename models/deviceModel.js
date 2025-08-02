const sqlite3 = require('sqlite3').verbose();

module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Devices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      device_token TEXT NOT NULL UNIQUE,
      device_model TEXT,
      device_os TEXT,
      last_seen TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES Users(id)
    )
  `);
};