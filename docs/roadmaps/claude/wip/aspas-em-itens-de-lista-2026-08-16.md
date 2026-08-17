---
name: aspas-em-itens-de-lista-2026-08-16
title: "Remover aspas de itens de lista em adr_dirs e agents"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-aspas-em-itens-de-lista
branch: fix/aspas-itens-de-lista
---

# Roadmap: aspas em itens de lista

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-aspas-em-itens-de-lista.md`

## Diagnóstico / Contexto

`adr_dirs:` e `agents:` são os dois únicos blocos do `trackfw.yaml` cujos itens de lista não têm as
aspas envolventes removidas — `acceptance_markers:`, `link_fields:`, `rules:` e os escalares
top-level todos removem. Com `by_agent`, um agente entre aspas faz o namespace inteiro sumir da
validação em silêncio. O diagnóstico completo, com a tabela por bloco e a medição, está na REQ.

Origem: encontrado ao investigar uma afirmação errada minha no corpo do PR #2, que dizia que o
parser Go não removia aspas no bloco `rules:`. Não é verdade — `splitKV` remove desde sempre. O
gap real estava nos itens de lista, onde ninguém tinha olhado. O corpo do PR #2 foi corrigido.

## Critérios de Aceite

- [ ] `- "claude"` e `- 'claude'` produzem o agente `claude` nos três runtimes
- [ ] `- "docs/adr"` produz o diretório `docs/adr` nos três runtimes
- [ ] Teste novo nos três runtimes
- [ ] Build e testes de config verdes nos três
- [ ] `check-cli-parity.sh` e `check-validate-parity.sh` passam

---

## Wave 1 — Correção por runtime (3 MLs independentes)

> Arquivos distintos por runtime; podem ser feitos em qualquer ordem. Go é a referência.

### ML-1 — Go: `adr_dirs` e `agents` + teste
**Status:** ⬜ Pendente
**Arquivos afetados:** `internal/config/config.go`, `internal/config/config_test.go`
**Ações:**
1. No bloco `if inADRDirs`, trocar `append(adrDirs, strings.TrimPrefix(trimmed, "- "))` por uma
   versão que aplique `strings.Trim(val, "\"'")` — mesmo tratamento de `inAcceptanceMarkers`.
2. Idem no bloco `if inAgents`.
3. Teste novo em `config_test.go`: `trackfw.yaml` com `adr_dirs` e `agents` usando aspas duplas e
   simples; asseverar valores limpos.
**Critérios de aceite:**
- [ ] `go build ./...` sem erros
- [ ] `go test ./internal/config/` verde, incluindo o teste novo
**Comandos de validação:** `go build ./... && go test ./internal/config/`

### ML-2 — Node.js: `adr_dirs` e `agents` + teste
**Status:** ⬜ Pendente
**Arquivos afetados:** `npm/src/config/index.js`, `npm/tests/config.test.js`
**Ações:**
1. Nos dois `if (line.startsWith('- '))` de `inAdrDirs` e `inAgents`, aplicar
   `.replace(/^["']|["']$/g, '')` — mesmo tratamento de `inAcceptanceMarkers`.
2. Teste equivalente ao do Go em `npm/tests/config.test.js`.
**Critérios de aceite:**
- [ ] `node --test npm/tests/config.test.js` verde
**Comandos de validação:** `cd npm && node --test tests/config.test.js`

### ML-3 — Python: `adr_dirs` e `agents` + teste
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/trackfw/config.py`, `pypi/tests/test_config.py`
**Ações:**
1. No bloco de itens de lista, trocar `adr_dirs.append(val)` e `agents.append(val)` por
   `.append(val.strip('"\''))` — mesmo tratamento de `acceptance_markers`.
2. Teste equivalente em `pypi/tests/test_config.py`.
**Critérios de aceite:**
- [ ] `python -m pytest pypi/tests/test_config.py` verde
**Comandos de validação:** `cd pypi && python -m pytest tests/test_config.py`

---

## Wave 2 — Fechamento

### ML-4 — Gates de paridade e verificação de ponta a ponta
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `go test ./...` — comparar o conjunto de falhas com a baseline conhecida (10 falhas
   pré-existentes de ambiente Windows em `internal/generators`, registradas em
   `REQ-2026-08-16-consolidar-arvores-governanca`). Nenhuma falha nova é aceitável.
2. `bash scripts/check-cli-parity.sh` e `bash scripts/check-validate-parity.sh`.
3. Verificação de ponta a ponta: rodar `validate` com `agents: - "claude"` e com `- claude`,
   confirmando o mesmo número de achados nos dois runtimes disponíveis.
4. `trackfw validate` limpo (gate verde, avisos herdados permitidos).
**Critérios de aceite:**
- [ ] Nenhuma falha de teste nova além das 10 pré-existentes
- [ ] Gates de paridade passam
- [ ] Contagem de achados idêntica com e sem aspas
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh && bash scripts/check-validate-parity.sh`
