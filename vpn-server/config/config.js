// config/config.js
const path = require('path');
const dotenv = require('dotenv');
dotenv.config();

module.exports = {
  port: process.env.PORT || 3000,
  dbPath: path.resolve(process.cwd(), process.env.DB_PATH || 'vpn.db'),

  // Сессии (для админки/SSR)
  session: {
    secret: process.env.SESSION_SECRET || 'your_secret_key',
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax'
    }
  },

  // YooKassa
  yooKassa: {
    shopId: process.env.YOOKASSA_SHOPID || process.env.YOOKASSA_SHOP_ID || '',
    secretKey: process.env.YOOKASSA_SECRETKEY || process.env.YOOKASSA_SECRET_KEY || ''
  },

  // Платёжные константы
  payment: {
    returnUrl: 'https://sham.shetanvpn.ru/payment-return',
    allowedMethods: ['bank_card', 'sbp', 'sberbank'],
    description: 'Оплата VPN',
    currency: 'RUB',
  },

  // SMTP/email
  smtp: {
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: process.env.SMTP_PORT ? Number(process.env.SMTP_PORT) : 587,
    secure: false,
    auth: {
      user: process.env.SMTP_USER || '',
      pass: process.env.SMTP_PASS || ''
    }
  },

  // Разрешённые домены для CORS
  cors: {
    origin: (process.env.CORS_ORIGIN || 'https://sham.shetanvpn.ru').split(',').map(s => s.trim()).filter(Boolean),
    credentials: true
  },

  // VPN-опции (WireGuard и скрипты)
  vpn: {
    wgConfPath: process.env.WG_CONF_PATH || '/etc/wireguard/wg0.conf',
    scriptGenerateKey: process.env.GENERATE_VPN_KEY_SCRIPT || __dirname + '/../scripts/generate_vpn_key.sh',
    scriptAddToConf: process.env.ADD_TO_WG_CONF_SCRIPT || __dirname + '/../scripts/add_to_wg_conf.sh',
    network: process.env.VPN_NETWORK || '10.0.0.0/24',
    serverPublicKey: process.env.WG_SERVER_PUBKEY || 'PASTE_YOUR_SERVER_PUBLIC_KEY',
    endpoint: process.env.WG_ENDPOINT || 'vpn.example.com:51820',
    dns: process.env.WG_DNS || '1.1.1.1',
  },

  site: {
    appName: 'ShetanVPN',
    tagline: 'Быстрый и безопасный VPN для всех устройств',
    description: 'Кроссплатформенный VPN с упором на приватность и стабильность. Простая установка, прозрачная подписка, поддержка WireGuard.',
    downloads: {
      ios: '#',     // 👉 потом вставь реальные ссылки
      android: '#',
      windows: '#',
      macos: '#',
    },
    contacts: {
      email: 'support@example.com',
      telegram: 'https://t.me/your_channel',
    },
    social: {
      x: '#',
      github: '#',
    },
    legal: {
      privacyUrl: '/privacy',
      termsUrl: '/terms',
    },
    theme: {
      colors: {
        bg: '#161208',           // из dark_theme.dart
        surface: '#201911',
        text: '#EBE6D7',
        textMuted: '#AEA486',
        primary: '#E2C77F',
        primaryHover: '#d5b56e',
        accent: '#C6D6F8',
        border: '#58513D',
      }
    },
    features: [
      { title: 'WireGuard', desc: 'Стабильные и быстрые соединения с минимальной задержкой.', icon: '🔐' },
      { title: 'Кроссплатформенность', desc: 'Один аккаунт для iOS, Android, Windows и macOS.', icon: '🧭' },
      { title: 'Приватность', desc: 'Минимум логов, защита трафика и шифрование по умолчанию.', icon: '🛡️' },
      { title: 'Простая подписка', desc: 'Прозрачные тарифы и автоматическое продление.', icon: '💳' },
    ],
  },
};
