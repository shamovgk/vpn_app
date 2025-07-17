const dotenv = require('dotenv');
dotenv.config();

module.exports.config = {
  port: process.env.PORT || 3000,
  dbPath: process.env.DB_PATH || './vpn.db',
  session: {
    secret: process.env.SESSION_SECRET || 'your_secret_key',
    resave: false,
    saveUninitialized: false,
    cookie: { secure: process.env.NODE_ENV === 'production' }
  },
  yooKassa: {
    shopId: process.env.YOOKASSA_SHOPID || process.env.YOOKASSA_SHOP_ID || '',
    secretKey: process.env.YOOKASSA_SECRETKEY || process.env.YOOKASSA_SECRET_KEY || ''
  },
  smtp: {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || ''
    }
  },
  cors: {
    origin: (process.env.CORS_ORIGIN || '').split(',').map(s => s.trim()).filter(Boolean),
    credentials: true
  }
};
