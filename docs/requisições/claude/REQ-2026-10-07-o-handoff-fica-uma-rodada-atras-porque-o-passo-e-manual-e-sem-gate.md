---
status: Open
date: 2026-10-07
author: ""
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-07-o-handoff-fica-uma-rodada-atras-porque-o-passo-e-manual-e-sem-gate.md"
---

# REQ: o handoff fica uma rodada atras porque o passo e manual e sem gate

> Date: 2026-10-07 | Status: Open
| Linear Issue: 
| Jira Issue: 

## Motivation

O `CLAUDE.md` exige atualizar o `docs/agents-working-context.md` **ao iniciar e ao encerrar cada
ciclo**, em dois lugares — nas *Regras específicas* e no passo 3 do *Agent Protocol*. 🔴 **Não existe
gate para isso, e o passo falhou duas vezes em 24 horas.**

| quando | o que escapou |
|---|---|
| 2026-10-03 a 2026-10-06 | **quatro ciclos** fechados sem entrada; o arquivo ficou três dias parado |
| 2026-10-06, 23:04 a 23:52 | a frente do alarme **inteira** (5 commits, PRs #207 e #208) ficou de fora da entrada escrita às 23:04 |

**As duas vezes quem pegou foi o usuário**, perguntando *"ficou algo pendente por aqui"*. O
`validate`, o `barrier` e os catorze gates locais ficaram verdes com a lacuna aberta — porque nenhum
deles olha para isso.

🔴 **E a segunda falha é estrutural, não descuido.** A atualização é o último passo do ciclo: o ciclo
que escreve a entrada não consegue cobrir a si mesmo, e o seguinte depende de alguém lembrar. Um passo
obrigatório cuja única salvaguarda é memória humana falha por construção — é a mesma forma do
`ml-so-fica-verde-com-os-acs-conferidos`.


## Acceptance Criteria

- [ ] AC1 — Existe gate que **reprova** quando o diff move roadmap para `done/` e **não** toca o
      `docs/agents-working-context.md`
- [ ] AC2 — O veredito é ancorado na **base de merge**, nunca em dois pontos — é a terceira vez que o
      dois-pontos engana neste fork
- [ ] AC3 — Falsificado contra os **casos reais**: o diff da PR #208 reprova e o da #207 passa
- [ ] AC4 — Leitura que falhou nunca vira verde: sem a ref de comparação, o gate reprova **nomeando o
      motivo**
- [ ] AC5 — Diff sem roadmap indo para `done/` passa, e diff vazio (rodando na própria `main`) passa
      **dizendo que passou por vacuidade**, não em silêncio
- [ ] AC6 — Declarado em `EXECUTAR` do `run-local-gates.sh`, com a guarda de completude fechada


## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-07-o-handoff-fica-uma-rodada-atras-porque-o-passo-e-manual-e-sem-gate.md

## Context

## O discriminante, e por que é este

A exigência do `CLAUDE.md` é *"ao encerrar cada ciclo"*. **Encerrar um ciclo tem assinatura no diff:
um roadmap sai de `wip/` e entra em `done/`.** É isso que o gate procura — não "o PR é grande", não
"passou tempo", que não são verificáveis.

Medido contra as duas PRs de ontem, pela base de merge:

```
8415b22e (#207, a entrada do handoff)   roadmap->done: 0 · tocou o handoff: 1   -> passa
2a97172e (#208, o alarme)               roadmap->done: 1 · tocou o handoff: 0   -> REPROVA
```

🔴 **A #208 é o caso que escapou na vida real**, não um caso sintético. É ela que dá sentido ao gate.

## O que o gate NÃO faz

- **Não lê o conteúdo da entrada.** Qualidade de texto não é verificável por gate; presença, sim. Um
  PR que toque o arquivo com uma linha vazia passa — e isso é limite declarado, não descuido.
- **Não exige entrada em PR que não fecha ciclo.** Sync, correção de gate, documentação: nenhum move
  roadmap para `done/`, nenhum é cobrado. Cobrar todos faria o gate ser desligado na primeira semana.
- **Não roda sobre a `main`.** Ali o diff contra a base é vazio, e o gate passa **dizendo** que passou
  por vacuidade.

## Escopo negativo

- Não se mexe no `CLAUDE.md` para afrouxar a regra. A regra está certa; o que faltava era instrumento.
- Não se tenta cobrir o *"ao iniciar"* da mesma exigência: início de ciclo não tem assinatura no diff
  de um PR fechado, e inventar uma produziria gate que reprova por adivinhação.
