const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const validate = require('../middlewares/validate');
const { payYookassaSchema } = require('../schemas/paymentSchemas');
const withDb = require('../middlewares/withDb');
const auth = require('../middlewares/auth');

router.use(withDb);
router.use(auth);

router.post('/', validate(payYookassaSchema), paymentController.payYookassa);

module.exports = router;
