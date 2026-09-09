---
status: backlog
date: 2026-09-08
req: "docs/requisições/claude/REQ-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md"
squad: "claude"
---

# Roadmap: sete REQs vivem em subdiretório de estado, e o `validate` não acusa

> Created: 2026-09-08 | Status: backlog

## Context

REQ: docs/requisições/claude/REQ-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md

A `ADR-2026-09-03` D1 escreve que REQ **não** tem dimensão de estado. Sete REQs estão em pasta de
estado, e o `validate` diz `✓ No violations found`. ADR decide, gate não verifica — pela terceira vez
em dois dias, e a primeira numa decisão nossa.

## Acceptance Criteria

- [ ] Gate acusa REQ fora de `req_dir/<agente>/*.md`, falsificado nas duas direções, com denominador
      impresso.
- [ ] As 7 REQs saem das pastas de estado, com o `status` reconciliado arquivo a arquivo.
- [ ] O número de "REQ `Done` com AC aberto" é refeito com glob recursivo.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ⬜ Pendente
**Files affected:** —
**Actions:**
1. **Enumeração completa.** Achar toda REQ fora do layout canônico — e não só sob `req_dir`. 🔴 O
   próprio achado que originou esta REQ veio de um caminho que ninguém procurava: varrer também
   `docs/req/` (resíduo do upstream) e qualquer diretório que o `req_dir` de outra config alcance.
   Declarar a lista fechada com o comando que a produziu.
2. **Quem esvazia esta wave sem quebrar regra escrita?** Formas conhecidas, a registrar com remédio:
   (a) gate com glob de um nível, que é **exatamente o defeito que produziu o número errado da
   PR #65**; (b) gate que varre zero REQs e sai 0; (c) gate que acusa o próprio `req_dir` como se
   fosse subdiretório.
3. **Falsificação nas duas direções.** REQ plantada em `<agente>/wip/` reprova; árvore corrigida
   passa. E o controle inverso: o gate **não** pode acusar `req_dir/<agente>/x.md`, que é o layout
   canônico.
4. **Residual declarado.** O que este desenho aceita não cobrir.
**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência, não com asserção de uma linha
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — O gate e a correção do acervo

### ML-1A — Gate do invariante de layout
**Status:** ⬜ Pendente
**Files affected:** `scripts/check-req-layout.sh` (novo)
**Actions:**
1. Lê `req_dir` e os agentes do `trackfw.yaml` — nunca chumbado.
2. Acusa `.md` com profundidade > 1 abaixo de `req_dir`, nomeando arquivo e o nível sobrando.
**Acceptance criteria:**
- [ ] 🔴 Denominador impresso: `N REQs varridas`, e falha se `N == 0`
- [ ] Falsificação: REQ plantada em `<agente>/wip/` reprova nomeando o arquivo
- [ ] Controle inverso: o layout canônico **não** é acusado
- [ ] O gate passa na árvore já corrigida pelo ML-1B

### ML-1B — As 7 REQs saem das pastas de estado
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/{apolo,artemis,claude}/**`
**Actions:**
1. Mover cada uma para `req_dir/<agente>/`.
2. Reconciliar o `status` com o par da ADR (`Open`/`Done`), **arquivo a arquivo**.
**Acceptance criteria:**
- [ ] 🔴 Cada `status` alterado tem justificativa escrita. Mover arquivo **não** muda o significado
      do frontmatter, e reconciliar em massa seria inventar estado
- [ ] Nenhuma referência a essas REQs quebra — varredura de referência na **árvore inteira**, não
      num diretório escolhido (é o erro que produziu a `REQ-2026-09-05-residuo-de-docs-req`)
- [ ] `trackfw validate` sem violação, com denominador conferido

### ML-1C — O número de "Done com AC aberto" refeito
**Status:** ⬜ Pendente
**Files affected:** —
**Actions:**
1. Refazer a varredura com glob **recursivo**, excluindo blocos de código e exigindo título de seção
   de AC — as três correções que a medição de 2026-09-08 já precisou.
**Acceptance criteria:**
- [ ] O número final é publicado com o comando que o produziu
- [ ] A diferença para o publicado na PR #65 (6 REQs / 54 ACs) fica **explicada**, não só corrigida

## Residual declarado

- Este roadmap **não** decide o destino dos ACs abertos das REQs de junho. É decisão do usuário,
  registrada como pendente. Aqui só o número é corrigido.
- O gate é **nosso**. Propor a regra ao upstream é issue própria, depois de medido — o invariante
  vem de uma ADR nossa, não do produto.
