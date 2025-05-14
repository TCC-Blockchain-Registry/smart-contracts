#!/bin/bash
set -e

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARDHAT_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$HARDHAT_DIR")"
CHAINCODE_DIR="$HARDHAT_DIR/chaincode"
CONFIG_DIR="$HARDHAT_DIR/config"
CHANNEL_NAME="mychannel"
CHAINCODE_NAME="PropertyRegistry"
CHAINCODE_LABEL="PropertyRegistry_1.0"
CHAINCODE_VERSION="1.0"
CC_SEQUENCE=1
CC_LANG="node"
CC_PACKAGE_FILE="$SCRIPT_DIR/${CHAINCODE_LABEL}.tar.gz"
FABRIC_BIN_DIR="$SCRIPT_DIR/fabric-tools/bin"
CRYPTO_CONFIG_PATH="$CONFIG_DIR/crypto-config.yaml"
CONFIGTX_PATH="$CONFIG_DIR/configtx.yaml"
CHANNEL_ARTIFACTS_DIR="$CONFIG_DIR/channel-artifacts"
CRYPTO_CONFIG_DIR="$CONFIG_DIR/crypto-config"

# 1. Limpar containers e artefatos antigos
echo "[1/8] Parando e removendo containers antigos..."
docker-compose -f "$CONFIG_DIR/docker-compose.yaml" down -v || true

# Remover volumes Docker relacionados ao Fabric
echo "Removendo volumes Docker..."
docker volume ls -q | grep -E 'dev-peer|fabric' | xargs -r docker volume rm || true

# Remover todos os artefatos
echo "Removendo artefatos antigos..."
sudo rm -rf \
    "$CHANNEL_ARTIFACTS_DIR" \
    "$FABRIC_BIN_DIR" \
    "$SCRIPT_DIR/${CHAINCODE_LABEL}.tar.gz" \
    "$CHAINCODE_DIR/*.tar.gz" \
    "$HARDHAT_DIR/wallet" \
    "$CRYPTO_CONFIG_DIR"

