const sqlite3 = require('sqlite3').verbose();

module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      email_verified INTEGER DEFAULT 1,
      is_paid INTEGER DEFAULT 0,
      subscription_level INTEGER DEFAULT 0,
      vpn_key TEXT,
      trial_end_date TEXT,
      device_count INTEGER DEFAULT 0,
      auth_token TEXT,
      token_expiry TEXT,
      client_ip TEXT,
      is_admin INTEGER DEFAULT 0
    )
  `);
};