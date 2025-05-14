const express = require('express');
const path = require('path');
const router = express.Router();
const propertyController = require('./controller');
const authMiddleware = require(path.resolve(__dirname, '../../../middleware/auth'));

// Rota pública (sem autenticação)
router.get('/', propertyController.getAllProperties);

// Rotas protegidas (exigem autenticação JWT)
router.post('/', authMiddleware, propertyController.registerProperty);
router.get('/:id', authMiddleware, propertyController.getProperty);
router.post('/:id/transfer', authMiddleware, propertyController.transferProperty);
router.get('/:id/transfers', authMiddleware, propertyController.getTransferHistory);
router.put('/:id/status', authMiddleware, propertyController.setPropertyStatus);
router.post('/:id/mortgage', authMiddleware, propertyController.addMortgage);
router.delete('/:id/mortgage', authMiddleware, propertyController.removeMortgage);

// Buscar propriedades de um usuário
router.get('/user/:userId', authMiddleware, propertyController.getPropertiesByUser);
// Buscar transferências de um usuário
router.get('/user/:userId/transfers', authMiddleware, propertyController.getTransfersByUser);

module.exports = router; 