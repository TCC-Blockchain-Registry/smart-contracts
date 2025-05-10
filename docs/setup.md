# Guia de Configuração e Execução

Este guia fornece instruções detalhadas para configurar e executar o projeto de Smart Contracts para Registro de Propriedades.

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- Node.js (v14 ou superior)
- Docker e Docker Compose
- Hyperledger Fabric v2.2
- Go (para compilar o chaincode)

## 🚀 Configuração Inicial

1. Clone o repositório:
```bash
git clone <url-do-repositorio>
cd smart-contracts
```

2. Instale as dependências:
```bash
npm install
```

3. Configure as variáveis de ambiente:
```bash
cp .env.example .env
# Edite o arquivo .env com suas configurações
```

## 🔄 Fluxo de Execução

### 1. Gerar Artefatos do Canal

```bash
npm run generate-artifacts
```

Este comando irá:
- Gerar certificados e chaves
- Criar blocos de gênese
- Configurar o canal

### 2. Iniciar a Rede Hyperledger Fabric

```bash
npm run start-network
```

Este comando irá:
- Iniciar os containers Docker necessários
- Configurar a rede peer-to-peer
- Iniciar os serviços de ordenação

### 3. Criar o Canal

```bash
npm run create-channel
```

Este comando irá:
- Criar o canal "mychannel"
- Juntar os peers ao canal
- Atualizar as âncoras

### 4. Instalar e Instanciar o Contrato

```bash
npm run deploy-contract
```

Este comando irá:
- Compilar o contrato PropertyRegistry
- Instalar o contrato no peer
- Aprovar o contrato
- Verificar a prontidão
- Fazer commit do contrato no canal

## 🧪 Testando o Contrato

Para executar os testes do contrato:

```bash
npm run test
```

## 🔍 Verificando o Status

Para verificar o status da rede e do contrato:

```bash
# Verificar containers em execução
docker ps

# Verificar logs do peer
docker logs peer0.org1.example.com

# Verificar logs do orderer
docker logs orderer.example.com
```

## 🛠️ Comandos Úteis

### Limpeza
```bash
# Limpar cache e artefatos
npm run clean

# Limpar tudo (incluindo node_modules)
npm run clean:all
```

### Formatação e Linting
```bash
# Formatar código
npm run format

# Verificar código
npm run lint
```

## 🔧 Solução de Problemas

### Problemas Comuns

1. **Erro de Conexão com o Peer**
   - Verifique se os containers estão rodando
   - Verifique as variáveis de ambiente
   - Verifique os logs do peer

2. **Erro na Instalação do Contrato**
   - Verifique se o contrato foi compilado corretamente
   - Verifique as permissões do diretório
   - Verifique os logs do peer

3. **Erro na Criação do Canal**
   - Verifique se os artefatos foram gerados
   - Verifique as configurações do canal
   - Verifique os logs do orderer

## 📚 Recursos Adicionais

- [Documentação do Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/)
- [Documentação do Contrato](packages/hardhat/docs/PropertyRegistry.md)
- [Guia de Contribuição](CONTRIBUTING.md)