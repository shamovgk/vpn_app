// controllers/adminController.js
const bcrypt = require('bcrypt');
const logger = require('../utils/logger.js');

// ===== Helpers
function run(db, sql, params = []) {
  return new Promise((resolve, reject) => db.run(sql, params, function (err) {
    if (err) reject(err); else resolve(this);
  }));
}
function get(db, sql, params = []) {
  return new Promise((resolve, reject) => db.get(sql, params, (err, row) => err ? reject(err) : resolve(row)));
}
function all(db, sql, params = []) {
  return new Promise((resolve, reject) => db.all(sql, params, (err, rows) => err ? reject(err) : resolve(rows)));
}

exports.adminAuth = (req, res, next) => {
  if (!req.session.admin) {
    if (req.accepts('html')) {
      const nextUrl = encodeURIComponent(req.originalUrl || '/admin');
      return res.redirect(302, `/admin/login?next=${nextUrl}`);
    }
    return res.status(401).json({ error: 'Admin access required' });
  }
  next();
};

exports.adminLogin = async (req, res, next) => {
  try {
    const { username, password, next: nextUrlBody } = req.body || {};
    const nextUrl = nextUrlBody || req.query.next || '/admin';
    const db = req.db;

    const user = await get(db,
      `SELECT id, username, password, is_admin FROM Users WHERE username = ?`,
      [username]
    );

    if (!user || user.is_admin !== 1 || !bcrypt.compareSync(password, user.password)) {
      logger.warn('Admin login failed', { username, ip: req.ip });
      if (req.accepts('html')) {
        return res.status(401).render('login', {
          title: 'Вход в админку',
          csrfToken: req.csrfToken(),
          next: nextUrl || '',
          error: 'Неверный логин или пароль',
        });
      }
      return res.status(401).json({ error: 'Invalid credentials or not an admin' });
    }

    req.session.admin = true;
    req.session.userId = user.id;

    logger.info('Admin login success', { adminId: user.id, username, ip: req.ip });

    if (req.accepts('html')) {
      return res.redirect(nextUrl || '/admin');
    }
    res.json({ message: 'Admin login successful', redirect: nextUrl || '/admin' });
  } catch (e) {
    next(e);
  }
};

// ======== Common query (pagination/sort/filter) ========
async function queryUsers(db, { page = 1, limit = 20, q = '', sort = 'id', dir = 'desc', filter = 'all' }) {
  page = Math.max(parseInt(page || '1', 10), 1);
  limit = Math.min(Math.max(parseInt(limit || '20', 10), 5), 100);
  q = (q || '').trim();
  dir = (dir || 'desc').toLowerCase() === 'asc' ? 'ASC' : 'DESC';

  const allowedSort = {
    id: 'id',
    username: 'username',
    email: 'email',
    email_verified: 'email_verified',
    is_paid: 'is_paid',
    paid_until: 'paid_until',
    trial_until: 'trial_until',
    device_count: 'device_count',
    created_at: 'created_at',
  };
  sort = (allowedSort[sort] ? sort : 'id');
  const sortExpr = allowedSort[sort];

  // ❗️Берём ТОЛЬКО active-подписки
  const baseSql = `
    WITH paid AS (
      SELECT user_id, MAX(end_date) AS paid_until
      FROM Subscriptions
      WHERE type='paid' AND status='active'
      GROUP BY user_id
    ),
    trial AS (
      SELECT user_id, MAX(end_date) AS trial_until
      FROM Subscriptions
      WHERE type='trial' AND status='active'
      GROUP BY user_id
    ),
    dc AS (
      SELECT user_id, COUNT(*) AS device_count
      FROM Devices
      GROUP BY user_id
    ),
    base AS (
      SELECT
        u.id, u.username, u.email, u.email_verified, u.is_admin, u.created_at,
        CASE WHEN p.paid_until IS NOT NULL AND datetime(p.paid_until) > datetime('now') THEN 1 ELSE 0 END AS is_paid,
        p.paid_until,
        t.trial_until,
        CASE WHEN t.trial_until IS NOT NULL AND datetime(t.trial_until) > datetime('now') THEN 1 ELSE 0 END AS is_trial_active,
        COALESCE(d.device_count, 0) AS device_count
      FROM Users u
      LEFT JOIN paid  p ON p.user_id = u.id
      LEFT JOIN trial t ON t.user_id = u.id
      LEFT JOIN dc    d ON d.user_id = u.id
      WHERE (? = '' OR u.username LIKE ? OR u.email LIKE ?)
    )
  `;

  const filterSql = {
    all: '1=1',
    paid: 'is_paid = 1',
    trial: 'is_paid = 0 AND is_trial_active = 1',
    none: 'is_paid = 0 AND is_trial_active = 0',
  }[filter] || '1=1';

  const countRow = await get(db, `
    ${baseSql}
    SELECT COUNT(*) AS n FROM base WHERE ${filterSql}
  `, [q, `%${q}%`, `%${q}%`]);

  const total = countRow?.n || 0;
  const pages = Math.max(Math.ceil(total / limit), 1);
  const pageClamped = Math.min(page, pages);
  const offset = (pageClamped - 1) * limit;

  const users = await all(db, `
    ${baseSql}
    SELECT * FROM base
    WHERE ${filterSql}
    ORDER BY ${sortExpr} ${dir}
    LIMIT ? OFFSET ?
  `, [q, `%${q}%`, `%${q}%`, limit, offset]);

  return {
    users,
    pagination: { page: pageClamped, pages, limit, total, q, sort, dir, filter }
  };
}

