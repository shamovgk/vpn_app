// middlewares/validate.js
module.exports = (schema) => (req, res, next) => {
  const { value, error } = schema.validate(req.body, {
    abortEarly: false,
    allowUnknown: true,
    stripUnknown: true,
  });
  if (error) {
    return res.status(400).json({ error: error.details.map(d => d.message).join(', ') });
  }
  req.body = value;
  next();
};
