---
status: Accepted
date: 2026-08-17
author: claude
---

# ADR: `req move` resolve as três formas de organização, e loga em arquivo próprio

> Date: 2026-08-17 | Status: Accepted

REQ: REQ-2026-08-17-req-move

## Context

O `roadmap move` opera num modelo simples: a pasta é o estado, e todo roadmap vive em
`<roadmap_dir>[/<agente>]/<estado>/`. Não há terceira possibilidade.

A REQ não tem essa disciplina. Neste repositório as REQs vivem em duas formas ao mesmo tempo — 31
direto em `docs/requisições/claude/` e 5 em subpasta de estado — e em modo `flat` existe ainda uma
terceira, `<req_dir>/*.md`. Os dois resolvedores que existem hoje cobrem formas diferentes e
incompletas: `ListREQs` glob só a raiz (vê 0 das 36 aqui), `resolveREQFiles` glob só
`<agente>/<estado>` (vê 5).

Duas decisões precisavam ser tomadas antes de escrever o comando: **onde procurar** e **onde
registrar a transição**.

## Decision

**O resolvedor cobre as três formas.** `req move` procura a REQ, nesta ordem, em
`<req_dir>/<agente>/<estado>/*.md`, `<req_dir>/<agente>/*.md` e `<req_dir>/*.md`. Em `by_agent`, o
agente de origem é preservado no destino: uma REQ em `apolo/done/` vai para `apolo/abandoned/`, não
para o primeiro agente da lista.

Isso significa que `req move` enxerga REQs que o `validate` não enxerga. É assimetria assumida — e o
lado certo dela: um comando que não encontra o arquivo que o usuário está vendo é pior que um
comando que encontra mais do que o gate. Corrigir os outros dois resolvedores é trabalho separado,
com consequência de governança própria (levaria o `validate` deste repo de 0 para 53 violações).

**A transição vai para `<req_dir>/.trackfw-log`**, arquivo distinto do log de roadmaps, com o mesmo
formato de linha.

`trackfw log` e `trackfw metrics` leem `<roadmap_dir>/.trackfw-log` e derivam lead time e throughput
tratando cada linha como transição de roadmap. Misturar REQs ali contaminaria as métricas de forma
silenciosa — um número que fica errado sem ninguém perceber é pior que um número que não existe.

## Consequences

**Positivas.** O comando funciona em qualquer repositório real, incluindo os que misturam as duas
formas — que é o caso deste. O agente preservado evita que mover uma REQ a mude de dono. E as
métricas de roadmap continuam íntegras.

**Negativas.** Passa a haver dois resolvedores de REQ com alcances diferentes no mesmo código: o do
`req move`, correto, e o do `validate`, parcial. Enquanto os dois existirem, o comportamento é
confuso de explicar — mover uma REQ pode torná-la visível ao gate, o que é um efeito colateral
surpreendente.

O log de REQ também nasce sem leitor: nenhum comando exibe `<req_dir>/.trackfw-log` hoje. É dívida
deliberada — preservar a história custa uma linha, reconstruí-la depois é impossível.

## Alternatives Considered

**Reusar `resolveREQFiles` como está.** Zero código novo e um resolvedor só. Descartada porque o
comando falharia em 31 das 36 REQs deste repositório — incluindo todas as criadas nesta sessão.
Entregar um `req move` que não acha a REQ que o usuário quer mover não é entregar o comando.

**Corrigir `resolveREQFiles` e `ListREQs` junto, unificando tudo num resolvedor.** É o destino
correto. Descartada nesta entrega porque muda o que o `validate` reporta — de 0 para 53 violações
neste repo — e isso é decisão de governança de quem mantém o projeto, não efeito colateral de um
comando novo.

**Logar no `.trackfw-log` de roadmaps, com prefixo distinguindo o tipo.** Um arquivo só, história
unificada. Descartada porque `ParseLog` não conhece prefixo: as linhas de REQ entrariam nas métricas
como se fossem roadmaps, distorcendo lead time e throughput sem sinal nenhum.