// ===== Страница со списком (SSR первичный рендер)
exports.listUsersPage = async (req, res) => {
  const db = req.db;
  const { page, limit, q, sort, dir, filter } = req.query;
  const { users, pagination } = await queryUsers(db, { page, limit, q, sort, dir, filter });

  logger.info('Admin loaded panel', {
    adminId: req.session.userId,
    userCount: users.length,
    pagination
  });

  res.render('admin', {
    users,
    csrfToken: req.csrfToken(),
    title: 'Admin Panel',
    pagination
  });
};

// ===== JSON endpoint
exports.listUsersJson = async (req, res) => {
  const db = req.db;
  const { page, limit, q, sort, dir, filter } = req.query;
  const data = await queryUsers(db, { page, limit, q, sort, dir, filter });
  logger.info('Admin listUsersJson', {
    adminId: req.session.userId,
    q: q || '',
    filter,
    page: data.pagination.page,
    total: data.pagination.total
  });
  res.json(data);
};

// ===== Обновление подписок пользователя
exports.updateUser = async (req, res) => {
  const db = req.db;
  const { id } = req.params;
  const { is_paid, paid_until, trial_until } = req.body;

  const nowISO = new Date().toISOString();
  const addDays = (n) => new Date(Date.now() + n*24*60*60*1000).toISOString();

  await run(db, 'BEGIN');
  try {
    // PAID
    if (typeof is_paid === 'boolean' || paid_until !== undefined) {
      // снимаем текущие активные
      await run(db, `
        UPDATE Subscriptions
        SET status='canceled', updated_at=CURRENT_TIMESTAMP
        WHERE user_id=? AND type='paid' AND status='active'
      `, [id]);

      if (is_paid) {
        const end = paid_until ? new Date(paid_until).toISOString() : addDays(30);
        await run(db, `
          INSERT INTO Subscriptions (user_id, type, status, start_date, end_date, created_at, updated_at)
          VALUES (?, 'paid', 'active', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `, [id, nowISO, end]);
      } else if (paid_until) {
        await run(db, `
          INSERT INTO Subscriptions (user_id, type, status, start_date, end_date, created_at, updated_at)
          VALUES (?, 'paid', 'active', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `, [id, nowISO, new Date(paid_until).toISOString()]);
      }
    }

    // TRIAL
    if (trial_until !== undefined) {
      await run(db, `
        UPDATE Subscriptions
        SET status='canceled', updated_at=CURRENT_TIMESTAMP
        WHERE user_id=? AND type='trial' AND status='active'
      `, [id]);

      if (trial_until) {
        const end = new Date(trial_until).toISOString();
        await run(db, `
          INSERT INTO Subscriptions (user_id, type, status, start_date, end_date, created_at, updated_at)
          VALUES (?, 'trial', 'active', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `, [id, nowISO, end]);
      }
    }

    await run(db, 'COMMIT');
  } catch (e) {
    await run(db, 'ROLLBACK');
    logger.error('Admin update user failed', { adminId: req.session.userId, userId: id, error: e.message });
    const err = new Error('Update failed');
    err.status = 500;
    throw err;
  }

  logger.info('Admin updated user', {
    adminId: req.session.userId,
    userId: id,
    changes: { is_paid, paid_until, trial_until }
  });

  res.json({ message: 'User updated' });
};

