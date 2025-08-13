// controllers/paymentController.js
const paymentService = require('../services/paymentService');
const subscriptionService = require('../services/subscriptionService');
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

exports.yookassaWebhook = async (req, res) => {
  try {
    // req.db гарантирован withDb в index.js
    const db = req.db;

    logger.info('Получен webhook от ЮKassa', { body: req.body, headers: req.headers });

    const event = req.body.event;
    const object = req.body.object;

    logger.info('Webhook event/object', { event, objectId: object?.id, status: object?.status });

    if (event === 'payment.succeeded' && object && object.status === 'succeeded') {
      const paymentId = object.id;
      const userId = object.metadata?.user_id;

      logger.info('Обработка payment.succeeded', { paymentId, userId });

      if (!userId) {
        logger.error('Webhook error: no user_id in metadata', { objectId: paymentId });
        return res.status(400).json({ error: 'user_id not found in payment metadata' });
      }

      // 1) Обновляем платеж
      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Payments SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP WHERE payment_id = ?`,
          [paymentId],
          err => err ? reject(err) : resolve()
        )
      );
      logger.info('Payment status updated to succeeded', { paymentId });

      // 2) Продлеваем подписку
      await subscriptionService.extendSubscription({ userId, months: 1, db });
      logger.info('User subscription extended (via webhook)', { userId });

      return res.status(200).json({ received: true });
    }

    if (event === 'payment.canceled') {
      const paymentId = object?.id;
      if (paymentId) {
        await new Promise((resolve, reject) =>
          db.run(
            `UPDATE Payments SET status = 'canceled', updated_at = CURRENT_TIMESTAMP WHERE payment_id = ?`,
            [paymentId],
            err => err ? reject(err) : resolve()
          )
        );
        logger.info('Payment status updated to canceled', { paymentId });
      }
      return res.status(200).json({ received: true });
    }

    // На прочие события просто отвечаем 200 (чтобы ЮKassa не ретраила бесконечно)
    logger.warn('Webhook: Необработанное событие', { event });
    return res.status(200).json({ received: true });
  } catch (e) {
    logger.error('Ошибка обработки webhook', { error: e.message, stack: e.stack });
    res.status(500).json({ error: 'Webhook error' });
  }
};

// "План Б": сверка статуса конкретного платежа по API ЮKassa
exports.reconcilePayment = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const db = req.db;

    const p = await paymentService.getPaymentById(paymentId);

    // Обновляем локальный статус
    await new Promise((resolve, reject) =>
      db.run(
        `UPDATE Payments SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE payment_id = ?`,
        [p.status, paymentId],
        err => err ? reject(err) : resolve()
      )
    );

    // Если успех — продлеваем подписку (идемпотентность ок: предыдущая может быть expired)
    if (p.status === 'succeeded') {
      const userId = p.metadata?.user_id;
      if (userId) {
        await subscriptionService.extendSubscription({ userId, months: 1, db });
        logger.info('User subscription extended (via reconcile)', { userId, paymentId });
      } else {
        logger.warn('Reconcile succeeded but no user_id in metadata', { paymentId });
      }
    }

    res.json({ paymentId, status: p.status });
  } catch (e) {
    logger.error('Reconcile error', { error: e.message, stack: e.stack });
    res.status(500).json({ error: 'Reconcile failed' });
  }
};
