const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');
const validate = require('../middlewares/validate');
const { addDeviceSchema, removeDeviceSchema } = require('../schemas/deviceSchemas');

const withDb = require('../middlewares/withDb');
router.use(withDb);

const auth = require('../middlewares/auth');
router.use(auth);

router.post('/add-device', validate(addDeviceSchema), deviceController.addDevice);
router.post('/remove-device', validate(removeDeviceSchema), deviceController.removeDevice);
router.get('/get-devices', deviceController.getDevices);
router.post('/update-last-seen', deviceController.updateLastSeen);

module.exports = router;
