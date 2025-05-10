#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando configuração da rede Hyperledger Fabric...${NC}"

# Configurar FABRIC_CFG_PATH
export FABRIC_CFG_PATH=${PWD}/config

# Verificar se as ferramentas do Fabric estão instaladas
if ! command -v cryptogen &> /dev/null; then
    echo -e "${YELLOW}Instalando ferramentas do Hyperledger Fabric...${NC}"
    
    # Criar diretório para as ferramentas
    mkdir -p fabric-tools
    cd fabric-tools
    
    # Baixar e extrair as ferramentas
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.12 1.5.5
    
    # Configurar PATH
    export PATH=${PWD}/bin:$PATH
    
    # Voltar para o diretório original
    cd ..
fi

# Verificar se as ferramentas foram instaladas corretamente
if ! command -v cryptogen &> /dev/null; then
    echo -e "${RED}Erro: Ferramentas do Fabric não foram instaladas corretamente${NC}"
    echo -e "${YELLOW}Tentando instalar manualmente...${NC}"
    
    # Tentar instalar manualmente
    mkdir -p fabric-tools
    cd fabric-tools
    
    # Baixar os binários diretamente
    curl -sSL https://github.com/hyperledger/fabric/releases/download/v2.2.12/hyperledger-fabric-linux-amd64-2.2.12.tar.gz | tar xz
    
    # Configurar PATH
    export PATH=${PWD}/bin:$PATH
    
    # Voltar para o diretório original
    cd ..
fi

# Verificar novamente se as ferramentas estão disponíveis
if ! command -v cryptogen &> /dev/null; then
    echo -e "${RED}Erro: Não foi possível instalar as ferramentas do Fabric${NC}"
    echo -e "${YELLOW}Por favor, instale manualmente seguindo as instruções em:${NC}"
    echo "https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
    exit 1
fi

# Verificar se os arquivos de configuração existem
if [ ! -f "${FABRIC_CFG_PATH}/configtx.yaml" ]; then
    echo -e "${RED}Erro: Arquivo configtx.yaml não encontrado em ${FABRIC_CFG_PATH}${NC}"
    exit 1
fi

if [ ! -f "${FABRIC_CFG_PATH}/crypto-config.yaml" ]; then
    echo -e "${RED}Erro: Arquivo crypto-config.yaml não encontrado em ${FABRIC_CFG_PATH}${NC}"
    exit 1
fi

# Limpar diretórios existentes
echo -e "${YELLOW}Limpando diretórios existentes...${NC}"
rm -rf crypto-config
rm -rf config/crypto-config

# Criar diretório para certificados
mkdir -p crypto-config

# Gerar certificados
echo -e "${YELLOW}Gerando certificados...${NC}"
cryptogen generate --config=${FABRIC_CFG_PATH}/crypto-config.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar certificados${NC}"
    exit 1
fi

# Gerar bloco genesis
echo -e "${YELLOW}Gerando bloco genesis...${NC}"
configtxgen -profile OneOrgOrdererGenesis -channelID system-channel -outputBlock ${FABRIC_CFG_PATH}/genesis.block
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar bloco genesis${NC}"
    exit 1
fi

# Gerar configuração do canal
echo -e "${YELLOW}Gerando configuração do canal...${NC}"
configtxgen -profile OneOrgChannel -outputCreateChannelTx ${FABRIC_CFG_PATH}/channel.tx -channelID mychannel
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar configuração do canal${NC}"
    exit 1
fi

# Parar containers existentes
echo -e "${YELLOW}Parando containers existentes...${NC}"
docker-compose -f ${FABRIC_CFG_PATH}/docker-compose.yaml down

# Iniciar containers
echo -e "${YELLOW}Iniciando containers...${NC}"
docker-compose -f ${FABRIC_CFG_PATH}/docker-compose.yaml up -d
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao iniciar containers${NC}"
    exit 1
fi

# Aguardar containers iniciarem
echo -e "${YELLOW}Aguardando containers iniciarem...${NC}"
sleep 10

# Instalar dependências
echo -e "${YELLOW}Instalando dependências...${NC}"
npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao instalar dependências${NC}"
    exit 1
fi

# Compilar contrato
echo -e "${YELLOW}Compilando contrato...${NC}"
npx hardhat compile
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao compilar contrato${NC}"
    exit 1
fi

# Registrar usuários
echo -e "${YELLOW}Registrando usuários...${NC}"
node scripts/enroll-admin.js
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao registrar usuários${NC}"
    exit 1
fi

echo -e "${GREEN}Rede configurada com sucesso!${NC}"
echo -e "${YELLOW}Para fazer deploy do contrato, execute:${NC}"
echo "npx hardhat run scripts/deploy.js --network fabric"
echo -e "${YELLOW}Para executar os testes, execute:${NC}"
echo "npx hardhat test" 