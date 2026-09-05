---
status: Open
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md"
---

# REQ: Dívida de governança do acervo — 42 violações, das quais 32 REQs sem ADR

> Date: 2026-09-05 | Status: Open

## Motivation

`trackfw validate` reprova com **42 violações e 5 avisos** nesta árvore, número estável há quatro
merges consecutivos do upstream. É dívida **nossa**, não do produto: nenhuma das 42 vem de código do
`kgsaran/trackfw`.

O ponto de partida importa. Antes de 2026-09-03 o `validate` dizia `✓ No violations found` — mas
avaliava **7 de 53** REQs, porque o resolvedor não cobria o layout `by_agent` deste fork. O verde era
**vacuidade**, não saúde. Depois da correção do resolvedor (upstream #259) o denominador virou 53 e a
dívida real apareceu de uma vez.

Composição medida em `a958b57`, com o binário da árvore:

| bloco | quantidade | mecanizável? |
|---|---|---|
| REQ sem ADR vinculada | **32** | ❌ exige julgamento por REQ |
| REQ sem roadmap resolvível | 9 | parcialmente |
| REQ `Open` com roadmap em `done/` | 4 (avisos) | ✅ |
| REQ sem frontmatter | 1 | ✅ |
| ADR não referenciada por nenhuma REQ | 1 (aviso) | ✅ |
| status fora de `open/done/closed` | 9 (visíveis em `Other`) | ✅ |

As 32 sem ADR são quase todas de **junho de 2026** — anteriores à adoção do upstream como base. Não
são esquecimento recente: são o acervo de antes da regra existir. Duas saídas legítimas por REQ, e a
escolha é do usuário: **ADR retroativa** (a decisão existiu, só não foi escrita) ou **abandono** (a
REQ não rege mais nada).

O custo de não resolver não é cosmético. `governance_mode: strict` no `trackfw.yaml` e 42 violações
significam que **o gate nunca passa**, então ele deixa de ser sinal: ninguém consegue distinguir
"quebrei algo agora" de "a dívida de junho continua lá". É a mesma classe do verde vacuoso, com o
sinal invertido — um vermelho permanente também não informa.

## Acceptance Criteria

- [ ] **AC1** — Os 4 blocos mecanizáveis (roadmap em `done/`, frontmatter ausente, ADR órfã, status
      fora do vocabulário) estão em **zero**. Falsificação: `trackfw validate` antes e depois, com o
      binário da árvore, e a diferença de contagem bate exatamente com a soma dos blocos tratados.
- [ ] **AC2** — Cada uma das **32 REQs sem ADR** recebeu um dos dois desfechos, com o motivo
      registrado: ADR retroativa vinculada, ou `status: abandoned`. **Nenhuma fica sem decisão.**
- [ ] **AC3** — `trackfw validate` sai com **exit 0** nesta árvore.
- [ ] **AC4** — Falsificação em duas direções: além de o gate passar, uma violação **plantada** de
      propósito (REQ nova sem ADR) tem de reprovar. Um gate que passa porque parou de olhar é o
      defeito que originou esta REQ.
- [ ] **AC5** — O `governance score` do `trackfw context` sai do patamar de **60/100** e o novo valor
      fica registrado no `docs/agents-working-context.md`.
- [ ] **AC6** — Nenhum arquivo de produto tocado. Falsificação:
      `git diff --name-only main upstream/main -- internal npm/src pypi/trackfw cmd .github Makefile`
      continua **vazio** (divergência de produto zero, medida em `a958b57`).

## Negative Scope

- **Não** alterar regra do `validate` para caber no acervo. Se uma regra estiver errada, isso é
  produto e vai para o upstream por issue — nunca afrouxada aqui.
- **Não** apagar REQ. `abandoned` é estado, e preserva o registro de que a decisão foi tomada.
- **Não** importar governança do upstream (ADR-2026-08-29).

## Linked ADR
ADR: docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-09-05-divida-de-governanca-do-acervo-42-violacoes-das-quais-32-reqs-sem-adr.md