// ===== Кнопка "+30 дней" — добавляем от max(now, paid_until)
exports.grant30Days = async (req, res) => {
  const db = req.db;
  const { id } = req.params;

  const now = new Date();
  const nowISO = now.toISOString();

  // берём текущую активную оплач. дату
  const row = await get(db, `
    SELECT MAX(end_date) AS paid_until
    FROM Subscriptions
    WHERE user_id=? AND type='paid' AND status='active' AND datetime(end_date) > datetime('now')
  `, [id]);

  const base = row?.paid_until ? new Date(row.paid_until) : now;
  const baseTime = base > now ? base.getTime() : now.getTime();
  const endISO = new Date(baseTime + 30*24*60*60*1000).toISOString();

  await run(db, 'BEGIN');
  try {
    await run(db, `
      UPDATE Subscriptions
      SET status='canceled', updated_at=CURRENT_TIMESTAMP
      WHERE user_id=? AND type='paid' AND status='active'
    `, [id]);

    await run(db, `
      INSERT INTO Subscriptions (user_id, type, status, start_date, end_date, created_at, updated_at)
      VALUES (?, 'paid', 'active', ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    `, [id, nowISO, endISO]);

    await run(db, 'COMMIT');
  } catch (e) {
    await run(db, 'ROLLBACK');
    logger.error('Grant 30d failed', { adminId: req.session.userId, userId: id, error: e.message });
    const err = new Error('Grant 30 days failed');
    err.status = 500;
    throw err;
  }

  logger.info('Granted 30 days', { adminId: req.session.userId, userId: id, end: endISO });
  res.json({ message: 'Выдано +30 дней', paid_until: endISO });
};

// ===== JSON: устройства пользователя
exports.getUserDevices = async (req, res) => {
  const db = req.db;
  const { id } = req.params;
  const devices = await all(db, `
    SELECT id, device_token, device_model, device_os, last_seen
    FROM Devices
    WHERE user_id = ?
    ORDER BY datetime(last_seen) DESC, id DESC
  `, [id]);
  logger.info('Admin getUserDevices', { adminId: req.session.userId, userId: id, count: devices.length });
  res.json(devices || []);
};

// ===== Удалить (отвязать) устройство
exports.unlinkDevice = async (req, res) => {
  const db = req.db;
  const { id, deviceId } = req.params;
  await run(db, `DELETE FROM Devices WHERE id = ? AND user_id = ?`, [deviceId, id]);

  const row = await get(db, `SELECT COUNT(*) AS n FROM Devices WHERE user_id = ?`, [id]);
  logger.info('Device unlinked', { adminId: req.session.userId, userId: id, deviceId });
  res.json({ message: 'Устройство отвязано', deviceCount: row?.n || 0 });
};

