// controllers/subscriptionController.js
const subscriptionService = require('../services/subscriptionService');
const deviceService = require('../services/deviceService');

exports.getStatus = async (req, res) => {
  const userId = req.user.id;
  const db = req.db;

  // Передаём deviceService для расчёта устройств и лимитов
  const subStatus = await subscriptionService.getStatus({ userId, db, deviceService });
  res.json(subStatus);
};
