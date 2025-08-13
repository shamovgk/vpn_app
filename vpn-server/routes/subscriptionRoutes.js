const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscriptionController');
const auth = require('../middlewares/auth');
const withDb = require('../middlewares/withDb');
router.use(withDb);
router.use(auth);

router.get('/status', subscriptionController.getStatus);

module.exports = router;
