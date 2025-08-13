// services/subscriptionService.js
const logger = require('../utils/logger.js');

async function getActiveSubscription({ userId, db }) {
  return await new Promise((resolve, reject) =>
    db.get(
      `SELECT * FROM Subscriptions WHERE user_id = ? AND status = 'active' AND end_date > ? ORDER BY end_date DESC LIMIT 1`,
      [userId, new Date().toISOString()],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );
}

async function extendSubscription({ userId, months = 1, db }) {
  const now = new Date();
  const sub = await getActiveSubscription({ userId, db });

  let baseDate = now;
  if (sub && new Date(sub.end_date) > now) {
    baseDate = new Date(sub.end_date);
  }

  const monthMs = 30 * 24 * 60 * 60 * 1000;
  const newEndDate = new Date(baseDate.getTime() + months * monthMs);

  if (sub) {
    await new Promise((resolve, reject) =>
      db.run(
        `UPDATE Subscriptions SET status = 'expired', updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
        [sub.id],
        err => err ? reject(err) : resolve()
      )
    );
  }

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Subscriptions (user_id, type, status, start_date, end_date)
       VALUES (?, 'paid', 'active', ?, ?)`,
      [userId, baseDate.toISOString(), newEndDate.toISOString()],
      err => err ? reject(err) : resolve()
    )
  );

  await new Promise((resolve, reject) =>
    db.run(
      `UPDATE Users SET is_paid = 1, paid_until = ? WHERE id = ?`,
      [newEndDate.toISOString(), userId],
      err => err ? reject(err) : resolve()
    )
  );

  logger.info('Subscription extended', { userId, newEndDate: newEndDate.toISOString() });
  return { userId, end_date: newEndDate.toISOString() };
}

async function startTrial({ userId, days = 3, db }) {
  const now = new Date();
  // Проверяем, был ли триал
  const existingTrial = await new Promise((resolve, reject) =>
    db.get(
      `SELECT * FROM Subscriptions WHERE user_id = ? AND type = 'trial'`,
      [userId],
      (err, row) => err ? reject(err) : resolve(row)
    )
  );
  if (existingTrial) {
    throw new Error('Триал уже был активирован ранее');
  }
  const endDate = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

  await new Promise((resolve, reject) =>
    db.run(
      `INSERT INTO Subscriptions (user_id, type, status, start_date, end_date)
       VALUES (?, 'trial', 'active', ?, ?)`,
      [userId, now.toISOString(), endDate.toISOString()],
      err => err ? reject(err) : resolve()
    )
  );

  logger.info('Trial started', { userId, endDate: endDate.toISOString() });
  return { userId, end_date: endDate.toISOString() };
}

async function getStatus({ userId, db, deviceService }) {
  const sub = await getActiveSubscription({ userId, db });
  const now = new Date();

  if (!sub) {
    return { is_trial: false, is_paid: false, can_use: false };
  }

  const isTrial = sub.type === 'trial' && new Date(sub.end_date) > now;
  const isPaid = sub.type === 'paid' && new Date(sub.end_date) > now;
  const can_use = isTrial || isPaid;

  const device_count = await deviceService.getUserDevicesCount({ userId, db });
  const max_devices = await deviceService.getUserDeviceLimit();

  return {
    is_trial: isTrial,
    is_paid: isPaid,
    can_use,
    start_date: sub.start_date,
    end_date: sub.end_date,
    device_count,
    max_devices,
    status: sub.status,
  };
}

module.exports = {
  extendSubscription,
  startTrial,
  getStatus,
  getActiveSubscription,
};
