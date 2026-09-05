---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md"
---

# REQ: Onda 1 de contribuição ao upstream — sinal honesto no CI e no `sync`

> Date: 2026-09-05 | Status: Done

## Motivation

Esta REQ governa **nossa decisão de investir**, não o código do produto. Os quatro itens pousam em
`kgsaran/trackfw` por issue ou PR; a `main` deste fork **nunca** os recebe direto, para preservar a
divergência de produto zero (ADR-2026-08-29). O padrão já funcionou: a `#263` (bucket `Other`) foi
planejada aqui, enviada, mesclada por ele, e voltou pelo merge do upstream.

O que este fork tem e o upstream não: **uma máquina Windows real**. Cinco PRs dele terminaram com
*"só o CI de Windows fecha"*; três eu fechei em minutos. É o ativo que justifica a onda.

Os quatro itens vêm de defeitos **medidos**, não de opinião:

**A3 — ratchet de vermelhos de Windows por nome, em vez de `continue-on-error`.**
Os jobs de Windows não bloqueiam nada hoje (`quality.yml:200`, marcado como temporário). Medi três
merges comparando conjuntos por nome, e o terceiro revelou o que a contagem escondia: a `#271` levou
`33 → 32` vermelhos, mas com **um vermelho novo** — `TestPathIsAnchoredForHookConfig_ControlePOSIX`,
teste introduzido pela própria PR, que reprova **porque a correção funciona**. Uma queda de contagem
pode conter regressão; um ratchet por nome não.

**A2 — distinguir "suíte não carregou" de "teste reprovou".**
`node --test` reporta `pass 0 / fail 1` quando o **arquivo inteiro** falha ao carregar, o que se lê
como um teste reprovando. Me enganou duas vezes em 2026-09-03; numa delas quase atribuí a falha à
minha própria edição. Um CI que não distingue os dois casos reporta 1 vermelho onde há uma suíte
inteira sem medir nada.

**F2 — `branch_has_wip_roadmap` casa por igualdade, não por `Contains`.**
`validator.go:2571` usa `strings.Contains(normalizeBranchSlug(name), branchSlug)` num `wip/` que só
cresce. O próprio mantenedor mediu o efeito: 11 de 13 roadmaps parados em `wip/` sem ML pendente, e
concluiu que *"`wip/` inchado enfraquece o portão"*. Substring num corpus crescente converge para
sempre casar.

**C2 — `sync` honra `req_dir`, usa o resolvedor, e ganha `--dry-run`.**
Os três runtimes chumbam `docs/req` e ignoram o `req_dir` configurado
(`sync.go:43`, `sync.js:237`, `sync.py:197,207`). Consequência **verificada por leitura** neste fork
(`req_dir: docs/requisições`, 53 REQs): `sync` sincronizaria **0** REQs reais e enumeraria 5 resíduos
de merge, dos quais **2 estão `Open` sem issue vinculada** — abriria issue no PM para REQ que não é
nossa. Não pude medir por execução justamente porque **não há `--dry-run`**, e o comando escreve em
serviço externo. A ausência do dry-run é parte do defeito, não só um incômodo.

Os itens A2, A3 e F2 já têm formulação; o C2 já está reportado na
[issue #268](https://github.com/kgsaran/trackfw/issues/268), cujo AC3 o mantenedor ampliou com os
três sítios após a medição.

## Acceptance Criteria

- [x] **AC1** — Cada um dos 4 itens tem issue no `kgsaran/trackfw` com: defeito medido, controle na
      direção oposta, e proposta de remédio. Issue sem medição não conta.
- [x] **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR
      existentes). Se já houver registro, o entregável é **correção de escopo**, não report novo — foi
      o que aconteceu na `#268`, onde a REQ dele já existia e o valor esteve em mostrar que o AC1
      podia ser satisfeito **sem corrigir o defeito**.
- [x] **AC3** — Onde ele pedir PR, a implementação sai em branch `upstream-pr/*` criada **a partir de
      `upstream/main`**, nunca da nossa `main`. Falsificação obrigatória antes de abrir:
      `git diff --stat upstream/main...<branch>` bate com a mudança real.
- [x] **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na
      issue com a ressalva do que ela **não** prova.
- [x] **AC5** — Nenhum dos 4 é mesclado na nossa `main` por fora. Volta só pelo merge do upstream.
      Falsificação: a divergência de produto continua **vazia** ao fim da onda.
- [x] **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele.
      **Recusa é desfecho legítimo** e fecha o ML; o que não pode é ficar aberto sem resposta.

## Negative Scope

- **Não** implementar nada de produto na nossa `main`.
- **Não** propor o que o upstream já mediu e descartou: `make -j` no alvo `parity` (2,2–3,4× mais
  lento), matriz de shards (renomearia o check obrigatório com `enforce_admins`), forçar o bit de
  execução em NTFS, e trocar `IsAbs` nos sítios de **travessia** de sistema de arquivos.
- **Não** abrir as 18 oportunidades do plano de uma vez. REQ que espera decisão de terceiro apodrece
  em `backlog/` — é literalmente a dívida de junho que a REQ irmã trata.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md

## Desfecho (2026-09-05)

| item | desfecho | issue |
|---|---|---|
| F2 `branch_has_wip_roadmap` | correção de escopo da `REQ-2026-08-20` dele | [#273](https://github.com/kgsaran/trackfw/issues/273) |
| A2 suíte não carregou | report novo | [#274](https://github.com/kgsaran/trackfw/issues/274) |
| A3 ratchet por nome | report novo | [#275](https://github.com/kgsaran/trackfw/issues/275) |
| C2 `sync` e `req_dir` | já entregue em 04/09; ele assumiu | [#268](https://github.com/kgsaran/trackfw/issues/268) |

**AC2 pegou 2 dos 4**: o F2 já tinha REQ dele desde 20/08, e o C2 já tinha issue minha. Sem a
varredura do acervo, metade da onda teria saído como duplicata.

**Nenhum PR foi necessário** — os quatro são dele por decisão dele ("é nosso, não precisa mandar
PR"), então o AC3 não foi exercitado. Registrado como não-aplicável, não como cumprido.
