#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Obter o diretório base do projeto
BASE_DIR="$PWD"
CONFIG_DIR="$BASE_DIR/config"
CHANNEL_ARTIFACTS_DIR="$CONFIG_DIR/channel-artifacts"
CONFIGTX_PATH="$CONFIG_DIR/configtx.yaml"
CRYPTO_CONFIG_PATH="$CONFIG_DIR/crypto-config.yaml"

echo -e "${YELLOW}Gerando artefatos do canal...${NC}"

# Remover diretório de artefatos existente
echo -e "\n${YELLOW}Removendo diretório de artefatos existente...${NC}"
sudo rm -rf "$CHANNEL_ARTIFACTS_DIR"

# Criar diretório para os artefatos
echo -e "\n${YELLOW}Criando diretório para os artefatos...${NC}"
sudo mkdir -p "$CHANNEL_ARTIFACTS_DIR"
sudo chown -R $USER:$USER "$CHANNEL_ARTIFACTS_DIR"

# Configurar variáveis de ambiente
export FABRIC_CFG_PATH="$CONFIG_DIR"

# Verificar se o configtxgen está disponível
CONFIGTXGEN="$BASE_DIR/fabric-tools/bin/configtxgen"
if [ ! -f "$CONFIGTXGEN" ]; then
    echo -e "${RED}Erro: configtxgen não encontrado em $CONFIGTXGEN${NC}"
    echo -e "${YELLOW}Instalando ferramentas do Fabric...${NC}"
    
    # Criar diretório para as ferramentas
    mkdir -p "$BASE_DIR/fabric-tools/bin"
    
    # Baixar e extrair as ferramentas
    curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.0 1.5.2 -d -s
    
    # Mover os binários para o diretório correto
    cp -r bin/* "$BASE_DIR/fabric-tools/bin/"
    chmod +x "$BASE_DIR/fabric-tools/bin/"*
    
    # Limpar arquivos temporários
    rm -rf bin
    
    if [ ! -f "$CONFIGTXGEN" ]; then
        echo -e "${RED}Erro: Falha ao instalar as ferramentas do Fabric${NC}"
        exit 1
    fi
fi

# Verificar se os certificados existem
if [ ! -d "$BASE_DIR/crypto-config" ]; then
    echo -e "${RED}Erro: Diretório crypto-config não encontrado${NC}"
    echo -e "${YELLOW}Gerando certificados...${NC}"
    
    # Criar diretório para os certificados
    mkdir -p "$BASE_DIR/crypto-config"
    
    # Gerar certificados
    "$BASE_DIR/fabric-tools/bin/cryptogen" generate --config="$CRYPTO_CONFIG_PATH" --output="$BASE_DIR/crypto-config"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao gerar certificados${NC}"
        exit 1
    fi
fi

# Criar arquivo configtx.yaml temporário
cat > "$CONFIGTX_PATH" << 'EOF'
---
Organizations:
  - &OrdererOrg
    Name: OrdererOrg
    ID: OrdererMSP
    MSPDir: ../crypto-config/ordererOrganizations/example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('OrdererMSP.member')"
      Writers:
        Type: Signature
        Rule: "OR('OrdererMSP.member')"
      Admins:
        Type: Signature
        Rule: "OR('OrdererMSP.admin')"

  - &Org1
    Name: Org1MSP
    ID: Org1MSP
    MSPDir: ../crypto-config/peerOrganizations/org1.example.com/msp
    Policies:
      Readers:
        Type: Signature
        Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
      Writers:
        Type: Signature
        Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
      Admins:
        Type: Signature
        Rule: "OR('Org1MSP.admin')"
    AnchorPeers:
      - Host: peer0.org1.example.com
        Port: 7051

Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_0: true

Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
  Capabilities:
    <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
  OrdererType: solo
  Addresses:
    - orderer.example.com:7050
  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    BlockValidation:
      Type: ImplicitMeta
      Rule: "ANY Writers"
  Capabilities:
    <<: *OrdererCapabilities

Channel: &ChannelDefaults
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
  Capabilities:
    <<: *ChannelCapabilities

Profiles:
  TwoOrgsOrdererGenesis:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      Organizations:
        - *OrdererOrg
    Consortiums:
      SampleConsortium:
        Organizations:
          - *Org1

  TwoOrgsChannel:
    Consortium: SampleConsortium
    <<: *ChannelDefaults
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *Org1
EOF

# Verificar se o arquivo foi criado corretamente
if [ ! -f "$CONFIGTX_PATH" ]; then
    echo -e "${RED}Erro: Falha ao criar configtx.yaml${NC}"
    exit 1
fi

# Verificar se o arquivo tem o conteúdo correto
if ! grep -q "TwoOrgsOrdererGenesis" "$CONFIGTX_PATH"; then
    echo -e "${RED}Erro: Perfil TwoOrgsOrdererGenesis não encontrado no configtx.yaml${NC}"
    echo -e "${YELLOW}Conteúdo do arquivo:${NC}"
    cat "$CONFIGTX_PATH"
    exit 1
fi

# Gerar bloco genesis
echo -e "\n${YELLOW}Gerando bloco genesis...${NC}"
"$CONFIGTXGEN" -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock "$CHANNEL_ARTIFACTS_DIR/genesis.block"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar bloco genesis${NC}"
    exit 1
fi

# Gerar configuração do canal
echo -e "\n${YELLOW}Gerando configuração do canal...${NC}"
"$CONFIGTXGEN" -profile TwoOrgsChannel -channelID mychannel -outputCreateChannelTx "$CHANNEL_ARTIFACTS_DIR/channel.tx"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar configuração do canal${NC}"
    exit 1
fi

# Gerar ancoras
echo -e "\n${YELLOW}Gerando ancoras...${NC}"
"$CONFIGTXGEN" -profile TwoOrgsChannel -channelID mychannel -outputAnchorPeersUpdate "$CHANNEL_ARTIFACTS_DIR/Org1MSPanchors.tx" -asOrg Org1MSP
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao gerar ancoras${NC}"
    exit 1
fi

# Verificar se os arquivos foram gerados
echo -e "\n${YELLOW}Verificando arquivos gerados...${NC}"
if [ ! -f "$CHANNEL_ARTIFACTS_DIR/genesis.block" ]; then
    echo -e "${RED}Erro: genesis.block não foi gerado${NC}"
    exit 1
fi

if [ ! -f "$CHANNEL_ARTIFACTS_DIR/channel.tx" ]; then
    echo -e "${RED}Erro: channel.tx não foi gerado${NC}"
    exit 1
fi

if [ ! -f "$CHANNEL_ARTIFACTS_DIR/Org1MSPanchors.tx" ]; then
    echo -e "${RED}Erro: Org1MSPanchors.tx não foi gerado${NC}"
    exit 1
fi

# Ajustar permissões
echo -e "\n${YELLOW}Ajustando permissões...${NC}"
sudo chown -R $USER:$USER "$CHANNEL_ARTIFACTS_DIR"

echo -e "\n${GREEN}Artefatos gerados com sucesso!${NC}"
echo -e "Artefatos gerados em: $CHANNEL_ARTIFACTS_DIR" 