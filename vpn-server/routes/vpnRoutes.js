const express = require('express');
const router = express.Router();
const vpnController = require('../controllers/vpnController');
const withDb = require('../middlewares/withDb');
const auth = require('../middlewares/auth');

router.use(withDb);
router.use(auth);

router.get('/get-vpn-config', vpnController.getVpnConfig);

module.exports = router;
