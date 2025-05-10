#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Obter o diretório base do projeto
BASE_DIR="$PWD"
CONFIG_DIR="$BASE_DIR/config"
CRYPTO_DIR="$BASE_DIR/crypto-config"
CHANNEL_ARTIFACTS_DIR="$CONFIG_DIR/channel-artifacts"

echo -e "${YELLOW}Iniciando a rede Hyperledger Fabric...${NC}"

# Verificar se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Erro: Docker não está instalado${NC}"
    exit 1
fi

# Verificar se o Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Erro: Docker Compose não está instalado${NC}"
    exit 1
fi

# Verificar se os certificados existem
if [ ! -d "$CRYPTO_DIR/peerOrganizations" ] || [ ! -d "$CRYPTO_DIR/ordererOrganizations" ]; then
    echo -e "${RED}Erro: Certificados não encontrados${NC}"
    echo -e "${YELLOW}Execute primeiro o script generate-artifacts.sh${NC}"
    exit 1
fi

# Verificar se os artefatos do canal existem
if [ ! -f "$CHANNEL_ARTIFACTS_DIR/genesis.block" ] || [ ! -f "$CHANNEL_ARTIFACTS_DIR/channel.tx" ]; then
    echo -e "${RED}Erro: Artefatos do canal não encontrados${NC}"
    echo -e "${YELLOW}Execute primeiro o script generate-artifacts.sh${NC}"
    exit 1
fi

# Parar todos os containers relacionados ao Fabric
echo -e "\n${YELLOW}Parando todos os containers relacionados ao Fabric...${NC}"
docker ps -a --filter "name=ca|orderer|peer|cli" --format "{{.Names}}" | xargs -r docker stop
docker ps -a --filter "name=ca|orderer|peer|cli" --format "{{.Names}}" | xargs -r docker rm

# Remover redes antigas
echo -e "\n${YELLOW}Removendo redes antigas...${NC}"
docker network prune -f

# Remover volumes antigos
echo -e "\n${YELLOW}Removendo volumes antigos...${NC}"
docker volume prune -f

# Criar diretórios temporários para a rede
echo -e "\n${YELLOW}Criando diretórios temporários...${NC}"
TEMP_CRYPTO="$CONFIG_DIR/temp_crypto"
TEMP_ARTIFACTS="$CONFIG_DIR/temp_artifacts"

sudo rm -rf "$TEMP_CRYPTO" "$TEMP_ARTIFACTS"
sudo mkdir -p "$TEMP_CRYPTO" "$TEMP_ARTIFACTS"

# Copiar certificados e artefatos para os diretórios temporários
echo -e "\n${YELLOW}Copiando certificados e artefatos...${NC}"
sudo cp -r "$CRYPTO_DIR"/* "$TEMP_CRYPTO/"
sudo cp "$CHANNEL_ARTIFACTS_DIR/genesis.block" "$TEMP_ARTIFACTS/"
sudo cp "$CHANNEL_ARTIFACTS_DIR/channel.tx" "$TEMP_ARTIFACTS/"
sudo cp "$CHANNEL_ARTIFACTS_DIR/Org1MSPanchors.tx" "$TEMP_ARTIFACTS/"

# Ajustar permissões
echo -e "\n${YELLOW}Ajustando permissões...${NC}"
sudo chown -R $USER:$USER "$TEMP_CRYPTO"
sudo chown -R $USER:$USER "$TEMP_ARTIFACTS"

# Mover para os diretórios finais
echo -e "\n${YELLOW}Movendo para os diretórios finais...${NC}"
sudo rm -rf "$CONFIG_DIR/crypto-config" "$CONFIG_DIR/channel-artifacts"
sudo mv "$TEMP_CRYPTO" "$CONFIG_DIR/crypto-config"
sudo mv "$TEMP_ARTIFACTS" "$CONFIG_DIR/channel-artifacts"

# Verificar se os arquivos foram copiados corretamente
echo -e "\n${YELLOW}Verificando arquivos...${NC}"
if [ ! -f "$CONFIG_DIR/channel-artifacts/genesis.block" ]; then
    echo -e "${RED}Erro: genesis.block não foi copiado corretamente${NC}"
    echo -e "${YELLOW}Verificando arquivos originais...${NC}"
    ls -la "$CHANNEL_ARTIFACTS_DIR"
    exit 1
fi

if [ ! -f "$CONFIG_DIR/channel-artifacts/channel.tx" ]; then
    echo -e "${RED}Erro: channel.tx não foi copiado corretamente${NC}"
    exit 1
fi

# Iniciar a rede
echo -e "\n${YELLOW}Iniciando a rede...${NC}"
cd "$CONFIG_DIR"
docker-compose -f docker-compose.yaml up -d

# Aguardar os containers iniciarem
echo -e "\n${YELLOW}Aguardando os containers iniciarem...${NC}"
sleep 10

# Verificar se os containers estão rodando
echo -e "\n${YELLOW}Verificando status dos containers...${NC}"
docker ps --filter "name=ca.example.com|orderer.example.com|peer0.org1.example.com|cli"

# Verificar logs dos containers
echo -e "\n${YELLOW}Verificando logs dos containers...${NC}"
for container in ca.example.com orderer.example.com peer0.org1.example.com cli; do
    if docker ps -q --filter "name=$container" | grep -q .; then
        echo -e "\n${YELLOW}Logs do container $container:${NC}"
        docker logs $container | tail -n 5
    else
        echo -e "\n${RED}Container $container não está rodando${NC}"
        echo -e "${YELLOW}Logs completos do container $container:${NC}"
        docker logs $container
    fi
done

echo -e "\n${GREEN}Rede iniciada!${NC}"
echo -e "Para ver os logs em tempo real, execute: ${YELLOW}docker-compose -f $CONFIG_DIR/docker-compose.yaml logs -f${NC}" 