const yup = require('yup');

const userSchema = yup.object({
  id: yup.string().optional(),
  username: yup.string().required(),
  password: yup.string().min(6).required(),
  email: yup.string().email().required(),
});

const loginSchema = yup.object({
  username: yup.string().required(),
  password: yup.string().required(),
});

module.exports = {
  userSchema,
  loginSchema,
}; 