// schemas/adminSchemas.js
const Joi = require('joi');

const adminLoginSchema = Joi.object({
  username: Joi.string().required(),
  password: Joi.string().required(),
  next: Joi.string().allow('', null).optional()
});

const adminUpdateUserSchema = Joi.object({
  is_paid: Joi.boolean().optional(),
  paid_until: Joi.date().iso().allow(null, '').optional(),
  trial_until: Joi.date().iso().allow(null, '').optional(),
});

module.exports = {
  adminLoginSchema,
  adminUpdateUserSchema,
};
