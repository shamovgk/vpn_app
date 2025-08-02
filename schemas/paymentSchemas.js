const Joi = require('joi');

const payYookassaSchema = Joi.object({
  amount: Joi.number().min(1).required(),
  method: Joi.string().valid('bank_card', 'sbp', 'sberbank').required(),
});

module.exports = {
  payYookassaSchema,
};
