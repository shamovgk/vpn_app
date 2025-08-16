// models/userStatsModel.js
module.exports = (db) => {
  db.run(`
    CREATE TABLE IF NOT EXISTS UserStats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      login_count INTEGER DEFAULT 0,
      last_login TEXT,
      device_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      total_traffic INTEGER DEFAULT 0,
      active_duration INTEGER DEFAULT 0,
      payment_count INTEGER DEFAULT 0,
      last_payment_date TEXT,
      FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE
    )
  `);

  db.run(`CREATE INDEX IF NOT EXISTS idx_userstats_user ON UserStats(user_id)`);
  db.run(`CREATE INDEX IF NOT EXISTS idx_userstats_last_login ON UserStats(last_login)`);
};