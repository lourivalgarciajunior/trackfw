---
status: wip
date: 2026-10-05
req: "REQ-2026-10-05-publiquei-678s-como-o-custo-de-um-gate-a-partir-de-uma-passada-e-o-numero-nao-reproduz-e-o-custo-real-e-criar-processo-nao-o-git"
squad: "claude"
---

# Roadmap: publiquei 678s como o custo de um gate a partir de uma passada e o numero nao reproduz, e o custo real e criar processo nao o git

> Created: 2026-10-05 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-10-05-publiquei-678s-como-o-custo-de-um-gate-a-partir-de-uma-passada-e-o-numero-nao-reproduz-e-o-custo-real-e-criar-processo-nao-o-git.md

Ver a REQ. Em uma frase: **publiquei uma amostra de wall-clock como constante, a hipótese óbvia para a
divergência é falsa, e o custo real está em criar processo — não no git.**

## Acceptance Criteria

- [x] AC1 a AC5 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model da correção
**Status:** ✅ Concluído
**Files affected:** nenhum (medição e decisão)
**Actions:**

**1. Enumeração dos sítios que repetem o número.** Por busca, não por memória:

```
scripts/check-req-done-caducou-falsify.sh        cabeçalho: "678 s", "~23 min"
docs/roadmaps/claude/done/ROADMAP-2026-10-04-…   evidência da AC2
CLAUDE.md, seção do `Caducou:`                   atribui o custo ao git cat-file
memória gate-caro-no-msys-e-barato-no-ci         (já corrigida, fora do repo)
corpo do PR #200                                 (já corrigido, aberto na hora)
```

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem **apagar** o 678 s em vez de
**corrigi-lo com o registro do erro**. O número apagado leva junto a lição — e a lição é mais cara que
o número: *uma passada de wall-clock nesta máquina não é medida.*

**3. O risco do remédio.** Trocar `git cat-file` por um mapa pré-computado muda **o que o gate
considera herdada**. Se o `git ls-tree` devolver vazio, **toda** REQ parece não-herdada e o gate passa
a acusar governança do upstream — um verde que vira vermelho no lugar errado. Daí a guarda explícita na
derivação, além da guarda de `herdadas -eq 0` que já existe por efeito.

**4. Resíduo declarado.** O `sed -n | head -1` e o `awk` ficam. Fundi-los numa passada só mudaria o
**contrato da função `censo`**, que o `check-req-done-caducou-falsify.sh` extrai e chama esperando
quatro campos. É outra mudança, com outra falsificação — e misturá-las tornaria impossível dizer qual
produziu qual efeito.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
      ✅ (1) três sítios enumerados por busca; (2) o esvaziador nomeado — **apagar** o número em vez
      de corrigi-lo com o registro; (3) o risco do remédio, que virou guarda explícita; (4) resíduo
      declarado com o motivo do contrato de `censo`.
- [x] Nenhuma linha de gate alterada neste ML
      ✅ o ML-0A é prosa; as edições de gate estão todas no ML-1B.

**Gates da wave:**
```bash
test "$(git grep -l 'git ls-tree' -- scripts | wc -l)" -ge 1
```

## Wave 1 — Correção
> Dependencies: Wave 0

### ML-1A — Os sítios passam a dizer a faixa medida
**Status:** ✅ Concluído
**Files affected:** `scripts/check-req-done-caducou-falsify.sh`, `CLAUDE.md`, o roadmap de 2026-10-04
**Actions:**
1. Substituir o ponto pela faixa, **mantendo o registro do erro** em vez de apagá-lo.
2. Corrigir a atribuição: o custo é criar processo, e o `git cat-file` é 19% dele.
**Acceptance criteria:**
- [x] AC1 e AC2 da REQ
      ✅ três sítios corrigidos com a faixa; contenção testada e falsificada (60 s para duas).
**Gates da wave:**
```bash
test "$(git grep -c '678 s' -- scripts CLAUDE.md docs/roadmaps | wc -l)" -ge 1
```

### ML-1B — Os processos removíveis saem do laço, nos dois gates
**Status:** ✅ Concluído
**Files affected:** `scripts/check-inherited-req.sh`, `scripts/check-req-done-com-criterio-aberto.sh`
**Actions:**
1. `basename` → `${f##*/}`; `git cat-file` por REQ → **uma** chamada `git ls-tree` + mapa;
   `printf | tr` → `${var,,}`.
2. Guarda explícita na derivação: lista vazia **falha nomeando**.
3. Provar que a saída não mudou: capturar antes, aplicar, capturar depois, `diff`.
**Acceptance criteria:**
- [x] AC3, AC4 e AC5 da REQ, com o `diff` vazio escrito
      ✅ `diff` vazio nos dois gates contra a versão anterior na **mesma árvore**; guarda nova
      falsificada por sabotagem (`git ls-tree` → `true`): **rc=1 e nomeia a causa** nos dois.
**Gates da wave:**
```bash
bash scripts/check-inherited-req.sh
```
