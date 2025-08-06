const paymentService = require('../services/paymentService');
const logger = require('../utils/logger.js');

exports.payYookassa = async (req, res) => {
  try {
    const { amount, method } = req.body;
    const userId = req.user?.id || req.body.user_id;
    logger.info('Payment initiated', { amount, method, userId });

    const payment = await paymentService.createPayment({ amount, method, userId });

    // Записываем в таблицу Payments (pending)
    await new Promise((resolve, reject) =>
      req.db.run(
        `INSERT INTO Payments (user_id, amount, currency, payment_id, status, method, meta)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [userId, amount, payment.amount.currency, payment.id, payment.status, method, JSON.stringify(payment)],
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
