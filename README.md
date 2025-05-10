# Smart Contracts - Registro de Propriedades

Este projeto implementa um sistema de registro de propriedades usando smart contracts com Hyperledger Fabric e Solidity. O sistema permite o registro, transferência e gerenciamento de propriedades imobiliárias de forma segura e transparente na blockchain.

## 🏗️ Estrutura do Projeto

```
smart-contracts/
├── packages/
│   └── hardhat/           # Contratos e configuração do Hardhat
│       ├── config/        # Configurações do Hyperledger Fabric
│       ├── contracts/     # Contratos Solidity
│       ├── scripts/       # Scripts de deploy e configuração
│       └── test/          # Testes do contrato
├── docs/                  # Documentação adicional
└── scripts/              # Scripts de utilidade
```

## 📋 Pré-requisitos

- Node.js (v14 ou superior)
- Docker e Docker Compose
- Hyperledger Fabric v2.2

## 🚀 Instalação

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

## 🛠️ Scripts Disponíveis

### Scripts Principais
- `npm run generate-artifacts`: Gera os artefatos do canal (certificados, blocos de gênese, etc)
- `npm run start-network`: Inicia a rede Hyperledger Fabric
- `npm run create-channel`: Cria o canal na rede
- `npm run deploy-contract`: Instala e instancia o contrato no canal

### Scripts de Utilidade
- `npm run clean`: Limpa todos os diretórios de cache e artefatos
- `npm run clean:all`: Limpa tudo, incluindo node_modules
- `npm run format`: Formata todo o código do projeto
- `npm run lint`: Verifica todo o código do projeto
- `npm run compile`: Compila os contratos
- `npm run test`: Executa os testes

### Scripts de Desenvolvimento
- `enroll-admin.js`: Registra o administrador na rede
- `check-network.sh`: Verifica o status da rede e dos containers

## 🔄 Fluxo de Trabalho

1. Gere os artefatos do canal:
```bash
npm run generate-artifacts
```

2. Inicie a rede:
```bash
npm run start-network
```

3. Crie o canal:
```bash
npm run create-channel
```

4. Instale e instancie o contrato:
```bash
npm run deploy-contract
```

## 📝 Funcionalidades do Contrato

O contrato `PropertyRegistry.sol` implementa as seguintes funcionalidades:

### Registro de Propriedades
- Registro de novos imóveis com informações detalhadas
- Validação de dados e verificação de duplicidade
- Atribuição de identificadores únicos

### Transferência de Propriedades
- Transferência segura de titularidade
- Registro de histórico de transferências
- Validação de permissões e status

### Gerenciamento de Hipotecas
- Registro de hipotecas
- Remoção de hipotecas
- Verificação de status de hipoteca

### Consultas e Relatórios
- Consulta de propriedades
- Histórico de transferências
- Status de propriedades

## 🧪 Desenvolvimento

### Testes
Para executar os testes:
```bash
npm run test
```

### Linting e Formatação
Para verificar o código:
```bash
npm run lint
```

Para formatar o código:
```bash
npm run format
```

### Limpeza
Para limpar os diretórios de cache e artefatos:
```bash
npm run clean
```

Para limpar tudo (incluindo node_modules):
```bash
npm run clean:all
```

## 📚 Documentação Adicional

- [Documentação do Contrato](packages/hardhat/docs/PropertyRegistry.md)
- [Guia de Configuração](docs/setup.md)
- [Guia de Contribuição](docs/CONTRIBUTING.md)

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.
