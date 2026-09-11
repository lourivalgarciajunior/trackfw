---
status: Open
date: 2026-08-29
author: claude
adr: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md
---

# REQ: Trazer o barrier dialeto canonico do upstream

> Date: 2026-08-29 | Status: Open

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md

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

- [x] Merge sem marcador de conflito
      → **(a) ENTREGUE.** `git grep '^<<<<<<<'` na árvore versionada: **0 ocorrências**.
- [ ] Os **sete** gates verdes; para cada perda, o gate que a acusou registrado
      → 🔴 **(b) NAO ENTREGUE.** Seis dos sete saem `exit 0`; o **`check-upstream-content.sh` está
      vermelho** com 7 arquivos de governança do upstream em `docs/`.
      ```
      slug-inventory 0 · python-writes-lf 0 · homedir-parity 0 · artifact-parity 0
      tty-detection 0 · barrier 0 · subcommand-parity 0 · upstream-content 1  <- VERMELHO
      ```
      A segunda metade do AC — *"para cada perda, o gate que a acusou registrado"* — é **(d)**: não
      há registro contemporâneo daquele merge para conferir.
- [x] `check-upstream-content.sh` barra o `vault/notes/index.md` que vem no diff — **primeira
      prova de fogo dele**
      → **(a) ENTREGUE**, e continua barrando: o gate acusa hoje, e `vault/notes/index.md` **não**
      está na nossa árvore. O mecanismo que este AC estreou é o mesmo que hoje acusa os 7 arquivos —
      ele funciona; o que falta é alguém olhar para ele.
- [x] `go build ./...` verde
      → **(a) ENTREGUE.** `exit 0`.
- [ ] Suite pypi sem regressao por lista nomeada contra 95 falhas
      → **(b) NAO ENTREGUE** — convertido de `(d)` em 2026-09-11 pela
      `REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados` (AC5). A afirmação sobre agosto é
      **irrecuperável**: um baseline tirado hoje não prova "sem regressão desde agosto", só daqui
      para a frente — e daqui para a frente quem verifica é o ratchet do upstream, no nosso CI.
      Registro de 2026-09-10, que continua verdadeiro: A lista das 95 não foi versionada.
