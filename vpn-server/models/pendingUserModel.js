// models/pendingUserModel.js
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
  db.run(`CREATE UNIQUE INDEX IF NOT EXISTS uq_pending_username ON PendingUsers(username)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_pending_user_email ON PendingUsers(email)`);
};