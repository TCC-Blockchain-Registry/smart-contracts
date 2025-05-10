#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Verificando status da rede Hyperledger Fabric...${NC}"

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Erro: Docker não está rodando${NC}"
    exit 1
fi

# Verificar containers
echo -e "\n${YELLOW}Status dos containers:${NC}"
docker ps -a --filter "name=fabric" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verificar logs do orderer
echo -e "\n${YELLOW}Últimas linhas do log do orderer:${NC}"
docker logs orderer.example.com --tail 5 2>/dev/null || echo -e "${RED}Container do orderer não encontrado${NC}"

# Verificar logs do peer
echo -e "\n${YELLOW}Últimas linhas do log do peer:${NC}"
docker logs peer0.org1.example.com --tail 5 2>/dev/null || echo -e "${RED}Container do peer não encontrado${NC}"

# Verificar logs do CA
echo -e "\n${YELLOW}Últimas linhas do log do CA:${NC}"
docker logs ca.org1.example.com --tail 5 2>/dev/null || echo -e "${RED}Container do CA não encontrado${NC}"

# Verificar certificados
echo -e "\n${YELLOW}Verificando certificados:${NC}"
if [ -d "crypto-config" ]; then
    echo -e "${GREEN}Diretório crypto-config encontrado${NC}"
    ls -la crypto-config/ordererOrganizations/example.com/msp/cacerts/ 2>/dev/null || echo -e "${RED}Certificados do orderer não encontrados${NC}"
    ls -la crypto-config/peerOrganizations/org1.example.com/msp/cacerts/ 2>/dev/null || echo -e "${RED}Certificados do peer não encontrados${NC}"
else
    echo -e "${RED}Diretório crypto-config não encontrado${NC}"
fi

# Verificar arquivos de configuração
echo -e "\n${YELLOW}Verificando arquivos de configuração:${NC}"
if [ -f "config/genesis.block" ]; then
    echo -e "${GREEN}Bloco genesis encontrado${NC}"
else
    echo -e "${RED}Bloco genesis não encontrado${NC}"
fi

if [ -f "config/channel.tx" ]; then
    echo -e "${GREEN}Arquivo channel.tx encontrado${NC}"
else
    echo -e "${RED}Arquivo channel.tx não encontrado${NC}"
fi

# Verificar wallet
echo -e "\n${YELLOW}Verificando wallet:${NC}"
if [ -d "wallet" ]; then
    echo -e "${GREEN}Diretório wallet encontrado${NC}"
    ls -la wallet/
else
    echo -e "${RED}Diretório wallet não encontrado${NC}"
fi

# Verificar contrato compilado
echo -e "\n${YELLOW}Verificando contrato compilado:${NC}"
if [ -d "artifacts/contracts" ]; then
    echo -e "${GREEN}Contrato compilado encontrado${NC}"
    ls -la artifacts/contracts/
else
    echo -e "${RED}Contrato não compilado${NC}"
fi

# Sugestões de próximos passos
echo -e "\n${YELLOW}Próximos passos sugeridos:${NC}"
if ! docker ps | grep -q "fabric"; then
    echo -e "1. Iniciar a rede: ${GREEN}docker-compose -f config/docker-compose.yaml up -d${NC}"
fi

if [ ! -d "wallet" ]; then
    echo -e "2. Registrar usuários: ${GREEN}node scripts/enroll-admin.js${NC}"
fi

if [ ! -d "artifacts/contracts" ]; then
    echo -e "3. Compilar contrato: ${GREEN}npx hardhat compile${NC}"
fi

echo -e "4. Fazer deploy do contrato: ${GREEN}npx hardhat run scripts/deploy.js --network fabric${NC}" 