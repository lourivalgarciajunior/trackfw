---
status: wip
date: 2026-08-29
req: docs/requisições/claude/REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md
---

# Roadmap: Trazer o barrier dialeto canonico do upstream

> Created: 2026-08-29 | Status: wip

## Context

Segundo merge do upstream, um commit. Governanca enxuta: a maquinaria de gates ja existe.

REQ: docs/requisições/claude/REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md

## Acceptance Criteria

- [ ] Merge sem conflito pendente
- [ ] Sete gates verdes, com as perdas e quem as acusou
- [ ] O gate de conteudo do upstream barra o `vault/notes/index.md` do diff
- [ ] Build verde e suite pypi sem regressao por lista nomeada

## Wave 1 — O merge

### ML-1A — Mesclar e verificar
**Status:** 🔄 Em andamento
**Actions:** `git merge upstream/main`; governanca e conteudo do upstream fora, pela ADR; rodar os
sete gates e registrar o que caiu.
**Acceptance criteria:**
- [ ] Sem marcador de conflito
- [ ] Tabela de perda/gate escrita
