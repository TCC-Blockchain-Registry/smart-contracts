# Guia de Configuração e Inicialização

Este guia descreve o passo a passo para configurar e iniciar a rede Hyperledger Fabric com o contrato de registro de propriedades.

## Pré-requisitos

- Node.js (v14 ou superior)
- Docker e Docker Compose
- Hyperledger Fabric v2.2

## Passo a Passo

### 1. Gerar Artefatos do Canal

Primeiro, precisamos gerar os artefatos necessários para a rede:

```bash
npm run generate-artifacts
```

Este comando irá:
- Gerar o bloco genesis
- Criar a configuração do canal
- Gerar as âncoras
- Criar os certificados necessários

### 2. Iniciar a Rede

Com os artefatos gerados, podemos iniciar a rede:

```bash
npm run start-network
```

Este comando irá:
- Parar containers existentes (se houver)
- Remover redes e volumes antigos
- Criar uma nova rede
- Iniciar os containers:
  - Certificate Authority (CA)
  - Orderer
  - Peer
  - CLI

### 3. Criar o Canal

Após a rede estar rodando, criamos o canal:

```bash
npm run create-channel
```

Este comando irá:
- Criar o canal `mychannel`
- Juntar o peer ao canal
- Atualizar as âncoras do canal

### 4. Registrar Admin

Agora registramos o administrador da rede:

```bash
npm run enroll-admin
```

Este comando irá:
- Criar uma wallet para gerenciar identidades
- Registrar o usuário admin
- Registrar o usuário da aplicação

### 5. Deploy do Contrato

Por fim, fazemos o deploy do contrato:

```bash
npm run deploy-contract
```

Este comando irá:
- Compilar o contrato
- Empacotar o contrato
- Instalar o contrato no peer
- Aprovar o contrato
- Commit o contrato no canal

## Verificação

Para verificar se tudo está funcionando corretamente:

```bash
npm run check-network
```

Este comando irá mostrar:
- Status dos containers
- Logs dos containers
- Status dos certificados
- Status do contrato

## Solução de Problemas

### Se a rede não iniciar corretamente:

1. Pare todos os containers:
```bash
docker-compose down
```

2. Remova os volumes:
```bash
docker volume prune
```

3. Limpe os artefatos:
```bash
npm run clean
```

4. Siga os passos novamente a partir do início

### Se o registro do admin falhar:

1. Verifique se o CA está rodando:
```bash
docker ps | grep ca
```

2. Verifique os logs do CA:
```bash
docker logs ca.example.com
```

3. Verifique se o arquivo `connection-profile.json` está correto

### Se o deploy do contrato falhar:

1. Verifique se o peer está no canal:
```bash
docker exec cli peer channel list
```

2. Verifique se o contrato foi compilado:
```bash
ls -la artifacts/contracts
```

3. Verifique os logs do peer:
```bash
docker logs peer0.org1.example.com
```

## Comandos Úteis

- Ver logs em tempo real:
```bash
docker-compose -f packages/hardhat/config/docker-compose.yaml logs -f
```

- Ver status dos containers:
```bash
docker ps
```

- Limpar tudo e começar do zero:
```bash
npm run clean:all
npm run generate-artifacts
npm run start-network
npm run create-channel
npm run enroll-admin
npm run deploy-contract
```

## 📚 Recursos Adicionais

- [Documentação do Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/)
- [Documentação do Contrato](packages/hardhat/docs/PropertyRegistry.md)
- [Guia de Contribuição](CONTRIBUTING.md)