const { logger } = require('../../../utils/logger');
const bcrypt = require('bcryptjs');
const userRepository = require('../../../repository/user');
const jwt = require('jsonwebtoken');

const createUser = async (req, res) => {
  try {
    const { username, password, email } = req.body;
    const existing = await userRepository.findByUsername(username) || await userRepository.findByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'Usuário ou e-mail já existe' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await userRepository.createUser({ username, password: hashedPassword, email });
    logger.info(`Usuário criado: ${username}`);
    res.status(201).json({ id: user.id, username: user.username, email: user.email });
  } catch (error) {
    logger.error(`Erro ao criar usuário: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const getAllUsers = async (req, res) => {
  const users = await userRepository.findAll();
  res.json(users);
};

const getUserById = async (req, res) => {
  const { userId } = req.params;
  const user = await userRepository.findById(userId);
  if (!user) return res.status(404).json({ error: 'Usuário não encontrado' });
  res.json(user);
};

const deleteUser = async (req, res) => {
  const { userId } = req.params;
  try {
    await userRepository.deleteById(userId);
    logger.info(`Usuário removido: ${userId}`);
    res.status(204).send();
  } catch {
    res.status(404).json({ error: 'Usuário não encontrado' });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await userRepository.findByEmail(email);
    if (!user) return res.status(401).json({ error: 'Usuário ou senha inválidos' });
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: 'Usuário ou senha inválidos' });
    const token = jwt.sign({ id: user.id, username: user.username }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ id: user.id, username: user.username, email: user.email, token });
  } catch (error) {
    logger.error(`Erro no login: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createUser,
  getAllUsers,
  getUserById,
  deleteUser,
  login,
}; 