// ===== Статистика (без изменений)
exports.getStats = async (req, res) => {
  const db = req.db;
  const now = new Date();
  const ago30 = new Date(now.getTime() - 30*24*60*60*1000).toISOString();

  const safeGet = async (fn, fallback = null) => {
    try { return await fn(); } catch (e) {
      logger.warn('Stats metric failed', { error: e.message });
      return fallback;
    }
  };

  const totalUsers = await safeGet(() => get(db, `SELECT COUNT(*) AS n FROM Users`, []), { n: 0 });
  const active30d  = await safeGet(() => get(db, `SELECT COUNT(DISTINCT user_id) AS n FROM UserStats WHERE last_login >= ?`, [ago30]), { n: 0 });
  const paidActive = await safeGet(() => get(db, `SELECT COUNT(DISTINCT user_id) AS n FROM Subscriptions WHERE type='paid' AND status='active' AND datetime(end_date) > datetime('now')`, []), { n: 0 });
  const trialActive = await safeGet(() => get(db, `SELECT COUNT(DISTINCT user_id) AS n FROM Subscriptions WHERE type='trial' AND status='active' AND datetime(end_date) > datetime('now')`, []), { n: 0 });
  const devicesTotal = await safeGet(() => get(db, `SELECT COUNT(*) AS n FROM Devices`, []), { n: 0 });
  const registrations30d = await safeGet(() => get(db, `SELECT COUNT(*) AS n FROM Users WHERE datetime(created_at) >= datetime(?)`, [ago30]), { n: 0 });

  const conv = await safeGet(async () => {
    const row = await get(db, `
      WITH trial_cohort AS (
        SELECT user_id, MIN(start_date) AS trial_start
        FROM Subscriptions
        WHERE type='trial' AND datetime(start_date) >= datetime(?)
        GROUP BY user_id
      ),
      converted AS (
        SELECT DISTINCT t.user_id
        FROM trial_cohort t
        JOIN Subscriptions s ON s.user_id = t.user_id
         AND s.type='paid'
         AND datetime(s.start_date) >= datetime(t.trial_start)
      )
      SELECT
        (SELECT COUNT(*) FROM trial_cohort) AS trials,
        (SELECT COUNT(*) FROM converted) AS converted
    `, [ago30]);
    const trials = row?.trials || 0;
    const converted = row?.converted || 0;
    const rate = trials ? Math.round((converted / trials) * 10000) / 100 : 0;
    return { trials, converted, rate };
  }, { trials: 0, converted: 0, rate: 0 });

  const revenue30d = await safeGet(() => all(db, `
    SELECT currency, ROUND(COALESCE(SUM(amount),0),2) AS sum
    FROM Payments
    WHERE status IN ('succeeded','paid') AND datetime(created_at) >= datetime(?)
    GROUP BY currency
    ORDER BY sum DESC
  `, [ago30]), []);

  const devicesByOs = await safeGet(() => all(db, `
    SELECT COALESCE(NULLIF(TRIM(LOWER(device_os)),''),'unknown') AS os, COUNT(*) AS n
    FROM Devices GROUP BY os ORDER BY n DESC
  `, []), []);

  const devicesByOsActive30 = await safeGet(() => all(db, `
    SELECT COALESCE(NULLIF(TRIM(LOWER(device_os)),''),'unknown') AS os, COUNT(*) AS n
    FROM Devices WHERE datetime(last_seen) >= datetime(?) GROUP BY os ORDER BY n DESC
  `, [ago30]), []);

  const topByDevices = await safeGet(() => all(db, `
    SELECT u.username, COUNT(d.id) AS devices
    FROM Devices d JOIN Users u ON u.id=d.user_id
    GROUP BY d.user_id
    ORDER BY devices DESC LIMIT 10
  `, []), []);

  logger.info('Admin viewed stats', { adminId: req.session.userId });

  res.render('stats', {
    title: 'Admin Statistics',
    csrfToken: req.csrfToken(),
    cards: {
      totalUsers: totalUsers.n,
      active30d: active30d.n,
      paidActive: paidActive.n,
      trialActive: trialActive.n,
      devicesTotal: devicesTotal.n,
      registrations30d: registrations30d.n,
      trialPaidTrials: conv.trials,
      trialPaidConverted: conv.converted,
      trialPaidRate: conv.rate
    },
    revenue30d,
    devicesByOs,
    devicesByOsActive30,
    topByDevices
  });
};
