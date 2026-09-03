---
id: REQ-2026-08-29-migrar-para-upstream-7.3.0
title: Migrar para a base do upstream 7.3.0 e estabelecer sincronização por merge
status: approved
priority: high
type: chore
created: 2026-08-29
author: claude
---

# REQ: Migrar para o upstream 7.3.0

Roadmap: docs/roadmaps/claude/done/migrar-para-upstream-7.3.0-2026-08-29.md
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Problema

Este repositório é uma cópia por ZIP da v2.12.2 do `kgsaran/trackfw`, de 2026-06-28. O upstream está
na **v7.3.0** — 26 releases, cinco majors, 420 commits contra 90 — e não há ancestral comum entre os
dois históricos, então `git merge upstream/main` se recusa a rodar.

O diagnóstico completo e a decisão de rota estão em `ADR-2026-08-29-adotar-upstream-como-base`.

## Requisitos

### R1 — Relação de ancestralidade estabelecida
`git merge v7.3.0 --allow-unrelated-histories`. Depois disso, `git fetch upstream && git merge
upstream/<tag>` precisa funcionar sem flag.

### R2 — Produto vem do upstream
`internal/`, `npm/`, `pypi/`, `cmd/`, `scripts/`, `site/`, `go.mod`, `go.sum`, `README.md`,
`.gitignore` e a documentação de produto em `docs/`.

### R3 — Governança local preservada
`docs/adr/` (7 ADRs), `docs/requisições/` (45 REQs), `docs/roadmaps/<agente>/` (56 roadmaps),
`docs/roadmaps/.trackfw-log`, `trackfw.yaml`, `.gitattributes`.

### R4 — Governança do upstream não importada
Os 379 arquivos de `docs/adr/`, `docs/req/` e `docs/roadmaps/` do upstream ficam de fora, junto com
`analises/`, `pesquisa/`, `qualidade/`, `seguranca/` e `analise-cmdb/`.

O motivo é concreto: `adr_dirs: [docs/adr]` no `trackfw.yaml` local faria as 52 ADRs dele caírem
onde estão as 7 daqui.

### R5 — Fix de UTF-8 reaplicado
O `_force_utf8_output` do `pypi/trackfw/cli.py` não existe no upstream e é necessário no Windows —
sem ele, `--help`, `status` e `validate` morrem com `UnicodeEncodeError` em console cp1252.
Reaplicar sobre o `cli.py` da 7.3.0.

### R6 — Estado verificado depois da migração
`trackfw version` reportando 7.3.0, `validate` executando, e os gates do upstream rodando.

O `.trackfw-baseline.json` foi gravado contra o validator da v2.12; se não corresponder ao da 7.3.0,
é regravado.

## Critérios de Aceite

- [ ] `git merge-base main upstream/main` devolve um commit — ancestralidade existe
- [ ] `trackfw version` reporta 7.3.0 nos três runtimes
- [ ] `docs/adr/` tem só as 7 ADRs locais; `docs/requisições/` e `docs/roadmaps/` intactos
- [ ] Nenhum arquivo de governança do upstream em `docs/`
- [ ] `trackfw.yaml` e `.gitattributes` preservados
- [ ] Fix de UTF-8 presente no `cli.py` da 7.3.0 e verificado em console cp1252
- [ ] `go build ./...` verde e `trackfw validate` executa
- [ ] Registrado o que a migração remove: `plugins` e os cinco aliases de integração
