const Joi = require('joi');

// Платеж через YooKassa
const payYookassaSchema = Joi.object({
  token: Joi.string().required(),
  amount: Joi.number().min(1).required(),
  method: Joi.string().valid('bank_card', 'sbp').optional(),
});

module.exports = {
  payYookassaSchema,
};
