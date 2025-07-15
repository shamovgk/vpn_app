const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/register', (req, res, next) => {
  req.db = req.app.get('db');
  authController.register(req, res);
});
router.post('/verify-email', (req, res, next) => {
  req.db = req.app.get('db');
  authController.verifyEmail(req, res);
});
router.post('/login', (req, res, next) => {
  req.db = req.app.get('db');
  authController.login(req, res);
});
router.get('/validate-token', (req, res, next) => {
  req.db = req.app.get('db');
  authController.validateToken(req, res);
});
router.post('/logout', (req, res, next) => {
  req.db = req.app.get('db');
  authController.logout(req, res);
});
router.post('/forgot-password', (req, res, next) => {
  req.db = req.app.get('db');
  authController.forgotPassword(req, res);
});
router.post('/reset-password', (req, res, next) => {
  req.db = req.app.get('db');
  authController.resetPassword(req, res);
});
router.post('/cancel-registration', (req, res, next) => {
  req.db = req.app.get('db');
  authController.cancelRegistration(req, res);
});

module.exports = router;