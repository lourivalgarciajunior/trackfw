---
status: backlog
date: 2026-08-29
req: REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node
squad: ""
---

# Roadmap: Slug de artefato no Python diverge de Go e Node

> Created: 2026-08-29 | Status: backlog

## Context

Os tres runtimes geram nomes de arquivo diferentes para o mesmo titulo quando ele contem
caractere nao-alfanumerico que nao seja espaco. Python **deleta** os nao-alfanumericos; Go e Node
os **substituem por hifen**. Medido com `adr new` em diretorio limpo por runtime:
`acao-cc-cafe` (Python) contra `acao-c-c-cafe` (Go e Node).

REQ: docs/requisições/claude/REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node.md

## Acceptance Criteria

- [ ] Os tres runtimes produzem o mesmo nome de arquivo para o mesmo titulo, em execucao real do CLI
- [ ] A regra escolhida documentada em `docs/cli-parity.md`, com o motivo
- [ ] `check-artifact-parity.sh` cobre `/` e `+`, e **falha** com a divergencia reintroduzida
- [ ] Vale para `adr new`, `req new` e `roadmap new`

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** pending
**Files affected:**
**Actions:**
1. Enumeration completeness — is the list of surfaces in this roadmap complete? Name what is missing, or show the list is closed. Do not limit the search to the files already named by the REQ — before declaring the list closed, search the repository for other places that emit the same artifact or the same pattern (for example, grep for the literal the final artifact contains).
2. Threat model — who empties this Wave 0 without breaking any written rule, and how?
3. Falsification targets in both directions — for each surface, what breaks when the behavior regresses, and what breaks when it regresses the opposite way?
4. Declared residual — what this design accepts not covering.
**Acceptance criteria:**
- [ ] The four sections above answered with evidence, not a one-line assertion
- [ ] No implementation line written for this ML

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
exit 1  # placeholder gate fails closed until ML-0A replaces it — see docs/cli-parity.md
```

## Wave 1 — Alinhar a regra
> Dependencies: ML-0A

### ML-1A — Decidir e documentar a regra de colapso
**Status:** pending
**Files affected:** `docs/cli-parity.md`
**Actions:**
1. Escolher entre colapso por hifen (Go e Node, hoje 2 contra 1) e delecao (Python).
2. Registrar a decisao e o motivo. Colapso por hifen preserva a fronteira de palavra —
   `C/C++` vira `c-c` e nao `cc` — o que argumenta a favor dele, mas a decisao e explicita.
**Acceptance criteria:**
- [ ] Regra escrita em `docs/cli-parity.md` com o motivo, nao so o comportamento

### ML-1B — Alinhar o runtime divergente
**Status:** pending
**Files affected:** `pypi/trackfw/generators/{adr,req,roadmap}.py` (ou os tres de Go e Node,
conforme a decisao de ML-1A)
**Actions:**
1. Aplicar a regra decidida.
2. Verificar em execucao real do CLI, um diretorio limpo por runtime, para `adr`, `req` e `roadmap`.
**Acceptance criteria:**
- [ ] Os tres produzem nome identico para o mesmo titulo, nos tres comandos
- [ ] `go build ./...` verde; suites sem regressao contra a medicao de 2026-08-29

## Wave 2 — Fechar o buraco do gate
> Dependencies: ML-1B

### ML-2A — Ampliar a fixture de `check-artifact-parity.sh`
**Status:** pending
**Files affected:** `scripts/check-artifact-parity.sh`
**Actions:**
1. Incluir `/` e `+` no `TITLE` da linha 43 — hoje e `"Autenticacao e Sessao"`, so acento, que e
   exatamente por que o gate passa enquanto o defeito existe.
**Acceptance criteria:**
- [ ] Gate passa com a correcao
- [ ] Gate **falha** com a divergencia reintroduzida — nao-vacuidade verificada, nao assumida
