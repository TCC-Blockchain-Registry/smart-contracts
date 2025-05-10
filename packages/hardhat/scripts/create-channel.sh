#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configurações
CHANNEL_NAME="mychannel"
CHANNEL_TX_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx"
ANCHOR_TX_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/Org1MSPanchors.tx"

# Configurar variáveis de ambiente do peer
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export FABRIC_LOGGING_SPEC=INFO

echo -e "${YELLOW}Criando canal...${NC}"

# Criar canal
echo -e "\n${YELLOW}Criando canal ${CHANNEL_NAME}...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer channel create -o orderer.example.com:7050 \
           -c $CHANNEL_NAME \
           -f $CHANNEL_TX_FILE \
           --tls \
           --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Entrar no canal
echo -e "\n${YELLOW}Entrando no canal...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer channel join -b $CHANNEL_NAME.block

# Atualizar ancoras
echo -e "\n${YELLOW}Atualizando ancoras...${NC}"
docker exec -e CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH \
           -e CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
           -e CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID \
           -e CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
           -e FABRIC_LOGGING_SPEC=$FABRIC_LOGGING_SPEC \
           cli peer channel update -o orderer.example.com:7050 \
           -c $CHANNEL_NAME \
           -f $ANCHOR_TX_FILE \
           --tls \
           --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

echo -e "\n${GREEN}Canal criado com sucesso!${NC}" 