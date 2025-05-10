#!/bin/bash

# Função para limpar a rede
cleanNetwork() {
    echo "Limpando a rede..."
    docker-compose -f config/docker-compose.yaml down
    rm -rf config/crypto-config
    rm -rf config/channel-artifacts
    rm -rf wallet
}

# Função para gerar certificados e artefatos do canal
generateCrypto() {
    echo "Gerando certificados..."
    cryptogen generate --config=./config/crypto-config.yaml --output=./config/crypto-config

    echo "Gerando bloco genesis..."
    configtxgen -profile OneOrgOrdererGenesis -channelID system-channel -outputBlock ./config/channel-artifacts/genesis.block

    echo "Gerando transação de criação do canal..."
    configtxgen -profile OneOrgChannel -channelID mychannel -outputCreateChannelTx ./config/channel-artifacts/channel.tx
}

# Função para iniciar a rede
startNetwork() {
    echo "Iniciando a rede..."
    docker-compose -f config/docker-compose.yaml up -d
    sleep 10

    echo "Criando canal..."
    docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

    echo "Juntando peer ao canal..."
    docker exec cli peer channel join -b mychannel.block --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
}

# Função para instalar e instanciar o chaincode
installChaincode() {
    echo "Instalando chaincode..."
    docker exec cli peer chaincode install -n title-transfer -v 1.0 -p github.com/chaincode -l node

    echo "Instanciando chaincode..."
    docker exec cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n title-transfer -v 1.0 -c '{"Args":["init"]}' --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
}

# Execução baseada no comando
case "$1" in
    "up")
        cleanNetwork
        mkdir -p config/channel-artifacts
        generateCrypto
        startNetwork
        installChaincode
        ;;
    "down")
        cleanNetwork
        ;;
    *)
        echo "Uso: $0 {up|down}"
        exit 1
        ;;
esac 