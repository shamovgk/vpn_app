// index.js
const express = require('express');
const path = require('path');
const helmet = require('helmet');
const csurf = require('csurf');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const sqlite3 = require('sqlite3');
const expressLayouts = require('express-ejs-layouts');
const errorHandler = require('./middlewares/errorHandler');
require('events').defaultMaxListeners = 30;
const logger = require('./utils/logger.js');
const config = require('./config/config');

// Routers
const authRoutes = require('./routes/authRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const vpnRoutes = require('./routes/vpnRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes');

// DB
const db = new sqlite3.Database(config.dbPath, async (err) => {
  if (err) {
    logger.error('Error opening database', { error: err });
    process.exit(1);
  }
  logger.info(`Connected to the SQLite database at ${config.dbPath}`);
  try {
    await require('./db/bootstrap')(db);
    startServer(db);
  } catch (e) {
    logger.error('bootstrap failed', { error: e });
    process.exit(1);
  }
});

function startServer(db) {
  const app = express();
  app.set('trust proxy', 1);
  app.set('view engine', 'ejs');
  app.set('views', __dirname + '/views');
  app.use(expressLayouts);

  // Безопасность/база
  app.use(helmet());
  app.use(cors(config.cors));
  app.use(express.json());              // JSON для API
  app.use(session(config.session));     // сессии
  app.set('db', db);

  // Раздача статики (внешний JS/CSS админки)
  app.use('/static', express.static(path.join(__dirname, 'public'), { maxAge: '1h', etag: true }));

  // locals для layout
  app.use((req, res, next) => {
    res.locals.error = null;
    res.locals.title = res.locals.title || 'UgbuganVPN Admin';
    next();
  });

  // Лимитеры
  app.use('/auth', rateLimit({ windowMs: 60_000, max: 10, message: 'Too many auth attempts, slow down!' }));
  app.use('/pay',  rateLimit({ windowMs: 60_000, max: 50, message: 'Too many payment attempts, try later.' }));
  app.use('/admin',rateLimit({ windowMs: 60_000, max: 300, message: 'Too many admin requests, relax!' }));

  // Health
  app.get('/healthz', (req, res) => {
    req.app.get('db').get('SELECT 1', [], (err) => {
      if (err) {
        logger.error('Healthcheck failed', { error: err });
        return res.status(500).send('DB error');
      }
      res.send('OK');
    });
  });

  // YooKassa вебхук — без CSRF
  const withDb = require('./middlewares/withDb');
  const paymentController = require('./controllers/paymentController');
  app.post('/pay/yookassa', express.json(), withDb, (req, res, next) =>
    paymentController.yookassaWebhook(req, res, next)
  );

  // Публичные API
  app.use('/auth', authRoutes);
  app.use('/devices', deviceRoutes);
  app.use('/pay', paymentRoutes);
  app.use('/vpn', vpnRoutes);
  app.use('/subscription', subscriptionRoutes);

  // ===== ADMIN: один CSRF-комбайн для форм и AJAX =====
  app.use('/admin',
    cookieParser(),
    express.urlencoded({ extended: false }),    // для формы логина
    csurf({ cookie: { sameSite: 'lax' } })
  );

  // Роуты админки
  app.use('/admin', adminRoutes);

  // Обработчик CSRF-ошибок только для /admin
  app.use('/admin', (err, req, res, next) => {
    if (err && err.code === 'EBADCSRFTOKEN') {
      logger.warn('Invalid CSRF token', { path: req.path, ip: req.ip });
      try {
        return res.status(403).render('login', {
          title: 'Вход в админку',
          csrfToken: req.csrfToken(),
          next: req.originalUrl.includes('/admin/login') ? '/admin' : (req.query.next || '/admin'),
          error: 'Неверный CSRF токен. Обновите страницу и войдите снова.'
        });
      } catch {
        return res.status(403).json({ error: 'invalid csrf token' });
      }
    }
    next(err);
  });

  // Возврат из YooKassa
  app.get('/payment-return', (_req, res) => {
    res.status(200).send(`<!doctype html><meta charset="utf-8">
      <title>Возврат в приложение</title>
      <p>Можно вернуться в приложение. Если страница не закрылась автоматически, закройте её.</p>`);
  });

  // 404/ошибки
  app.use((req, res) => res.status(404).json({ error: 'Not Found' }));
  app.use(errorHandler);

  app.listen(config.port, () => logger.info(`Server running on http://localhost:${config.port}`));
}
