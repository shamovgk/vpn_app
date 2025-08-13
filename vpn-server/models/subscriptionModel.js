module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS Subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,                -- 'trial' или 'paid'
      status TEXT NOT NULL,              -- 'active', 'expired', 'canceled'
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      subscription_level INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES Users(id)
    )
  `);
};
