---
status: backlog
date: 2026-09-11
req: "docs/requisições/claude/REQ-2026-09-11-o-gitattributes-do-fork-mascara-um-defeito-de-produto-que-o-upstream-mantem-exposto-de-proposito.md"
squad: ""
---

# Roadmap: o .gitattributes do fork mascara um defeito de produto que o upstream mantém exposto de propósito

> Created: 2026-09-11 | Status: backlog

## Context

REQ: docs/requisições/claude/REQ-2026-09-11-o-gitattributes-do-fork-mascara-um-defeito-de-produto-que-o-upstream-mantem-exposto-de-proposito.md

A REQ decide o que o `.gitattributes` deste fork cobre — **depois** de medir. Nasce do ML-0A da
`REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao`, que achou a causa dos 8 "sumidos": o nosso `.gitattributes` mascara, no checkout
Windows, um defeito de produto que o upstream mantém exposto de propósito.

## Acceptance Criteria
- [ ] Os seis ACs da REQ

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Medição, antes de qualquer decisão

### ML-0A — O que muda no checkout, por arquivo (AC1)
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Para as opções A, B e C, a lista de arquivos rastreados que mudam de fim de linha no checkout
      Windows, por nome e agrupada por área
- [ ] Medido em worktree próprio, nunca na árvore de trabalho: a medição não pode ser contaminada por
      edição em curso

### ML-0B — O efeito nos nossos gates (AC2)
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Cada gate local e o `validate` rodados sobre docs em CRLF, com controle em LF
- [ ] Separado, gate por gate: quebra, reprova pelo motivo errado, ou passa

## Wave 1 — A decisão (AC3)

### ML-1A — ADR
**Status:** ⬜ Pendente
**Files affected:** `docs/adr/`
**Acceptance criteria:**
- [ ] ADR nova, ou emenda à `ADR-2026-08-29`, com as opções e o motivo medido

## Wave 2 — Aplicar e provar (AC4 a AC6)

### ML-2A — O `.gitattributes`, e os 8 no CI
**Status:** ⬜ Pendente
**Files affected:** `.gitattributes`
**Acceptance criteria:**
- [ ] Os 8 falham no nosso `windows-full-suites` (38 de 38 observados) — ou ficam declarados por nome,
      se a decisão for manter
- [ ] Nenhum arquivo de produto tocado; `validate` e gates verdes

## Residual declarado

- O defeito de produto — o parser de frontmatter e o CRLF — continua sendo do upstream. Esta REQ decide
  só se o fork o **vê**.
