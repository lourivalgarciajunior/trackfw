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

- [x] `--help`, `status` e `validate` retornam rc=0 sem variável de ambiente
- [x] `check-cli-parity.sh` e `check-validate-parity.sh` passam sem prefixo
- [x] Suíte pypi sem falha nova; `go test ./...` segue com zero falhas
- [x] Teste cobrindo `sys.stdout` sem `reconfigure`

---

## Wave 1 — Correção e teste

### ML-1 — Reconfigurar stdout/stderr para UTF-8 no entry point
**Status:** ✅ Concluído
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
- [x] `--help`, `status`, `validate` e `version` com rc=0, sem variável de ambiente
- [x] Nenhum `UnicodeEncodeError` na saída; `→` e `—` renderizam corretos
**Comandos de validação:** `cd pypi && python -m trackfw --help && python -m trackfw status`

### ML-2 — Teste do helper
**Status:** ✅ Concluído
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
- [x] Os cinco testes passam (2 de unidade + 3 de subprocesso)
- [x] Não-vacuoso: removendo a chamada do ML-1, `FAILED (failures=3)`
**Comandos de validação:** `cd pypi && python -m unittest tests.test_cli_encoding`

---

## Wave 2 — Fechamento

### ML-4 — Encoding explícito em `open()` nos testes
**Status:** ✅ Concluído
**Escopo acrescentado.** Não estava previsto: só apareceu quando a suíte passou a rodar sem
`PYTHONUTF8=1` e revelou um `UnicodeEncodeError` que não era de stdout, mas de **escrita de
arquivo** — `open(log_path, "w")` sem `encoding`, gravando uma linha com `→`. O default de `open()`
no Windows é cp1252.
**Arquivos afetados:** `pypi/tests/test_commands_extras.py`, `pypi/tests/test_validator.py`
**Ações:**
1. Auditar todo `open()` sem `encoding=` no runtime Python.
2. **Produção está limpa** — a única ocorrência é `serve.py:101` com `"rb"`, binário, onde
   `encoding` não se aplica. O defeito era só nos testes: 5 chamadas.
3. Acrescentar `encoding="utf-8"` nas 5.
**Critérios de aceite:**
- [x] Nenhum `open()` sem `encoding` nos testes, exceto binário
- [x] Produção auditada e confirmada limpa
**Comandos de validação:** `grep -rnE 'open\([^)]*["'"'"'][rwa]' pypi/ --include=*.py | grep -v encoding=`

---

### ML-3 — Gates sem prefixo e suítes
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `bash scripts/check-cli-parity.sh` e `check-validate-parity.sh` **sem** `PYTHONIOENCODING` nem
   `PYTHONUTF8`.
2. Suíte pypi: comparar com a baseline de 6 errors + 1 failure pré-existentes.
3. `go test ./...` continua com zero falhas.
**Critérios de aceite:**
- [x] `check-cli-parity.sh`, `check-validate-parity.sh` e `check-static-assets.sh` passam **sem**
      `PYTHONIOENCODING` nem `PYTHONUTF8`
- [x] Suíte pypi sem prefixo bate a baseline exata: 6 errors + 1 failure
- [x] `go test ./...` segue com zero falhas

**Correção de leitura sobre a baseline.** O "6 errors + 1 failure" citado nas entregas anteriores
foi medido **com `PYTHONUTF8=1`**. Sem o prefixo, o número real era 22 errors — os 16 extras eram o
mesmo `UnicodeEncodeError`, em funções de biblioteca (`scaffold`, `generate_claude_commands`)
chamadas direto pelos testes, sem passar pelo `main()`. O `tests/__init__.py` deste ML resolve.

**Os 6 erros de loader estão explicados**, não só contados: são 6 módulos que fazem `import pytest`,
e pytest não está instalado neste ambiente. Ambiental, não defeito de código.

**Invocação da suíte.** Com `tests/__init__.py`, a suíte precisa ser importada como pacote:
`python -m unittest discover -s tests -t .` ou `pytest tests/` (o comando documentado no
`CLAUDE.md`). A forma `discover -s tests` sem `-t .` insere `tests/` no `sys.path` e importa os
módulos como top-level, pulando o `__init__.py` — e aí os 16 erros voltam.
**Comandos de validação:** `bash scripts/check-cli-parity.sh && bash scripts/check-validate-parity.sh`
