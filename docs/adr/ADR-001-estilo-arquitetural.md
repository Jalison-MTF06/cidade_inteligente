# ADR-001 — Adotar monólito modular em camadas

- **Status:** Proposto
- **Data:** 09/10/2026

## Contexto

O sistema precisa oferecer consulta pública do mapa, pesquisa por endereço, classificação e filtros de risco, além de cadastro/atualização protegidos por autenticação e auditoria. O projeto tem escopo acadêmico e metas de desempenho, disponibilidade, usabilidade e segurança.

## Decisão

Adotar inicialmente um **monólito modular em camadas**, expondo uma API para a aplicação Web. Separar responsabilidades em API/apresentação, aplicação/regras de negócio e persistência. Centralizar no backend validações, permissões, classificação e auditoria.

## Alternativas consideradas

### A. Monólito modular em camadas — escolhida
**Vantagens:** menor complexidade operacional; regras centralizadas; transações e auditoria mais simples; custo inicial menor.

**Desvantagens:** módulos mal separados podem gerar acoplamento; escalar partes isoladamente é mais difícil.

### B. Microserviços — descartada nesta fase
**Vantagens:** implantação e escala independentes; maior autonomia entre equipes.

**Motivo da rejeição:** adiciona complexidade de implantação, observabilidade, comunicação, autenticação entre serviços e consistência de dados sem evidência de que o volume ou a equipe exijam isso.

### C. Aplicação única sem separação interna — descartada
**Vantagens:** início rápido.

**Motivo da rejeição:** tende a misturar regras de risco, acesso e persistência, dificultando testes, manutenção e auditoria uniforme.

## Consequências

- Backend implantado inicialmente como uma unidade, com módulos internos definidos.
- A interface Web comunica-se com o backend pela API.
- Segurança e regras de negócio são aplicadas no servidor.
- Testes de carga verificam a meta de 95% das requisições em até 2 segundos para até 100 usuários simultâneos.
- A separação interna facilita uma futura extração de serviços se métricas reais justificarem.
- A meta de 99% de disponibilidade exige monitoramento, backups e recuperação, independentemente do estilo escolhido.
