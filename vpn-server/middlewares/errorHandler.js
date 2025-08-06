const logger = require('../utils/logger');

module.exports = function (err, req, res, next) {
  logger.error('Unhandled Error', { error: err, url: req.url, method: req.method });
  res.status(err.status || 500).json({ error: err.message || 'Internal Server Error' });
};