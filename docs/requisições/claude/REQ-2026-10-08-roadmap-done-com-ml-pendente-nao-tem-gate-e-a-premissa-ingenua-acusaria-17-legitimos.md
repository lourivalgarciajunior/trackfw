---
status: Done
date: 2026-10-08
author: ""
adr: "docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-08-roadmap-done-com-ml-pendente-nao-tem-gate-e-a-premissa-ingenua-acusaria-17-legitimos.md"
---

# REQ: roadmap done com ML pendente nao tem gate e a premissa ingenua acusaria 17 legitimos

> Date: 2026-10-08 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
Existe gate para **REQ** `done` com critério aberto (`check-req-done-com-criterio-aberto.sh`) e
**nenhum** para **ROADMAP** `done` com ML não concluído — a mesma classe de defeito, *artefato cujo
estado contradiz o que ele afirma*, no outro acervo.

🔴 **E a varredura que encontrou a lacuna quase produziu trabalho errado.** A premissa ingênua
— *"ML ⬜ em roadmap `done/` é contradição"* — acusa **17** arquivos, e **os 17 são legítimos**.

## Acceptance Criteria

- [x] AC1 — A premissa ingênua está **medida e recusada**, com o denominador decomposto
      ✅ 17 casados: **15 herdados** do upstream (derivado por `git cat-file`, não allowlist) e
      **2 nossos** que **já declaravam** o fechamento retroativo desde **2026-08-16**, em prosa:
      *"os MLs abaixo permanecem ⬜ Pendente **de propósito** — o fechamento foi por inspeção do
      entregável, não por execução"*. **Contradição real: 0.**
- [x] AC2 — Marcar aqueles MLs `✅` está **recusado como saída**, por escrito
      ✅ seria afirmar execução que não houve — fabricar histórico, a mesma saída que o gate de REQ
      recusa. O gate imprime as três saídas e nomeia a terceira como inválida.
- [x] AC3 — A premissa do gate é **marca explícita**, nunca prosa
      ✅ `<!-- fechamento-retroativo: … -->`. Procurar *"de propósito"* faria o registro histórico
      manter o gate vermelho para sempre — o defeito que levamos ao upstream na
      [#530](https://github.com/kgsaran/trackfw/issues/530) e que o
      `check-contorno-dos-shims-caducou.sh` já pagou aqui.
- [x] AC4 — Herdada fica fora **por construção**, não por lista
      ✅ `git cat-file -e upstream/main:docs/roadmaps/done/<basename>`, a mesma derivação do
      `check-inherited-req.sh`. Sem a ref o gate **falha dizendo o motivo**, e não faz `fetch`
      sozinho.
- [x] AC5 — Reconciliação e duas guardas de vacuidade
      ✅ os quatro baldes somam o total (`71 + 15 + 2 + 0 = 88`) ou o gate falha nomeando; varrer
      **zero** roadmap reprova; e **zero herdados** reprova, porque em 2026-10-08 eram 15 — zero ali
      é derivação quebrada, não acervo limpo.
- [x] AC6 — Falsificado nas duas direções, com o arquivo real
      ✅ marca removida → **acusa por nome**, `rc=1`; restaurada → `rc=0`. 🔴 **A primeira tentativa
      de falsificação estava errada** e teria passado por boa: apaguei as linhas 1–3 e a marca estava
      na 6, então o gate seguiu verde "corretamente" por eu não ter mexido no que dizia medir.
- [x] AC7 — Consumidor declarado e self-test em CI
      ✅ `EXECUTAR` do `run-local-gates.sh` (16 executados · 0 falhas), que é o que o
      `check-orphan-gates.sh` do upstream exige — `OK` conferido. E o `--self-test` ganhou passo
      próprio no `local-gates.yml`, com guarda sobre o denominador, porque o acervo tem **0 acusados**
      e portanto **não exercita nenhuma forma de recusa**.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-08-roadmap-done-com-ml-pendente-nao-tem-gate-e-a-premissa-ingenua-acusaria-17-legitimos.md

## Medição — 2026-10-08

```
varridos em done/     88
sem ML pendente       71
herdados do upstream  15   <- derivado, nao allowlist
fechamento DECLARADO   2   <- os nossos, declarados desde 2026-08-16
ACUSADOS               0
                      71 + 15 + 2 + 0 = 88, reconcilia
```

🔴 **O valor deste gate não é o total — é o zero da última classe**, igual ao
`check-os-predicate-classification.sh`. Ele congela o acervo de hoje e reprova o **próximo** roadmap
que fechar com ML pendente sem dizer por quê.

## Context

**Por que a medição vinha antes do trabalho.** A leitura ingênua levaria a marcar **14 MLs** (3 + 11)
como concluídos em dois roadmaps de junho — e os dois dizem, por escrito desde agosto, que os MLs
**nunca foram executados** e que o fechamento foi por inspeção do entregável nos geradores. Marcar
seria inverter o registro.

🔴 **Segunda vez no mesmo dia que a medição recusou o trabalho que a pergunta sugeria.** A primeira
foram os 22 avisos de `req_done_open_criteria`, todos herdados, que teriam virado 22 critérios
fechados em REQ de outro repositório.

**Limite declarado:** o gate olha a **forma do status** (`**Status:** ⬜/🔄/❌` ancorado em início de
linha) e a **presença da marca**. Ele **não** verifica se o entregável citado na declaração existe —
isso é leitura humana, e a declaração obriga a nomear o sítio justamente para que seja conferível.
