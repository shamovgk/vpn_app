const Joi = require('joi');

// Добавление устройства
const addDeviceSchema = Joi.object({
  user_id: Joi.number().integer().required(),
  device_token: Joi.string().required(),
  device_model: Joi.string().optional(),
  device_os: Joi.string().optional(),
});

// Удаление устройства
const removeDeviceSchema = Joi.object({
  user_id: Joi.number().integer().required(),
  device_token: Joi.string().required(),
  trigger_logout: Joi.boolean().optional(),
});

module.exports = {
  addDeviceSchema,
  removeDeviceSchema,
};
