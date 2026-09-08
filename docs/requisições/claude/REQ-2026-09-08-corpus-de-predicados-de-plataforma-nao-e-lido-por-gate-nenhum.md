---
status: Open
date: 2026-09-08
author: "claude"
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/backlog/ROADMAP-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum.md"
---

# REQ: corpus de predicados de plataforma não é lido por gate nenhum

> Date: 2026-09-08 | Status: Open

## Motivation

Criamos `scripts/testdata/platform-predicates.tsv` na Onda 2 como **contrato**: 13 casos, 5
famílias, cada um declarando o que o predicado **deveria** responder e o que o predicado **nativo do
Windows** responde de fato — *"e onde as duas divergem está o defeito"*.

Medido em 2026-09-08, buscando quem lê o arquivo na árvore inteira:

```
docs/agents-working-context.md
docs/analises/2026-09-05-oportunidades-de-evolucao.md
docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-2-...
```

**Três documentos. Nenhum script, nenhum gate, nenhum job de CI.**

Escrevemos o contrato e nunca ligamos a verificação. É exatamente a forma que passamos dois dias
reportando ao upstream — [#278](https://github.com/kgsaran/trackfw/issues/278) (regra sem
denominador), [#290](https://github.com/kgsaran/trackfw/issues/290) (contrato escrito no
`cli-parity.md` com `gap reason=nenhum gate verifica`) — agora do nosso lado da linha.

### O corpus está desatualizado, e isso já é demonstrável

Ao conferir em x64 o achado do upstream sobre `filepath.IsAbs` em
`internal/integrations/manager.go`, medi 21 vetores contra os dois predicados e encontrei **9
contraexemplos** de `IsAbs=true ∧ Anchored=false`. O corpus cobre **2** deles (`\` e `\x`).

Fora do corpus, medidos hoje:

| vetor | `IsAbs` | `IsAnchored` |
|---|---|---|
| `\.\x` · `\srv` · `\srv\` · `\\a\b` | true | false |
| `\..\evil` · `\.\pipe\x` | true | false |
| `1:\x` (letra de unidade inválida) | true | false |

Nenhum é defeito: todos são rejeição **deliberada** do predicado ancorado. O que o corpus perde é
justamente a evidência de que a distinção existe e é intencional.

### E há um risco de fixture que esta REQ tem de tratar de frente

🔴 A primeira sonda que escrevi para essa medição deu **1 contraexemplo**, e teria contradito o
upstream. O heredoc comeu metade das barras invertidas — `%q` mostrava `"\\"` onde devia mostrar
`"\\\\"`. Um corpus de predicados de caminho é **exatamente** o tipo de arquivo em que uma barra
perdida na leitura produz verde falso sem ninguém notar.

O gate desta REQ, portanto, não pode só comparar respostas: tem de provar que **leu o vetor que
está escrito**.

## Acceptance Criteria

- [ ] **AC1** — Existe um gate que lê `scripts/testdata/platform-predicates.tsv` e executa cada
      caso contra o predicado real do runtime, comparando com a coluna correta para o SO corrente
      (`esperado` em POSIX, `nativo_windows` no Windows).
- [ ] **AC2** — 🔴 **Guarda de integridade do vetor**, antes de qualquer comparação: o gate afirma o
      **comprimento em bytes** de cada vetor lido e falha se divergir do declarado. Sem isso, uma
      barra perdida na leitura vira verde. Falsificação obrigatória: corromper um vetor no arquivo
      tem de reprovar o gate.
- [ ] **AC3** — **Guarda de vacuidade**: o gate falha se o corpus tiver zero linhas, se nenhuma
      família for exercitada, ou se o número de casos executados for menor que o número de linhas
      não-comentário. Verde sobre denominador zero não conta.
- [ ] **AC4** — Falsificação nas duas direções, por família: mutar o predicado (ou o valor esperado)
      faz o gate reprovar, **e** o gate passa na árvore intacta. Só uma das duas não é prova.
- [ ] **AC5** — O corpus é estendido com os 7 vetores medidos hoje que ele não cobre, cada um com a
      nota do **porquê** a rejeição é deliberada — não como defeito.
- [ ] **AC6** — Decisão escrita sobre **onde o gate roda**. O nosso CI de `parity` roda em
      `ubuntu-latest`, onde metade do corpus é vacuamente satisfeita (`os.sep` já é `/`,
      `filepath.IsAbs` já concorda). 🔴 "Só roda no Windows local" é decisão válida — mas fica
      **escrito** que a cobertura depende disso, em vez de silenciosamente.
- [ ] **AC7** — `trackfw validate` sem violação e com denominador conferido, medido com o binário da
      árvore reconstruído.

## Negative Scope

- **Não** tocar produto. O corpus e o gate são nossos (`scripts/testdata/`, `scripts/`), e adição de
  arquivo só nosso não cria divergência — é o precedente dos outros cinco scripts locais.
- **Não** transformar o corpus em teste do produto. Ele descreve o comportamento **nativo da
  plataforma**, não o do trackfw; confundir os dois foi o erro que a
  `REQ-2026-09-05-tres-reqs-de-docs-req` registra.
- **Não** propor o gate ao upstream nesta REQ. Se ele se provar útil aqui, isso é issue própria,
  depois de medido.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum.md
