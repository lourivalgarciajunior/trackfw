---
name: resolvedor-req-unificado-2026-08-17
title: "Unificar os três resolvedores de REQ"
status: done
date: 2026-08-17
req: REQ-2026-08-17-resolvedor-req-unificado
branch: feat/resolvedor-req-unificado
---

# Roadmap: resolvedor de REQ unificado

> Created: 2026-08-17 | Status: done

REQ: `docs/requisições/claude/REQ-2026-08-17-resolvedor-req-unificado.md`

## Diagnóstico / Contexto

Três resolvedores de REQ com alcances diferentes: `ListREQs` vê 0 das 36, `resolveREQFiles` vê 5, e
`findREQ` — escrito em `REQ-2026-08-17-req-move` — vê as 36. Medição e consequência assumida estão
na REQ.

**O gate fica vermelho ao fim desta entrega, de propósito.** Não é regressão: é o `validate`
passando a olhar 86% do corpus que ignorava. O destino das violações reveladas é decisão separada,
que esta entrega não toma — ela mede e registra.

## Critérios de Aceite

- [x] Um resolvedor por runtime, com os consumidores delegando a ele
- [x] `req list` mostra as 40, agrupadas por agente e estado (Go e npm; Python não tem o comando)
- [x] Violações reveladas medidas por regra e registradas
- [x] Sem falha nova nas suítes; três gates passam
- [x] Baseline aplicado, gate verde nos três, ratchet funcionando

---

## Wave 1 — Go

### ML-1 — Pacote do resolvedor + os três consumidores
**Status:** ✅ Concluído
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
- [x] `go build ./...`, `go vet ./...` e `gofmt` limpos
- [x] `req list` mostra as 40 REQs agrupadas por agente e estado — antes respondia
      "No REQs found" (as 36 originais mais as 4 criadas nesta sessão)
- [x] Nenhuma lógica de caminho de REQ fora de `internal/reqs`

**Escopo acrescentado: `parseREQMeta`.** Com o `req list` finalmente listando algo, a coluna de
status apareceu como lixo — a função varria o arquivo inteiro atrás de `| Status: ` e a **última**
ocorrência vencia, então qualquer tabela ou trecho de corpo com esse texto sobrescrevia o valor.
Reescrita para preferir o `status:` do frontmatter e, na ausência dele, ler só a linha de cabeçalho,
parando no primeiro `## `. Bug pré-existente que estava escondido atrás do resolvedor quebrado.
**Comandos de validação:** `go build ./... && go test ./internal/reqs/ ./internal/generators/ ./internal/validator/`

### ML-2 — Medir o que a unificação revela
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (medição)
**Ações:**
1. `trackfw validate --json` e contagem por regra.
2. Registrar o número exato neste roadmap — é o insumo da decisão seguinte.
**Critérios de aceite:**
- [x] Contagem por regra registrada:

```
44 violações, 0 avisos

25  req_has_adr        req "…" has no linked ADR
18  req_has_roadmap    req "…" has no linked Roadmap
 1  req_frontmatter    req "…" has no frontmatter block
```

- [x] Nenhuma violação de tipo inesperado — as três são regras de REQ, exatamente as que nunca
      haviam rodado sobre as 31 invisíveis
- [x] **Correção da minha estimativa:** eu havia projetado 53 contando linhas `ADR:` e `Roadmap:`
      ausentes por grep. O número real é **44**. A diferença vem de a regra `req_has_roadmap` não
      disparar para toda REQ sem link — algumas já eram contadas, e o grep não reproduzia as
      condições da regra. Estimativa por grep não substitui medição.

---

## Wave 2 — Espelhar

### ML-3 — Node.js
**Status:** ✅ Concluído
**Arquivos afetados:** `npm/src/reqs.js` (NOVO), `npm/src/generators/req.js`,
`npm/src/validator/*.js`, `npm/tests/reqs.test.js` (NOVO)
**Ações:** mesmo desenho do ML-1.
**Critérios de aceite:**
- [x] `npm/src/reqs.js` criado; `resolveReqFiles`, `listREQs` e `findREQ` delegam a ele
- [x] `req list` mostra as 40 agrupadas, com o mesmo status do Go
- [x] `parseREQStatus` teve o mesmo defeito do `parseREQMeta` e a mesma correção — varria o
      arquivo inteiro e a primeira ocorrência de `| Status: ` vencia
- [x] Suítes npm sem falha nova: 16 + 8 + 7 + 3 verdes

### ML-4 — Python
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/reqs.py` (NOVO), `pypi/trackfw/generators/req.py`,
`pypi/trackfw/validator.py`, `pypi/tests/test_reqs.py` (NOVO)
**Ações:** mesmo desenho do ML-1.
**Critérios de aceite:**
- [x] `pypi/trackfw/reqs.py` criado; `resolve_req_files` e `find_req` delegam a ele
- [x] `validate` do Python passa a reportar as mesmas 44 violações
- [x] **`req list` não existe no runtime Python** — só `new` e `move`. Não havia o que unificar
      ali; registrado como lacuna de paridade, fora do escopo desta REQ
- [x] `pytest tests/` sem falha nova: 299 passed

---

## Wave 3 — Fechamento

### ML-5 — Paridade e gates
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. Fixture única: contagem de REQs resolvidas nas três formas, nos três runtimes.
2. `check-validate-parity.sh` — os três precisam produzir as mesmas violações.
3. Suítes dos três; nenhuma falha nova além das já conhecidas.
**Critérios de aceite:**
- [x] Mesmo alcance nos três: **44 violações** em Go, npm e Python
- [x] Os três gates passam
- [x] Go zero falhas, `vet` limpo, `gofmt -l` zero; npm 34 testes; pypi 299 passed

### Baseline aplicado (decisão do usuário)

`trackfw baseline` congelou as 44. O gate volta a rc=0 nos três, e violação **nova** continua sendo
acusada — verificado criando uma REQ sem ADR nem roadmap: os três a apontam.

**Bug de interoperabilidade achado ao aplicar.** O Python estourava com
`TypeError: 'NoneType' object is not iterable` ao ler um baseline gravado pelo Go: slice nil vira
`null` no JSON, e `baseline.get("warnings", [])` devolve `None` quando a chave existe com valor
nulo. Corrigido dos dois lados — o Go passa a gravar `[]` em vez de `null`, e o Python usa
`or []` para tolerar baselines já existentes no mundo. O `.trackfw-baseline.json` é artefato
compartilhado entre os três runtimes; nenhum gate cobria isso.
**Comandos de validação:** `bash scripts/check-validate-parity.sh && go test ./...`
