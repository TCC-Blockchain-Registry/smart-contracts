// Este arquivo foi renomeado de user.repository.js para user.js para seguir o padrão desejado.
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const createUser = (data) => prisma.user.create({ data });
const findByUsername = (username) => prisma.user.findUnique({ where: { username } });
const findByEmail = (email) => prisma.user.findUnique({ where: { email } });
const findById = (id) => prisma.user.findUnique({ where: { id } });
const findAll = () => prisma.user.findMany({ select: { id: true, username: true, email: true, createdAt: true } });
const deleteById = (id) => prisma.user.delete({ where: { id } });

module.exports = {
  createUser,
  findByUsername,
  findByEmail,
  findById,
  findAll,
  deleteById,
}; 