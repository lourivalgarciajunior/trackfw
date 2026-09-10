---
status: backlog
date: 2026-09-09
req: "docs/requisições/claude/REQ-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md"
squad: "claude"
---

# Roadmap: governança do upstream vive no nosso `req_dir` — 28 REQs contra a `ADR-2026-08-29`

> Created: 2026-09-09 | Status: backlog

## Context

REQ: docs/requisições/claude/REQ-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md

**28 das nossas 65 REQs existem em `docs/req/` do upstream.** São governança dele, entrada quando
este repo era cópia por ZIP, e a `ADR-2026-08-29` diz que governança do upstream não é importada.

A classe já foi tratada duas vezes em 2026-09-05 — 7 roadmaps órfãos e 5 resíduos de `docs/req/` —
e **as duas remoções quebraram gate**. É por isso que a Wave 0 bloqueia tudo aqui.

> **Este roadmap foi gerado com `trackfw roadmap new --from-req`** e depois reescrito. A geração
> acertou a estrutura (um ML por AC, mais o ML-0A de threat model) e falhou em três pontos, os dois
> primeiros já reportados pelo mantenedor em 2026-09-09: o bloco `Acceptance Criteria` do roadmap
> ficou com os placeholders do template em vez do conteúdo da REQ; o frontmatter da REQ continuou
> `roadmap: ""`; e — não reportado ainda — **AC de múltiplas linhas é truncado na primeira**, tanto
> no título do ML quanto no AC dele, cortando a frase no meio.

## Acceptance Criteria

- [ ] As 28 herdadas são identificadas por derivação, com denominador impresso.
- [ ] Falsificação prévia na árvore inteira antes de tocar em qualquer arquivo.
- [ ] Fixture de teste do produto fica, com o motivo escrito.
- [ ] Gates verdes ao fim, com denominador conferido.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia toda a implementação** — e aqui isso não é formalidade: as duas
> remoções anteriores desta mesma classe quebraram gate.

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ⬜ Pendente
**Files affected:** —
**Actions:**
1. **Enumeração derivada.** `git cat-file -e upstream/main:docs/req/<basename>` para cada REQ do
   nosso `req_dir`, recursivo. Imprimir `N varridas · M herdadas`. 🔴 Não escrever a lista à mão: o
   número desta REQ já foi corrigido **duas vezes** por varredura estreita — glob de um nível, e
   comparação `= "Done"` case-sensitive que perdeu seis `done` minúsculos.
2. **Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita:**

   | forma | remédio |
   |---|---|
   | varrer referência só em `docs/requisições/` | AC2 exige `grep -r` na árvore **inteira** — é o erro literal da `REQ-2026-09-05-residuo-de-docs-req`, que quebrou o `parity` |
   | remover uma REQ que é fixture de teste | AC3, com a checagem escrita mesmo quando o resultado for "nenhuma" |
   | derivar zero herdadas e concluir "não há o que fazer" | denominador impresso, falha se `M == 0` |
   | mover para outro diretório nosso em vez de remover | escopo negativo: adotar pela porta dos fundos é o que a ADR recusa |

3. **Falsificação nas duas direções.** Plantar uma REQ que **existe** no upstream deve aparecer na
   lista derivada; plantar uma que **não** existe **não** deve. Só a primeira direção não é prova.
4. **Residual declarado.** O que este desenho aceita não cobrir.

**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência, não com asserção de uma linha
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — Medir antes de tocar

### ML-1A — Lista derivada, com denominador
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] `N varridas · M herdadas` impresso; falha se `M == 0`
- [ ] A lista bate com a medição desta REQ (65 varridas · 28 herdadas) **ou** a diferença é explicada

### ML-1B — Varredura de referência na árvore inteira
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Para cada uma das 28: `grep -r` em **todo** o repositório, incluindo `scripts/testdata/`,
      `docs/roadmaps/`, `vault/` e o snapshot congelado do barrier
- [ ] 🔴 Referência no **snapshot congelado** não autoriza edição do snapshot — ela **veta a
      remoção** da REQ, ou exige decisão escrita. Regenerar o snapshot é o que não se faz

### ML-1C — Fixture de teste do produto
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Checado se alguma das 28 é lida por caminho literal em `internal/`, `npm/` ou `pypi/`
- [ ] O resultado fica escrito **mesmo se for "nenhuma"** — gate sem achado é resultado

## Wave 2 — A decisão, e só então a ação

### ML-2A — Decisão por classe, não por arquivo
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/**`
**Acceptance criteria:**
- [ ] A decisão é **uma**, aplicada às 28 — não 28 julgamentos
- [ ] As que a Wave 1 vetar ficam, cada uma com o motivo
- [ ] Denominador antes e depois; `validate` sem violação

### ML-2B — Vínculo vivo e `status` minúsculo
**Status:** ⬜ Pendente
**Files affected:** `docs/roadmaps/**`, `docs/requisições/**`
**Acceptance criteria:**
- [ ] Roadmap **nosso** apontando para REQ dele: identificado e decidido, arquivo a arquivo
- [ ] Os seis `status: done` minúsculos: reconciliados **ou** declarados fora de escopo com motivo

### ML-2C — Gates
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] `validate`, `check-req-layout.sh`, `check-referential-integrity.sh` e
      `check-subcommand-parity.sh` verdes, com o binário da árvore reconstruído

## Residual declarado

- **Esta REQ não decide o estado de entrega das 28.** O trabalho foi entregue — verificado
  executando o produto. O que se decide aqui é **onde a governança dele mora**.
- **Os 109 ACs abertos não são marcados nem desmarcados.** Marcar afirmaria autoria nossa sobre
  entrega dele.
