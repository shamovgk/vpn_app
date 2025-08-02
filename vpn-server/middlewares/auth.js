// middlewares/auth.js
module.exports = function (req, res, next) {
  const db = req.db || req.app.get('db');
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authorization header missing' });
  }
  const token = authHeader.split(' ')[1];
  db.get('SELECT * FROM Users WHERE auth_token = ? AND token_expiry > ?', [token, new Date().toISOString()], (err, user) => {
    if (err) return res.status(500).json({ error: 'DB error' });
    if (!user) return res.status(401).json({ error: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};
