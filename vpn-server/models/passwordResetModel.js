const sqlite3 = require('sqlite3').verbose();

module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS PasswordReset (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      reset_code TEXT NOT NULL,
      expiry_date TEXT NOT NULL,
      FOREIGN KEY (email) REFERENCES Users(email)
    )
  `);
};