const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');

router.post('/pay-yookassa', (req, res, next) => {
  req.db = req.app.get('db');
  paymentController.payYookassa(req, res);
});
router.get('/get-vpn-config', (req, res, next) => {
  req.db = req.app.get('db');
  paymentController.getVpnConfig(req, res);
});

module.exports = router;