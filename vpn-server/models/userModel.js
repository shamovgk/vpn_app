// models/userModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      email_verified INTEGER DEFAULT 1,
      vpn_key TEXT,
      auth_token TEXT,
      token_expiry TEXT,
      client_ip TEXT,
      is_admin INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  db.run(`CREATE INDEX IF NOT EXISTS idx_users_auth ON Users(auth_token, token_expiry)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_users_created_at ON Users(created_at)`);
};