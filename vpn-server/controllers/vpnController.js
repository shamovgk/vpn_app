const config = require('../config/config');
const logger = require('../utils/logger.js');

exports.getVpnConfig = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) throw new Error('Token is required');
    const token = authHeader.split(' ')[1];
    const db = req.db;

    const user = await new Promise((resolve, reject) =>
      db.get(
        `SELECT username, is_paid, trial_end_date, vpn_key, client_ip FROM Users WHERE auth_token = ? AND token_expiry > ?`,
        [token, new Date().toISOString()],
        (err, user) => err ? reject(err) : resolve(user)
      )
    );
    if (!user) throw new Error('Invalid or expired token');

    // Проверка оплаты или trial
    const trialActive = user.trial_end_date && new Date(user.trial_end_date) > new Date();
    if (!user.is_paid && !trialActive) throw new Error('Trial period expired or not paid');

    // Параметры WireGuard из config.vpn
    const serverPublicKey = config.vpn.serverPublicKey;
    const endpoint = config.vpn.endpoint;
    const dns = config.vpn.dns;

    if (!user.vpn_key || !user.client_ip) throw new Error('VPN key or IP not assigned');

    // JSON (Клиенту — удобно парсить, удобно собирать конфиг)
    res.json({
      privateKey: user.vpn_key,
      address: user.client_ip,
      dns,
      serverPublicKey,
      endpoint,
      allowedIps: '0.0.0.0/0, ::/0'
    });
  } catch (e) {
    logger.error('GetVpnConfig error', { error: e.message });
    res.status(400).json({ error: e.message });
  }
};
