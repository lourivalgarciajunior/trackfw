---
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
id: REQ-2026-08-16-consolidar-arvores-governanca
title: Consolidar as três árvores de artefato de governança em uma só
status: approved
priority: high
type: chore
created: 2026-08-16
author: claude
---

# REQ: Consolidar as três árvores de artefato de governança

## Problema

O repositório acumulou **três convenções concorrentes** de organização de artefatos de governança, sobrepostas no tempo. O `trackfw` só enxerga uma delas — a menor — porque não existe `trackfw.yaml` na raiz e tudo roda no default (`docs/req`, `docs/roadmaps`, `roadmap_namespacing: flat`).

| Árvore | Caminho | Volume | Visível ao CLI |
|---|---|---|---|
| A — flat (default) | `docs/req/` (vazia), `docs/adr/` (vazia), `docs/roadmaps/{wip,done}/` | 2 roadmaps, 0 REQ, 0 ADR | ✅ sim |
| B — by_agent pt-BR | `docs/requisições/{apolo,artemis,claude}/`, `docs/roadmaps/claude/{wip,done}/` | 27 REQs + 35 roadmaps | ❌ não |
| C — `roadmap` singular | `docs/roadmap/artemis/done/` | 2 roadmaps | ❌ não |

### Consequências observadas

1. **`trackfw status` reporta 1 roadmap em WIP; existem 3.** Os outros dois vivem em `docs/roadmaps/claude/wip/` e são invisíveis. A regra de `wip_limit: 1` está violada desde junho/2026 sem que o gate consiga acusar.
2. **Zero ADRs no repositório.** `docs/adr/` e `docs/adr/claude/` estão vazias e não existe nenhum arquivo `ADR-*` em lugar nenhum — o primeiro elo da cadeia nunca foi materializado. As 27 REQs estão órfãs de ADR.
3. **Link REQ quebrado.** `ROADMAP-2026-06-20-codex-agent-integrations.md` (árvore A) aponta para `REQ-2026-06-20-attention-hooks-agent-clis.md`, que não existe em nenhuma das três árvores.
4. **`.trackfw-log` preso à árvore A** (`docs/roadmaps/.trackfw-log`) — o histórico de transições das 62 peças das árvores B e C nunca foi gravado.
5. **`CLAUDE.md` do repo documenta a árvore A** como se fosse a realidade, o que induz erro em qualquer sessão futura.

### Contexto de origem

O repositório tem apenas 2 commits, ambos de 2026-06-28, e os artefatos entraram todos num único commit inicial. Os roadmaps citam paths de outra máquina (`/Users/kgsaran/Sistemas/…`). O estado de governança é **herdado de um snapshot upstream**, não é trabalho em andamento do mantenedor atual.

## Requisitos

### R1 — `trackfw.yaml` pinando a realidade
Criar `trackfw.yaml` na raiz declarando a árvore B como canônica: `req_dir: docs/requisições`, `roadmap_dir: docs/roadmaps`, `roadmap_namespacing: by_agent`, `agents: [apolo, artemis, claude]`, `adr_dirs: [docs/adr]`, `wip_limit: 1`.

O schema em `internal/config/config.go` já suporta todas essas chaves — nenhuma mudança de código do produto é necessária.

### R2 — Migração das árvores A e C para a B
Mover, preservando histórico via `git mv`:
- `docs/roadmaps/wip/ROADMAP-2026-06-20-codex-agent-integrations.md` → namespace `claude`
- `docs/roadmaps/done/ROADMAP-2026-06-20-gate-pre-trabalho-…md` → `docs/roadmaps/claude/done/`
- `docs/roadmap/artemis/done/*.md` (2 arquivos) → `docs/roadmaps/artemis/done/`

Remover os diretórios vazios remanescentes (`docs/req/`, `docs/roadmap/`, `docs/roadmaps/{wip,done}/`).

### R3 — REQ retroativa para o roadmap órfão
Criar `docs/requisições/claude/REQ-2026-06-20-attention-hooks-agent-clis.md`, reconstruída a partir do conteúdo do próprio roadmap (que já traz a tabela de hook por CLI e a estratégia), com data de origem 2026-06-20 e nota explícita de reconstrução retroativa.

### R4 — Fechamento dos 3 roadmaps em WIP herdados
Os três descrevem trabalho já presente no código dos três runtimes:

| Roadmap | Evidência |
|---|---|
| `trackfw-update-command-2026-06-18` | cópia byte-idêntica já existe em `done/`; `update` está no `--help` do CLI |
| `architect-command-guidelines-2026-06-19` | `architect.md` em `internal/generators/scaffold.go:306`, `npm/src/generators/init.js:831`, `pypi/trackfw/generators/init_gen.py:463` |
| `codex-agent-integrations-2026-06-20` | `codex.*` e `hooks.*` presentes em `internal/generators/`, `npm/src/generators/`, `pypi/trackfw/generators/` |

Mover os dois primeiros para `done/`; o `trackfw-update-command` em `wip/` é duplicata byte-idêntica da cópia em `done/` e deve ser removido, não movido.

**Limitação assumida:** a verificação foi por inspeção do entregável principal em cada runtime, não critério de aceite a critério de aceite.

### R5 — Documentação alinhada
`CLAUDE.md` do repositório descreve a árvore A. Atualizar a seção de domínio de governança para refletir os caminhos reais e o `roadmap_namespacing: by_agent`.

## Critérios de Aceite

- [x] `trackfw.yaml` existe na raiz e `trackfw status` enxerga as 62 peças das árvores B e C
- [x] `docs/req/`, `docs/roadmap/`, `docs/roadmaps/wip/` e `docs/roadmaps/done/` não existem mais
- [x] Nenhum artefato fora de `docs/adr/`, `docs/requisições/<agente>/` e `docs/roadmaps/<agente>/`
- [x] `REQ-2026-06-20-attention-hooks-agent-clis.md` existe e o warning de link quebrado sumiu
- [x] `trackfw status` reporta exatamente 1 roadmap em WIP (o desta REQ)
- [x] `trackfw validate` com **zero warnings** (10 → 0)
- [ ] `trackfw validate` com zero violations — **não atingido**: 20 → 5. As 5 restantes são
      `req_has_adr` e exigem ADRs que não existem no repositório. Ver Residual no roadmap.
- [x] `CLAUDE.md` descreve os caminhos reais
- [x] `go build ./...` verde e nenhuma mudança de código do produto foi necessária
- [ ] `go test ./...` verde — **não atingido**: 10 falhas em `internal/generators`, pré-existentes
      e específicas de Windows, confirmadamente independentes deste trabalho. Ver Residual.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md
