---
status: backlog
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md"
squad: ""
---

# Roadmap: Onda 1 de contribuição ao upstream — sinal honesto no CI e no `sync`

> Created: 2026-09-05 | Status: backlog

## Context
<!-- Derived from REQ: REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ] **AC1** — Cada um dos 4 itens tem issue no `kgsaran/trackfw` com: defeito medido, controle na direção oposta, e proposta de remédio. Issue sem medição não conta.
- [ ] **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR existentes). Se já houver registro, o entregável é **correção de escopo**, não report novo — foi o que aconteceu na `#268`, onde a REQ dele já existia e o valor esteve em mostrar que o AC1 podia ser satisfeito **sem corrigir o defeito**.
- [ ] **AC3** — Onde ele pedir PR, a implementação sai em branch `upstream-pr/*` criada **a partir de `upstream/main`**, nunca da nossa `main`. Falsificação obrigatória antes de abrir: `git diff --stat upstream/main...<branch>` bate com a mudança real.
- [ ] **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na issue com a ressalva do que ela **não** prova.
- [ ] **AC5** — Nenhum dos 4 é mesclado na nossa `main` por fora. Volta só pelo merge do upstream. Falsificação: a divergência de produto continua **vazia** ao fim da onda.
- [ ] **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele. **Recusa é desfecho legítimo** e fecha o ML; o que não pode é ficar aberto sem resposta.

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

### ML-1A — **AC1** — Cada um dos 4 itens tem issue no `kgsaran/trackfw` com: defeito medido, controle na…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC1** — Cada um dos 4 itens tem issue no kgsaran/trackfw com: defeito medido, controle na
- [ ] build passes
- [ ] tests green

### ML-1B — **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR
- [ ] build passes
- [ ] tests green

### ML-1C — **AC3** — Onde ele pedir PR, a implementação sai em branch `upstream-pr/*` criada **a partir de…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC3** — Onde ele pedir PR, a implementação sai em branch upstream-pr/* criada **a partir de
- [ ] build passes
- [ ] tests green

### ML-1D — **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na
- [ ] build passes
- [ ] tests green

### ML-1E — **AC5** — Nenhum dos 4 é mesclado na nossa `main` por fora. Volta só pelo merge do upstream.…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC5** — Nenhum dos 4 é mesclado na nossa main por fora. Volta só pelo merge do upstream.
- [ ] build passes
- [ ] tests green

### ML-1F — **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele.…
**Status:** ⬜ Pendente
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele.
- [ ] build passes
- [ ] tests green
