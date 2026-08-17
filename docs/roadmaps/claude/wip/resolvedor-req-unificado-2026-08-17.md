---
name: resolvedor-req-unificado-2026-08-17
title: "Unificar os três resolvedores de REQ"
status: wip
date: 2026-08-17
req: REQ-2026-08-17-resolvedor-req-unificado
branch: feat/resolvedor-req-unificado
---

# Roadmap: resolvedor de REQ unificado

> Created: 2026-08-17 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-17-resolvedor-req-unificado.md`

## Diagnóstico / Contexto

Três resolvedores de REQ com alcances diferentes: `ListREQs` vê 0 das 36, `resolveREQFiles` vê 5, e
`findREQ` — escrito em `REQ-2026-08-17-req-move` — vê as 36. Medição e consequência assumida estão
na REQ.

**O gate fica vermelho ao fim desta entrega, de propósito.** Não é regressão: é o `validate`
passando a olhar 86% do corpus que ignorava. O destino das violações reveladas é decisão separada,
que esta entrega não toma — ela mede e registra.

## Critérios de Aceite

- [ ] Um resolvedor por runtime, com os três consumidores delegando a ele
- [ ] `req list` mostra as 36, agrupadas por agente e estado
- [ ] Violações reveladas medidas por regra e registradas
- [ ] Sem falha nova nas suítes; três gates passam

---

## Wave 1 — Go

### ML-1 — Pacote do resolvedor + os três consumidores
**Status:** ⬜ Pendente
**Arquivos afetados:** `internal/reqs/resolve.go` (NOVO), `internal/reqs/resolve_test.go` (NOVO),
`internal/validator/validator.go`, `internal/generators/req.go`, `internal/commands/req.go`
**Ações:**
1. Criar `internal/reqs` importando apenas `internal/config` — `generators` já importa `validator`,
   então o resolvedor não pode morar em nenhum dos dois sem criar ciclo.
2. Expor `States`, `Files(cfg)` e `Find(cfg, name)`, movendo para lá a lógica que hoje está em
   `findREQ`.
3. `resolveREQFiles` e `findREQ` viram casca sobre o pacote. `ListREQs` passa a receber `cfg` e usar
   `Files`, agrupando por agente e estado.
4. Teste do pacote cobrindo as três formas, ambiguidade e não-encontrada.
**Critérios de aceite:**
- [ ] `go build ./...`, `go vet ./...` e `gofmt` limpos
- [ ] `trackfw req list` mostra as 36 REQs agrupadas
- [ ] Nenhuma lógica de caminho de REQ fora de `internal/reqs`
**Comandos de validação:** `go build ./... && go test ./internal/reqs/ ./internal/generators/ ./internal/validator/`

### ML-2 — Medir o que a unificação revela
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (medição)
**Ações:**
1. `trackfw validate --json` e contagem por regra.
2. Registrar o número exato neste roadmap — é o insumo da decisão seguinte.
**Critérios de aceite:**
- [ ] Contagem por regra registrada
- [ ] Nenhuma violação de tipo inesperado (só as regras de REQ)

---

## Wave 2 — Espelhar

### ML-3 — Node.js
**Status:** ⬜ Pendente
**Arquivos afetados:** `npm/src/reqs.js` (NOVO), `npm/src/generators/req.js`,
`npm/src/validator/*.js`, `npm/tests/reqs.test.js` (NOVO)
**Ações:** mesmo desenho do ML-1.
**Critérios de aceite:**
- [ ] `node npm/tests/reqs.test.js` verde
- [ ] `node npm/bin/trackfw req list` mostra as 36

### ML-4 — Python
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/trackfw/reqs.py` (NOVO), `pypi/trackfw/generators/req.py`,
`pypi/trackfw/validator.py`, `pypi/tests/test_reqs.py` (NOVO)
**Ações:** mesmo desenho do ML-1.
**Critérios de aceite:**
- [ ] `python -m unittest tests.test_reqs` verde
- [ ] `python -m trackfw req list` mostra as 36

---

## Wave 3 — Fechamento

### ML-5 — Paridade e gates
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. Fixture única: contagem de REQs resolvidas nas três formas, nos três runtimes.
2. `check-validate-parity.sh` — os três precisam produzir as mesmas violações.
3. Suítes dos três; nenhuma falha nova além das já conhecidas.
**Critérios de aceite:**
- [ ] Mesmo alcance nos três
- [ ] Gates passam; suítes sem falha nova
**Comandos de validação:** `bash scripts/check-validate-parity.sh && go test ./...`
