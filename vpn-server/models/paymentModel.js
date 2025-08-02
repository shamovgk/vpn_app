// models/paymentModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      currency TEXT NOT NULL,
      payment_id TEXT NOT NULL,
      status TEXT NOT NULL,
      method TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      meta TEXT,
      FOREIGN KEY (user_id) REFERENCES Users(id)
    )
  `);
};
