---
status: backlog
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md"
squad: ""
---

# Roadmap: Procedimento de merge do upstream com retenção da governança local

> Created: 2026-09-05 | Status: backlog

## Context
<!-- Derived from REQ: REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ] **AC1** — Existe um comando único (`make upstream-sync` ou `scripts/upstream-sync.sh`) que faz merge do upstream, retém `docs/` e `vault/`, e **falha** se sobrar conflito.
- [ ] **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la: `git diff --cached main -- docs vault --stat` tem de sair **vazio**, e o comando aborta se não sair. A prova é por efeito, não por intenção.
- [ ] **AC3** — O comando **relata a proporção**: `N arquivos de produto, M de governança retidos`. É o discriminante — um merge que fecha com muito mais que uma mão-cheia de arquivos de produto indica que algo de `docs/` passou.
- [ ] **AC4** — Falsificação em duas direções: rodar contra `4f0ad33` (32 arquivos de governança) tem de reter os 32 e trazer 4; rodar contra `6b3ba49` (zero governança) tem de trazer os 42 **sem reter nada** — o procedimento não pode suprimir produto.
- [ ] **AC5** — Verificação pós-merge automatizada: `go build ./...` exit 0 e contagem de violações do `validate` **idêntica** antes e depois, medida em worktree destacado com o binário da árvore. Falha se divergir.
- [ ] **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge upstream/<tag>`, que não menciona retenção.
- [ ] **AC7** — A seção **"Divergência local deliberada"** do `CLAUDE.md` é corrigida: ela afirma que `_force_utf8_output` só existe aqui, mas o upstream **absorveu** (medido: 2 ocorrências em `upstream/main:pypi/trackfw/cli.py`). Documentação que descreve divergência inexistente faz o próximo merge procurar conflito onde não há.

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

### ML-1A — **AC1** — Existe um comando único (`make upstream-sync` ou `scripts/upstream-sync.sh`) que faz…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC1** — Existe um comando único (make upstream-sync ou scripts/upstream-sync.sh) que faz
- [ ] build passes
- [ ] tests green

### ML-1B — **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la: `git diff --cached…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la:
- [ ] build passes
- [ ] tests green

### ML-1C — **AC3** — O comando **relata a proporção**: `N arquivos de produto, M de governança retidos`. É…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC3** — O comando **relata a proporção**: N arquivos de produto, M de governança retidos. É
- [ ] build passes
- [ ] tests green

### ML-1D — **AC4** — Falsificação em duas direções: rodar contra `4f0ad33` (32 arquivos de governança) tem…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC4** — Falsificação em duas direções: rodar contra 4f0ad33 (32 arquivos de governança) tem
- [ ] build passes
- [ ] tests green

### ML-1E — **AC5** — Verificação pós-merge automatizada: `go build ./...` exit 0 e contagem de violações do…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC5** — Verificação pós-merge automatizada: go build ./... exit 0 e contagem de violações
- [ ] build passes
- [ ] tests green

### ML-1F — **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge upstream/<tag>`, que não menciona retenção.
- [ ] build passes
- [ ] tests green

### ML-1G — **AC7** — A seção **"Divergência local deliberada"** do `CLAUDE.md` é corrigida: ela afirma que…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC7** — A seção **"Divergência local deliberada"** do CLAUDE.md é corrigida: ela afirma que
- [ ] build passes
- [ ] tests green