# 2. Baixar binários do Fabric se necessário
echo "[2/8] Baixando binários do Fabric (se necessário)..."
if [ ! -f "$FABRIC_BIN_DIR/configtxgen" ]; then
  mkdir -p "$FABRIC_BIN_DIR"
  curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.0 1.5.2 -d -s
  cp -r bin/* "$FABRIC_BIN_DIR/"
  chmod +x "$FABRIC_BIN_DIR"/*
  rm -rf bin
fi

# 3. Gerar certificados com cryptogen
echo "[3/8] Gerando certificados..."
mkdir -p "$CRYPTO_CONFIG_DIR"

# Gerar certificados
"$FABRIC_BIN_DIR/cryptogen" generate --config="$CRYPTO_CONFIG_PATH" --output="$CRYPTO_CONFIG_DIR"

# Verificar se os certificados foram gerados corretamente
if [ ! -d "$CRYPTO_CONFIG_DIR/ordererOrganizations/example.com/msp/cacerts" ]; then
    echo "Erro: Certificados do orderer não foram gerados corretamente"
    echo "Verificando diretório: $CRYPTO_CONFIG_DIR/ordererOrganizations/example.com/msp/cacerts"
    ls -la "$CRYPTO_CONFIG_DIR/ordererOrganizations/example.com/msp" || true
    exit 1
fi

if [ ! -d "$CRYPTO_CONFIG_DIR/peerOrganizations/org1.example.com/msp/cacerts" ]; then
    echo "Erro: Certificados do peer não foram gerados corretamente"
    echo "Verificando diretório: $CRYPTO_CONFIG_DIR/peerOrganizations/org1.example.com/msp/cacerts"
    ls -la "$CRYPTO_CONFIG_DIR/peerOrganizations/org1.example.com/msp" || true
    exit 1
fi

# 4. Gerar artefatos do canal (genesis, channel tx, anchor peer)
echo "[4/8] Gerando artefatos do canal..."
export FABRIC_CFG_PATH="$CONFIG_DIR"
rm -rf "$CHANNEL_ARTIFACTS_DIR"
mkdir -p "$CHANNEL_ARTIFACTS_DIR"

# Verificar se o configtx.yaml está no lugar correto
if [ ! -f "$CONFIG_DIR/configtx.yaml" ]; then
    echo "Erro: configtx.yaml não encontrado em $CONFIG_DIR"
    exit 1
fi

# Genesis block
echo "Gerando genesis block..."
"$FABRIC_BIN_DIR/configtxgen" -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock "$CHANNEL_ARTIFACTS_DIR/genesis.block"

# Channel tx
echo "Gerando channel tx..."
"$FABRIC_BIN_DIR/configtxgen" -profile TwoOrgsChannel -outputCreateChannelTx "$CHANNEL_ARTIFACTS_DIR/$CHANNEL_NAME.tx" -channelID $CHANNEL_NAME

# Anchor peer
echo "Gerando anchor peer tx..."
"$FABRIC_BIN_DIR/configtxgen" -profile TwoOrgsChannel -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS_DIR/Org1MSPanchors.tx" -channelID $CHANNEL_NAME -asOrg Org1MSP

# Ajustar permissões
sudo chown -R $USER:$USER "$CHANNEL_ARTIFACTS_DIR" "$CRYPTO_CONFIG_DIR"

# 5. Subir a rede
echo "[5/8] Subindo a rede..."
docker-compose -f "$CONFIG_DIR/docker-compose.yaml" up -d
sleep 5

# 6. Criar canal e peers entrarem
echo "[6/8] Criando canal e adicionando peer..."
docker exec cli peer channel create -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock /etc/hyperledger/configtx/channel-artifacts/${CHANNEL_NAME}.block --tls --cafile /etc/hyperledger/fabric/tlsca/tlsca.example.com-cert.pem

docker exec cli peer channel join -b /etc/hyperledger/configtx/channel-artifacts/${CHANNEL_NAME}.block

# 7. Definir anchor peer
echo "[7/8] Definindo anchor peer..."
docker exec cli peer channel update -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel-artifacts/Org1MSPanchors.tx --tls --cafile /etc/hyperledger/fabric/tlsca/tlsca.example.com-cert.pem

# 8. Empacotar e instalar chaincode Node.js
echo "[8/8] Empacotando e instalando chaincode Node.js..."

# Limpar definições existentes do chaincode
echo "Limpando definições existentes do chaincode..."

# Parar containers
echo "Parando containers..."
docker stop peer0.org1.example.com cli

# Reiniciar containers em ordem
echo "Reiniciando containers em ordem..."
docker start peer0.org1.example.com
sleep 5
docker start cli
sleep 5

# Limpar peer
echo "Limpando peer..."
docker exec peer0.org1.example.com sh -c "
    rm -rf /var/hyperledger/production/chaincodes/* && \
    rm -rf /var/hyperledger/production/lifecycle/chaincodes/* && \
    rm -rf /var/hyperledger/production/ledgersData/* && \
    rm -rf /var/hyperledger/production/transientStore/*"

# Limpar CLI
echo "Limpando CLI..."
docker exec cli sh -c "
    rm -rf /var/hyperledger/production/chaincodes/* && \
    rm -rf /var/hyperledger/production/lifecycle/chaincodes/* && \
    rm -rf /var/hyperledger/production/ledgersData/* && \
    rm -rf /var/hyperledger/production/transientStore/*"

# Aguardar containers reiniciarem completamente
echo "Aguardando containers reiniciarem completamente..."
sleep 10

# Verificar e remover instalações existentes
echo "Verificando instalações existentes..."
EXISTING_PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "$CHAINCODE_LABEL" | awk -F ":" '{print $3}' | awk '{print $1}')

if [ ! -z "$EXISTING_PACKAGE_ID" ]; then
    echo "Removendo instalação existente do CLI..."
    docker exec cli peer lifecycle chaincode uninstall $CHAINCODE_LABEL:$EXISTING_PACKAGE_ID 2>/dev/null || true
    
    echo "Removendo instalação existente do peer..."
    docker exec peer0.org1.example.com sh -c "
        export CORE_PEER_LOCALMSPID=Org1MSP && \
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
        export CORE_PEER_TLS_ENABLED=true && \
        export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
        export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
        peer lifecycle chaincode uninstall $CHAINCODE_LABEL:$EXISTING_PACKAGE_ID" 2>/dev/null || true
    
    # Aguardar um pouco para garantir que a desinstalação foi processada
    sleep 5
    
    # Verificar se a desinstalação foi bem sucedida
    echo "Verificando se a desinstalação foi bem sucedida..."
    CLI_INSTALLED=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "$CHAINCODE_LABEL" || true)
    PEER_INSTALLED=$(docker exec peer0.org1.example.com sh -c "
        export CORE_PEER_LOCALMSPID=Org1MSP && \
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
        export CORE_PEER_TLS_ENABLED=true && \
        export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
        export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
        peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)
    
    if [ ! -z "$CLI_INSTALLED" ] || [ ! -z "$PEER_INSTALLED" ]; then
        echo "Erro: Falha ao desinstalar o chaincode existente"
        exit 1
    fi
fi

# Empacotar chaincode
echo "Empacotando chaincode..."
docker exec cli peer lifecycle chaincode package /opt/gopath/src/github.com/chaincode/$CHAINCODE_LABEL.tar.gz --path /opt/gopath/src/github.com/chaincode --lang $CC_LANG --label $CHAINCODE_LABEL

# Instalar chaincode no cli
echo "Instalando chaincode no cli..."
docker exec cli peer lifecycle chaincode install /opt/gopath/src/github.com/chaincode/$CHAINCODE_LABEL.tar.gz

# Obter package ID
echo "Obtendo package ID..."
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "$CHAINCODE_LABEL" | awk -F ":" '{print $3}' | awk '{print $1}')

if [ -z "$PACKAGE_ID" ]; then
    echo "Erro: Não foi possível obter o package ID do chaincode"
    exit 1
fi

echo "Package ID: $PACKAGE_ID"

# Verificar se o chaincode já está instalado no peer
echo "Verificando instalação no peer..."
PEER_INSTALLED=$(docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)

if [ ! -z "$PEER_INSTALLED" ]; then
    echo "Removendo instalação existente do peer..."
    PEER_PACKAGE_ID=$(echo "$PEER_INSTALLED" | awk -F ":" '{print $3}' | awk '{print $1}')
    
    # Parar e remover o peer
    echo "Parando e removendo peer para limpeza completa..."
    docker stop peer0.org1.example.com
    docker rm peer0.org1.example.com
    
    # Remover volumes do peer
    echo "Removendo volumes do peer..."
    docker volume ls -q | grep -E 'peer0.org1.example.com' | xargs -r docker volume rm || true
    
    # Recriar o peer
    echo "Recriando peer..."
    docker-compose -f "$CONFIG_DIR/docker-compose.yaml" up -d peer0.org1.example.com
    
    # Aguardar o peer iniciar completamente
    echo "Aguardando peer iniciar..."
    sleep 15
    
    # Reingressar no canal
    echo "Reingressando no canal..."
    docker exec cli peer channel join -b /etc/hyperledger/configtx/channel-artifacts/${CHANNEL_NAME}.block
    
    # Verificar se o peer está no canal
    echo "Verificando se o peer está no canal..."
    CHANNEL_JOINED=$(docker exec cli peer channel list | grep "$CHANNEL_NAME" || true)
    if [ -z "$CHANNEL_JOINED" ]; then
        echo "Peer não está no canal. Reingressando..."
        docker exec cli peer channel join -b /etc/hyperledger/configtx/channel-artifacts/${CHANNEL_NAME}.block
        
        # Verificar novamente
        CHANNEL_JOINED=$(docker exec cli peer channel list | grep "$CHANNEL_NAME" || true)
        if [ -z "$CHANNEL_JOINED" ]; then
            echo "Erro: Falha ao reingressar no canal"
            exit 1
        fi
    fi
    
    # Verificar se a remoção foi bem sucedida
    echo "Verificando se a remoção foi bem sucedida..."
    PEER_STILL_INSTALLED=$(docker exec peer0.org1.example.com sh -c "
        export CORE_PEER_LOCALMSPID=Org1MSP && \
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
        export CORE_PEER_TLS_ENABLED=true && \
        export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
        export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
        export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
        peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)
    
    if [ ! -z "$PEER_STILL_INSTALLED" ]; then
        echo "Erro: Não foi possível remover o chaincode do peer após reconstrução"
        exit 1
    fi
fi

# Instalar chaincode no peer
echo "Instalando chaincode no peer..."
docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode install /opt/gopath/src/github.com/chaincode/$CHAINCODE_LABEL.tar.gz"

# Aguardar um pouco para garantir que a instalação foi processada
sleep 60

# Verificar se a instalação no peer foi bem sucedida
echo "Verificando instalação no peer..."
PEER_INSTALLED=$(docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)

if [ -z "$PEER_INSTALLED" ]; then
    echo "Erro: Falha ao instalar o chaincode no peer"
    exit 1
fi

# Aprovar chaincode
echo "Aprovando chaincode..."
docker exec cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $CHAINCODE_LABEL:$PACKAGE_ID --sequence $CC_SEQUENCE --init-required --tls --cafile /etc/hyperledger/fabric/tlsca/tlsca.example.com-cert.pem

# Aguardar um pouco para garantir que a aprovação foi processada
sleep 60

# Verificar readiness
echo "Verificando readiness do chaincode..."
docker exec cli peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence $CC_SEQUENCE --init-required --output json

# Commit do chaincode
echo "Commit do chaincode..."
docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence $CC_SEQUENCE --init-required --tls --cafile /etc/hyperledger/fabric/tlsca/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /etc/hyperledger/fabric/tlsca-org1/tlsca.org1.example.com-cert.pem

# Aguardar um pouco para garantir que o commit foi processado
sleep 60

# Verificar se o chaincode está pronto
echo "Verificando se o chaincode está pronto..."
docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --output json

# Verificar se o chaincode está instalado no peer
echo "Verificando instalação no peer..."
docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode queryinstalled"

# Aguardar um pouco para garantir que tudo está pronto
sleep 60

# Verificar se o chaincode está definido no canal
echo "Verificando se o chaincode está definido no canal..."
CHAINCODE_DEFINED=$(docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --output json | grep -c "sequence" || true)
if [ "$CHAINCODE_DEFINED" -eq 0 ]; then
    echo "Erro: Chaincode não está definido no canal"
    exit 1
fi

# Verificar se o chaincode está instalado no peer novamente
echo "Verificando instalação no peer novamente..."
PEER_INSTALLED_AGAIN=$(docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)

if [ -z "$PEER_INSTALLED_AGAIN" ]; then
    echo "Erro: Chaincode não está instalado no peer após commit"
    exit 1
fi

# Verificar se o peer está no canal novamente
echo "Verificando se o peer está no canal novamente..."
CHANNEL_JOINED_AGAIN=$(docker exec cli peer channel list | grep "$CHANNEL_NAME" || true)
if [ -z "$CHANNEL_JOINED_AGAIN" ]; then
    echo "Erro: Peer não está no canal após commit"
    exit 1
fi

# Verificar se o chaincode está pronto para uso
echo "Verificando se o chaincode está pronto para uso..."
CHAINCODE_READY=$(docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --output json | grep -c "init_required" || true)
if [ "$CHAINCODE_READY" -eq 0 ]; then
    echo "Erro: Chaincode não está pronto para uso"
    exit 1
fi

# Verificar se o chaincode está instalado no peer novamente
echo "Verificando instalação no peer novamente..."
PEER_INSTALLED_FINAL=$(docker exec peer0.org1.example.com sh -c "
    export CORE_PEER_LOCALMSPID=Org1MSP && \
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && \
    export CORE_PEER_TLS_ENABLED=true && \
    export CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/peer/tls/server.crt && \
    export CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/peer/tls/server.key && \
    export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt && \
    peer lifecycle chaincode queryinstalled" | grep "$CHAINCODE_LABEL" || true)

if [ -z "$PEER_INSTALLED_FINAL" ]; then
    echo "Erro: Chaincode não está instalado no peer após todas as verificações"
    exit 1
fi

# Verificar se o chaincode está pronto para uso novamente
echo "Verificando se o chaincode está pronto para uso novamente..."
CHAINCODE_READY_FINAL=$(docker exec cli peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --output json | grep -c "init_required" || true)
if [ "$CHAINCODE_READY_FINAL" -eq 0 ]; then
    echo "Erro: Chaincode não está pronto para uso após todas as verificações"
    exit 1
fi

# Tentar inicializar o chaincode com retry
echo "Inicializando chaincode..."
MAX_RETRIES=3
RETRY_COUNT=0
INIT_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$INIT_SUCCESS" = false ]; do
    if docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /etc/hyperledger/fabric/tlsca/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n $CHAINCODE_NAME --isInit -c '{"Args":["initLedger"]}' --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /etc/hyperledger/fabric/tlsca-org1/tlsca.org1.example.com-cert.pem; then
        INIT_SUCCESS=true
        echo "Chaincode inicializado com sucesso!"
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Tentativa $RETRY_COUNT de $MAX_RETRIES falhou. Aguardando antes da próxima tentativa..."
        sleep 60
    fi
done

if [ "$INIT_SUCCESS" = false ]; then
    echo "Erro: Falha ao inicializar o chaincode após $MAX_RETRIES tentativas"
    exit 1
fi

# Enrolar admin na wallet
echo "[Final] Enrolando admin na wallet..."
cd "$SCRIPT_DIR"
node enroll-admin.js

echo "\nRede Hyperledger Fabric pronta para uso com o chaincode Node.js!" 