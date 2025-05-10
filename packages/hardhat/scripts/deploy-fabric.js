const { Wallets, Gateway } = require('fabric-network');
const fs = require('fs');
const path = require('path');

async function main() {
  try {
    // Carrega o perfil de conexão
    const connectionProfile = JSON.parse(fs.readFileSync(path.join(__dirname, '../config/connection-profile.json'), 'utf8'));

    // Cria uma nova wallet
    const wallet = await Wallets.newFileSystemWallet(path.join(__dirname, '../wallet'));

    // Verifica se a identidade existe
    const identity = await wallet.get('appUser');
    if (!identity) {
      console.log('Identidade "appUser" não encontrada na wallet. Execute primeiro o script enroll-admin.js');
      return;
    }

    // Conecta ao gateway
    const gateway = new Gateway();
    await gateway.connect(connectionProfile, {
      wallet,
      identity: 'appUser',
      discovery: { enabled: true, asLocalhost: true }
    });

    // Obtém a rede
    const network = await gateway.getNetwork('mychannel');

    // Obtém o contrato
    const contract = network.getContract('title-transfer');

    // Compila os contratos Solidity
    console.log('Compilando contratos...');
    await hre.run('compile');

    // Obtém o bytecode do contrato compilado
    const contractPath = path.join(__dirname, '../artifacts/contracts/TitleTransfer.sol/TitleTransfer.json');
    const contractArtifact = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
    const bytecode = contractArtifact.bytecode;

    // Instala o chaincode
    console.log('Instalando chaincode...');
    await contract.submitTransaction('install', bytecode);

    // Instancia o chaincode
    console.log('Instanciando chaincode...');
    await contract.submitTransaction('instantiate', '1.0', JSON.stringify([]));

    console.log('Deploy concluído com sucesso!');

    // Desconecta do gateway
    gateway.disconnect();

  } catch (error) {
    console.error('Erro durante o deploy:', error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 