const YooKassa = require('yookassa');
const { config } = require('../config/config');

const yooKassa = new YooKassa({
  shopId: config.yooKassa.shopId,
  secretKey: config.yooKassa.secretKey
});

async function payYookassa(req, res) {
  const { token, amount, method } = req.body;
  console.log('Получен запрос на /pay-yookassa:', req.body);
  console.log('Перед вызовом createPayment');
  try {
    const payment = await yooKassa.createPayment({
      amount: { value: amount, currency: 'RUB' },
      payment_method_data: { type: method || 'bank_card', payment_token: token },
      confirmation: { type: 'redirect', return_url: 'https://your-app.com/success' },
      capture: true,
      description: 'Оплата VPN',
    });
    console.log('Ответ от YooKassa:', payment);
    if (payment.status === 'succeeded') {
      req.db.get(`SELECT id FROM Users WHERE auth_token = ? AND token_expiry > ?`, [req.headers.authorization?.split(' ')[1], new Date().toISOString()], (err, user) => {
        if (err || !user) console.error('User not found for payment:', err?.message);
        else {
          const userId = user.id;
          req.db.run(
            `UPDATE Users SET is_paid = 1, subscription_level = ? WHERE id = ?`,
            [amount >= 500 ? 1 : 0, userId],
            (err) => { if (err) console.error('Error updating is_paid:', err.message); }
          );
          req.db.run(
            `INSERT OR REPLACE INTO UserStats (user_id, payment_count, last_payment_date) VALUES (?, COALESCE((SELECT payment_count + 1 FROM UserStats WHERE user_id = ?), 1), ?)`,
            [userId, userId, new Date().toISOString()],
            (err) => { if (err) console.error('Stats payment update error:', err.message); }
          );
        }
      });
    }
    res.json({ status: payment.status, paymentId: payment.id, confirmationUrl: payment.confirmation?.confirmation_url });
  } catch (e) {
    console.error('Ошибка при создании платежа:', e.message, e);
    res.status(500).json({ error: e.message });
  }
}

module.exports = { payYookassa };