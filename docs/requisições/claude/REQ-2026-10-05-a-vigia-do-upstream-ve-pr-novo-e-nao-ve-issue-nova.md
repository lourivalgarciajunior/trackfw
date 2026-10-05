---
status: Open
date: 2026-10-05
author: ""
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-05-a-vigia-do-upstream-ve-pr-novo-e-nao-ve-issue-nova.md"
---

# REQ: a vigia do upstream ve PR novo e nao ve issue nova

> Date: 2026-10-05 | Status: Open
| Linear Issue: 
| Jira Issue: 

## Motivation

A vigia do upstream (`scripts/vigia-do-upstream.sh`) observa tres coisas, e a issue CRIADA nao esta
entre elas. Derivado do proprio script em 2026-10-05:

| sinal | cobertura | onde |
|---|---|---|
| commit na `main` | sim | `snap_main`, por `git ls-remote` |
| PR mudando de estado, **inclusive PR novo** | sim | `snap_prs`, por `pulls?state=all` |
| comentario de OUTRO autor | sim | `snap_com` |
| comentario nosso | suprimido por desenho | `diff_com`, linha `[ "$au" = "$ME" ] && continue` |
| **issue criada, por qualquer autor** | **ZERO** | nenhum endpoint de listagem de issues |

Medido por efeito no mesmo dia: a issue #526 do upstream foi criada as 17:27 local e a vigia, armada
as 17:41 e viva as 18:06, nao emitiu nada a respeito. Quem a encontrou foi a leitura avulsa do roteiro
de re-arme — o passo manual que existe para cobrir a janela cega entre a expiracao e o re-arme.

🔴 **A assimetria e o defeito.** PR novo aparece porque `snap_prs` le a lista inteira de PRs e compara
por numero; issue nova nao aparece porque nao se le lista nenhuma de issues. Nao e decisao escrita em
lugar algum: e consequencia de a reescrita de 2026-09-29 ter trocado a lista fixa de 39 issues por
`issues/comments`, que traz comentario de qualquer issue mas nao traz issue sem comentario.

## Acceptance Criteria

- [ ] AC1 — A vigia emite evento quando uma issue e CRIADA no upstream, e o evento nomeia o autor
- [ ] AC2 — Pull request NAO aparece pelo braco de issues, falsificado por efeito contra o braco
      `snap_prs` que ja o cobre: o endpoint `/issues` do GitHub devolve PR junto, e sem filtro cada PR
      novo sairia duas vezes, com vocabulario de estado diferente nas duas
- [ ] AC3 — O braco novo passa pelas TRES guardas existentes: forma sobre o snapshot inteiro,
      leitura que falhou nao move a base, e ordenacao na mesma colacao
- [ ] AC4 — O custo por ciclo e re-declarado no cabecalho: deixa de ser 2 chamadas de API e passa a 3,
      com o numero escrito onde hoje se le 2
- [ ] AC5 — O `check-vigia-forma.sh` ganha caso para cada afirmacao acima, e a guarda de vacuidade
      dele sobe para o novo minimo — sem isso um `return` precoce deixaria os casos novos sem rodar
- [ ] AC6 — Evento de issue nova NAO e filtrado por autor, e a razao da assimetria com `diff_com`
      fica escrita no proprio script

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-05-a-vigia-do-upstream-ve-pr-novo-e-nao-ve-issue-nova.md

## Context

## Por que o evento de issue nao filtra autor, e o comentario filtra

🔴 Esta e a unica escolha de desenho desta REQ que contraria a simetria obvia, e ela e deliberada.

O `diff_com` descarta comentario nosso porque comentario nosso nao e noticia: fomos nos que
escrevemos, nesta sessao, ha segundos. **Issue criada nao tem essa propriedade.** O caso que originou
esta REQ e exatamente o contrario: a #526 foi aberta pela NOSSA conta, de outro repositorio consumidor
e de outra sessao, e esta sessao precisava sabe-lo — ela vigia o estado do repositorio compartilhado,
nao a autoria.

**Consequencia pratica:** filtrar por `$ME` aqui faria o braco novo nascer cego para o unico caso
medido que justifica existir. Seria fechar a lacuna com um instrumento que nao a alcanca — a forma de
defeito que este repositorio ja pagou varias vezes.

## O ponto cego que o endpoint traz de brinde

O `/repos/<repo>/issues` do GitHub **devolve pull request na mesma lista**, com uma chave
`pull_request` a mais. Sem filtrar por ela, cada PR novo passaria a sair duas vezes por ciclo: uma
como `PR #N -> OPEN` pelo `snap_prs` e outra como issue aberta. E com vocabulario diferente, porque o
`snap_prs` deriva MERGED de `merged_at` e a lista de issues nao traz esse campo.

O filtro e `select(.pull_request == null)`, e o AC2 o falsifica por efeito com carga que tem a chave.

## Escopo negativo

- Nao se mexe na supressao de comentario proprio do `diff_com`. Ela esta certa pelo motivo escrito
  acima, e alterar as duas no mesmo ML impediria atribuir efeito a cada uma.
- Nao se troca REST por GraphQL para economizar a chamada. O balde do GraphQL foi justamente o que o
  limite secundario cortou em 2026-09-29, e o cabecalho da vigia registra a medicao.
- Nao se funde o braco de PRs no de issues para manter 2 chamadas: a lista de issues nao traz
  `merged_at`, entao a fusao custaria a distincao entre "mesclou" e "fechou sem mesclar", que e a
  diferenca que interessa vigiar.
