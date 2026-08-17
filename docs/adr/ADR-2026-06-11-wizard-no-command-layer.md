---
status: Accepted
date: 2026-06-11
author: apolo
---

# ADR: Wizard interativo mora no command layer, generators nunca fazem I/O

> Date: 2026-06-11 | Status: Accepted

REQ: REQ-req-wizard-e-list-2026-06-11

> **Reconstrução retroativa, escrita em 2026-08-16.** Esta decisão foi tomada em 2026-06-11 e nunca
> registrada — o repositório não tinha nenhuma ADR. Reconstruída de três fontes: o texto da REQ, o
> roadmap `roadmap-req-wizard-e-list-2026-06-11.md` e o código atual. Verificado: `internal/commands/req.go`
> constrói o formulário `huh` (linha 42) e `internal/generators/req.go` recebe a struct `REQContent`
> sem executar nenhum prompt. Ver `REQ-2026-08-16-adrs-retroativas`.

## Context

O `trackfw adr` já tinha ganhado um wizard interativo, e o `trackfw req` precisava do mesmo
tratamento: perguntar Motivation, Acceptance Criteria, Linked ADR e Linked Roadmap antes de gerar o
arquivo.

A pergunta arquitetural não era "qual biblioteca de formulário" — era **onde o formulário mora**. O
trackfw separa `internal/commands/` (wiring cobra, entrada do usuário) de `internal/generators/`
(produção dos artefatos). Um wizard escrito dentro do generator seria mais curto, e a tentação era
real: o generator já sabe quais campos o template precisa.

Só que generator com prompt embutido não roda sem TTY. Isso atinge três coisas ao mesmo tempo:
teste automatizado, uso em pipeline de CI, e a chamada programática que o `discover --init` e o
`update` fazem.

## Decision

Todo I/O interativo fica **exclusivamente** no command layer. O generator recebe uma struct já
preenchida e nunca pergunta nada.

Concretamente, para `req`:

- `internal/commands/req.go` monta o formulário `huh`, coleta as respostas e preenche `REQContent`.
- `internal/generators/req.go` expõe `NewREQ(content REQContent) error` — lê a struct, escreve o
  arquivo, mais nada.
- Quando não há TTY, o command layer detecta e usa flags/argumentos, sem tocar no generator.

O mesmo contrato vale para `adr` e `roadmap`. O `req list` entrou junto como subcomando puro de
leitura, sem estado.

## Consequences

**Positivas.** Os generators são testáveis sem terminal — é o que permite a suíte
`internal/generators/*_test.go` rodar em CI. O mesmo generator serve o wizard, as flags e as
chamadas internas de `init`/`discover --init`/`update`, sem duplicação. E a fronteira é verificável
por leitura: um `huh.` dentro de `internal/generators/` é, por si só, uma violação da decisão.

**Negativas.** O command layer fica mais gordo — `req.go` acumula wiring, wizard e detecção de TTY.
Cada campo novo no template exige tocar dois arquivos: a struct no generator e o formulário no
command. É atrito real, aceito em troca da testabilidade.

## Alternatives Considered

**Wizard dentro do generator.** Menos código e um arquivo a menos por comando. Descartada porque
tornaria os generators dependentes de TTY, quebrando teste automatizado e as chamadas programáticas
de `init` e `update` — que são justamente os caminhos mais usados.

**Camada intermediária de "prompts" compartilhada entre commands e generators.** Resolveria a
duplicação de wiring, mas adiciona um terceiro pacote para um problema que a fronteira simples já
resolve. Descartada por peso desproporcional ao ganho.
