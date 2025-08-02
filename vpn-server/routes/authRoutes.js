const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const validate = require('../middlewares/validate');
const {
  registerSchema,
  loginSchema,
  verifyEmailSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  cancelRegistrationSchema,
} = require('../schemas/authSchemas');

const withDb = require('../middlewares/withDb');
router.use(withDb);

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', validate(loginSchema), authController.login);
router.post('/verify-email', validate(verifyEmailSchema), authController.verifyEmail);
router.post('/forgot-password', validate(forgotPasswordSchema), authController.forgotPassword);
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);
router.get('/validate-token', authController.validateToken);
router.post('/logout', authController.logout);
router.get('/subscription-status', authController.subscriptionStatus);

module.exports = router;
