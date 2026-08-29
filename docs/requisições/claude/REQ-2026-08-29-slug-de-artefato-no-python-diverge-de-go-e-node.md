---
status: Open
date: 2026-08-29
author: claude
adr: ""
roadmap: ROADMAP-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node
---

# REQ: Slug de artefato no Python diverge de Go e Node

> Date: 2026-08-29 | Status: Open

## Motivation

Os tres runtimes geram nomes de arquivo diferentes para o mesmo titulo quando ele contem
caractere nao-alfanumerico que nao seja espaco. Medido em diretorios limpos, um por runtime,
com `adr new "Acao C/C++ & Cafe"` (o titulo real usa acentos):

```
Go      ADR-2026-08-29-acao-c-c-cafe.md
Node    ADR-2026-08-29-acao-c-c-cafe.md
Python  ADR-2026-08-29-acao-cc-cafe.md
```

A regra difere: o Python **deleta** os nao-alfanumericos
(`re.sub(r'[^a-z0-9-]', '', slug)` em `pypi/trackfw/generators/adr.py:22`), enquanto Go e Node
os **substituem por hifen**. Acento, `/`, `+` e `&` ja sao tratados nos tres — o defeito nao e
sanitizacao ausente, e a regra de colapso divergente.

Consequencia pratica: uma REQ criada pelo Python e outra criada pelo Go a partir do mesmo titulo
viram arquivos distintos, e a cadeia ADR-REQ-ROADMAP quebra por referencia que nao resolve.

O gate `scripts/check-artifact-parity.sh` nao pega porque sua fixture e
`TITLE="Autenticacao e Sessao"` (linha 43) — so acento, nenhum dos caracteres onde os runtimes
discordam. O gate passa e o defeito sobrevive.

## Historico

Duas branches locais atacavam a sanitizacao de slug antes da migracao para a base do upstream
7.3.0 — `fix/slug-unificado` (PR #18) e `claude/jovial-morse-3a90d1` (commit `83e3e07`). As duas
foram fechadas: o `slugify` da 7.3.0 ja cobre o que elas consertavam. Esta REQ e o residuo real,
descoberto ao verificar se elas ainda faziam sentido.

## Acceptance Criteria

- [ ] Os tres runtimes produzem o mesmo nome de arquivo para o mesmo titulo, verificado em
      execucao real do CLI (nao so em teste unitario da funcao)
- [ ] A regra escolhida esta documentada em `docs/cli-parity.md` — colapso por hifen ou delecao,
      com o motivo
- [ ] A fixture de `scripts/check-artifact-parity.sh` inclui `/` e `+`
- [ ] O gate **falha** com a divergencia atual reintroduzida (nao-vacuidade verificada antes de
      considerar o trabalho pronto)
- [ ] Vale para `adr new`, `req new` e `roadmap new` — nao so `adr`

## Nao faz parte

`internal/identity/slug.go` (slug de identidade de agente) tem contrato proprio e fixture de
vetores em `internal/identity/testdata/slug_vectors.json`. Nao e o mesmo slug e nao muda aqui.

## Linked ADR

ADR: 

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node.md
