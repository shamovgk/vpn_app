const config = require('../config/config');
const logger = require('../utils/logger.js');
const { getUserByToken } = require('../services/authService');
const { getActiveSubscription } = require('../services/subscriptionService');

exports.getVpnConfig = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer '))
      return res.status(401).json({ error: 'Token is required' });
    const token = authHeader.split(' ')[1];
    const db = req.db;

    const user = await getUserByToken({ token, db });
    if (!user) return res.status(401).json({ error: 'Invalid or expired token' });

    const sub = await getActiveSubscription({ userId: user.id, db });
    if (!sub) return res.status(403).json({ error: 'Нет активной подписки или триала' });

    if (!user.vpn_key || !user.client_ip)
      return res.status(400).json({ error: 'VPN key or IP not assigned' });

    res.json({
      privateKey: user.vpn_key,
      address: user.client_ip,
      dns: config.vpn.dns,
      serverPublicKey: config.vpn.serverPublicKey,
      endpoint: config.vpn.endpoint,
      allowedIps: '0.0.0.0/0, ::/0'
    });
  } catch (e) {
    logger.error('GetVpnConfig error', { error: e.message });
    res.status(400).json({ error: e.message });
  }
};
