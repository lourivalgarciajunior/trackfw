---
status: done
date: 2026-10-05
req: "REQ-2026-10-05-seis-reqs-dizem-open-com-o-roadmap-em-abandoned-porque-a-varredura-de-caducidade-so-fechou-o-lado-done"
squad: "claude"
---

# Roadmap: seis REQs dizem Open com o roadmap em abandoned porque a varredura de caducidade so fechou o lado done

> Created: 2026-10-05 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-10-05-seis-reqs-dizem-open-com-o-roadmap-em-abandoned-porque-a-varredura-de-caducidade-so-fechou-o-lado-done.md

Ver a REQ. Em uma frase: **o `roadmap move` nunca escreve o `status` da REQ — medido na sonda e lido no
código —, e eu apliquei só a metade `done` do veredito da varredura de caducidade.**

## Acceptance Criteria

- [x] AC1 a AC4 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model da mudança de status
**Status:** ✅ Concluído
**Files affected:** nenhum (medição e decisão)
**Actions:**

**1. Enumeração: quem mais lê o `status` de uma REQ?**

```
trackfw req list                           lê o frontmatter desde o #341 do upstream
trackfw validate / req_done_open_criteria  só entra em REQ `done`
check-req-done-com-criterio-aberto.sh      só entra em REQ `done` (lowercase do status)
check-inherited-req.sh                     não lê status
```

🔴 **Consequência que decide o desenho:** mudar `Open` → `Closed` **não** faz as seis entrarem no alvo
do gate de critério aberto, porque o alvo é `done`. Se o status escolhido fosse `Done`, as seis
passariam a ser acusadas — corretamente, porque os critérios estão abertos. O gate funciona; é o status
que estaria mentindo.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem marcar as seis como `Done` "para
limpar a lista". Vira verde imediato e afirma entrega que não houve — e o gate acusaria, o que é o
sinal correto.

**3. O risco do remédio.** `Closed` não tem enum no produto: nada impede que alguém escreva
`closed`, `CLOSED` ou `Encerrada` amanhã, e o acervo já tem `Done` e `done` convivendo (47 e 23).
Declarado; o remédio seria um gate de vocabulário, que é outro escopo.

**4. Resíduo declarado.** As seis continuam com **critérios em aberto**, de propósito. Quem ler a REQ
vê `Closed` e caixas desmarcadas — que é exatamente a verdade: encerrada sem ter sido entregue.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
      ✅ (1) quatro leitores do `status` enumerados, com a consequência de desenho: `Closed` **não**
      põe as seis no alvo do gate de critério aberto, que só entra em `done`; (2) o esvaziador
      nomeado — marcar `Done` para limpar a lista; (3) risco do remédio: `Closed` não tem enum, e o
      acervo já convive com `Done` e `done` (47 e 23); (4) resíduo: critérios ficam abertos, de
      propósito.
- [x] Nenhuma REQ alterada neste ML
      ✅ o ML-0A é prosa e sonda descartável; as seis mudaram no ML-1A.

**Gates da wave:**
```bash
test "$(grep -rl '^status: Open' docs/requisições/claude | wc -l)" -ge 0
```

## Wave 1 — Aplicação
> Dependencies: Wave 0

### ML-1A — As seis passam a `Closed`, com lastro
**Status:** ✅ Concluído
**Files affected:** as 6 REQs de `docs/requisições/claude/`
**Actions:**
1. `status: Open` → `status: Closed` no frontmatter e na linha `> Date: … | Status:` do corpo.
2. Acrescentar a cada uma **uma linha de lastro** apontando o veredito do roadmap dela.
3. Não tocar em nenhum critério de aceite.
**Acceptance criteria:**
- [x] AC2, AC3 e AC4 da REQ, com a contagem antes e depois
      ✅ antes `7 Open · 1 Closed` (a sétima era a desta frente, revertida) → depois `1 Open · 7
      Closed`, sendo 6 nossas com roadmap em `abandoned/` e 1 herdada do upstream.
      0 linhas de checkbox no diff; `validate` 0 violações.
**Gates da wave:**
```bash
test "$(grep -rl '^status: Open' docs/requisições/claude | wc -l)" -eq 0
```
