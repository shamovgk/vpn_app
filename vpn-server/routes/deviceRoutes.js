const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');

router.post('/add-device', (req, res, next) => {
  req.db = req.app.get('db');
  deviceController.addDevice(req, res);
});
router.post('/remove-device', (req, res, next) => {
  req.db = req.app.get('db');
  deviceController.removeDevice(req, res);
});
router.get('/get-devices', (req, res, next) => {
  req.db = req.app.get('db');
  deviceController.getDevices(req, res);
});

module.exports = router;