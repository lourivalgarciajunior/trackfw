---
status: Open
date: 2026-10-04
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou-e-acusaria-criterio-justificado.md"
---

# REQ: o nosso gate de REQ done nao conhece a forma canonica Caducou: e acusaria criterio justificado

> Date: 2026-10-04 | Status: Open
| Linear Issue: 
| Jira Issue: 

## Motivation

O [#519](https://github.com/kgsaran/trackfw/pull/519) do upstream — que implementa a **nossa**
[#514](https://github.com/kgsaran/trackfw/issues/514) — definiu a forma canônica do critério
caducado, e ela é **a do nosso precedente**: a caixa continua `- [ ]` e ganha uma linha de
continuação.

```
- [ ] <critério>
  Caducou: <justificativa obrigatória>
```

O produto passou a contar `acceptance.lapsed` à parte, e o `unmet` ficou **estrito**: só conta
`- [ ]` **sem** continuação `Caducou:` válida.

🔴 **O nosso gate não conhece a forma.** Medido em 2026-10-04:

```
grep -ci caducou scripts/check-req-done-com-criterio-aberto.sh   ->  0
```

Ele conta checkbox aberto sob bloco de critério e para ali. Consequência concreta e imediata: os
**4 roadmaps** que a varredura de caducidade deixou em `backlog/` — os *"entregues com critério de
verificação permanentemente inverificável"* — só podem ir para `done/` se as REQs ligadas forem
`Done`, e isso exige fechar o critério. Com a forma canônica isso deixou de exigir mentir… **para o
produto**. Para o nosso gate, não: ele acusaria a REQ `Done` mesmo com a justificativa escrita no
padrão que o produto definiu.

**O gate vira, então, o único instrumento que recusa a saída que o produto passou a oferecer** — e
foi este gate que, na varredura, me impediu de fabricar histórico. Ele não deve ser enfraquecido:
deve aprender a forma.

## Acceptance Criteria

- [ ] AC1 — O gate reconhece a continuação `Caducou:` com as **mesmas quatro bordas** que o produto
      mede (`docs/cli-parity.md`, D3 da `ADR-2026-10-04`): justificativa **obrigatória** após os
      dois-pontos; linha **imediatamente** após o `- [ ]`, sem linha em branco intercalada;
      **≥ 2 espaços** de indentação; e `Caducou:` **dentro de cerca de código é ignorado**.
      🔴 Paridade com o produto é o critério, não "uma heurística que funcione": divergir de
      borda faria o nosso gate e o `validate` discordarem sobre o mesmo arquivo.
- [ ] AC2 — Falsificado **nas duas direções**, por efeito: `Caducou:` válido **não** acusa; e cada
      uma das quatro bordas violada **continua** acusando, uma por uma. Sem o segundo braço, "o gate
      aprendeu a forma" é indistinguível de "o gate parou de contar".
- [ ] AC3 — A guarda de vacuidade do gate continua: se o denominador de REQs varridas for zero, ele
      falha nomeando o motivo em vez de passar descrevendo o vazio.
- [ ] AC4 — As **4 REQs** que travam os 4 roadmaps recebem `Caducou:` nos critérios inverificáveis,
      com a justificativa que **já está escrita** no veredito de cada roadmap — não uma nova.
- [ ] AC5 — Os 4 roadmaps vão para `done/` e as 4 REQs para `Done`, com `validate` em 0 violações e
      o nosso gate em 0 achados. Medido antes e depois, com o `lapsed` subindo onde o `unmet` caiu.
- [ ] AC6 — O `CLAUDE.md` registra a forma canônica na seção do gate, para que a próxima varredura
      não reabra a análise do zero.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

A ADR decide que **este repositório é governado pelo próprio trackfw**, e é dela que sai a
consequência aplicada aqui: quando o produto define uma forma de artefato de governança, o nosso
gate local segue a forma do produto em vez de manter uma própria.

🔴 **O limite da citação:** a ADR não decide nada sobre critério caducado, que não existia quando ela
foi escrita. O que ela governa é **de quem é a forma**; a paridade de bordas é decisão desta REQ.

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou-e-acusaria-criterio-justificado.md
