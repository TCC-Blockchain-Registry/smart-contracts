const express = require('express');
const router = express.Router();
const userService = require('./user-service');
const { validateUser, validateLogin } = require('./user-validator');
const authMiddleware = require('../../../middleware/auth');

// Rotas públicas
router.post('/', validateUser, userService.createUser);
router.post('/login', validateLogin, userService.login);

// Rotas protegidas (exigem autenticação JWT)
router.get('/', authMiddleware, userService.getAllUsers);
router.get('/:userId', authMiddleware, userService.getUserById);
router.delete('/:userId', authMiddleware, userService.deleteUser);

module.exports = router; 