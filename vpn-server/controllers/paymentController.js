// controllers/paymentController.js
const YooKassa = require('yookassa');
const { config } = require('../config/config');
const logger = require('../logger');

const yooKassa = new YooKassa({
  shopId: config.yooKassa.shopId,
  secretKey: config.yooKassa.secretKey
});

exports.payYookassa = async (req, res) => {
  try {
    const { amount, method } = req.body;
    const userId = req.user?.id || req.body.user_id; // желательно получать user_id из токена или явно из клиента
    logger.info('Payment initiated', { amount, method, userId });

    // Проверка метода
    const allowed = ['bank_card', 'sbp', 'sberbank'];
    if (!allowed.includes(method)) {
      return res.status(400).json({ error: 'Unsupported payment method' });
    }

    const payment = await yooKassa.createPayment({
      amount: { value: amount, currency: 'RUB' },
      payment_method_data: { type: method },
      confirmation: { type: 'redirect', return_url: 'https://sham.shetanvpn.ru/mainscreen' },
      capture: true,
      description: 'Оплата VPN',
      metadata: { user_id: userId }, // <-- вот это главное!
    });

    // Записываем в таблицу Payments (pending)
    await new Promise((resolve, reject) =>
      req.db.run(
        `INSERT INTO Payments (user_id, amount, currency, payment_id, status, method, meta)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [userId, amount, 'RUB', payment.id, payment.status, method, JSON.stringify(payment)],
        err => err ? reject(err) : resolve()
      )
    );

    logger.info('Payment created', { paymentId: payment.id, status: payment.status });

    res.json({
      status: payment.status,
      paymentId: payment.id,
      confirmationUrl: payment.confirmation?.confirmation_url
    });
  } catch (err) {
    logger.error('Payment error', { error: err.message, stack: err.stack });
    res.status(500).json({ error: err.message });
  }
};

