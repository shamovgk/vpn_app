const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const validate = require('../middlewares/validate');
const { payYookassaSchema } = require('../schemas/paymentSchemas');

const withDb = require('../middlewares/withDb');
router.use(withDb);

router.post('/pay-yookassa', validate(payYookassaSchema), paymentController.payYookassa);

module.exports = router;
