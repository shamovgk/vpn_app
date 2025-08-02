const Joi = require('joi');

// Логин админа
const adminLoginSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
});

// Обновление пользователя админом
const adminUpdateUserSchema = Joi.object({
  is_paid: Joi.boolean().required(),
  trial_end_date: Joi.date().iso().optional().allow(null, ''),
  subscription_level: Joi.number().integer().optional(),
});

module.exports = {
  adminLoginSchema,
  adminUpdateUserSchema,
};
