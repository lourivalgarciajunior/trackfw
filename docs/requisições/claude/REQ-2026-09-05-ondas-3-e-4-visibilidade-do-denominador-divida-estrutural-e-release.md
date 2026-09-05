---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md"
---

# REQ: Ondas 3 e 4 — visibilidade do denominador, dívida estrutural e release

> Date: 2026-09-05 | Status: Done

## Motivation

As ondas 1 e 2 reportaram casos e classes. As ondas 3 e 4 do plano
(`docs/analises/2026-09-05-oportunidades-de-evolucao.md`) tratam de **visibilidade** — fazer o gate
dizer sobre quantos artefatos opinou — e de **dívida estrutural**.

O item de visibilidade (A1, `validate --coverage`) nasceu de um fato deste fork: `✓ No violations
found` avaliando **7 de 53** REQs. A proposta era acrescentar o denominador à saída.

**Ao medir para justificar a proposta, o defeito apareceu — e é maior que a proposta.** Não é que o
gate não mostre o denominador: é que o denominador está errado por um motivo que ninguém tinha
medido, e no acervo do próprio mantenedor.

## Restrição assumida: volume de issues

Ao começar esta onda havia **5 issues abertas com ele desde hoje de manhã**, nenhuma respondida.
Abrir mais oito seria transformar contribuição em ruído — e é exatamente a falha que o escopo
negativo da REQ da onda 1 previu: *"REQ que espera decisão de terceiro apodrece em backlog"*.

A decisão foi **entregar só o que produziu achado medido**, e registrar os demais aqui como
não-entregues, com o motivo. Dois dos oito itens saíram.

## Acceptance Criteria

- [x] **AC1 — A1 (visibilidade do denominador).** Entregue como **defeito medido**, não como proposta
      de flag: a detecção de marcador vazio compara com uma literal, e 5 de 7 grafias de vazio passam.
      Executado contra o acervo dele: o gate acusa **11** REQs sem ADR; são **69**. → [#278](https://github.com/kgsaran/trackfw/issues/278)
- [x] **AC2 — G2 (os `t.Skip`).** Entregue: **9 skips de classe plataforma sobraram do ML-4A**, em 4
      arquivos que a #269 não tocou, mais o inventário das duas classes (plataforma × dependência
      ausente). → [#279](https://github.com/kgsaran/trackfw/issues/279)
- [x] **AC3 — os demais itens ficam registrados como NÃO entregues, com o motivo.** Ver a seção
      abaixo. Item não entregue por decisão é desfecho; item não entregue por esquecimento é dívida.
- [x] **AC4** — Cada issue traz o achado medido, o controle na direção oposta, e a ressalva do que a
      medição **não** prova.
- [x] **AC5** — Nada mesclado na nossa `main` como produto. Divergência de produto continua **zero**.

## Itens NÃO entregues, e por quê

| item | por quê |
|---|---|
| **F3** `doctor --governance` | proposta de ferramenta sem defeito medido por trás. O `validate` já reporta as mesmas condições; a diferença seria de forma. Sem achado, não vale uma issue. |
| **G3** release `v7.4.0` | 42+ commits desde a v7.3.0, incluindo correção de segurança (#271). É observação factual, não achado — e a cadência de release é decisão dele, num repositório onde ele é o único mantenedor. Registrado aqui, não reportado. |
| **D1** cache por gate no `falsify` | exigiria medir o custo por gate no CI **dele** para dizer quanto o cache pouparia. Não tenho acesso ao runner, e um número de máquina local não transfere — foi a lição da #273, onde eu quase reportei 62% em vez de 9%. |
| **G1** quebrar os três `validator` | refatoração pura, sem defeito medido. O diff seria enorme e o risco é dele, não meu. Fica no plano. |
| **F1** vocabulário canônico de ML | o nosso acervo já está normalizado e o `validate` está limpo; medir o dele exigiria rodar o `barrier`, que leva ~16 min e depende do corpus acoplado — que é justamente o [#277](https://github.com/kgsaran/trackfw/issues/277). Bloqueado por outro item aberto. |
| **D2** Windows local para o mantenedor | não é issue: é o arranjo que já existe de fato. Este fork **é** o Windows dele há três dias, e sete achados saíram disso. Propor a formalização é conversa, não report. |

## Negative Scope

- **Não** abrir issue para item sem achado medido.
- **Não** propor o que ele já mediu e descartou.
- **Não** aplicar nada de produto na nossa `main`.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md
