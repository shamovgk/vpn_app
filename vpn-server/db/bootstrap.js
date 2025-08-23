// db/bootstrap.js
const logger = require('../utils/logger');

function run(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) {
        logger.error('SQLite run failed', { sql, params, message: err.message });
        return reject(err);
      }
      resolve(this);
    });
  });
}

function get(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) {
        logger.error('SQLite get failed', { sql, params, message: err.message });
        return reject(err);
      }
      resolve(row);
    });
  });
}

function all(db, sql, params = []) {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) {
        logger.error('SQLite all failed', { sql, params, message: err.message });
        return reject(err);
      }
      resolve(rows);
    });
  });
}

module.exports = async function bootstrap(db) {
  // serialize гарантирует порядок, но мы ещё и await'им для явной диагностики
  db.serialize();

  // 1) PRAGMA
  await run(db, 'PRAGMA foreign_keys = ON');
  await run(db, 'PRAGMA journal_mode = WAL');
  await run(db, 'PRAGMA synchronous = NORMAL');
  await run(db, 'PRAGMA busy_timeout = 5000');

  // 2) Модели (если внутри есть синтаксическая ошибка — require бросит исключение, и мы его увидим в index.js с message/stack)
  try {
    require('../models/userModel')(db);
    require('../models/pendingUserModel')(db);
    require('../models/subscriptionModel')(db);
    require('../models/deviceModel')(db);
    require('../models/userStatsModel')(db);
    require('../models/paymentModel')(db);
    require('../models/passwordResetModel')(db);
  } catch (e) {
    logger.error('Model bootstrap require failed', { message: e.message, stack: e.stack });
    throw e;
  }

  // 3) Убедимся, что таблицы существуют перед созданием триггеров
  const needed = ['Payments', 'Subscriptions'];
  const existing = await all(
    db,
    `SELECT name FROM sqlite_master WHERE type='table' AND name IN (${needed.map(() => '?').join(',')})`,
    needed
  );
  const existingNames = new Set(existing.map(r => r.name));
  const missing = needed.filter(n => !existingNames.has(n));
  if (missing.length) {
    // Частая причина: несовпадение имени таблицы в модели/триггере
    // (например, модель создала payments, а триггер ссылается на Payments — в SQLite имена в целом case-insensitive, но проверь)
    const msg = `Missing tables for triggers: ${missing.join(', ')}`;
    logger.error(msg);
    throw new Error(msg);
  }

  // 4) Триггеры с явной диагностикой
  await run(db, `
    CREATE TRIGGER IF NOT EXISTS trg_payments_updated
    AFTER UPDATE ON Payments
    FOR EACH ROW
    WHEN NEW.updated_at = OLD.updated_at
    BEGIN
      UPDATE Payments SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;
  `);

  await run(db, `
    CREATE TRIGGER IF NOT EXISTS trg_subs_updated
    AFTER UPDATE ON Subscriptions
    FOR EACH ROW
    WHEN NEW.updated_at = OLD.updated_at
    BEGIN
      UPDATE Subscriptions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;
  `);

  // 5) Барьер + диагностика окружения
  await get(db, 'SELECT 1');
  try {
    const rows = await all(db, 'PRAGMA database_list');
    logger.info('SQLite database_list', { rows });
  } catch (e) {
    logger.warn('PRAGMA database_list failed', { message: e.message });
  }
  logger.info('Schema bootstrapped from models (no migrations).');
};
