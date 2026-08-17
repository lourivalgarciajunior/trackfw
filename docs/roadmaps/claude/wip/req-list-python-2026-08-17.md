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

- [ ] `req list` no Python, com saída byte a byte igual à do Go e do npm
- [ ] Status do frontmatter primeiro; corpo nunca sobrescreve
- [ ] Usa `trackfw.reqs.all_reqs`, sem lógica de caminho nova
- [ ] Testes e gates verdes

---

## Wave 1 — Implementar

### ML-1 — Parser de status + `list_reqs` + subcomando
**Status:** ⬜ Pendente
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
- [ ] `python -m trackfw req list` funciona e aparece no `--help`
- [ ] `python -m unittest tests.test_req_list` verde
**Comandos de validação:** `cd pypi && python -m unittest tests.test_req_list`

---

## Wave 2 — Fechamento

### ML-2 — Paridade byte a byte e gates
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `diff` da saída dos três runtimes neste repositório — precisa ser vazio.
2. Fixture com `req_dir` vazio: mesma mensagem nos três.
3. Suíte pypi e os três gates.
**Critérios de aceite:**
- [ ] `diff` vazio entre os três
- [ ] Mensagem de vazio idêntica
- [ ] Suítes e gates verdes
**Comandos de validação:** `bash scripts/check-cli-parity.sh`
