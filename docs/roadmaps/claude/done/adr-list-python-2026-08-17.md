---
name: adr-list-python-2026-08-17
title: "adr list no Python e parser de status alinhado nos três"
status: done
date: 2026-08-17
req: REQ-2026-08-17-adr-list-python
branch: feat/adr-list-python
---

# Roadmap: adr list no Python

> Created: 2026-08-17 | Status: done

REQ: `docs/requisições/claude/REQ-2026-08-17-adr-list-python.md`

## Diagnóstico / Contexto

`adr list` nunca foi portado para o Python — divergência que o gate de subcomando revelou ao nascer.
Ao investigar o port, apareceu que **Go e Node.js já discordam entre si** sobre de onde vem o
status: com tabela no corpo, o Go devolve a última ocorrência e o npm a primeira, e nenhum lê o
frontmatter. Medição na REQ.

Portar sem resolver isso acrescentaria uma terceira resposta.

## Critérios de Aceite

- [x] `adr list` no Python, saída byte a byte igual à dos outros dois
- [x] Os três concordam para uma ADR com `| Status: ` no corpo
- [x] Declaração removida do allowlist do gate, e o gate passa
- [x] Suítes e quatro gates verdes

---

## Wave 1 — Alinhar o contrato

### ML-1 — Parser de status nos três
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/adr.go`, `npm/src/generators/adr.js`,
`pypi/trackfw/generators/adr.py`
**Ações:**
1. Contrato único, o mesmo já adotado para REQ: frontmatter primeiro; na ausência, a linha
   `> … | Status: `, parando no primeiro `## `.
2. Go: reescrever `parseADRMeta`. Node.js: reescrever o equivalente. Python: nasce correto.
3. Teste em cada runtime com o caso da tabela no corpo — é o que distingue os três hoje.
**Critérios de aceite:**
- [x] Os três devolvem `Accepted` para a ADR com tabela no corpo — antes o Go dizia `quebrado` e o
      npm dizia `Accepted`
- [x] Frontmatter vence o cabeçalho quando divergem
- [x] 4 testes no Go e 5 no Python cobrindo frontmatter, cabeçalho, tabela no corpo e ausência
- [x] `bufio` saiu do `adr.go` — a reescrita passou a ler o arquivo inteiro em vez de scanner
**Comandos de validação:** `go test ./internal/generators/ -run ADR`

### ML-2 — `adr list` no Python
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/generators/adr.py`, `pypi/trackfw/commands/adr.py`,
`pypi/tests/test_adr_list.py` (NOVO)
**Ações:**
1. `list_adrs(adr_dir)` — glob flat no primeiro `adr_dir`, igual aos outros dois. A limitação é
   herdada de propósito; está registrada na REQ.
2. Registrar `adr list` no argparse e no dispatch.
3. Teste: listagem, fonte do status, corpo que não decide, diretório vazio.
**Critérios de aceite:**
- [x] `adr list` aparece no `adr --help` e funciona
- [x] Saída **byte a byte** igual à do Go e do npm neste repositório
- [x] Diretório sem ADR: `No ADRs found in docs/adr` nos três
- [x] A linha de uso do dispatch também passou a citar `list`, não só `new`

---

## Wave 2 — Fechamento

### ML-3 — Gate e verificação
**Status:** ✅ Concluído
**Arquivos afetados:** `scripts/check-subcommand-parity.sh`
**Ações:**
1. Remover `adr:python:list:faltando` do allowlist.
2. Conferir que o gate passa sem ela e que as outras quatro declarações continuam válidas.
3. `diff` das três saídas; fixture com diretório vazio; suítes e os quatro gates.
**Critérios de aceite:**
- [x] `adr:python:list:faltando` removida; allowlist com 4 entradas, todas ainda reais — o gate
      não emitiu aviso de declaração obsoleta
- [x] `diff` vazio entre os três
- [x] Os quatro gates passam
- [x] Go zero falhas; npm 24 testes; pypi **315 passed**; `trackfw validate` rc=0
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh`
