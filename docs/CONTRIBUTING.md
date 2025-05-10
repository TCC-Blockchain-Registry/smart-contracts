# Guia de Contribuição

Obrigado pelo seu interesse em contribuir com o projeto Smart Contracts para Registro de Propriedades! Este documento fornece diretrizes e instruções para contribuir.

## 📋 Como Contribuir

### 1. Configuração do Ambiente

1. Faça um fork do repositório
2. Clone seu fork:
```bash
git clone https://github.com/seu-usuario/smart-contracts.git
cd smart-contracts
```

3. Configure o ambiente de desenvolvimento:
```bash
npm install
cp .env.example .env
```

### 2. Fluxo de Trabalho

1. Crie uma branch para sua feature:
```bash
git checkout -b feature/nova-feature
```

2. Faça suas alterações seguindo as convenções de código

3. Execute os testes:
```bash
npm run test
```

4. Verifique o código:
```bash
npm run lint
```

5. Formate o código:
```bash
npm run format
```

6. Commit suas alterações:
```bash
git commit -m "feat: adiciona nova feature"
```

7. Push para sua branch:
```bash
git push origin feature/nova-feature
```

8. Abra um Pull Request

## 🎨 Convenções de Código

### Solidity

- Use a versão mais recente do Solidity
- Siga o guia de estilo do Solidity
- Documente todas as funções públicas
- Adicione comentários para lógica complexa
- Use nomes descritivos para variáveis e funções

### JavaScript/TypeScript

- Use ES6+ features
- Siga o guia de estilo do Airbnb
- Use async/await ao invés de callbacks
- Documente funções e classes
- Adicione tipos TypeScript quando possível

## 🧪 Testes

- Escreva testes para todas as novas funcionalidades
- Mantenha a cobertura de testes acima de 80%
- Use descrições claras nos testes
- Teste casos de sucesso e erro
- Siga o padrão AAA (Arrange, Act, Assert)

## 📝 Commits

Siga o padrão de commits convencionais:

- `feat`: Nova feature
- `fix`: Correção de bug
- `docs`: Documentação
- `style`: Formatação
- `refactor`: Refatoração
- `test`: Testes
- `chore`: Tarefas de manutenção

Exemplo:
```bash
git commit -m "feat: adiciona função de transferência de propriedade"
```

## 🔍 Pull Requests

1. Atualize sua branch com a main
2. Resolva conflitos se houver
3. Adicione uma descrição clara das mudanças
4. Referencie issues relacionadas
5. Aguarde a revisão

## 📚 Documentação

- Atualize a documentação quando necessário
- Mantenha o README.md atualizado
- Documente novas funcionalidades
- Adicione exemplos de uso
- Mantenha a documentação do contrato atualizada

## 🤝 Comunicação

- Seja respeitoso e profissional
- Use o sistema de issues para discussões
- Mantenha as discussões focadas e construtivas
- Ajude outros contribuidores
- Reporte bugs e problemas

## 📄 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a mesma licença do projeto (MIT). 