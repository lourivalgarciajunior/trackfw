---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md"
squad: ""
---

# Roadmap: Dívida de governança do acervo — 42 violações, das quais 32 REQs sem ADR

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] **AC1** — Os 4 blocos mecanizáveis (roadmap em `done/`, frontmatter ausente, ADR órfã, status fora do vocabulário) estão em **zero**. Falsificação: `trackfw validate` antes e depois, com o binário da árvore, e a diferença de contagem bate exatamente com a soma dos blocos tratados.
- [x] **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo registrado: ADR retroativa vinculada, ou `status: abandoned`. **Nenhuma fica sem decisão.**
- [x] **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
- [x] **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de propósito (REQ nova sem ADR) tem de reprovar. Um gate que passa porque parou de olhar é o defeito que originou esta REQ.
- [x] **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor fica registrado no `docs/agents-working-context.md`.
- [x] **AC6** — Nenhum arquivo de produto tocado. Falsificação: `git diff --name-only main upstream/main -- internal npm/src pypi/trackfw cmd .github Makefile` continua **vazio** (divergência de produto zero, medida em `a958b57`).

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** docs/adr/ADR-2026-09-05-*.md · docs/requisições/claude/*.md
**Actions:**
1. Enumeração completa
2. Threat model
3. Falsificação nas duas direções
4. Residual declarado
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

> **Ordem real, registrada em vez de encoberta:** este ML-0A foi respondido **depois** do ML-1B, não
> antes. O roadmap manda o contrário. O que o tornou recuperável foi o ML-1B ter sido conduzido por
> medição — a enumeração saiu do `validate --json`, não de lista escrita à mão.

**1. Enumeração completa.** As 32 vieram do `validate` (`req_has_adr`), não de busca manual. Não
limitei a lista ao que a REQ nomeava: varri `docs/requisições/**` inteiro e conferi o total pelo
`status` (56 REQs), que é o denominador. As 6 sem roadmap resolvível foram verificadas **por
execução** — `trackfw update` responde, `analyzing` está nos 6 estados, i18n tem 3 locales e
`generators/java.go` existe, 46 arquivos citam `trackfw-attention`, e o `trackfw.yaml` que a REQ de
consolidação pedia está na raiz.

**2. Threat model — quem esvazia este trabalho sem quebrar regra escrita.** Três caminhos, todos
verdes:

- **Uma ADR guarda-chuva** cobrindo as 32 zera o gate e não registra nada. O contrapeso é o
  agrupamento por decisão real, com Alternatives Considered em cada uma.
- **Marcar as 32 como `Closed`** para a regra parar de olhar. É o gate deixando de examinar, não o
  acervo melhorando — e foi recusado explicitamente.
- **O pior: o gate parar de enxergar o denominador.** Foi o que já aconteceu aqui —
  `✓ No violations found` sobre 7 de 53 REQs, por layout `by_agent` não resolvido. Um verde sem
  denominador é indistinguível de um verde honesto **na saída do comando**.

**3. Falsificação nas duas direções.** Não bastava o gate passar:

```
denominador   status: 56 REQs · 14 ADRs · 66 roadmaps    <- nao e vacuidade
plantei       REQ sem ADR  ->  2 violacoes disparam na hora
removi        ->  volta a 0
```

O que quebra na regressão oposta: normalizar status por conveniência apagaria a distinção
`Done` (entregue) × `Closed` (encerrada sem entrega). Por isso a única REQ genuinamente abandonada
virou `Closed`, e não `Done` junto com as outras.

**4. Residual declarado.**

- As 6 decisões foram **inferidas do trabalho entregue**, não recuperadas de registro da época. São
  reconstrução de boa-fé, e cada ADR declara isso no cabeçalho.
- A `ADR-001` do upstream cobre o mesmo assunto de uma das novas. **Não foi lida antes de escrever**
  — a ADR-2026-08-29 impede importar, e ler para depois não importar contaminaria sem poder citar.
  Consequência assumida: as duas podem divergir.
- `governance score 100/100` mede as regras que existem. Nenhuma delas verifica se a ADR **descreve
  a decisão que de fato foi tomada**.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
test "$(./bin/trackfw validate 2>&1 | grep -c '^â')" = "0" || { echo "gate: validate reprova"; exit 1; }
./bin/trackfw status | grep -qE "REQs +5[0-9]" || { echo "gate: denominador colapsou — verde pode ser vacuo"; exit 1; }
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Os 4 blocos mecanizáveis (roadmap em `done/`, frontmatter ausente, ADR órfã, status…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — Os 4 blocos mecanizáveis (roadmap em done/, frontmatter ausente, ADR órfã, status
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor fica registrado no `docs/agents-working-context.md`.
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Nenhum arquivo de produto tocado. Falsificação: `git diff --name-only main…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Nenhum arquivo de produto tocado. Falsificação:
- [x] build passes
- [x] tests green
