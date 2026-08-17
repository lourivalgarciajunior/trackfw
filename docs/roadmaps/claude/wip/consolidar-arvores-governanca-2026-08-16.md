---
name: consolidar-arvores-governanca-2026-08-16
title: "Consolidar as três árvores de artefato de governança em uma só"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-consolidar-arvores-governanca
branch: feat/consolidar-arvores-governanca
---

# Roadmap: consolidar árvores de governança

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-consolidar-arvores-governanca.md`

## Diagnóstico / Contexto

Três convenções de artefato coexistem em `docs/` e não há `trackfw.yaml` na raiz — o CLI roda no default (`docs/req`, `docs/roadmaps`, `flat`) e só enxerga 2 dos 66 artefatos. O diagnóstico completo, com a tabela das três árvores e as cinco consequências, está na REQ.

Decisão de rota (usuário, 2026-08-16): **Opção 1 — pinar a config na realidade** (mover 4 arquivos) em vez de migrar 62 para o default do produto. Preserva o histórico e o `git log` das peças existentes.

**Exceção consciente à regra de 1 WIP:** este roadmap nasce em `wip/` convivendo com os 3 roadmaps herdados que também estão em `wip/`. Isso é transitório e deliberado — o ML-3 deste próprio roadmap é justamente o que os retira de lá, restaurando `wip_limit: 1`. Sem essa exceção o trabalho não poderia começar, já que a violação só se torna visível depois do ML-1.

**Origem do estado:** o repo tem 2 commits (2026-06-28) e os artefatos vieram inteiros de um snapshot upstream — os roadmaps citam `/Users/kgsaran/Sistemas/…`. Nada aqui é trabalho parado do mantenedor atual.

---

## Wave 1 — Config e migração (sequencial)

> ML-2 depende do ML-1: sem o `trackfw.yaml` o CLI não valida os caminhos de destino.

## Critérios de Aceite

- [ ] `trackfw.yaml` existe na raiz e `trackfw status` enxerga as 62 peças das árvores B e C
- [ ] `docs/req/`, `docs/roadmap/`, `docs/roadmaps/wip/` e `docs/roadmaps/done/` não existem mais
- [ ] Nenhum artefato fora de `docs/adr/`, `docs/requisições/<agente>/` e `docs/roadmaps/<agente>/`
- [ ] `REQ-2026-06-20-attention-hooks-agent-clis.md` existe e o warning de link quebrado sumiu
- [ ] `trackfw status` reporta exatamente 1 roadmap em WIP (o deste roadmap)
- [ ] `CLAUDE.md` descreve os caminhos reais
- [ ] `go build ./...` e `go test ./...` verdes

---

### ML-1 — `trackfw.yaml` pinando a árvore B como canônica
**Status:** ✅ Concluído
**Arquivos afetados:** `trackfw.yaml` (NOVO)
**Ações:**
1. Criar `trackfw.yaml` na raiz com `adr_dirs: [docs/adr]`, `req_dir: docs/requisições`, `roadmap_dir: docs/roadmaps`, `roadmap_namespacing: by_agent`, `agents: [apolo, artemis, claude]`, `wip_limit: 1`, `governance_mode: strict`.
2. Conferir contra o schema em `internal/config/config.go` (`defaults()` e o `switch key`) que toda chave escrita é efetivamente parseada — chave desconhecida é silenciosamente ignorada pelo parser.
3. Rodar `trackfw status` e confirmar que as 62 peças das árvores B e C passaram a aparecer.
**Critérios de aceite:**
- [ ] `trackfw status` lista roadmaps de `docs/roadmaps/claude/`
- [ ] `trackfw status` acusa a violação de `wip_limit` que antes estava escondida
**Comandos de validação:** `trackfw status && trackfw validate`

### ML-2 — Migrar árvores A e C para a B
**Status:** 🔄 Em andamento
**Arquivos afetados:** 4 roadmaps movidos; `docs/req/`, `docs/roadmap/`, `docs/roadmaps/{wip,done}/` removidos
**Ações:**
1. `git mv docs/roadmaps/wip/ROADMAP-2026-06-20-codex-agent-integrations.md docs/roadmaps/claude/wip/`
2. `git mv docs/roadmaps/done/ROADMAP-2026-06-20-gate-pre-trabalho-…md docs/roadmaps/claude/done/`
3. `git mv docs/roadmap/artemis/done/*.md docs/roadmaps/artemis/done/` (2 arquivos, criar o diretório destino)
4. Remover os diretórios vazios: `docs/req/`, `docs/roadmap/`, `docs/roadmaps/wip/`, `docs/roadmaps/done/`.
5. Manter `docs/roadmaps/.trackfw-log` onde está — é o log do `roadmap_dir`, não de um namespace.
**Critérios de aceite:**
- [ ] Nenhum artefato fora de `docs/adr/`, `docs/requisições/<agente>/`, `docs/roadmaps/<agente>/`
- [ ] `git log --follow` continua resolvendo o histórico dos 4 arquivos movidos
**Comandos de validação:** `trackfw status && git status --short`

---

## Wave 2 — Fechar a cadeia herdada (sequencial)

### ML-3 — REQ retroativa + fechamento dos 3 WIPs herdados
**Status:** ⬜ Pendente
**Arquivos afetados:** `docs/requisições/claude/REQ-2026-06-20-attention-hooks-agent-clis.md` (NOVO); 3 roadmaps em `docs/roadmaps/claude/wip/`
**Ações:**
1. Escrever a REQ retroativa a partir do conteúdo do roadmap `codex-agent-integrations` (tabela de hook por CLI + estratégia já estão lá), com nota explícita de reconstrução retroativa.
2. `git rm docs/roadmaps/claude/wip/trackfw-update-command-2026-06-18.md` — é duplicata byte-idêntica da cópia em `done/` (confirmado por `diff` vazio e mesmo tamanho, 8004 bytes).
3. `git mv` de `architect-command-guidelines-2026-06-19.md` e `ROADMAP-2026-06-20-codex-agent-integrations.md` para `docs/roadmaps/claude/done/`, atualizando `status: wip` → `status: done` e o cabeçalho `Status: 🔄 WIP` → `Status: ✅ Done` em cada um.
4. Não marcar os MLs internos desses roadmaps como concluídos — o fechamento é por inspeção do entregável, não por execução; registrar isso no bloco Context de cada um.
**Critérios de aceite:**
- [ ] `trackfw status` reporta exatamente 1 roadmap em WIP (este)
- [ ] Warning de link REQ quebrado some do `trackfw validate`
**Comandos de validação:** `trackfw status && trackfw validate`

---

## Wave 3 — Fechamento

### ML-4 — Alinhar `CLAUDE.md` e fechar o gate
**Status:** ⬜ Pendente
**Arquivos afetados:** `CLAUDE.md`
**Ações:**
1. Atualizar a seção "The governance domain model" para os caminhos reais (`docs/requisições/<agente>/`, `docs/roadmaps/<agente>/`) e registrar `roadmap_namespacing: by_agent` como o modo deste repo.
2. Remover da seção "Conventions" a menção às três árvores paralelas (`docs/requisições`, `docs/roadmaps`, `docs/roadmap`) — agora é uma só.
3. `go build ./...` e `go test ./...` — nenhuma mudança de código do produto é esperada; serve de rede de segurança.
4. `trackfw validate` com zero violations **e** zero warnings.
**Critérios de aceite:**
- [ ] `CLAUDE.md` descreve os caminhos reais
- [ ] `go build ./...` e `go test ./...` verdes
- [ ] `trackfw validate` limpo
**Comandos de validação:** `go build ./... && go test ./... && trackfw validate`
