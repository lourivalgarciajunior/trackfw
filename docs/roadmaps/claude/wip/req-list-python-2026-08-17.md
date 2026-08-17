---
name: req-list-python-2026-08-17
title: "Comando req list no runtime Python"
status: wip
date: 2026-08-17
req: REQ-2026-08-17-req-list-python
branch: feat/req-list-python
---

# Roadmap: req list no Python

> Created: 2026-08-17 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-17-req-list-python.md`

## Diagnóstico / Contexto

Go e npm têm `req list` e produzem saída idêntica entre si desde a unificação do resolvedor. O
Python não tem o comando. A lacuna apareceu ao espelhar o resolvedor: não havia consumidor de
listagem para adaptar. Detalhe e o motivo de os gates não pegarem estão na REQ.

Origem: lacuna registrada em `REQ-2026-08-17-resolvedor-req-unificado`.

## Critérios de Aceite

- [x] `req list` no Python, com saída byte a byte igual à do Go e do npm
- [x] Status do frontmatter primeiro; corpo nunca sobrescreve
- [x] Usa `trackfw.reqs.all_reqs`, sem lógica de caminho nova
- [x] Testes e gates verdes

---

## Wave 1 — Implementar

### ML-1 — Parser de status + `list_reqs` + subcomando
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/generators/req.py`, `pypi/trackfw/commands/req.py`,
`pypi/tests/test_req_list.py` (NOVO)
**Ações:**
1. `parse_req_status(path)` — frontmatter `status:` primeiro; na ausência, a linha `> … | Status: `,
   parando no primeiro `## `. Nasce com o comportamento corrigido; não reproduzir o defeito de
   varrer o arquivo inteiro.
2. `list_reqs(cfg)` — usa `reqs.all_reqs`, agrupa por `[agente/estado]`, coluna de 60 caracteres.
3. Registrar `req list` no argparse e no dispatch.
4. Testes: agrupamento, status do frontmatter, status do cabeçalho, corpo que não sobrescreve, e
   diretório vazio.
**Critérios de aceite:**
- [x] `req list` funciona e aparece no `req --help`
- [x] `python -m unittest tests.test_req_list` verde — 8 testes
- [x] `parse_req_status` nasceu correta: 4 testes garantem que o frontmatter vence e que o corpo
      nunca sobrescreve, inclusive numa tabela com `| Status: ` depois do primeiro `## `
**Comandos de validação:** `cd pypi && python -m unittest tests.test_req_list`

---

## Wave 2 — Fechamento

### ML-2 — Paridade byte a byte e gates
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `diff` da saída dos três runtimes neste repositório — precisa ser vazio.
2. Fixture com `req_dir` vazio: mesma mensagem nos três.
3. Suíte pypi e os três gates.
**Critérios de aceite:**
- [x] `diff` vazio entre os três — saída **byte a byte idêntica** neste repositório, 51 linhas
- [x] `req_dir` vazio: `No REQs found in docs/req` nos três
- [x] Go zero falhas; npm 31 testes; pypi **307 passed**
- [x] Os três gates passam; `trackfw validate` rc=0

**Escopo acrescentado: newline do CLI Python.** O `diff` acusou as 51 linhas como diferentes com o
conteúdo idêntico — o Python emitia CRLF no Windows enquanto Go e Node.js emitem LF. Não era do
`req list`: era de **toda** saída do CLI Python, desde sempre. `_force_utf8_output` reconfigurava a
codificação mas não o newline. Corrigido passando `newline` explícito ao `reconfigure`, com teste
próprio que assevera ausência de CRLF na saída.

**Nota de método.** Meu primeiro check de não-vacuosidade desse teste passou indevidamente: o script
que removia o fix não casou o padrão por causa de escape, e o teste rodou duas vezes com o fix
presente. Só percebi ao conferir o arquivo com `grep` em vez de confiar na saída do script. Refeito
com edição direta e `__pycache__` limpo: sem o fix, `FAILED (failures=1)`.
**Comandos de validação:** `bash scripts/check-cli-parity.sh`
