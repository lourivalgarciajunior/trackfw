---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-sete-roadmaps-do-upstream-orfaos-em-wip-flat-invisiveis-ao-by-agent.md"
squad: ""
---

# Roadmap: Sete roadmaps do upstream órfãos em `wip/` flat, invisíveis ao `by_agent`

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-sete-roadmaps-do-upstream-orfaos-em-wip-flat-invisiveis-ao-by-agent.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-sete-roadmaps-do-upstream-orfaos-em-wip-flat-invisiveis-ao-by-agent.md

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
**Files affected:** docs/roadmaps/wip/*.md (7 removidos)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Não parti de suspeita: parti de medir o marcador `REQ:`, a superfície que eu tinha
**declarado não ter verificado** ao fechar a REQ da prosa. O caminho passou pelo `wip_has_req` e
esbarrou na discrepância entre `wip 0` no kanban e 7 arquivos no disco. **O achado veio de honrar um
residual declarado**, não de procurar por acaso. Varri os 6 estados flat: só `wip/` tinha arquivo.

**2. Threat model — quem esvazia isto sem quebrar regra escrita.**

- 🔴 **Adotar os 7 movendo para `<agente>/done/`.** É o gesto mais natural e seria **importar
  governança do upstream pela porta dos fundos**, contra a ADR-2026-08-29. Está no escopo negativo.
- **Apagar sem falsificar.** Se algum estivesse referenciado por REQ nossa, apagar quebraria
  `ref_targets_exist` — ou pior, passaria despercebido porque nada lê aquele diretório. Por isso a
  falsificação é **prévia** e dupla: zero referências **e** presença em `done/` do upstream.
- **Tratar `wip 0` como saúde.** Foi o que aconteceu o dia inteiro: o kanban dizia vazio e havia 7
  arquivos. Denominador zero não é ausência de trabalho.

**3. Falsificação nas duas direções.**

```
ANTES de remover, por arquivo:
  referencias em docs/requisicoes/   0
  presente em done/ do upstream      1
  -> 7 de 7 seguros

DEPOIS:
  estados flat com arquivo     nenhum
  validate                     sem violacao
  REQs                         60 (denominador intacto)
  Roadmaps                     76 -> 70   <- a queda esperada, medida
```

O controle na direção oposta: se eu tivesse removido um roadmap **referenciado**, o
`ref_targets_exist` reprovaria. Ele não reprovou porque não havia nenhum — e a checagem prévia já
tinha dito isso.

**4. Residual declarado.**

- **Os 12 roadmaps que passam só por prosa ficam.** Estão em `done/`, e a regra só avalia `wip/` —
  são latentes, não ativos. Corrigir 12 arquivos para um verde que já é verde seria churn.
- **Não medi o marcador `REQ:` no acervo do upstream**, só no nosso. Lá o `wip/` tem conteúdo, então
  o efeito pode ser ativo — está dito no #278.
- **`AcceptanceMarkers` usa o mesmo `contentHasMarker`** (`validator.go:1678`) e **não foi medido em
  nenhum dos dois acervos**. É a próxima superfície da mesma família.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
test -z "$(find docs/roadmaps -maxdepth 2 -path '*/wip/*.md' -not -path '*/claude/*' -not -path '*/apolo/*' -not -path '*/artemis/*' 2>/dev/null)" || { echo "roadmap em estado flat"; exit 1; }
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Os 7 roadmaps órfãos saem de docs/roadmaps/wip/. Falsificação prévia obrigatória:
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — Os 7 roadmaps órfãos saem de docs/roadmaps/wip/. Falsificação prévia obrigatória:
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — Nenhum outro diretório de estado **flat** tem arquivo. Medido: backlog, analyzing,
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — Nenhum outro diretório de estado **flat** tem arquivo. Medido: backlog, analyzing,
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — validate sem violação **e** com denominador conferido: status continua reportando
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — validate sem violação **e** com denominador conferido: status continua reportando
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Os 12 roadmaps que passam só por prosa ficam **registrados e não corrigidos**, com o
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Os 12 roadmaps que passam só por prosa ficam **registrados e não corrigidos**, com o
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — A medição do REQ: e o denominador zero do wip_has_req vão ao #278, fechando a
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — A medição do REQ: e o denominador zero do wip_has_req vão ao #278, fechando a
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Nenhum arquivo de produto tocado.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Nenhum arquivo de produto tocado.
- [x] build passes
- [x] tests green
