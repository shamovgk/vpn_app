// models/subscriptionModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,                -- 'trial' | 'paid'
      status TEXT NOT NULL,              -- 'active' | 'expired' | 'canceled'
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  db.run(`CREATE INDEX IF NOT EXISTS idx_subs_user ON Subscriptions(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_subs_type_status ON Subscriptions(type, status)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_subs_end_date ON Subscriptions(end_date)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_subs_start_date ON Subscriptions(start_date)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_subs_user_type_status ON Subscriptions(user_id, type, status)`);
};

