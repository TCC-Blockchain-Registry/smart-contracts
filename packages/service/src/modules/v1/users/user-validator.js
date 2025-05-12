const { userSchema, loginSchema } = require('./user-schema');

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

const validateUser = validate(userSchema);
const validateLogin = validate(loginSchema);

module.exports = {
  validateUser,
  validateLogin,
}; 