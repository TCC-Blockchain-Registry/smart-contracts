const hre = require("hardhat");

async function main() {
  console.log("Iniciando deploy do contrato PropertyRegistry...");

  // Obtém o contrato
  const PropertyRegistry = await hre.ethers.getContractFactory("PropertyRegistry");
  
  // Faz o deploy
  const propertyRegistry = await PropertyRegistry.deploy();
  await propertyRegistry.deployed();

  console.log("PropertyRegistry deployed to:", propertyRegistry.address);
  
  // Verifica se o deploy foi bem sucedido
  const code = await hre.ethers.provider.getCode(propertyRegistry.address);
  if (code === '0x') {
    throw new Error('Falha no deploy: contrato não encontrado no endereço especificado');
  }
  
  console.log("Deploy verificado com sucesso!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 