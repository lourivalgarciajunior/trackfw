---
id: REQ-2026-08-17-resolvedor-req-unificado
title: Unificar os três resolvedores de REQ
status: done
priority: high
type: bug
created: 2026-08-17
author: claude
---

# REQ: Resolvedor de REQ unificado

Roadmap: docs/roadmaps/claude/done/resolvedor-req-unificado-2026-08-17.md
ADR: docs/adr/ADR-2026-08-17-req-move-resolve-as-tres-formas.md

## Problema

Existem três resolvedores de REQ no mesmo código, com alcances diferentes. Medido neste
repositório, que tem 36 REQs:

| resolvedor | onde | o que varre | vê |
|---|---|---|---|
| `ListREQs` | `internal/generators/req.go` | `reqDir/*.md` | **0** |
| `resolveREQFiles` | `internal/validator/validator.go` | `reqDir/<agente>/<estado>/*.md` | **5** |
| `findREQ` | `internal/generators/req.go` | as três formas | **36** |

O terceiro é o único correto — foi escrito em `REQ-2026-08-17-req-move` justamente porque os dois
existentes não serviam. Os outros dois continuam quebrados, cada um de um jeito, e o comportamento
é idêntico nos três runtimes: bug replicado, invisível aos gates de paridade.

### O que cada defeito custa

**`req list` responde "No REQs found" num repositório com 36 REQs.** Ele ignora `by_agent` inteiro.

**O `validate` não olha 31 das 36 REQs.** Toda REQ que mora direto em `<req_dir>/<agente>/` — que é
a maioria aqui, incluindo todas as criadas nesta sessão — passa despercebida pelo gate. As regras
`req_has_adr`, `req_has_roadmap`, `req_frontmatter` e `blocked_by_draft_adr` nunca rodaram sobre
elas.

Isso qualifica o "zero violações" que este repositório vinha reportando: as regras que rodaram
passaram, mas o gate não estava olhando 86% do corpus.

## Consequência assumida

Unificar torna as 31 REQs visíveis ao `validate`. **O gate vai de 0 para dezenas de violações** —
estimado em 53 pela contagem de linhas `ADR:` e `Roadmap:` ausentes, a ser medido com precisão
depois da unificação.

Isso não é regressão: é o gate passando a fazer o que sempre deveria. Mas muda o estado do
repositório de verde para vermelho, e **o que fazer com as violações reveladas é decisão separada** —
escrever os artefatos faltantes, congelar com `trackfw baseline`, ou ajustar severidade de regra.
Esta REQ entrega o resolvedor correto e a medição; não decide o destino das violações.

## Requisitos

### R1 — Um resolvedor só, em pacote compartilhado
No Go, pacote novo importando apenas `internal/config`, consumível por `internal/validator` e
`internal/generators` sem ciclo — hoje `generators` importa `validator`, então o resolvedor não pode
morar em nenhum dos dois.

Expõe: a lista dos cinco estados, a resolução de todos os arquivos e a busca por nome com erro de
não-encontrada e de ambiguidade.

### R2 — Os três consumidores passam a usá-lo
`resolveREQFiles`, `ListREQs` e `findREQ` viram casca fina sobre o resolvedor. Nenhuma lógica de
caminho duplicada.

### R3 — `req list` mostra agente e estado
Com o resolvedor correto, listar só o nome do arquivo perde informação. Em `by_agent`, a saída
agrupa por agente e estado, como o `roadmap list` já faz.

### R4 — Paridade nos três runtimes
Mesmo alcance e mesma saída em Go, Node.js e Python.

### R5 — Medir e registrar
Número exato de violações reveladas, por regra, registrado no roadmap. É o insumo da decisão
seguinte.

## Critérios de Aceite

- [x] Um resolvedor por runtime; `resolveREQFiles`, `ListREQs` e `findREQ` delegam a ele
- [x] `req list` mostra as 36 REQs, agrupadas por agente e estado
- [x] `validate` passa a enxergar as 36
- [x] Violações reveladas medidas e registradas por regra
- [x] Teste por runtime cobrindo as três formas de organização
- [x] `go test ./...` sem falha nova; suítes npm e pypi sem falha nova
- [x] Os três gates de paridade passam
