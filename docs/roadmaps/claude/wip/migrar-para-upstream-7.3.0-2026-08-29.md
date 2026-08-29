---
name: migrar-para-upstream-7.3.0-2026-08-29
title: "Migrar para a base do upstream 7.3.0"
status: wip
date: 2026-08-29
req: REQ-2026-08-29-migrar-para-upstream-7.3.0
branch: chore/migrar-upstream-7.3.0
---

# Roadmap: migrar para o upstream 7.3.0

> Created: 2026-08-29 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-29-migrar-para-upstream-7.3.0.md`
ADR: `docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md`

## Diagnóstico / Contexto

Cópia por ZIP da v2.12.2 contra um upstream na v7.3.0, sem ancestral comum. Medição e decisão de
rota na REQ e na ADR.

Superfície medida antes de começar: **237 arquivos em conflito**, **985 novos** do upstream, **228**
só locais.

## Critérios de Aceite

- [ ] Ancestralidade estabelecida; `merge upstream/<tag>` funciona sem flag
- [ ] Produto na 7.3.0, governança local intacta, governança do upstream fora
- [ ] Fix de UTF-8 reaplicado e verificado
- [ ] Build verde e `validate` executando

---

## Wave 1 — O merge

### ML-1 — Merge de históricos com resolução por área
**Status:** ⬜ Pendente
**Ações:**
1. `git merge v7.3.0 --allow-unrelated-histories --no-commit`.
2. Resolver em bloco: produto e doc de produto vêm do upstream; governança e configuração locais
   permanecem.
3. Remover do índice a governança do upstream que entrou como arquivo novo — `docs/adr/ADR-*` dele,
   `docs/req/`, `docs/roadmaps/` flat, `analises/`, `pesquisa/`, `qualidade/`, `seguranca/`,
   `analise-cmdb/`.
**Critérios de aceite:**
- [ ] Nenhum marcador de conflito em arquivo versionado
- [ ] `docs/adr/` só com as ADRs locais
- [ ] `trackfw.yaml`, `.gitattributes` e `docs/roadmaps/.trackfw-log` preservados

### ML-2 — `CLAUDE.md` mesclado
**Status:** ⬜ Pendente
**Ações:** base do upstream, mais a seção de dogfooding deste repositório — `req_dir` em português,
`roadmap_namespacing: by_agent` e os agentes.
**Critérios de aceite:**
- [ ] Instruções de produto correspondem à 7.3.0
- [ ] Seção de dogfooding presente

### ML-3 — Fix de UTF-8 reaplicado
**Status:** ⬜ Pendente
**Ações:** reaplicar `_force_utf8_output` sobre o `cli.py` da 7.3.0, com o teste correspondente.
**Critérios de aceite:**
- [ ] `--help`, `status` e `validate` com rc=0 em console cp1252
- [ ] Saída sem CRLF

---

## Wave 2 — Verificação

### ML-4 — Estado pós-migração
**Status:** ⬜ Pendente
**Ações:**
1. `trackfw version` nos três runtimes; `go build ./...`; `validate`.
2. Conferir a ancestralidade com `git merge-base`.
3. Regravar o baseline se o validator da 7.3.0 divergir do antigo.
4. Registrar o que a migração remove — `plugins` e os cinco aliases.
**Critérios de aceite:**
- [ ] `merge-base` devolve commit
- [ ] Versão 7.3.0 nos três; build verde
- [ ] Remoções registradas
