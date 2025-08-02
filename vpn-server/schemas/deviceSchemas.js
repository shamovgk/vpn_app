const Joi = require('joi');

const addDeviceSchema = Joi.object({
  device_token: Joi.string().required(),
  device_model: Joi.string().optional(),
  device_os: Joi.string().optional(),
});
const removeDeviceSchema = Joi.object({
  device_token: Joi.string().required(),
  trigger_logout: Joi.boolean().optional(),
});

module.exports = {
  addDeviceSchema,
  removeDeviceSchema,
};
