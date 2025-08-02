const logger = require('../logger');

exports.yookassaWebhook = async (req, res) => {
  try {
    logger.info('Получен webhook от ЮKassa', { body: req.body, headers: req.headers });

    const event = req.body.event;
    const object = req.body.object;

    logger.info('Webhook event/object', { event, object });

    if (event === 'payment.succeeded' && object && object.status === 'succeeded') {
      const paymentId = object.id;
      const amount = object.amount.value;
      const currency = object.amount.currency;
      const userId = object.metadata?.user_id;

      logger.info('Обработка payment.succeeded', { paymentId, amount, currency, userId, metadata: object.metadata });

      if (!userId) {
        logger.error('Webhook error: no user_id in metadata', { object });
        return res.status(400).json({ error: 'user_id not found in payment metadata' });
      }

      const db = req.app.get('db');

      // Лог платёж до апдейта
      const paymentRow = await new Promise((resolve, reject) =>
        db.get(`SELECT * FROM Payments WHERE payment_id = ?`, [paymentId], (err, row) => err ? reject(err) : resolve(row))
      );
      logger.info('Payment row before update', { paymentRow });

      // 1. Помечаем платёж как завершённый
      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Payments SET status = 'succeeded', updated_at = CURRENT_TIMESTAMP WHERE payment_id = ?`,
          [paymentId],
          err => err ? reject(err) : resolve()
        )
      );
      logger.info('Payment status updated to succeeded', { paymentId });

      // 2. Продлеваем подписку: если paid_until ещё активен, +1 мес. от paid_until, иначе +1 мес. от текущей даты
      const user = await new Promise((resolve, reject) =>
        db.get(`SELECT id, paid_until, is_paid FROM Users WHERE id = ?`, [userId], (err, row) => err ? reject(err) : resolve(row))
      );
      logger.info('User row before update', { user });

      let baseDate = new Date();
      if (user && user.paid_until && new Date(user.paid_until) > baseDate) {
        baseDate = new Date(user.paid_until);
      }
      const month = 30 * 24 * 60 * 60 * 1000;
      const newPaidUntil = new Date(baseDate.getTime() + month);

      await new Promise((resolve, reject) =>
        db.run(
          `UPDATE Users SET is_paid = 1, paid_until = ? WHERE id = ?`,
          [newPaidUntil.toISOString(), userId],
          err => err ? reject(err) : resolve()
        )
      );
      logger.info('User subscription extended', { userId, paid_until: newPaidUntil.toISOString() });

      // Лог после обновления
      const userAfter = await new Promise((resolve, reject) =>
        db.get(`SELECT id, paid_until, is_paid FROM Users WHERE id = ?`, [userId], (err, row) => err ? reject(err) : resolve(row))
      );
      logger.info('User row after update', { userAfter });

      return res.status(200).json({ received: true });
    }

    logger.warn('Webhook: Необработанное событие', { event });
    res.status(200).json({ received: true });
  } catch (e) {
    logger.error('Ошибка обработки webhook', { error: e.message, stack: e.stack });
    res.status(500).json({ error: 'Webhook error' });
  }
};
