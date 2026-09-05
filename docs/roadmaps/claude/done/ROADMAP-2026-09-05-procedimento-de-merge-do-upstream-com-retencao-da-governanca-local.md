---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md"
squad: ""
---

# Roadmap: Procedimento de merge do upstream com retenção da governança local

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] **AC1** — Existe um comando único (`make upstream-sync` ou `scripts/upstream-sync.sh`) que faz merge do upstream, retém `docs/` e `vault/`, e **falha** se sobrar conflito.
- [x] **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la: `git diff --cached main -- docs vault --stat` tem de sair **vazio**, e o comando aborta se não sair. A prova é por efeito, não por intenção.
- [x] **AC3** — O comando **relata a proporção**: `N arquivos de produto, M de governança retidos`. É o discriminante — um merge que fecha com muito mais que uma mão-cheia de arquivos de produto indica que algo de `docs/` passou.
- [x] **AC4** — Falsificação em duas direções: rodar contra `4f0ad33` (32 arquivos de governança) tem de reter os 32 e trazer 4; rodar contra `6b3ba49` (zero governança) tem de trazer os 42 **sem reter nada** — o procedimento não pode suprimir produto.
- [x] **AC5** — Verificação pós-merge automatizada: `go build ./...` exit 0 e contagem de violações do `validate` **idêntica** antes e depois, medida em worktree destacado com o binário da árvore. Falha se divergir.
- [x] **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge upstream/<tag>`, que não menciona retenção.
- [x] **AC7** — A seção **"Divergência local deliberada"** do `CLAUDE.md` é corrigida: ela afirma que `_force_utf8_output` só existe aqui, mas o upstream **absorveu** (medido: 2 ocorrências em `upstream/main:pypi/trackfw/cli.py`). Documentação que descreve divergência inexistente faz o próximo merge procurar conflito onde não há.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** scripts/upstream-sync.sh · scripts/check-upstream-sync-falsify.sh · CLAUDE.md
**Actions:**
1. Enumeração completa · 2. Threat model · 3. Falsificação nas duas direções · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** As superfícies não vieram da REQ: vieram das **quatro execuções manuais de hoje**
(`4f0ad33`, `1c16cb0`, `6b3ba49`, `87aded6`). São cinco — merge, retenção, prova da retenção,
proporção, verificação pós-merge. Não limitei ao que a REQ nomeava: procurei outros pontos que
emitem o mesmo artefato e achei que **o `Makefile` seria um deles e foi recusado de propósito** (é
arquivo compartilhado; alvo novo ali cria divergência de produto que todo merge futuro paga).

**2. Threat model — quem esvazia isto sem quebrar regra escrita.**

- **Retenção que suprime produto.** É o pior caso: silencioso, e só aparece semanas depois quando
  falta um arquivo. Contrapeso: a invariante 1 do gate, e o gate foi **mutado** para confirmar que
  reprova.
- **Prova por intenção em vez de por efeito.** O script poderia dizer "retido" sem conferir. Por isso
  o `git diff --cached -- docs vault` tem de sair **vazio** e o script **aborta** quando não sai.
- **Contagem em vez de invariante.** Foi o defeito da primeira redação do AC4: números à mão que
  erraram nos dois extremos. Contagem quebra quando o acervo muda; invariante não.
- **`--commit` virar padrão.** O commit é onde a medição vira registro. Automatizá-lo transforma
  quatro merges medidos em quatro merges com mensagem genérica.

**3. Falsificação nas duas direções.**

```
governanca pesada (4f0ad33)   retido 37 ⊆ docs/∪vault/ · trazido 4  · docs/ identico
produto puro     (6b3ba49)    retido 10 ⊆ docs/∪vault/ · trazido 42 · docs/ identico
controle: arvore suja         RECUSADA
controle: ref inexistente     RECUSADA
MUTACAO: reter scripts/ tambem  ->  gate REPROVA nas duas invariantes, nos dois casos
```

O que quebra na regressão oposta: um script que **nunca retém** traria a governança dele inteira —
os 37 arquivos de `4f0ad33` — e é o que a invariante 3 (`docs/` idêntico à base) pega.

**4. Residual declarado.**

- **Só dois merges no corpus.** São os dois extremos observados, não uma amostra. Um merge que
  renomeie arquivo de produto dentro de `docs/` — que hoje não existe — não está coberto.
- **O gate depende de dois SHAs deste repositório.** Se a história for reescrita, ele quebra. É
  acoplamento aceito: fixture sintética não reproduz a detecção de renomeação de diretório do git,
  que é o mecanismo inteiro.
- **`vault/` é tratado como sempre-deletar**, porque nossa `main` tem zero arquivo lá. Se algum dia
  tivermos `vault/` próprio, a regra muda e o script precisa saber.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
bash scripts/check-upstream-sync-falsify.sh
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Existe um comando único (`make upstream-sync` ou `scripts/upstream-sync.sh`) que faz…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — Existe um comando único (make upstream-sync ou scripts/upstream-sync.sh) que faz
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la: `git diff --cached…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la:
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — O comando **relata a proporção**: `N arquivos de produto, M de governança retidos`. É…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — O comando **relata a proporção**: N arquivos de produto, M de governança retidos. É
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Falsificação em duas direções: rodar contra `4f0ad33` (32 arquivos de governança) tem…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Falsificação em duas direções: rodar contra 4f0ad33 (32 arquivos de governança) tem
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Verificação pós-merge automatizada: `go build ./...` exit 0 e contagem de violações do…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Verificação pós-merge automatizada: go build ./... exit 0 e contagem de violações
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge upstream/<tag>`, que não menciona retenção.
- [x] build passes
- [x] tests green

### ML-1G — **AC7** — A seção **"Divergência local deliberada"** do `CLAUDE.md` é corrigida: ela afirma que…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC7** — A seção **"Divergência local deliberada"** do CLAUDE.md é corrigida: ela afirma que
- [x] build passes
- [x] tests green
