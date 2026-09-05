---
status: wip
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md"
squad: ""
---

# Roadmap: Dívida de governança do acervo — 42 violações, das quais 32 REQs sem ADR

> Created: 2026-09-05 | Status: wip

## Context
<!-- Derived from REQ: REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ] **AC1** — Os 4 blocos mecanizáveis (roadmap em `done/`, frontmatter ausente, ADR órfã, status fora do vocabulário) estão em **zero**. Falsificação: `trackfw validate` antes e depois, com o binário da árvore, e a diferença de contagem bate exatamente com a soma dos blocos tratados.
- [ ] **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo registrado: ADR retroativa vinculada, ou `status: abandoned`. **Nenhuma fica sem decisão.**
- [ ] **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
- [ ] **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de propósito (REQ nova sem ADR) tem de reprovar. Um gate que passa porque parou de olhar é o defeito que originou esta REQ.
- [ ] **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor fica registrado no `docs/agents-working-context.md`.
- [ ] **AC6** — Nenhum arquivo de produto tocado. Falsificação: `git diff --name-only main upstream/main -- internal npm/src pypi/trackfw cmd .github Makefile` continua **vazio** (divergência de produto zero, medida em `a958b57`).

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
1. Enumeration completeness — is the list of surfaces in this roadmap complete? Name what is missing, or show the list is closed. Do not limit the search to the files already named by the REQ — before declaring the list closed, search the repository for other places that emit the same artifact or the same pattern (for example, grep for the literal the final artifact contains).
2. Threat model — who empties this Wave 0 without breaking any written rule, and how?
3. Falsification targets in both directions — for each surface, what breaks when the behavior regresses, and what breaks when it regresses the opposite way?
4. Declared residual — what this design accepts not covering.
**Acceptance criteria:**
- [ ] The four sections above answered with evidence, not a one-line assertion
- [ ] No implementation line written for this ML

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
exit 1  # placeholder gate fails closed until ML-0A replaces it — see docs/cli-parity.md
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Os 4 blocos mecanizáveis (roadmap em `done/`, frontmatter ausente, ADR órfã, status…
**Status:** 🔄 Em andamento
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC1** — Os 4 blocos mecanizáveis (roadmap em done/, frontmatter ausente, ADR órfã, status
- [ ] build passes
- [ ] tests green

### ML-1B — **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo
- [ ] build passes
- [ ] tests green

### ML-1C — **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
- [ ] build passes
- [ ] tests green

### ML-1D — **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de
- [ ] build passes
- [ ] tests green

### ML-1E — **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor fica registrado no `docs/agents-working-context.md`.
- [ ] build passes
- [ ] tests green

### ML-1F — **AC6** — Nenhum arquivo de produto tocado. Falsificação: `git diff --name-only main…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC6** — Nenhum arquivo de produto tocado. Falsificação:
- [ ] build passes
- [ ] tests green
