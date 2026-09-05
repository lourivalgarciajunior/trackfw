---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-tres-reqs-de-docs-req-sao-lidas-por-teste-de-produto-nos-tres-runtimes.md"
squad: ""
---

# Roadmap: Três REQs de `docs/req/` são lidas por teste de produto nos três runtimes

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-tres-reqs-de-docs-req-sao-lidas-por-teste-de-produto-nos-tres-runtimes.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-tres-reqs-de-docs-req-sao-lidas-por-teste-de-produto-nos-tres-runtimes.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ]
- [ ]

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** docs/req/REQ-2026-07-27-*.md (3 restauradas)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Vim de duas regressões em cadeia. A primeira quebrou o `parity`; consertei olhando
só o gate que reclamou. **A segunda quebrou `go`/`node`/`python` — e eu não tinha olhado se algum
TESTE lia aqueles arquivos.** Desta vez enumerei os consumidores dos 5 removidos em três eixos: gates
de `scripts/`, testes dos 3 runtimes, e referências de governança na árvore. Os três chumbam
`docs/req/`.

**2. Threat model — quem esvazia isto sem quebrar regra escrita.**

- 🔴 **Restaurar os 5.** Voltaria a quebrar a integridade referencial. Os 5 não são um bloco: 3 são
  fixture de teste, 2 eram referência quebrada. Tratar como bloco erra nos dois sentidos.
- **Corrigir o teste aqui.** Fixture própria em `testdata/` é a correção certa **e é produto** —
  divergência local que todo merge futuro pagaria. Escopo negativo.
- **Confiar num gate só.** Foi a causa da segunda regressão: o `check-referential-integrity.sh` ficou
  verde e eu parei. O `go test` não tinha rodado.
- **Achar que `validate` verde encerra.** Ele diz `✓ No violations found` com `docs/req/` inteiro
  removido **e** com ele restaurado. Não distingue os dois estados.

**3. Falsificação nas duas direções.**

```
com as 3 removidas    go test  FAIL (3 subtestes, "no such file")   ·  integridade OK
com as 5 restauradas  go test  ok                                   ·  integridade FAIL (2)
com as 3 restauradas  go test  ok                                   ·  integridade OK      <- unico estado verde nos dois
```

O terceiro estado é o único em que **os dois gates passam ao mesmo tempo**, e foi medido antes do
commit. Node e Python confirmados no mesmo estado: 0 erros de arquivo ausente, 7 passed.

**4. Residual declarado.**

- **O acoplamento não foi corrigido, só contornado.** O teste continua lendo governança do
  mantenedor por caminho literal, nos 3 runtimes. Vai como issue — é instância mais forte do #277.
- **Não medi** se outros testes do produto leem `docs/`. Enumerei por `grep docs/req/REQ-2026-07-27`;
  um teste que leia outro artefato do acervo escaparia.
- **O `parity` ainda não rodou** desde a correção. Só o run pós-merge dirá se ele chega ao gate do
  barrier — que é o que responde o #277.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
bash scripts/check-referential-integrity.sh && go test ./internal/validator/ -run TestExtractRefPath
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — As 3 REQs lidas pelos testes voltam a docs/req/; as 2 que quebravam a integridade
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — As 3 REQs lidas pelos testes voltam a docs/req/; as 2 que quebravam a integridade
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — Os dois gates passam **ao mesmo tempo**: check-referential-integrity.sh diz
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — Os dois gates passam **ao mesmo tempo**: check-referential-integrity.sh diz
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — validate sem violação e denominador conferido.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — validate sem violação e denominador conferido.
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — O acoplamento vira issue no upstream, com a medição — é instância mais forte do #277
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — O acoplamento vira issue no upstream, com a medição — é instância mais forte do #277
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Nenhum arquivo de produto tocado aqui.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Nenhum arquivo de produto tocado aqui.
- [x] build passes
- [x] tests green
