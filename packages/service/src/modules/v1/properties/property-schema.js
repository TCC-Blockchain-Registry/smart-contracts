const yup = require('yup');

const propertySchema = yup.object({
  id: yup.string().optional(),
  owner: yup.string().required(),
  address: yup.string().required(),
  value: yup.number().required(),
  description: yup.string().optional(),
});

const transferSchema = yup.object({
  newOwner: yup.string().required(),
});

const mortgageSchema = yup.object({
  bank: yup.string().required(),
  amount: yup.number().required(),
  startDate: yup.date().required(),
  endDate: yup.date().optional(),
});

module.exports = {
  propertySchema,
  transferSchema,
  mortgageSchema,
}; 