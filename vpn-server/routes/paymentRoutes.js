const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const validate = require('../middlewares/validate');
const { payYookassaSchema } = require('../schemas/paymentSchemas');

const withDb = require('../middlewares/withDb');
router.use(withDb);

router.post('/pay-yookassa', validate(payYookassaSchema), paymentController.payYookassa);
// get-vpn-config можно оставить без валидации, если нет тела
router.get('/get-vpn-config', paymentController.getVpnConfig);

module.exports = router;
