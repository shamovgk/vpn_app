const sqlite3 = require('sqlite3').verbose();

module.exports = (db) => {
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
};