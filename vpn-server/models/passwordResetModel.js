// models/passwordResetModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS PasswordReset (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      reset_code TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      FOREIGN KEY (email) REFERENCES Users(email) ON DELETE CASCADE
    )
  `);
  db.run(`CREATE INDEX IF NOT EXISTS idx_pwdreset_email ON PasswordReset(email)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_pwdreset_email_code ON PasswordReset(email, reset_code)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_pwdreset_expiry ON PasswordReset(expiry_date)`);
};