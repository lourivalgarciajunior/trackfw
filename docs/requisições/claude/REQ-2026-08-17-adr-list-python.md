---
id: REQ-2026-08-17-adr-list-python
title: Portar adr list para o Python e alinhar o parser de status nos três
status: approved
priority: medium
type: feature
created: 2026-08-17
author: claude
---

# REQ: `adr list` no Python

Roadmap: docs/roadmaps/claude/done/adr-list-python-2026-08-17.md

## Problema

`adr list` existe em Go e Node.js desde `REQ-adr-wizard-e-list-2026-06-11` e nunca foi portado para
o Python. Foi uma das cinco divergências que `check-subcommand-parity.sh` revelou ao nascer, em
`REQ-2026-08-17-gate-paridade-subcomando`, e está declarada no allowlist daquele gate.

## O que apareceu ao investigar

Portar exige decidir de onde o status vem — e aí se descobre que **Go e Node.js já discordam entre
si**. Com uma ADR cujo corpo contém uma tabela mencionando `| Status: `:

```
ADR-x.md    quebrado     ← Go: varre o arquivo inteiro, a ULTIMA ocorrencia vence
ADR-x.md    Accepted     ← Node.js: varre o arquivo inteiro, a PRIMEIRA vence
```

Nenhum dos dois lê o `status:` do frontmatter, que é onde o valor canônico está — é o campo que o
`adr new` grava e que o validator usa.

É a mesma família de defeito que `parseREQMeta` e `parseREQStatus` tinham, corrigida em
`REQ-2026-08-17-resolvedor-req-unificado` e `REQ-2026-08-17-req-list-python`. Aqui ela estava
latente: nenhuma ADR deste repositório tem tabela com esse texto, então as duas saídas coincidiam
por acidente.

Portar sem resolver isso acrescentaria uma **terceira** resposta possível para a mesma pergunta.

## Requisitos

### R1 — `adr list` no Python, com a mesma saída dos outros dois
Nome do arquivo em coluna de 60 caracteres, status à direita. Comparação byte a byte contra Go e
Node.js é o critério.

### R2 — Parser de status alinhado nos três
Contrato único, o mesmo já adotado para REQ: o `status:` do frontmatter é a fonte preferida; na
ausência dele, a linha de cabeçalho `> … | Status: …`, parando no primeiro `## `. Corpo do arquivo
nunca decide o status.

O Python nasce correto; Go e Node.js são corrigidos para o mesmo contrato.

### R3 — Remover a declaração do gate
Com `adr list` nos três, `adr:python:list:faltando` sai do allowlist de
`check-subcommand-parity.sh`. O gate precisa passar sem ela.

### R4 — Mensagem de vazio idêntica
`No ADRs found in <dir>`.

## Limitação herdada, registrada e não corrigida

`ListADRs` recebe `cfg.ADRDirs[0]` e faz glob flat: lista apenas o **primeiro** diretório de ADR
configurado, sem recursão. O validator, por outro lado, usa `walkADRFiles`, que percorre **todos** os
`adr_dirs` recursivamente.

Ou seja: `adr list` mostra menos do que o `validate` enxerga — a mesma classe de problema que existia
para REQ antes de `REQ-2026-08-17-resolvedor-req-unificado`.

Não é corrigido aqui. O port mantém o comportamento dos outros dois, porque paridade é o objetivo
desta REQ; unificar o resolvedor de ADR é trabalho próprio, com o mesmo formato daquele que já foi
feito para REQ. Neste repositório não há diferença observável: `adr_dirs` tem uma entrada só e as
ADRs são planas.

## Critérios de Aceite

- [x] `python -m trackfw adr list` existe e aparece em `adr --help`
- [x] Saída byte a byte idêntica à do Go e à do npm neste repositório
- [x] Os três dão a mesma resposta para uma ADR com `| Status: ` no corpo
- [x] Status vem do frontmatter quando existe; cai para o cabeçalho quando não
- [x] Diretório sem ADR produz a mesma mensagem nos três
- [x] `adr:python:list:faltando` removida do allowlist e o gate passa
- [x] Teste por runtime cobrindo a fonte do status e o caso do corpo
- [x] Quatro gates passam; suítes dos três sem falha nova
