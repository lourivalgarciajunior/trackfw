---
name: cli-python-utf8-windows-2026-08-16
title: "CLI Python força UTF-8 na saída e para de quebrar no Windows"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-cli-python-utf8-windows
branch: fix/cli-python-utf8-windows
---

# Roadmap: CLI Python UTF-8 no Windows

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-cli-python-utf8-windows.md`

## Diagnóstico / Contexto

Console Windows entrega `sys.stdout.encoding = cp1252`; o CLI escreve `→`, `✓`, `⚙`, `──` e texto
acentuado. `--help`, `status` e `validate` morrem com `UnicodeEncodeError`. Go e Node.js não sofrem
porque escrevem bytes UTF-8 direto — o comportamento correto já é o deles. Medição por comando e
por runtime está na REQ.

Origem: item 3 da lista de dívida de `REQ-2026-08-16-consolidar-arvores-governanca`, onde apareceu
como atrito para rodar os gates de paridade. A investigação mostrou que o atrito no gate era a
ponta: os dois comandos mais usados da ferramenta estão quebrados no runtime Python.

Correção só no Python — os outros dois já fazem o certo.

## Critérios de Aceite

- [ ] `--help`, `status` e `validate` retornam rc=0 sem variável de ambiente
- [ ] `check-cli-parity.sh` e `check-validate-parity.sh` passam sem prefixo
- [ ] Suíte pypi sem falha nova; `go test ./...` segue com zero falhas
- [ ] Teste cobrindo `sys.stdout` sem `reconfigure`

---

## Wave 1 — Correção e teste

### ML-1 — Reconfigurar stdout/stderr para UTF-8 no entry point
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/trackfw/cli.py`
**Ações:**
1. Criar helper `_force_utf8_output()` que reconfigura `sys.stdout` e `sys.stderr` para
   `encoding="utf-8", errors="replace"`.
2. Guardar com `hasattr(stream, "reconfigure")` e `try/except` — testes e pipelines trocam
   `sys.stdout` por objetos que não têm o método.
3. Chamar no topo de `main()`, antes de qualquer construção de parser ou escrita.
4. Documentar no código por que UTF-8 e não a codificação do console: é o que Go e Node.js já
   fazem, e é o único jeito de imprimir os glifos que a ferramenta usa.
**Critérios de aceite:**
- [ ] `python -m trackfw --help`, `status`, `validate` com rc=0 e sem variável de ambiente
- [ ] Nenhum `UnicodeEncodeError` na saída
**Comandos de validação:** `cd pypi && python -m trackfw --help && python -m trackfw status`

### ML-2 — Teste do helper
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/tests/test_cli_encoding.py` (NOVO)
**Ações:**
1. Teste que substitui `sys.stdout` por um objeto sem `reconfigure` e chama o helper, asseverando
   que não levanta.
2. Teste que substitui por um duplo que registra a chamada, asseverando `encoding="utf-8"` e
   `errors="replace"`.
3. Teste de ponta a ponta por subprocesso: roda `python -m trackfw --help` com `PYTHONIOENCODING`
   forçado a `cp1252` e assevera rc=0 — reproduz o console Windows de forma determinística, em
   qualquer sistema onde a suíte rodar.
**Critérios de aceite:**
- [ ] Os três testes passam
- [ ] O teste de subprocesso falha se o ML-1 for revertido (não-vacuoso)
**Comandos de validação:** `cd pypi && python -m unittest tests.test_cli_encoding`

---

## Wave 2 — Fechamento

### ML-3 — Gates sem prefixo e suítes
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `bash scripts/check-cli-parity.sh` e `check-validate-parity.sh` **sem** `PYTHONIOENCODING` nem
   `PYTHONUTF8`.
2. Suíte pypi: comparar com a baseline de 6 errors + 1 failure pré-existentes.
3. `go test ./...` continua com zero falhas.
**Critérios de aceite:**
- [ ] Gates passam sem prefixo
- [ ] Nenhuma falha nova em pypi; Go segue verde
**Comandos de validação:** `bash scripts/check-cli-parity.sh && bash scripts/check-validate-parity.sh`
