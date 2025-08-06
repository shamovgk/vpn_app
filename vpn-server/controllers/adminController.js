const bcrypt = require('bcrypt');
const logger = require('../utils/logger.js');

exports.adminAuth = (req, res, next) => {
  if (!req.session.admin) {
    logger.warn('Admin access denied (no session)', { ip: req.ip });
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

exports.adminLogin = async (req, res) => {
  const { username, password } = req.body;
  const db = req.db;
  const user = await new Promise((resolve, reject) =>
    db.get(
      `SELECT id, username, password, is_admin FROM Users WHERE username = ?`,
      [username],
      (err, user) => err ? reject(err) : resolve(user)
    )
  );
  if (!user || user.is_admin !== 1 || !bcrypt.compareSync(password, user.password)) {
    logger.warn('Admin login failed', { username, ip: req.ip });
    throw new Error('Invalid credentials or not an admin');
  }
  req.session.admin = true;
  req.session.userId = user.id;
  logger.info('Admin login success', { adminId: user.id, username, ip: req.ip });
  res.json({ message: 'Admin login successful' });
};

exports.adminLogout = async (req, res) => {
  const adminId = req.session.userId;
  req.session.destroy((err) =>
    err
      ? res.status(500).json({ error: 'Failed to logout' })
      : res.json({ message: 'Logged out' })
  );
  logger.info('Admin logged out', { adminId, ip: req.ip });
};

// Для страницы логина ничего менять не надо — только рендерит login.ejs

// Для страницы админки — теперь реализуем отдельную функцию получения users:
exports.getUsers = async (req, res, returnArray = false) => {
  const db = req.db;
  const users = await new Promise((resolve, reject) =>
    db.all(
      `SELECT id, username, email, email_verified, is_paid, subscription_level, trial_end_date, device_count FROM Users`,
      [],
      (err, users) => err ? reject(err) : resolve(users)
    )
  );
  logger.info('Admin loaded panel', { adminId: req.session.userId, userCount: users.length });
  if (returnArray) return users;
  res.render('admin', { users, csrfToken: req.csrfToken(), title: 'Admin Panel' });
};

exports.updateUser = async (req, res) => {
  const db = req.db;
  const { id } = req.params;
  const { is_paid, trial_end_date, subscription_level } = req.body;
  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET is_paid = ?, trial_end_date = ?, subscription_level = ? WHERE id = ?`,
      [is_paid ? 1 : 0, trial_end_date, subscription_level || 0, id],
      err => err ? reject(err) : resolve()
    )
  );
  logger.info('Admin updated user', {
    adminId: req.session.userId,
    userId: id,
    changes: { is_paid, trial_end_date, subscription_level }
  });
  res.json({ message: 'User updated' });
};

exports.searchUsers = async (req, res) => {
  const db = req.db;
  const { username } = req.query;
  if (!username) throw new Error('Username is required');
  const users = await new Promise((resolve, reject) =>
    db.all(
      `SELECT id, username, email, email_verified, is_paid, subscription_level, trial_end_date, device_count FROM Users WHERE username LIKE ?`,
      [`%${username}%`],
      (err, users) => err ? reject(err) : resolve(users)
    )
  );
  logger.info('Admin user search', {
    adminId: req.session.userId,
    query: username,
    found: users.length
  });
  res.json(users || []);
};

exports.getStats = async (req, res) => {
  const db = req.db;
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const userActivity = await new Promise((resolve, reject) =>
    db.all(`
      SELECT 
        u.username,
        COUNT(CASE WHEN s.last_login >= ? THEN 1 END) as active_users,
        SUM(CASE WHEN u.is_paid = 1 THEN 1 ELSE 0 END) as paid_users,
        SUM(CASE WHEN u.trial_end_date > ? AND u.is_paid = 0 THEN 1 ELSE 0 END) as trial_users,
        COUNT(CASE WHEN u.created_at >= ? THEN 1 END) as registrations,
        ROUND((SUM(CASE WHEN u.email_verified = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2) as email_verified_pct
      FROM Users u
      LEFT JOIN UserStats s ON u.id = s.user_id
      GROUP BY u.username
    `, [thirtyDaysAgo, new Date().toISOString(), thirtyDaysAgo],
      (err, activity) => err ? reject(err) : resolve(activity)
    )
  );
  logger.info('Admin viewed stats', { adminId: req.session.userId });
  res.render('stats', { title: 'Admin Statistics', userActivity: userActivity || [], csrfToken: req.csrfToken() });
};
