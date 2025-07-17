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
  },
 vpn: {
    wgConfPath: process.env.WG_CONF_PATH || '/etc/wireguard/wg0.conf',
    scriptGenerateKey: process.env.GENERATE_VPN_KEY_SCRIPT || __dirname + '/../scripts/generate_vpn_key.sh',
    scriptAddToConf: process.env.ADD_TO_WG_CONF_SCRIPT || __dirname + '/../scripts/add_to_wg_conf.sh',
    network: process.env.VPN_NETWORK || '10.0.0.0/24',
    serverPublicKey: process.env.WG_SERVER_PUBKEY || 'PASTE_YOUR_SERVER_PUBLIC_KEY',
    endpoint: process.env.WG_ENDPOINT || 'vpn.example.com:51820',
    dns: process.env.WG_DNS || '1.1.1.1',
  }
};
