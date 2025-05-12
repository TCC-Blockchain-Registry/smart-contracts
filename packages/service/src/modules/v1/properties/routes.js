const express = require('express');
const router = express.Router();
const propertyService = require('./property-service');
const { validateProperty, validateTransfer, validateMortgage } = require('./property-validator');

// Registrar nova propriedade
router.post('/', validateProperty, propertyService.registerProperty);
// Listar todas as propriedades
router.get('/', propertyService.getAllProperties);
// Buscar propriedade específica
router.get('/:propertyId', propertyService.getProperty);
// Transferir propriedade
router.post('/:propertyId/transfer', validateTransfer, propertyService.transferProperty);
// Registrar hipoteca
router.post('/:propertyId/mortgage', validateMortgage, propertyService.registerMortgage);
// Remover hipoteca
router.delete('/:propertyId/mortgage', propertyService.removeMortgage);

module.exports = router; 