---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-sete-roadmaps-do-upstream-orfaos-em-wip-flat-invisiveis-ao-by-agent.md"
---

# REQ: Sete roadmaps do upstream órfãos em `wip/` flat, invisíveis ao `by_agent`

> Date: 2026-09-05 | Status: Done

## Motivation

Fui medir o marcador `REQ:` — a única superfície que eu tinha declarado **não** ter verificado ao
fechar a REQ da prosa — e o caminho passou por `wip_has_req`, que só avalia roadmaps em `wip/`.

O kanban diz `wip 0`. O disco diz outra coisa:

```
docs/roadmaps/<agente>/wip/   0 roadmaps   <- o que a regra resolve
docs/roadmaps/wip/            7 roadmaps   <- flat, ninguem olha
```

Com `roadmap_namespacing: by_agent`, `resolveWIPDirs` resolve `docs/roadmaps/<agente>/wip`. O
diretório **flat** não entra em nenhum resolvedor, então esses 7 arquivos não são avaliados por regra
nenhuma — nem contados pelo `status`, nem varridos pelo `validate`.

**São do upstream.** Entraram por merges de 2026-09-02/03 — `3f07546`, `3e2cf11`, `f15aa69` e
irmãos —, **antes** de o `scripts/upstream-sync.sh` existir. No repositório dele, os sete já estão em
`docs/roadmaps/done/`. Aqui ficaram parados em `wip/`, num layout que a nossa config não lê.

Medido: **zero REQs deste acervo os referenciam.** São órfãos completos.

Pela `ADR-2026-08-29`, governança do upstream não é importada. Estes sete não deveriam estar aqui —
e a única razão de nunca terem incomodado é justamente a que os torna preocupantes: **nada os
enxerga**.

### O que isto diz sobre o gate

`wip_has_req` hoje tem denominador **zero** neste repositório. Ele reporta verde sobre nada, duas
vezes: os diretórios que resolve estão vazios, e os arquivos que existem estão fora do que ele
resolve.

É a mesma vacuidade do `✓ No violations found` sobre 7 de 53 REQs — agora numa regra que nunca
acendeu.

### E o marcador `REQ:`, que era a pergunta original

Medido sobre os 76 roadmaps do acervo:

| categoria | n |
|---|---|
| o gate **acusaria**, se estivessem em `wip/` | 24 |
| `REQ:` ancorado com valor (legítimo) | 40 |
| passa **só por prosa** | **12** |
| passa sem valor nenhum | 0 |

O mesmo defeito do `ADR:` existe no `REQ:` — 12 roadmaps passariam por citarem `REQ:` no texto. Hoje
não causam verde falso porque estão em `done/`, e a regra só olha `wip/`. **É latente, não ativo.**

## Acceptance Criteria

- [x] **AC1** — Os 7 roadmaps órfãos saem de `docs/roadmaps/wip/`. Falsificação prévia obrigatória:
      zero REQs deste acervo os referenciam **e** os 7 existem em `docs/roadmaps/done/` do upstream —
      as duas coisas medidas antes de remover.
- [x] **AC2** — Nenhum outro diretório de estado **flat** tem arquivo. Medido: `backlog`, `analyzing`,
      `blocked`, `done`, `abandoned` estão todos vazios; só `wip/` tinha.
- [x] **AC3** — `validate` sem violação **e** com denominador conferido: `status` continua reportando
      59 REQs e o total de roadmaps cai de 76 para 69.
- [x] **AC4** — Os 12 roadmaps que passam só por prosa ficam **registrados e não corrigidos**, com o
      motivo: estão em `done/`, a regra só avalia `wip/`, e o defeito é do gate — reportado no
      [#278](https://github.com/kgsaran/trackfw/issues/278). Corrigi-los agora seria mexer em 12
      arquivos para um verde que já é verde.
- [x] **AC5** — A medição do `REQ:` e o denominador zero do `wip_has_req` vão ao #278, fechando a
      superfície que eu tinha declarado não ter medido.
- [x] **AC6** — Nenhum arquivo de produto tocado.

## Negative Scope

- **Não** mover os 7 para `<agente>/done/`. Não são nossos: são governança do upstream, e a
  `ADR-2026-08-29` diz que ela não é importada. Adotá-los seria importar pela porta dos fundos.
- **Não** corrigir os 12 de prosa agora. Ver AC4.
- **Não** mudar a config para que o `by_agent` também leia o layout flat. Isso é produto, e a
  `ADR-2026-09-03` já decidiu que **leitura é união e escrita é única** — para roadmap, a união
  ainda não existe, e propô-la é issue, não mudança local.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-sete-roadmaps-do-upstream-orfaos-em-wip-flat-invisiveis-ao-by-agent.md
