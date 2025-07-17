const YooKassa = require('yookassa');
const { config } = require('../config/config');
const logger = require('../logger');

const yooKassa = new YooKassa({
  shopId: config.yooKassa.shopId,
  secretKey: config.yooKassa.secretKey
});

exports.payYookassa = async (req, res) => {
  const { token, amount, method } = req.body;
  const db = req.db;

  logger.info('Payment initiated', { amount, method });

  const payment = await yooKassa.createPayment({
    amount: { value: amount, currency: 'RUB' },
    payment_method_data: method === 'sbp'
      ? { type: 'sbp' }
      : { type: method || 'bank_card', payment_token: token },
    confirmation: { type: 'redirect', return_url: 'https://your-app.com/success' },
    capture: true,
    description: 'Оплата VPN',
  });

  if (payment.status === 'succeeded') {
    const user = await new Promise((resolve, reject) =>
      db.get(`SELECT id FROM Users WHERE auth_token = ? AND token_expiry > ?`, [req.headers.authorization?.split(' ')[1], new Date().toISOString()],
        (err, user) => err ? reject(err) : resolve(user))
    );
    if (user) {
      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Users SET is_paid = 1, subscription_level = ? WHERE id = ?`,
          [amount >= 500 ? 1 : 0, user.id],
          err => err ? reject(err) : resolve()
        )
      );
      await new Promise((resolve, reject) =>
        db.run(
          `INSERT OR REPLACE INTO UserStats (user_id, payment_count, last_payment_date) VALUES (?, COALESCE((SELECT payment_count + 1 FROM UserStats WHERE user_id = ?), 1), ?)`,
          [user.id, user.id, new Date().toISOString()],
          err => err ? reject(err) : resolve()
        )
      );
      logger.info('Payment succeeded', { userId: user.id, amount, paymentId: payment.id });
    } else {
      logger.warn('Payment succeeded, but user not found for token', { amount, paymentId: payment.id });
    }
  } else {
    logger.warn('Payment failed', { status: payment.status, paymentId: payment.id });
  }

  res.json({ status: payment.status, paymentId: payment.id, confirmationUrl: payment.confirmation?.confirmation_url });
};
