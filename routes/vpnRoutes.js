const express = require('express');
const router = express.Router();
const vpnController = require('../controllers/vpnController');
const withDb = require('../middlewares/withDb');

router.use(withDb);

router.get('/get-vpn-config', vpnController.getVpnConfig);

module.exports = router;
