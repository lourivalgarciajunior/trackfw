---
status: backlog
date: 2026-09-08
req: "docs/requisições/claude/REQ-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum.md"
squad: "claude"
---

# Roadmap: corpus de predicados de plataforma não é lido por gate nenhum

> Created: 2026-09-08 | Status: backlog

## Context

REQ: docs/requisições/claude/REQ-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum.md

O `scripts/testdata/platform-predicates.tsv` tem 13 casos e é referenciado só por três documentos.
Nenhum script o lê. Contrato escrito, gate ausente — a mesma forma dos achados #278 e #290, do nosso
lado.

## Acceptance Criteria

- [ ] Gate lê o corpus e executa cada caso contra o predicado real, com guarda de integridade de
      vetor e guarda de vacuidade, falsificado nas duas direções.
- [ ] Corpus estendido com os 7 vetores medidos em 2026-09-08.
- [ ] Onde o gate roda fica decidido **por escrito**.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ⬜ Pendente
**Files affected:** —
**Actions:**
1. **Enumeração completa.** Varrer a árvore inteira por consumidores do corpus — não só `scripts/`.
   Declarar a lista fechada com o comando que a produziu. 🔴 A enumeração que originou esta REQ
   varreu com `grep -rl` e achou 3 documentos; confirmar que não há consumidor indireto (um script
   que monte o caminho por variável, por exemplo).
2. **Quem esvazia esta wave sem quebrar regra escrita?** Pelo menos três formas conhecidas, a
   registrar com o remédio de cada uma: (a) gate que percorre zero linhas e sai 0; (b) gate que lê o
   vetor com barra perdida e compara duas coisas erradas que coincidem; (c) gate que só roda em
   Linux, onde metade do corpus é vacuamente satisfeita.
3. **Falsificação nas duas direções, por família.** Para cada uma das 5 famílias (`anchored`,
   `direrr`, `bash`, `execbit`, `isatty`): o que quebra quando o predicado regride, e o que quebra
   quando o **valor esperado** no corpus é que está errado.
4. **Residual declarado.** O que este desenho aceita não cobrir.
**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência, não com asserção de uma linha
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — O gate

### ML-1A — Leitor do corpus com guarda de integridade de vetor
**Status:** ⬜ Pendente
**Files affected:** `scripts/check-platform-predicates.sh` (novo), `scripts/testdata/platform-predicates.tsv`
**Actions:**
1. Acrescentar ao corpus uma coluna de **comprimento em bytes** do vetor, ou um checksum por linha.
2. O leitor afirma o comprimento antes de comparar qualquer resposta.
**Acceptance criteria:**
- [ ] 🔴 Falsificação obrigatória: remover **uma** barra invertida de um vetor no arquivo faz o gate
      reprovar, nomeando a linha — não passa nem reporta divergência de predicado
- [ ] Guarda de vacuidade: corpus vazio, ou zero casos executados, reprova
- [ ] O gate passa na árvore intacta

### ML-1B — Execução dos predicados por família
**Status:** ⬜ Pendente
**Files affected:** `scripts/check-platform-predicates.sh`
**Actions:**
1. Cada família executa o predicado real do runtime e compara com a coluna do SO corrente.
2. Famílias que não podem ser exercitadas no SO corrente **declaram-se não-aplicáveis com razão**, e
   a declaração é falsificável — no SO onde ela **pode** rodar, declarar não-aplicável reprova.
**Acceptance criteria:**
- [ ] Mutar o predicado de cada família reprova o gate — uma falsificação por família, não uma só
- [ ] O relatório imprime `N casos · M não-aplicáveis (razão)`, nunca só `OK`

### ML-1C — Corpus estendido com os vetores de 2026-09-08
**Status:** ⬜ Pendente
**Files affected:** `scripts/testdata/platform-predicates.tsv`
**Actions:**
1. Acrescentar os 7 vetores medidos hoje: `\.\x`, `\srv`, `\srv\`, `\\a\b`, `\..\evil`,
   `\.\pipe\x`, `1:\x`.
2. Cada um com nota dizendo **por que a rejeição é deliberada** — não são defeito.
**Acceptance criteria:**
- [ ] Os 7 entram e o gate os executa; o denominador sai de 13 para 20
- [ ] Nenhum é marcado como defeito

### ML-1D — Onde o gate roda, decidido por escrito
**Status:** ⬜ Pendente
**Files affected:** `CLAUDE.md` ou `docs/`
**Actions:**
1. Medir quantos dos 20 casos são **vacuamente satisfeitos** em `ubuntu-latest`.
2. Decidir e escrever: entra no CI, roda só local no Windows, ou ambos.
**Acceptance criteria:**
- [ ] 🔴 A decisão vem com o número medido, não com estimativa
- [ ] "Só roda no Windows local" é aceitável **se escrito** — o que não é aceitável é a cobertura
      depender disso em silêncio

## Residual declarado

- Este roadmap **não** propõe o gate ao upstream. Se ele se provar útil, é issue própria e depois de
  medido.
- O corpus descreve comportamento **nativo da plataforma**, não do trackfw. Se algum caso passar a
  depender de código do produto, ele sai do corpus — misturar os dois é o erro que a
  `REQ-2026-09-05-tres-reqs-de-docs-req` registra.
