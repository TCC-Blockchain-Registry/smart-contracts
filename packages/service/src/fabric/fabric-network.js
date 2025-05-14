const { Gateway, Wallets } = require('fabric-network');
const path = require('path');
const fs = require('fs');

const connectionProfilePath = require.resolve('@hardhat/config/connection-profile.json');
const walletPath = require('@hardhat/wallet');
const channelName = 'mychannel';
const chaincodeName = 'PropertyRegistry';

async function getContract(userId = 'appUser') {
  const ccp = JSON.parse(fs.readFileSync(connectionProfilePath, 'utf8'));
  const wallet = await Wallets.newFileSystemWallet(walletPath);
  const gateway = new Gateway();
  await gateway.connect(ccp, {
    wallet,
    identity: userId,
    discovery: { enabled: false, asLocalhost: true }
  });
  const network = await gateway.getNetwork(channelName);
  const contract = network.getContract(chaincodeName);
  return { gateway, contract };
}

const registerProperty = async (property) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.submitTransaction(
      'registerProperty',
      property.propertyId,
      property.registrationNumber,
      property.owner,
      property.description,
      property.propertyAddress,
      property.area.toString(),
      property.propertyType
    );
    return { success: true, tx: result.toString() };
  } finally {
    gateway.disconnect();
  }
};

const transferProperty = async (data) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.submitTransaction(
      'transferProperty',
      data.propertyId,
      data.newOwner,
      data.reason,
      data.documentHash,
      data.notaryInfo,
      data.transferValue.toString(),
      data.paymentStatus
    );
    return { success: true, tx: result.toString() };
  } finally {
    gateway.disconnect();
  }
};

const getProperty = async (propertyId) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.evaluateTransaction('getProperty', propertyId);
    // O retorno é um tuple, pode ser necessário ajustar o parse conforme o retorno do contrato
    return result.toString();
  } finally {
    gateway.disconnect();
  }
};

const getTransferHistory = async (propertyId) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.evaluateTransaction('getTransferHistory', propertyId);
    return JSON.parse(result.toString());
  } finally {
    gateway.disconnect();
  }
};

const setPropertyStatus = async (propertyId, status) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.submitTransaction('setPropertyStatus', propertyId, status);
    return { success: true, tx: result.toString() };
  } finally {
    gateway.disconnect();
  }
};

const addMortgage = async (propertyId, details) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.submitTransaction('addMortgage', propertyId, details);
    return { success: true, tx: result.toString() };
  } finally {
    gateway.disconnect();
  }
};

const removeMortgage = async (propertyId) => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.submitTransaction('removeMortgage', propertyId);
    return { success: true, tx: result.toString() };
  } finally {
    gateway.disconnect();
  }
};

const getAllProperties = async () => {
  const { gateway, contract } = await getContract();
  try {
    const result = await contract.evaluateTransaction('getAllProperties');
    return JSON.parse(result.toString());
  } finally {
    gateway.disconnect();
  }
};

module.exports = {
  registerProperty,
  transferProperty,
  getProperty,
  getTransferHistory,
  setPropertyStatus,
  addMortgage,
  removeMortgage,
  getAllProperties,
}; 