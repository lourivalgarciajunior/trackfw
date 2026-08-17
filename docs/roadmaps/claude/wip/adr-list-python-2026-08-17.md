---
name: adr-list-python-2026-08-17
title: "adr list no Python e parser de status alinhado nos três"
status: wip
date: 2026-08-17
req: REQ-2026-08-17-adr-list-python
branch: feat/adr-list-python
---

# Roadmap: adr list no Python

> Created: 2026-08-17 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-17-adr-list-python.md`

## Diagnóstico / Contexto

`adr list` nunca foi portado para o Python — divergência que o gate de subcomando revelou ao nascer.
Ao investigar o port, apareceu que **Go e Node.js já discordam entre si** sobre de onde vem o
status: com tabela no corpo, o Go devolve a última ocorrência e o npm a primeira, e nenhum lê o
frontmatter. Medição na REQ.

Portar sem resolver isso acrescentaria uma terceira resposta.

## Critérios de Aceite

- [ ] `adr list` no Python, saída byte a byte igual à dos outros dois
- [ ] Os três concordam para uma ADR com `| Status: ` no corpo
- [ ] Declaração removida do allowlist do gate, e o gate passa
- [ ] Suítes e quatro gates verdes

---

## Wave 1 — Alinhar o contrato

### ML-1 — Parser de status nos três
**Status:** ⬜ Pendente
**Arquivos afetados:** `internal/generators/adr.go`, `npm/src/generators/adr.js`,
`pypi/trackfw/generators/adr.py`
**Ações:**
1. Contrato único, o mesmo já adotado para REQ: frontmatter primeiro; na ausência, a linha
   `> … | Status: `, parando no primeiro `## `.
2. Go: reescrever `parseADRMeta`. Node.js: reescrever o equivalente. Python: nasce correto.
3. Teste em cada runtime com o caso da tabela no corpo — é o que distingue os três hoje.
**Critérios de aceite:**
- [ ] Os três devolvem o mesmo status para a mesma ADR com tabela no corpo
- [ ] Frontmatter vence o cabeçalho quando os dois existem e divergem
**Comandos de validação:** `go test ./internal/generators/ -run ADR`

### ML-2 — `adr list` no Python
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/trackfw/generators/adr.py`, `pypi/trackfw/commands/adr.py`,
`pypi/tests/test_adr_list.py` (NOVO)
**Ações:**
1. `list_adrs(adr_dir)` — glob flat no primeiro `adr_dir`, igual aos outros dois. A limitação é
   herdada de propósito; está registrada na REQ.
2. Registrar `adr list` no argparse e no dispatch.
3. Teste: listagem, fonte do status, corpo que não decide, diretório vazio.
**Critérios de aceite:**
- [ ] `adr list` aparece no `adr --help` e funciona
- [ ] Saída byte a byte igual à do Go e do npm

---

## Wave 2 — Fechamento

### ML-3 — Gate e verificação
**Status:** ⬜ Pendente
**Arquivos afetados:** `scripts/check-subcommand-parity.sh`
**Ações:**
1. Remover `adr:python:list:faltando` do allowlist.
2. Conferir que o gate passa sem ela e que as outras quatro declarações continuam válidas.
3. `diff` das três saídas; fixture com diretório vazio; suítes e os quatro gates.
**Critérios de aceite:**
- [ ] Allowlist com 4 entradas, todas ainda reais
- [ ] `diff` vazio entre os três
- [ ] Quatro gates passam; suítes sem falha nova
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh`
