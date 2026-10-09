# ADR-002 — Banco relacional com suporte a dados espaciais

- **Status:** Proposto
- **Data:** 09/10/2026

## Contexto

O sistema precisa armazenar áreas de risco, localização/geometria, nível de classificação (baixo, médio, alto ou muito alto), informações sobre perigos, orientações e histórico de alterações. A pesquisa geográfica e a integridade dos dados são centrais para o mapa.

## Decisão

Adotar um **banco de dados relacional com suporte a dados espaciais**. PostgreSQL com PostGIS é uma opção recomendada, sujeita à confirmação da equipe. O backend valida os dados e executa operações de leitura e escrita.

## Alternativas consideradas

### A. Banco relacional com extensão espacial — escolhida
**Vantagens:** relacionamentos e restrições de integridade; transações; consultas espaciais; histórico consistente.

**Desvantagens:** exige modelagem do esquema e conhecimento de consultas espaciais; requer configuração de índices e backups.

### B. Banco NoSQL orientado a documentos — descartada nesta fase
**Vantagens:** esquema flexível para documentos variáveis.

**Motivo da rejeição:** o domínio possui relações claras entre áreas, classificações, informações de risco, usuários e auditoria. Não há vantagem comprovada para este escopo; parte das validações poderia acabar transferida para a aplicação.

### C. Arquivos JSON/CSV como armazenamento principal — descartada
**Vantagens:** simples para protótipos pequenos e importação inicial.

**Motivo da rejeição:** controles limitados para escrita concorrente, transações, consultas geográficas e auditoria confiável, aumentando o risco de inconsistências.

## Consequências

- A modelagem deverá contemplar Área de Risco, Classificação/Nível de Risco, Informação de Risco, Orientação e Registro de Auditoria; as entidades finais podem ser ajustadas durante o projeto.
- O sistema impedirá publicar áreas sem localização válida ou classificação permitida.
- Cadastro/atualização registrará responsável, data, hora e tipo de alteração.
- Consultas frequentes serão medidas e receberão índices quando necessário.
- Backups e testes de restauração serão necessários.
- Provedor e configuração espacial deverão ser confirmados pela equipe antes da implementação.
