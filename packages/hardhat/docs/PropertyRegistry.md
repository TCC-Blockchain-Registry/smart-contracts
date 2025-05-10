# PropertyRegistry Smart Contract

## Visão Geral
O `PropertyRegistry` é um contrato inteligente desenvolvido para gerenciar o registro e transferência de propriedades imobiliárias na blockchain. Ele fornece funcionalidades para registrar imóveis, transferir titularidade, gerenciar hipotecas e manter um histórico completo de transferências.

## Estruturas de Dados

### Property
```solidity
struct Property {
    string propertyId;        // Identificador único do imóvel
    string registrationNumber;// Número de registro no cartório
    address owner;            // Endereço do titular atual
    string description;       // Descrição do imóvel
    string propertyAddress;   // Endereço físico do imóvel
    uint256 area;            // Área em m²
    string propertyType;      // Tipo do imóvel (CASA, APARTAMENTO, TERRENO, etc)
    string status;           // Status do imóvel (REGULAR, PENDENTE, BLOQUEADO)
    uint256 lastTransferDate;// Data da última transferência
    bool hasMortgage;        // Indica se o imóvel tem hipoteca
    string mortgageDetails;  // Detalhes da hipoteca, se houver
}
```

### Transfer
```solidity
struct Transfer {
    address from;             // Endereço do titular anterior
    address to;               // Endereço do novo titular
    uint256 timestamp;        // Data e hora da transferência
    string reason;            // Motivo da transferência
    string documentHash;      // Hash do documento de transferência
    string notaryInfo;        // Informações do cartório
    uint256 transferValue;    // Valor da transferência
    string paymentStatus;     // Status do pagamento
}
```

## Funcionalidades Principais

### 1. Registro de Imóveis
- `registerProperty`: Registra um novo imóvel no sistema
  - Validações:
    - ID único
    - Área maior que zero
    - Endereço do proprietário válido
  - Status inicial: "REGULAR"
  - Sem hipoteca inicial

### 2. Transferência de Propriedade
- `transferProperty`: Transfere a titularidade de um imóvel
  - Requisitos:
    - Apenas o proprietário atual pode transferir
    - Imóvel deve estar com status "REGULAR"
    - Não pode ter hipoteca ativa
  - Registra histórico completo da transferência
  - Atualiza data da última transferência

### 3. Gerenciamento de Hipotecas
- `addMortgage`: Adiciona uma hipoteca ao imóvel
  - Requisitos:
    - Apenas o proprietário pode adicionar
    - Imóvel não pode ter hipoteca ativa
- `removeMortgage`: Remove uma hipoteca existente
  - Requisitos:
    - Apenas o proprietário pode remover
    - Imóvel deve ter hipoteca ativa

### 4. Gestão de Status
- `setPropertyStatus`: Altera o status do imóvel
  - Status possíveis:
    - "REGULAR": Permite transferências
    - "PENDENTE": Bloqueia transferências
    - "BLOQUEADO": Bloqueia transferências
  - Apenas o proprietário pode alterar o status

### 5. Consultas
- `getProperty`: Retorna todos os detalhes de um imóvel
- `getTransferHistory`: Retorna o histórico de transferências
- `getAllProperties`: Retorna lista de todos os imóveis registrados

## Eventos
- `PropertyRegistered`: Emitido quando um novo imóvel é registrado
- `PropertyTransferred`: Emitido quando ocorre uma transferência
- `PropertyStatusChanged`: Emitido quando o status é alterado
- `MortgageAdded`: Emitido quando uma hipoteca é adicionada
- `MortgageRemoved`: Emitido quando uma hipoteca é removida

## Segurança
- Modificadores implementados:
  - `onlyOwner`: Garante que apenas o proprietário pode executar certas ações
  - `propertyExists`: Verifica se o imóvel existe
  - `noMortgage`: Verifica se o imóvel não tem hipoteca ativa

## Uso
```solidity
// Exemplo de registro de imóvel
await propertyRegistry.registerProperty(
    "PROP001",
    "123456",
    owner.address,
    "Casa em condomínio",
    "Rua das Flores, 123",
    150,
    "CASA"
);

// Exemplo de transferência
await propertyRegistry.transferProperty(
    "PROP001",
    newOwner.address,
    "Venda",
    "0x1234567890abcdef",
    "Cartório Central",
    ethers.utils.parseEther("1.0"),
    "PAGO"
);
```

## Testes
O contrato possui uma suite completa de testes que cobre:
- Registro de imóveis
- Transferências
- Gerenciamento de hipotecas
- Alteração de status
- Listagem de imóveis
- Casos de erro e validações

## Considerações de Implementação
1. O contrato utiliza strings para IDs e descrições, o que pode aumentar o custo de gas
2. O histórico de transferências é mantido indefinidamente
3. Não há limite para o número de imóveis registrados
4. As validações são feitas no nível do contrato para garantir integridade dos dados 