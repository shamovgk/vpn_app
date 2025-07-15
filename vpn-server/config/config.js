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
    shopId: process.env.YOOKASSA_SHOP_ID || 'crhsnk',
    secretKey: process.env.YOOKASSA_SECRET_KEY || 'crhsnj'
  },
  smtp: {
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER || 'UgbuganSoft@gmail.com',
      pass: process.env.SMTP_PASS || 'ohkr jgtg unce hjuc'
    }
  }
};