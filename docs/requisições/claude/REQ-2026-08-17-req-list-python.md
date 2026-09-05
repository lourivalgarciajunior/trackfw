---
adr: "docs/adr/ADR-2026-09-05-paridade-tri-runtime-e-a-regra-de-que-nenhuma-mudanca-de-comportamento-entra-num-cli-so.md"
id: REQ-2026-08-17-req-list-python
title: Comando req list no runtime Python
status: done
priority: medium
type: feature
created: 2026-08-17
author: claude
---

# REQ: `req list` no Python

Roadmap: docs/roadmaps/claude/done/req-list-python-2026-08-17.md

## Problema

O runtime Python não tem `req list`. Só `req new` e `req move`. Go e Node.js têm o comando desde
sempre, e desde `REQ-2026-08-17-resolvedor-req-unificado` os dois listam as 40 REQs agrupadas por
agente e estado, com saída idêntica entre si.

A lacuna apareceu durante aquela unificação: ao espelhar o resolvedor no Python, não havia
consumidor de listagem para adaptar. Ficou registrada e é o que esta REQ fecha.

O CLI Python é o que roda como `pip install trackfw`. Quem usa esse pacote hoje não tem como listar
as REQs do próprio projeto pela ferramenta.

### Por que os gates não pegaram

`check-cli-parity.sh` compara o conjunto de **comandos de primeiro nível** e a saída de `version`.
Não desce em subcomando. `req` existe nos três, então a paridade passa mesmo com `list` faltando em
um deles — do mesmo jeito que passava com `move` faltando nos três antes de
`REQ-2026-08-17-req-move`.

## Requisitos

### R1 — `req list` com a mesma saída dos outros dois
Agrupamento por `[agente/estado]`, nome do arquivo em coluna de 60 caracteres, status à direita.
Comparação byte a byte contra a saída do Go é o critério.

### R2 — Parser de status equivalente
O Python não tem parser de status de REQ — Go tem `parseREQMeta` e npm tem `parseREQStatus`, ambos
corrigidos em `REQ-2026-08-17-resolvedor-req-unificado` para preferir o `status:` do frontmatter e
parar no primeiro `## `.

A versão Python nasce já com o comportamento correto; o defeito de varrer o arquivo inteiro não
deve ser reproduzido.

### R3 — Usar o resolvedor unificado
`trackfw.reqs.all_reqs`, o mesmo que o `validate` e o `move` do Python já usam. Nenhuma lógica de
caminho nova.

### R4 — Sem REQ nenhuma, mensagem igual à dos outros
`No REQs found in <req_dir>`.

## Critérios de Aceite

- [x] `python -m trackfw req list` existe e aparece em `req --help`
- [x] Saída byte a byte idêntica à do Go e à do npm neste repositório
- [x] Status vem do frontmatter quando existe; cai para a linha de cabeçalho quando não
- [x] Corpo do arquivo nunca sobrescreve o status
- [x] Diretório vazio produz a mesma mensagem dos outros dois
- [x] Teste cobrindo agrupamento, fonte do status e caso vazio
- [x] `pytest tests/` sem falha nova; três gates passam

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-paridade-tri-runtime-e-a-regra-de-que-nenhuma-mudanca-de-comportamento-entra-num-cli-so.md
