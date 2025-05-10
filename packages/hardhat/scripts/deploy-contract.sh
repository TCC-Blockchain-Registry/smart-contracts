#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configurações
CHANNEL_NAME="mychannel"
CONTRACT_NAME="PropertyRegistry"
CONTRACT_VERSION="1.0"
CONTRACT_PATH="contracts/PropertyRegistry.sol"
PACKAGE_ID="PropertyRegistry_1.0"

# Verificar se os containers estão rodando
echo -e "${YELLOW}Verificando containers...${NC}"
if ! docker ps | grep -q "peer0.org1.example.com"; then
    echo -e "${RED}Erro: Container do peer não está rodando${NC}"
    echo -e "${YELLOW}Execute o script start-network.sh primeiro${NC}"
    exit 1
fi

if ! docker ps | grep -q "orderer.example.com"; then
    echo -e "${RED}Erro: Container do orderer não está rodando${NC}"
    echo -e "${YELLOW}Execute o script start-network.sh primeiro${NC}"
    exit 1
fi

# Configurar variáveis de ambiente do peer
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export FABRIC_LOGGING_SPEC=INFO

echo -e "${YELLOW}Instalando contrato inteligente...${NC}"

# Compilar o contrato
echo -e "\n${YELLOW}Compilando contrato...${NC}"
npx hardhat compile

# Verificar se o contrato foi compilado
if [ ! -f "artifacts/contracts/PropertyRegistry.sol/PropertyRegistry.json" ]; then
    echo -e "${RED}Erro: Contrato não foi compilado corretamente${NC}"
    exit 1
fi

# Criar diretório para o chaincode
echo -e "\n${YELLOW}Criando diretório para o chaincode...${NC}"
mkdir -p chaincode

# Copiar contrato compilado
echo -e "\n${YELLOW}Copiando contrato compilado...${NC}"
cp artifacts/contracts/PropertyRegistry.sol/PropertyRegistry.json chaincode/

# Verificar se o contrato já está instalado
echo -e "\n${YELLOW}Verificando se o contrato já está instalado...${NC}"
if docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer lifecycle chaincode queryinstalled | grep -q "$CONTRACT_NAME"; then
    echo -e "${YELLOW}Contrato já está instalado, pulando instalação...${NC}"
else
    # Empacotar o contrato
    echo -e "\n${YELLOW}Empacotando contrato...${NC}"
    docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
               -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
               -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
               -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
               -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
               cli peer lifecycle chaincode package $CONTRACT_NAME.tar.gz \
               --path /opt/gopath/src/github.com/chaincode \
               --lang node \
               --label $PACKAGE_ID

    # Instalar o contrato
    echo -e "\n${YELLOW}Instalando contrato no peer...${NC}"
    docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
               -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
               -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
               -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
               -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
               cli peer lifecycle chaincode install $CONTRACT_NAME.tar.gz
fi

# Aprovar o contrato
echo -e "\n${YELLOW}Aprovando contrato...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer lifecycle chaincode approveformyorg \
           -o orderer.example.com:7050 \
           --channelID $CHANNEL_NAME \
           --name $CONTRACT_NAME \
           --version $CONTRACT_VERSION \
           --package-id $PACKAGE_ID \
           --sequence 1 \
           --init-required \
           --signature-policy "OR('Org1MSP.member')" \
           --tls \
           --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Verificar se o contrato está pronto para ser commitado
echo -e "\n${YELLOW}Verificando se o contrato está pronto para ser commitado...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer lifecycle chaincode checkcommitreadiness \
           --channelID $CHANNEL_NAME \
           --name $CONTRACT_NAME \
           --version $CONTRACT_VERSION \
           --sequence 1 \
           --init-required \
           --signature-policy "OR('Org1MSP.member')" \
           --tls \
           --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Commit do contrato
echo -e "\n${YELLOW}Commitando contrato...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer lifecycle chaincode commit \
           -o orderer.example.com:7050 \
           --channelID $CHANNEL_NAME \
           --name $CONTRACT_NAME \
           --version $CONTRACT_VERSION \
           --sequence 1 \
           --init-required \
           --signature-policy "OR('Org1MSP.member')" \
           --tls \
           --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo -e "\n${GREEN}Contrato instalado e instanciado com sucesso!${NC}" 