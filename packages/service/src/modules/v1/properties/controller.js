const path = require('path');
const propertyRepository = require(path.resolve(__dirname, '../../../repository/property'));

class PropertyController {
  async registerProperty(req, res) {
    try {
      const {
        propertyId,
        registrationNumber,
        description,
        propertyAddress,
        area,
        propertyType,
      } = req.body;
      const ownerId = req.user.id;

      const property = await propertyRepository.create({
        propertyId,
        registrationNumber,
        ownerId,
        description,
        propertyAddress,
        area,
        propertyType,
      });

      return res.status(201).json(property);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async getProperty(req, res) {
    try {
      const { id } = req.params;
      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      return res.json(property);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async getAllProperties(req, res) {
    try {
      const properties = await propertyRepository.findAll();
      return res.json(properties);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async transferProperty(req, res) {
    try {
      const { id } = req.params;
      const {
        toId,
        reason,
        documentHash,
        notaryInfo,
        transferValue,
        paymentStatus,
      } = req.body;

      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      // if (property.ownerId !== req.user.id) {
      //   return res.status(403).json({ error: 'Only the owner can transfer the property' });
      // }

      if (property.hasMortgage) {
        return res.status(400).json({ error: 'Property has an active mortgage' });
      }

      if (property.status !== 'REGULAR') {
        return res.status(400).json({ error: 'Property status does not allow transfer' });
      }

      const transfer = await propertyRepository.createTransfer({
        propertyId: id,
        fromId: property.ownerId,
        toId,
        reason,
        documentHash,
        notaryInfo,
        transferValue,
        paymentStatus,
      });

      await propertyRepository.update(id, {
        ownerId: toId,
        lastTransferDate: new Date(),
      });

      return res.status(200).json(transfer);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async getTransferHistory(req, res) {
    try {
      const { id } = req.params;
      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      const transfers = await propertyRepository.getTransferHistory(id);
      return res.json(transfers);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async setPropertyStatus(req, res) {
    try {
      const { id } = req.params;
      const { status } = req.body;

      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      if (property.ownerId !== req.user.id) {
        return res.status(403).json({ error: 'Only the owner can change the property status' });
      }

      const updatedProperty = await propertyRepository.updateStatus(id, status);
      return res.json(updatedProperty);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async addMortgage(req, res) {
    try {
      const { id } = req.params;
      const { details } = req.body;

      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      if (property.ownerId !== req.user.id) {
        return res.status(403).json({ error: 'Only the owner can add a mortgage' });
      }

      if (property.hasMortgage) {
        return res.status(400).json({ error: 'Property already has a mortgage' });
      }

      const updatedProperty = await propertyRepository.updateMortgage(id, true, details);
      return res.json(updatedProperty);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async removeMortgage(req, res) {
    try {
      const { id } = req.params;

      const property = await propertyRepository.findById(id);

      if (!property) {
        return res.status(404).json({ error: 'Property not found' });
      }

      if (property.ownerId !== req.user.id) {
        return res.status(403).json({ error: 'Only the owner can remove a mortgage' });
      }

      if (!property.hasMortgage) {
        return res.status(400).json({ error: 'Property has no mortgage' });
      }

      const updatedProperty = await propertyRepository.updateMortgage(id, false, null);
      return res.json(updatedProperty);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async getPropertiesByUser(req, res) {
    try {
      const { userId } = req.params;
      const properties = await propertyRepository.findByOwnerId(userId);
      return res.json(properties);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }

  async getTransfersByUser(req, res) {
    try {
      const { userId } = req.params;
      const transfers = await propertyRepository.getTransfersByUserId(userId);
      return res.json(transfers);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }
}

module.exports = new PropertyController(); 