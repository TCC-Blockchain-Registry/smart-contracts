const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class PropertyRepository {
  async create(data) {
    return prisma.property.create({
      data: {
        ...data,
        status: 'REGULAR',
        lastTransferDate: new Date(),
      },
      include: {
        owner: true,
      },
    });
  }

  async findById(id) {
    return prisma.property.findUnique({
      where: { id },
      include: {
        owner: true,
        transfers: {
          include: {
            from: true,
            to: true,
          },
        },
      },
    });
  }

  async findByPropertyId(propertyId) {
    return prisma.property.findUnique({
      where: { propertyId },
      include: {
        owner: true,
        transfers: {
          include: {
            from: true,
            to: true,
          },
        },
      },
    });
  }

  async findAll() {
    return prisma.property.findMany({
      include: {
        owner: true,
      },
    });
  }

  async update(id, data) {
    return prisma.property.update({
      where: { id },
      data,
      include: {
        owner: true,
      },
    });
  }

  async createTransfer(data) {
    return prisma.transfer.create({
      data,
      include: {
        property: true,
        from: true,
        to: true,
      },
    });
  }

  async getTransferHistory(propertyId) {
    return prisma.transfer.findMany({
      where: { propertyId },
      include: {
        from: true,
        to: true,
      },
      orderBy: {
        timestamp: 'desc',
      },
    });
  }

  async updateStatus(id, status) {
    return prisma.property.update({
      where: { id },
      data: { status },
      include: {
        owner: true,
      },
    });
  }

  async updateMortgage(id, hasMortgage, mortgageDetails) {
    return prisma.property.update({
      where: { id },
      data: {
        hasMortgage,
        mortgageDetails,
      },
      include: {
        owner: true,
      },
    });
  }

  async findByOwnerId(ownerId) {
    return prisma.property.findMany({
      where: { ownerId },
      include: {
        owner: true,
      },
    });
  }

  async getTransfersByUserId(userId) {
    return prisma.transfer.findMany({
      where: {
        OR: [
          { fromId: userId },
          { toId: userId }
        ]
      },
      include: {
        property: true,
        from: true,
        to: true,
      },
      orderBy: {
        timestamp: 'desc',
      },
    });
  }
}

module.exports = new PropertyRepository(); 