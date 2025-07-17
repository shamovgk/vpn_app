module.exports = function withDb(req, res, next) {
  req.db = req.app.get('db');
  next();
};