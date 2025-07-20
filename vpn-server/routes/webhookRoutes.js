const express = require('express');
const router = express.Router();
const webhookController = require('../controllers/webhookController');

// ЮKassa шлёт POST-запросы сюда. 
// Без проверки авторизации!
router.post('/yookassa', express.json({ type: '*/*' }), webhookController.yookassaWebhook);

module.exports = router;
