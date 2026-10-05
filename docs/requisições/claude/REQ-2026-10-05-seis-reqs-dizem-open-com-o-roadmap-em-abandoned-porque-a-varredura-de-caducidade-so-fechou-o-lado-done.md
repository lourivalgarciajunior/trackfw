---
status: Done
date: 2026-10-05
author: ""
adr: "docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-05-seis-reqs-dizem-open-com-o-roadmap-em-abandoned-porque-a-varredura-de-caducidade-so-fechou-o-lado-done.md"
---

# REQ: seis REQs dizem Open com o roadmap em abandoned porque a varredura de caducidade so fechou o lado done

> Date: 2026-10-05 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
Seis REQs declaram `status: Open` enquanto o roadmap de cada uma está em `abandoned/` com o veredito
`(c) caducou` escrito. O roadmap diz *"não será feito"*; a REQ diz *"trabalho em aberto"*.

🔴 É a mesma classe de defeito que as 14 branches `upstream-pr/*` — **artefato cujo estado contradiz o
que ele afirma** —, agora no acervo de REQs. E o efeito é o mesmo: `trackfw req list` mostra seis
abertas de 77, e quem lê conclui que há seis frentes vivas.

## Acceptance Criteria

- [x] AC1 — A causa é **medida**, não presumida
      ✅ sonda: `roadmap move <x> abandoned` sincroniza o **vínculo** e deixa `status: Open` intacto.
      O controle pelo caminho `done` ficou **inconclusivo** — o barrier bloqueou a sonda por ML
      pendente —, então o discriminante veio do código: `rewriteREQRoadmapRef` reescreve **só a
      referência de caminho**, em ramo nenhum escreve `status`, para destino nenhum.
      🔴 **Logo não é defeito do produto, e nada vai para o upstream** — é resultado da medição, não
      ausência dela. A omissão é **minha**: a varredura de 2026-10-03 aplicou `Done` nas quatro que
      foram para `done/` e esqueceu as seis de `abandoned/`.
- [x] AC2 — As 6 deixam de dizer `Open`, com **lastro escrito** por REQ
      ✅ `trackfw req move <nome> Closed` — **pelo produto**, não por edição de frontmatter —, e o
      `move` também acerta a linha `> Date: … | Status:` do corpo. Cada uma ganhou uma nota citando
      o veredito **(c) caducou** do roadmap dela, com o motivo próprio.
      🔴 **E um erro meu, pego pelo output:** o seletor `status: Open` casou **sete**, incluindo a
      REQ desta própria frente, que está legitimamente aberta. Revertida na hora, e a conferência
      passou a ser por par — `Closed` ⇒ roadmap em `abandoned/` —, seis de seis.
- [x] AC3 — Nenhuma delas passa a afirmar entrega
      ✅ **0 linhas de checkbox no diff** contra o `HEAD`. O diff reconcilia: 12 remoções (as duas
      linhas de status × 6) e 54 adições (12 de status + 42 de lastro).
      🔴 **A minha primeira conferência estava errada:** contei `- [x]` nas seis, deu 23, e eu quase
      li isso como "marquei 23 por engano". Os 23 já existiam. A pergunta certa não é *quantos*
      estão marcados — é **se eu mudei algum**, e isso é diff, não contagem.
- [x] AC4 — `req list` sem REQ aberta de frente morta, e `validate` limpo
      ✅ `Open: 1` (esta REQ, em curso) · `Closed: 6` · `validate` **0 violações · 3 avisos**.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-05-seis-reqs-dizem-open-com-o-roadmap-em-abandoned-porque-a-varredura-de-caducidade-so-fechou-o-lado-done.md

## Context

## A causa foi medida, e ela é nossa

**Sonda, com REQ e roadmap descartáveis:**

```
trackfw roadmap move <sonda> abandoned
  ✓ moved  … → docs/roadmaps/claude/abandoned
  ✓ synced REQ-… → docs/roadmaps/claude/abandoned/ROADMAP-…

status da REQ   ANTES: Open      DEPOIS: Open
```

O `move` **sincroniza o vínculo e não toca no status**. O controle pelo caminho `done` ficou
**inconclusivo** — o barrier bloqueou a transição da sonda por ML pendente, que é ele fazendo o
trabalho dele —, então o discriminante veio do código:

```go
// internal/generators/roadmap.go — a função de sync
updated, changed := rewriteREQRoadmapRef(content, roadmapBasename, newRoadmapPath)
```

Ela reescreve **apenas a referência de caminho**. Não há escrita de `status` em nenhum ramo, para
nenhum estado de destino.

🔴 **Logo: não é lacuna do `abandoned`, e não é defeito do produto.** O `status` da REQ é do autor, por
construção — e a omissão é **minha**: na varredura de caducidade de 2026-10-03 eu marquei
`status: Done` nas **quatro** que foram para `done/` e **esqueci as seis** que foram para
`abandoned/`. Metade do veredito foi aplicada ao acervo; a outra metade ficou no roadmap.

**Nada a reportar ao upstream** — e isso é resultado da medição, não ausência dela.

## Por que `Closed`, e por que não `Done` nem `Abandoned`

| candidato | por que não |
|---|---|
| `Done` | afirmaria entrega. Os critérios **não** foram atendidos — é exatamente o que o `check-req-done-com-criterio-aberto.sh` recusa |
| `Abandoned` | não existe em lugar nenhum do acervo nem do produto; inventar vocabulário cria divergência com o upstream sem ganho |
| **`Closed`** | **já é usado no acervo** (`apolo/REQ-roadmap-ai-generation-2026-06-11.md`), e o `req move` aceita texto livre — não há enum no produto |

**Limite declarado:** o precedente de `Closed` está numa REQ **herdada** do upstream, então é convenção
dele que estamos adotando, não um precedente nosso. Fica escrito para que ninguém o leia como decisão
original deste fork.

## Escopo negativo

- 🔴 **Nenhum critério de aceite é marcado.** As seis continuam com os critérios **em aberto**, porque
  eles não foram atendidos. Fechar caixa aqui seria fabricar histórico — a saída que o nosso gate de
  REQ `done` existe para recusar.
- Os roadmaps não saem de `abandoned/`: o veredito deles está certo e é ele que dá lastro ao status
  novo.
