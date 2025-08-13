// index.js
const express = require('express');
const helmet = require('helmet');
const csurf = require('csurf');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const sqlite3 = require('sqlite3');
const expressLayouts = require('express-ejs-layouts');
const errorHandler = require('./middlewares/errorHandler');
const logger = require('./utils/logger.js');
const config = require('./config/config');

// ==== Импорты роутов ====
const authRoutes = require('./routes/authRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const vpnRoutes = require('./routes/vpnRoutes');
const subscriptionRoutes = require('./routes/subscriptionRoutes');

// ==== Database connection and models ====
const db = new sqlite3.Database(config.dbPath, (err) => {
  if (err) {
    logger.error('Error opening database', { error: err });
  } else {
    logger.info(`Connected to the SQLite database at ${config.dbPath}`);
    require('./models/userModel')(db);
    require('./models/pendingUserModel')(db);
    require('./models/deviceModel')(db);
    require('./models/passwordResetModel')(db);
    require('./models/userStatsModel')(db);
    require('./models/paymentModel')(db);
    require('./models/subscriptionModel')(db);
  }
});

// ==== Express app settings ====
const app = express();
app.set('trust proxy', 1);
app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');
app.use(expressLayouts);

// Глобальный json-парсер (остаётся)
app.use(express.json());

// ==== Security middlewares ====
app.use(helmet());
app.use(cors(config.cors));

// ==== Sessions (только для SSR/админки) ====
app.use(session(config.session));
app.set('db', db);

// ==== Глобальный Rate Limit ====
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: 'Too many requests from this IP, please try again later.'
}));

// ==== CSRF только для админки (EJS формы, не для API) ====
app.use('/admin', cookieParser(), csurf({ cookie: true }));

// ==== Healthcheck endpoint (для мониторинга) ====
app.get('/healthz', (req, res) => {
  req.app.get('db').get('SELECT 1', [], (err) => {
    if (err) {
      logger.error('Healthcheck failed', { error: err });
      return res.status(500).send('DB error');
    }
    res.send('OK');
  });
});

// ======= ВЕБХУК ЮKassa ДО лимитеров и ДО /pay роутера =======
const withDb = require('./middlewares/withDb');
const paymentController = require('./controllers/paymentController');

// Явно принимаем вебхук тут, чтобы его не трогали ни auth, ни лимитеры
app.post('/pay/yookassa', express.json(), withDb, (req, res, next) => {
  // расширенный лог для диагностики (временно можно оставить)
  logger.info('Webhook hit', { ip: req.ip, ips: req.ips, ua: req.headers['user-agent'] });
  return paymentController.yookassaWebhook(req, res, next);
});
// =============================================================

// ==== Пер-роут Rate Limit ====
app.use('/auth', rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many auth attempts, slow down!'
}));

// Лимитер на /pay НЕ касается вебхука — он выше и отдельно
app.use('/pay', rateLimit({
  windowMs: 60 * 1000,
  max: 50,
  message: 'Too many payment attempts, try later.'
}));

app.use('/admin', rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: 'Too many admin requests, relax!'
}));

// ==== Routers ====
app.use('/auth', authRoutes);
app.use('/devices', deviceRoutes);
app.use('/admin', adminRoutes);
app.use('/pay', paymentRoutes); // здесь уже нет вебхука
app.use('/vpn', vpnRoutes);
app.use('/subscription', subscriptionRoutes);

// redirect после успешной оплаты
app.get('/payment_success', (req, res) => {
  res.redirect('https://sham.shetanvpn.ru/payment-success');
});

// ==== 404 ====
app.use((req, res, next) => {
  res.status(404).json({ error: 'Not Found' });
});

// ==== Глобальный Error handler ====
app.use(errorHandler);

// ==== Start server ====
app.listen(config.port, () => logger.info(`Server running on http://localhost:${config.port}`));
