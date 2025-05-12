const fabricNetwork = require('../../../fabric/fabric-network');
const { logger } = require('../../../utils/logger');

const registerProperty = async (req, res) => {
  try {
    const propertyData = req.body;
    const result = await fabricNetwork.registerProperty(propertyData);
    res.status(201).json(result);
  } catch (error) {
    logger.error(`Erro ao registrar propriedade: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const transferProperty = async (req, res) => {
  try {
    const { propertyId } = req.params;
    const { newOwner } = req.body;
    const result = await fabricNetwork.transferProperty(propertyId, newOwner);
    res.json(result);
  } catch (error) {
    logger.error(`Erro ao transferir propriedade: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const getProperty = async (req, res) => {
  try {
    const { propertyId } = req.params;
    const result = await fabricNetwork.getProperty(propertyId);
    res.json(result);
  } catch (error) {
    logger.error(`Erro ao buscar propriedade: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const getAllProperties = async (req, res) => {
  try {
    const result = await fabricNetwork.getAllProperties();
    res.json(result);
  } catch (error) {
    logger.error(`Erro ao buscar todas as propriedades: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const registerMortgage = async (req, res) => {
  try {
    const { propertyId } = req.params;
    const mortgageData = req.body;
    const result = await fabricNetwork.registerMortgage(propertyId, mortgageData);
    res.status(201).json(result);
  } catch (error) {
    logger.error(`Erro ao registrar hipoteca: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

const removeMortgage = async (req, res) => {
  try {
    const { propertyId } = req.params;
    const result = await fabricNetwork.removeMortgage(propertyId);
    res.json(result);
  } catch (error) {
    logger.error(`Erro ao remover hipoteca: ${error}`);
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  registerProperty,
  transferProperty,
  getProperty,
  getAllProperties,
  registerMortgage,
  removeMortgage,
}; 