const { propertySchema, transferSchema, mortgageSchema } = require('./property-schema');

function validate(schema) {
  return async (req, res, next) => {
    try {
      await schema.validate(req.body, { abortEarly: false });
      next();
    } catch (error) {
      return res.status(400).json({ error: error.errors.join(', ') });
    }
  };
}

const validateProperty = validate(propertySchema);
const validateTransfer = validate(transferSchema);
const validateMortgage = validate(mortgageSchema);

module.exports = {
  validateProperty,
  validateTransfer,
  validateMortgage,
}; 