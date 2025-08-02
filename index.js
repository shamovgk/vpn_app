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
const logger = require('./logger');
const { config } = require('./config/config');

const mainscreenRoutes = require('./routes/mainscreenRoutes');
const webhookRoutes = require('./routes/webhookRoutes');  
const authRoutes = require('./routes/authRoutes');
const deviceRoutes = require('./routes/deviceRoutes');
const adminRoutes = require('./routes/adminRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const vpnRoutes = require('./routes/vpnRoutes');

// === Database connection and models ===
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
  }
});

// === Express app settings ===
const app = express();
app.set('view engine', 'ejs');
app.set('views', __dirname + '/views');
app.use(expressLayouts);
app.use(express.json());

// === Security middlewares ===
app.use(helmet());
app.use(cors({ origin: ['https://sham.shetanvpn.ru'], credentials: true }));

// === Sessions ===
app.use(session(config.session));
app.set('db', db);

// === Global Rate Limit ===
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: 'Too many requests from this IP, please try again later.'
}));

// === CSRF ONLY for admin (ejs forms, not API) ===
app.use('/admin', cookieParser(), csurf({ cookie: true }));

// === Per-route rate limiters ===
app.use('/auth', rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many auth attempts, slow down!'
}));
app.use('/pay', rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: 'Too many payment attempts, try later.'
}));
app.use('/admin', rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: 'Too many admin requests, relax!'
}));

// === Routers ===
app.use('/auth', authRoutes);
app.use('/devices', deviceRoutes);
app.use('/admin', adminRoutes);
app.use('/pay', paymentRoutes);
app.use('/vpn', vpnRoutes);

// === Healthcheck endpoint (для мониторинга) ===
app.get('/healthz', (req, res) => {
  req.app.get('db').get('SELECT 1', [], (err) => {
    if (err) {
      logger.error('Healthcheck failed', { error: err });
      return res.status(500).send('DB error');
    }
    res.send('OK');
  });
});

app.use('/webhook', webhookRoutes);  // POST /webhook/yookassa

app.use('/', mainscreenRoutes);

// === Error handler ===
app.use(errorHandler);

// === Start server ===
app.listen(config.port, () => logger.info(`Server running on http://localhost:${config.port}`));
