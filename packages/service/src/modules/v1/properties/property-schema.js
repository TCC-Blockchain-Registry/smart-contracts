const yup = require('yup');

const propertySchema = yup.object({
  propertyId: yup.string().required(),
  registrationNumber: yup.string().required(),
  owner: yup.string().required(), // endereço Ethereum
  description: yup.string().required(),
  propertyAddress: yup.string().required(),
  area: yup.number().required(),
  propertyType: yup.string().required(),
});

const transferSchema = yup.object({
  propertyId: yup.string().required(),
  newOwner: yup.string().required(),
  reason: yup.string().required(),
  documentHash: yup.string().required(),
  notaryInfo: yup.string().required(),
  transferValue: yup.number().required(),
  paymentStatus: yup.string().required(),
});

const mortgageSchema = yup.object({
  propertyId: yup.string().required(),
  details: yup.string().required(),
});

module.exports = {
  propertySchema,
  transferSchema,
  mortgageSchema,
}; 