const express = require('express');
const router = express.Router();
const userService = require('./user-service');
const { validateUser, validateLogin } = require('./user-validator');

// Criar usuário
router.post('/', validateUser, userService.createUser);
// Buscar todos usuários
router.get('/', userService.getAllUsers);
// Buscar usuário por id
router.get('/:userId', userService.getUserById);
// Deletar usuário
router.delete('/:userId', userService.deleteUser);
// Login
router.post('/login', validateLogin, userService.login);

module.exports = router; 