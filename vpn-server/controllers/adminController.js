const bcrypt = require('bcrypt');

function adminAuth(req, res, next) {
  if (!req.session.admin) return res.status(403).json({ error: 'Admin access required' });
  next();
}

function adminLogin(req, res) {
  const { username, password } = req.body;
  req.db.get(
    `SELECT id, username, password, is_admin FROM Users WHERE username = ?`,
    [username],
    (err, user) => {
      if (err || !user || user.is_admin !== 1 || !bcrypt.compareSync(password, user.password)) {
        return res.status(401).json({ error: 'Invalid credentials or not an admin' });
      }
      req.session.admin = true;
      req.session.userId = user.id;
      res.json({ message: 'Admin login successful' });
    }
  );
}

function adminLogout(req, res) {
  req.session.destroy((err) => err ? res.status(500).json({ error: 'Failed to logout' }) : res.json({ message: 'Logged out' }));
}

function adminLoginPage(req, res) {
  if (req.session.admin) return res.redirect('/admin');
  res.render('login', { title: 'Admin Login' });
}

function adminPage(req, res) {
  req.db.all(`SELECT id, username, email, email_verified, is_paid, subscription_level, trial_end_date, device_count FROM Users`, [], (err, users) => {
    if (err) {
      console.error('Admin page error:', err.message);
      return res.status(500).render('admin', { title: 'Admin Panel', users: [], error: 'Failed to load users' });
    }
    res.render('admin', { title: 'Admin Panel', users: users || [] });
  });
}

function updateUser(req, res) {
  const { id } = req.params;
  const { is_paid, trial_end_date, subscription_level } = req.body;
  req.db.run(
    `UPDATE Users SET is_paid = ?, trial_end_date = ?, subscription_level = ? WHERE id = ?`,
    [is_paid ? 1 : 0, trial_end_date, subscription_level || 0, id],
    (err) => {
      if (err) {
        console.error('User update error:', err.message);
        return res.status(500).json({ error: 'Update failed' });
      }
      res.json({ message: 'User updated' });
    }
  );
}

function searchUsers(req, res) {
  const { username } = req.query;
  if (!username) return res.status(400).json({ error: 'Username is required' });
  req.db.all(
    `SELECT id, username, email, email_verified, is_paid, subscription_level, trial_end_date, device_count FROM Users WHERE username LIKE ?`,
    [`%${username}%`],
    (err, users) => {
      if (err) {
        console.error('Search error:', err.message);
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(users || []);
    }
  );
}

function getStats(req, res) {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  req.db.all(`
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
  `, [thirtyDaysAgo, new Date().toISOString(), thirtyDaysAgo], (err, userActivity) => {
    if (err) {
      console.error('Stats error:', err.message);
      return res.status(500).render('stats', { title: 'Admin Statistics', userActivity: [], error: 'Failed to load stats' });
    }
    res.render('stats', { title: 'Admin Statistics', userActivity: userActivity || [] });
  });
}

module.exports = { adminAuth, adminLogin, adminLogout, adminLoginPage, adminPage, updateUser, searchUsers, getStats };