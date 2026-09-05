---
adr: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md
id: REQ-2026-08-16-adrs-retroativas
title: Escrever as ADRs retroativas das 5 REQs sem decisão registrada
status: done
priority: medium
type: chore
created: 2026-08-16
author: claude
---

> **Corrigida em 2026-09-05.** Passava `req_has_adr` **por acidente** — `ADR:` aparecia na
> prosa e o `contentHasMarker` casa o marcador em qualquer posição do arquivo. Não havia
> link de ADR. Ver REQ-2026-09-05-reqs-que-passam-so-por-prosa e kgsaran/trackfw#278.

# REQ: ADRs retroativas

Roadmap: docs/roadmaps/claude/done/adrs-retroativas-2026-08-16.md

## Problema

O repositório não tem **nenhuma** ADR. Cinco REQs disparam `req_has_adr`, rebaixada para `warning`
em `REQ-2026-08-16-consistencias-template-saida-e-eol` justamente porque não havia como satisfazê-la:

- `REQ-req-wizard-e-list-2026-06-11`
- `REQ-roadmap-ai-generation-2026-06-11`
- `REQ-2026-06-14-serve-api-tests-nodejs`
- `REQ-multi-ai-support-2026-06-11`
- `REQ-req-driven-adr-discovery-2026-06-12`

O primeiro elo da cadeia `ADR → REQ → ROADMAP` nunca foi materializado. As decisões arquiteturais
existem — estão no código — mas não estão escritas em lugar nenhum onde alguém as encontre.

## Método: reconstruir de evidência, não do enunciado

ADR retroativa tem um risco óbvio: escrever a decisão que a REQ *pediu* em vez da que o código
*tomou*. Cada ADR aqui é reconstruída de três fontes — o texto da REQ, o roadmap correspondente e o
código que existe hoje — e **o código vence** quando divergem.

Todas trazem nota de reconstrução retroativa no corpo. Nenhuma se apresenta como escrita à época.

### O método já pagou: a REQ de geração por IA

`REQ-roadmap-ai-generation-2026-06-11` está marcada `status: done` e especifica um pacote
`internal/ai/` com clientes Anthropic e OpenAI, `anthropic-sdk-go` no `go.mod` e fallback por chave
de API.

**Nada disso existe.** Verificado: não há `internal/ai/`, nenhuma menção a `anthropic`/`openai` no
código Go, nenhuma dependência de IA no `go.mod`, nenhum tratamento de chave de API. O roadmap
correspondente está em `done/` com **todos os MLs `⬜ Pendente`**.

O que existe é `roadmap new --from-req`, que deriva os MLs dos critérios de aceite da REQ de forma
determinística, sem LLM. A ADR registra essa decisão — a que vale no código — e não a que a REQ
pediu.

Isso é, por si, um achado de governança: uma REQ marcada como entregue para trabalho que não
aconteceu. Registrado aqui, fora do escopo desta entrega.

## Requisitos

### R1 — Uma ADR por REQ, com a decisão que o código sustenta
Cinco ADRs em `docs/adr/`, no formato que `trackfw adr new` gera: frontmatter com `status`, `date`,
`author`; seções Context, Decision, Consequences e Alternatives Considered.

### R2 — Status `Accepted`
As decisões estão em produção há meses. `Draft` ou `Proposed` acionaria `blocked_by_draft_adr`, que
é `error` — e seria falso: nada está pendente.

### R3 — Nota de reconstrução em cada uma
Data real de escrita, origem da reconstrução e o que foi verificado no código. Quem ler daqui a um
ano precisa saber que a ADR foi escrita depois do fato.

### R4 — Link bidirecional
Cada REQ ganha a linha `ADR:` apontando para sua ADR, e cada ADR nomeia a REQ que a originou. Sem
isso o `req_has_adr` continua acusando.

### R5 — Regra de volta para `error`
Com as cinco cobertas, `req_has_adr` volta a ser `error` no `trackfw.yaml`. Foi rebaixada por falta
de saída, não por discordância da regra.

## Critérios de Aceite

- [x] 5 ADRs em `docs/adr/`, com `status: Accepted` e as quatro seções
- [x] Cada ADR traz nota de reconstrução retroativa com o que foi verificado
- [x] Cada uma das 5 REQs tem linha `ADR:` apontando para a sua
- [x] `req_has_adr` de volta a `error` no `trackfw.yaml`
- [x] `trackfw validate` com zero violações **e** zero avisos
- [x] `go test ./...` zero falhas; suítes npm e pypi verdes; três gates passam

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md
