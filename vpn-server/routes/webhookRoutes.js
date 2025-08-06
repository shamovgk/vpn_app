const express = require('express');
const router = express.Router();
const webhookController = require('../controllers/webhookController');

router.post('/yookassa', express.json({ type: '*/*' }), webhookController.yookassaWebhook);

module.exports = router;
