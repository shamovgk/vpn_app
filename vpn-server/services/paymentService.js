const YooKassa = require('yookassa');
const { yooKassa, payment } = require('../config/config');

const yooKassaInstance = new YooKassa({
  shopId: yooKassa.shopId,
  secretKey: yooKassa.secretKey,
});

async function createPayment({ amount, method, userId }) {
  if (!payment.allowedMethods.includes(method)) {
    throw new Error('Unsupported payment method');
  }
  return yooKassaInstance.createPayment({
    amount: { value: amount, currency: payment.currency },
    payment_method_data: { type: method },
    confirmation: { type: 'redirect', return_url: payment.returnUrl },
    capture: true,
    description: payment.description,
    metadata: { user_id: userId },
  });
}

module.exports = { createPayment };
