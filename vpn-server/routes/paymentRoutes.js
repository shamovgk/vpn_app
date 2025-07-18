const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const validate = require('../middlewares/validate');
const { payYookassaSchema } = require('../schemas/paymentSchemas');
const withDb = require('../middlewares/withDb');
router.use(withDb);

// Универсальный endpoint для всех типов оплаты (карта, SBP)
router.post('/', validate(payYookassaSchema), paymentController.payYookassa);

module.exports = router;
