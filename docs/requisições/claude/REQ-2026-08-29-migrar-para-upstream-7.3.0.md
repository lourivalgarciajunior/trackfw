---
id: REQ-2026-08-29-migrar-para-upstream-7.3.0
title: Migrar para a base do upstream 7.3.0 e estabelecer sincronização por merge
status: Open
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

- [x] `git merge-base main upstream/main` devolve um commit — ancestralidade existe
      → **(a) ENTREGUE.** 2026-09-10: `97543eef979a`.
- [ ] `trackfw version` reporta 7.3.0 nos três runtimes
      → **(c) CADUCOU.** Os três runtimes reportam **`trackfw 7.5.1`**, concordando entre si. A
      migração para 7.3.0 aconteceu e foi ultrapassada por merges posteriores do upstream — o último
      nesta mesma semana. **O que o AC queria (paridade de versão entre os três) está satisfeito; o
      número literal não faz mais sentido como critério.**
      🔴 Fica **aberto de propósito**: marcá-lo afirmaria `7.3.0`, que é falso hoje.
- [ ] `docs/adr/` tem só as 7 ADRs locais; `docs/requisições/` e `docs/roadmaps/` intactos
      → 🔴 **(b) NAO ENTREGUE.** Hoje `docs/adr/` tem **15** ADRs, e **uma delas é do upstream**:
      `ADR-2026-09-03-layout-canonico-de-req-em-by-agent...` existe em `upstream/main:docs/adr/`.
      As outras 14 são nossas — o crescimento de 7 → 14 é trabalho legítimo. **A 15ª é resíduo de
      merge**, e é a mesma classe das 28 REQs herdadas.
      🔴 **Agravante:** essa ADR é citada por **5 REQs nossas** como se fosse nossa, incluindo a
      `REQ-2026-09-08-sete-reqs`, cuja motivação inteira é *"a `ADR-2026-09-03` decide D1"*.
- [ ] Nenhum arquivo de governança do upstream em `docs/`
      → 🔴 **(b) NAO ENTREGUE, e há gate vermelho provando.** `scripts/check-upstream-content.sh`
      **reprova hoje** com **7 arquivos**:
      ```
      docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-...
      docs/portabilidade/2026-09-02-renomeacao-de-agentes-identidade-e-presets.md
      docs/qualidade/2026-09-02-parecer-codificacao-declarada.md
      docs/qualidade/2026-09-03-parecer-resolvedor-de-req.md
      docs/seguranca/2026-09-02-modelo-de-ameaca-da-saida-nao-ascii.md
      docs/seguranca/2026-09-02-parecer-codificacao-declarada.md
      docs/seguranca/2026-09-03-parecer-resolvedor-de-req.md
      ```
      O gate é **nosso** e existe justamente para isto. Ele está vermelho e ninguém notou —
      exatamente o que a `REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate` existia para
      impedir.
- [x] `trackfw.yaml` e `.gitattributes` preservados
      → **(a) ENTREGUE.** Os dois existem na raiz, e o `trackfw.yaml` mantém `req_dir:
      docs/requisições` e `roadmap_namespacing: by_agent`, que são os dois defaults sobrescritos.
- [x] Fix de UTF-8 presente no `cli.py` da 7.3.0 e verificado em console cp1252
      → **(a) ENTREGUE.** `pypi/trackfw/cli.py` tem **6** ocorrências de `reconfigure`/
      `_force_utf8_output`, e a execução com `PYTHONIOENCODING=cp1252` conclui: `trackfw 7.5.1`.
      Nota: o upstream **absorveu** este fix — deixou de ser divergência local, e a
      `REQ-2026-08-16-cli-python-utf8-windows` continua válida como registro do defeito.
- [x] `go build ./...` verde e `trackfw validate` executa
      → **(a) ENTREGUE.** `go build ./...` → `exit 0`; `trackfw validate` → `✓ No violations found`.
- [x] Registrado o que a migração remove: `plugins` e os cinco aliases de integração
      → **(a) ENTREGUE.** O comando `plugins` **não existe** no binário de hoje (`trackfw plugins
      --help` → erro), e a remoção está registrada nesta própria REQ e no
      `check-subcommand-parity.sh`, cujo `known_divergences` documenta: *"o subsistema de plugins foi
      removido pelo upstream (ADR-2026-08-15) e com ele as quatro divergências"*.
