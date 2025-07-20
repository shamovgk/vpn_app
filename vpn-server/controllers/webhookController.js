const logger = require('../logger');

/**
 * Обработчик webhook от ЮKassa.
 * ЮKassa шлёт POST-запрос с событием (например, payment.succeeded).
 */
exports.yookassaWebhook = async (req, res) => {
  try {
    // Логируем всё, что пришло (можно убрать body из лога, если в проде)
    logger.info('Получен webhook от ЮKassa', { body: req.body, headers: req.headers });

    // Для безопасности можно добавить проверку подписи, если ЮKassa это поддерживает

    const event = req.body.event;
    const object = req.body.object;

    // Обработка успешного платежа
    if (event === 'payment.succeeded' && object && object.status === 'succeeded') {
      const paymentId = object.id;
      const amount = object.amount.value;
      const currency = object.amount.currency;
      // Тут надо определить, к какому пользователю относится платёж. Например:
      // const userId = object.metadata?.user_id;

      logger.info('Обработка payment.succeeded', { paymentId, amount, currency });
      
      // --- Логика поиска пользователя по paymentId или metadata ---
      // Например, если вы передавали user_id в metadata платежа:
      // if (userId) { ... апдейт is_paid и т.д. }

      // Здесь пример без привязки к юзеру:
      // await updateUserAsPaid(userId, ...);

      // Всегда возвращаем 200, чтобы ЮKassa не дублировала webhook!
      return res.status(200).json({ received: true });
    }

    // Можно добавить другие события, если надо (например, payment.canceled)
    logger.warn('Webhook: Необработанное событие', { event });
    res.status(200).json({ received: true });
  } catch (e) {
    logger.error('Ошибка обработки webhook', { error: e.message });
    res.status(500).json({ error: 'Webhook error' });
  }
};
