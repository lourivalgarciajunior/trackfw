---
status: Open
date: 2026-08-29
author: claude
adr: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md
---

# REQ: Trazer o barrier dialeto canonico do upstream

> Date: 2026-08-29 | Status: Open

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md

## Motivation

Segundo `git merge upstream/main`, agora com a maquinaria pronta. Um commit: `d4e286e`
(`fix(barrier)` — dialeto canonico do roadmap, status por token, consciencia de cerca). Sem tag.

**Governanca enxuta de proposito.** O primeiro merge levou threat model completo porque o processo
era inedito e o risco desconhecido; ele derrubou quatro fixes locais sem gerar conflito. Agora os
sete gates existem e dizem o que se perde. A cerimonia acompanha o risco, nao o habito.

**Superficie:** 173 arquivos, quase todos `docs/`, `vault/` e testdata do upstream. De codigo, o que
interessa e `pypi/trackfw/generators/roadmap.py` — arquivo que este repo patcheou (o separador do
`.trackfw-log`, ML-1B de REQ-2026-08-29-isatty). Inspecionado antes de mesclar: o upstream mexe no
`WAVE0_BLOCK` do template, o fix local esta no `log_basename` da funcao de move. **Nao colidem.**

## Acceptance Criteria

- [ ] Merge sem marcador de conflito
- [ ] Os **sete** gates verdes; para cada perda, o gate que a acusou registrado
- [ ] `check-upstream-content.sh` barra o `vault/notes/index.md` que vem no diff — **primeira
      prova de fogo dele**
- [ ] `go build ./...` verde
- [ ] Suite pypi sem regressao por lista nomeada contra 95 falhas
