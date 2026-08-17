---
id: REQ-2026-08-17-req-move
title: Comando req move nos três runtimes
status: approved
priority: medium
type: feature
created: 2026-08-17
author: claude
---

# REQ: `req move`

Roadmap: req-move-2026-08-17.md
ADR: ADR-2026-08-17-req-move-resolve-as-tres-formas.md

## Problema

O roadmap tem transição de estado como comando de primeira classe — `trackfw roadmap move <nome>
<estado>`. A REQ não tem nada equivalente, em nenhum dos três runtimes: só `req new` e `req list`.

A assimetria não é cosmética. O validator conhece o ciclo de estados da REQ — `resolveREQFiles`
varre `backlog`, `wip`, `blocked`, `done` e `abandoned` sob cada agente. Ou seja: o modelo prevê que
a REQ transite, mas a ferramenta não oferece o comando. Mover uma REQ hoje é `git mv` à mão mais
edição do frontmatter — foi exatamente o que precisei fazer para abandonar
`REQ-roadmap-ai-generation-2026-06-11`.

## O que a implementação esbarra

Escrever `req move` exige resolver "onde está a REQ", e essa camada está quebrada de duas formas
diferentes neste repositório. Medido em 2026-08-17:

| resolvedor | o que varre | vê quantas das 36 REQs |
|---|---|---|
| `req list` (`ListREQs`) | `reqDir/*.md` | **0** — ignora `by_agent` inteiro |
| `validate` (`resolveREQFiles`) | `reqDir/<agente>/<estado>/*.md` | **5** — ignora `reqDir/<agente>/*.md` |

As REQs deste repo vivem em duas formas ao mesmo tempo: 31 direto em `docs/requisições/claude/` e 5
em subpasta de estado. Confirmado com fixture: uma REQ em `claude/backlog/` é validada, uma em
`claude/` não é — e o comportamento é idêntico nos três runtimes, então é bug replicado, não quebra
de paridade.

**Isto é reportado, não corrigido aqui.** Tornar as 31 visíveis levaria o `validate` de 0 para 53
violações (31 `req_has_adr` + 22 `req_has_roadmap`) — é decisão de governança, não de implementação,
e merece REQ própria.

O que esta REQ faz é entregar um resolvedor **correto para o `req move`**, que encontra a REQ nas
três formas. Ele fica disponível para quem for consertar `list` e `validate` depois.

## Requisitos

### R1 — `req move <nome> <estado>` nos três runtimes
Estados: `backlog`, `wip`, `blocked`, `done`, `abandoned` — os mesmos cinco que o
`resolveREQFiles` já varre. Match parcial por nome, como no `roadmap move`. Erro claro quando não
encontra ou quando o nome é ambíguo.

### R2 — Resolver as três formas
`reqDir/*.md` (flat), `reqDir/<agente>/*.md` (by_agent sem estado) e `reqDir/<agente>/<estado>/*.md`
(by_agent com estado). Em `by_agent`, o agente é preservado no destino.

### R3 — Sincronizar `status:` e a linha humana
Mesmo contrato do `roadmap move`, reaproveitando os helpers já existentes: reescreve o `status:` do
frontmatter e o trecho após `| Status: ` na linha de cabeçalho, e **só** se já existirem. Arquivo
sem frontmatter sai byte a byte idêntico.

### R4 — Registrar a transição
Linha em `<req_dir>/.trackfw-log`, mesmo formato do log de roadmaps. Arquivo separado de propósito:
`trackfw log` e `trackfw metrics` leem `<roadmap_dir>/.trackfw-log` e calculam lead time sobre
roadmaps — misturar REQs ali corromperia a métrica. Nenhum comando lê o log de REQs ainda;
registrado como pendência.

### R5 — Paridade verificada
Mesmo exit code e mesmo arquivo resultante nos três, nas três formas de origem.

## Critérios de Aceite

- [ ] `req move <nome> <estado>` existe e funciona nos três runtimes
- [ ] Encontra a REQ nas três formas de organização
- [ ] Em `by_agent`, o agente é preservado no destino
- [ ] `status:` e linha humana sincronizados; arquivo sem frontmatter intocado
- [ ] Estado inválido e nome ambíguo dão erro claro com exit ≠ 0
- [ ] Transição registrada em `<req_dir>/.trackfw-log`
- [ ] Teste por runtime, cada um confirmado não-vacuoso
- [ ] `check-cli-parity.sh` reconhece o comando novo nos três
- [ ] Suítes dos três runtimes verdes; `trackfw validate` limpo
