---
status: wip
date: 2026-08-30
req: docs/requisições/claude/REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md
---

# Roadmap: Ruido de gofmt divergindo do upstream

> Created: 2026-08-30 | Status: wip

## Context

20 dos 80 arquivos de divergencia sao so formatacao, vindos de um `gofmt -w` rodado com Go 1.26.1
contra um upstream em 1.25.2. Nao quebram, mas conflitam em todo merge e poluiriam PR.

REQ: docs/requisições/claude/REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md

## Acceptance Criteria

- [ ] 20 arquivos na formatacao do upstream
- [ ] Nenhuma divergencia deliberada perdida, verificado por marcador
- [ ] build, vet e os sete gates verdes
- [ ] Divergencia de codigo cai de 80 para 60

## Wave 1 — A limpeza

### ML-1A — Reverter os 20 e provar que nada se perdeu
**Status:** 🔄 Em andamento
**Actions:**
1. Restaurar cada um dos 20 a partir de `upstream/main`.
2. Contar os marcadores das divergencias deliberadas ANTES e DEPOIS — igualdade e a prova.
3. build, vet, sete gates.
**Acceptance criteria:**
- [ ] Contagem de marcadores identica antes e depois
- [ ] Divergencia cai para 60
