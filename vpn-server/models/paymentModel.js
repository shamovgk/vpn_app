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
      FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  db.run(`CREATE INDEX IF NOT EXISTS idx_payments_user ON Payments(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_payments_status ON Payments(status)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_payments_created ON Payments(created_at)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_payments_currency ON Payments(currency)`);
  db.run(`CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_payment_id ON Payments(payment_id)`);
};