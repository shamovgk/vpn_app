const Joi = require('joi');

// Регистрация
const registerSchema = Joi.object({
  username: Joi.string().min(3).max(32).alphanum().required(),
  password: Joi.string().min(6).max(100).required(),
  email: Joi.string().email().required(),
});

// Логин
const loginSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
  device_token: Joi.string().optional(),
  device_model: Joi.string().optional(),
  device_os: Joi.string().optional(),
});

// Верификация email
const verifyEmailSchema = Joi.object({
  username: Joi.string().required(),
  email: Joi.string().email().required(),
  verificationCode: Joi.string().length(6).required(),
});

// Проверка токена (query)
const validateTokenSchema = Joi.object({
  token: Joi.string().required(),
});

// Восстановление пароля
const forgotPasswordSchema = Joi.object({
  username: Joi.string().required(),
});

// Сброс пароля
const resetPasswordSchema = Joi.object({
  username: Joi.string().required(),
  resetCode: Joi.string().required(),
  newPassword: Joi.string().min(6).max(100).required(),
});

// Отмена регистрации (если понадобится)
const cancelRegistrationSchema = Joi.object({
  username: Joi.string().required(),
  email: Joi.string().email().required(),
});

module.exports = {
  registerSchema,
  loginSchema,
  verifyEmailSchema,
  validateTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  cancelRegistrationSchema,
};
