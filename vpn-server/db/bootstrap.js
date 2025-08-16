// db/bootstrap.js
const logger = require('../utils/logger');

module.exports = function bootstrap(db) {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // PRAGMA до создания таблиц
      db.run('PRAGMA foreign_keys = ON');
      db.run('PRAGMA journal_mode = WAL');
      db.run('PRAGMA synchronous = NORMAL');
      db.run('PRAGMA busy_timeout = 5000');

      // Порядок важен: Users -> остальные
      require('../models/userModel')(db);
      require('../models/pendingUserModel')(db);
      require('../models/subscriptionModel')(db);
      require('../models/deviceModel')(db);
      require('../models/userStatsModel')(db);
      require('../models/paymentModel')(db);
      require('../models/passwordResetModel')(db);

      // Барьер: всё выше в очереди, этот SELECT вызовется в самом конце
      db.get('SELECT 1', (err) => {
        if (err) return reject(err);

        db.all('PRAGMA database_list', [], (e2, rows) => {
          if (e2) logger.error('PRAGMA database_list failed', { error: e2 });
          else logger.info('SQLite database_list', { rows });
          logger.info('Schema bootstrapped from models (no migrations).');
          resolve();
        });
      });

      db.run(`
          CREATE TRIGGER IF NOT EXISTS trg_payments_updated
          AFTER UPDATE ON Payments
          FOR EACH ROW WHEN NEW.updated_at = OLD.updated_at
          BEGIN
            UPDATE Payments SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
          END;
        `);
        db.run(`
          CREATE TRIGGER IF NOT EXISTS trg_subs_updated
          AFTER UPDATE ON Subscriptions
          FOR EACH ROW WHEN NEW.updated_at = OLD.updated_at
          BEGIN
            UPDATE Subscriptions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
          END;
        `);
    });
  });
};
