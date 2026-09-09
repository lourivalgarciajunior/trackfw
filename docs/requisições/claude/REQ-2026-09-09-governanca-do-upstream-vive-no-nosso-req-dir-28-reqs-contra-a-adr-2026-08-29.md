---
status: Open
date: 2026-09-09
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/backlog/ROADMAP-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md"
---

# REQ: governança do upstream vive no nosso `req_dir` — 28 REQs contra a `ADR-2026-08-29`

> Date: 2026-09-09 | Status: Open

## Motivation

A pergunta que originou esta REQ era outra: *"o que fazer com os ACs abertos das REQs de junho?"*
Eu vinha tratando como **dívida nossa de checkbox**. A medição mostrou que a pergunta estava errada.

### 1. O trabalho foi entregue — todos eles

Verificado **executando o produto de hoje**, não lendo os artefatos:

```
validate --json     EXISTE     serve (UI)              EXISTE
multi-AI targets    EXISTE     i18n (internal/i18n)    EXISTE
traceid             EXISTE     discover                EXISTE
help <key>          EXISTE     agent-memory            EXISTE
```

Marcar os ACs, portanto, não seria mentira sobre a **entrega**.

### 2. Mas seria mentira sobre a AUTORIA

**As 28 existem em `docs/req/` do `kgsaran/trackfw`.** São REQs **dele**. Vinte e seis entraram aqui
em 2026-06-28, quando este repositório era **cópia por ZIP** do dele — antes da `ADR-2026-08-29`, que
decidiu:

> *"A governança do upstream **não** é importada."*

Marcar os ACs afirmaria, no nosso acervo, que **nós** entregamos o que **ele** entregou. Os critérios
falam de decisões e medições que não são nossas. Seria fabricar histórico.

E abandonar também não serve: diria que o trabalho não foi feito, e foi.

### 3. O tamanho real: não são 8, são 28

```
REQs no nosso acervo         65
que existem no upstream      28   <- governanca DELE
so nossas                    37

das 28:  14 com AC aberto (109 ACs)  ·  14 sem
```

🔴 **Este número foi corrigido duas vezes, e as duas por varredura minha mais estreita que o alvo:**

| medição | resultado | o que estava estreito |
|---|---|---|
| PR #65 | 6 REQs · 54 ACs | glob de **um nível** — não descia em `<agente>/backlog/` |
| comentário na #65 | 8 REQs · 70 ACs | comparação `= "Done"` — perdeu seis com `status: done` **minúsculo** |
| aqui | **14 REQs · 109 ACs** | — |

A segunda é especialmente instrutiva: eu **normalizei** quatro `done`→`Done` na
`REQ-2026-09-08-sete-reqs`, e não percebi que existiam mais seis, porque a mesma comparação
case-sensitive que criou o problema foi a que usei para medi-lo.

### 4. É a mesma classe que já tratamos duas vezes

Em 2026-09-05 removemos **7 roadmaps órfãos** e **5 resíduos** de `docs/req/` pelo mesmo motivo: eram
governança dele, entrada por merge, que a ADR diz não importar. As 28 são o mesmo resíduo — num lote
maior, mais antigo, e que ninguém tinha medido.

E as duas remoções anteriores **quebraram gate**, cada uma de um jeito. É o motivo de o AC2 desta REQ
existir.

## Acceptance Criteria

- [ ] **AC1** — A lista das REQs herdadas é **derivada por comparação com o upstream**
      (`git cat-file -e upstream/main:docs/req/<basename>`), nunca escrita à mão. O denominador —
      quantas varridas, quantas herdadas — é impresso.
- [ ] **AC2** — 🔴 **Falsificação prévia obrigatória, na árvore inteira.** Para cada candidata:
      varredura de referência com `grep -r` em **todo** o repositório, não num diretório escolhido.
      É o erro exato que produziu a `REQ-2026-09-05-residuo-de-docs-req` — lá varri
      `docs/requisições/` e não varri `docs/req/`, e o `parity` quebrou.
- [ ] **AC3** — 🔴 **Nenhuma REQ que seja fixture de teste do produto é tocada.** Três de
      `docs/req/` são lidas por caminho literal nos 3 runtimes
      (`REQ-2026-09-05-tres-reqs-de-docs-req`); a checagem tem de cobrir também as 28, e o resultado
      fica escrito mesmo se for "nenhuma".
- [ ] **AC4** — Denominador conferido antes e depois: `status` reporta 65 REQs hoje. Se cair, o
      número novo é medido e escrito, e `validate` continua sem violação.
- [ ] **AC5** — Vínculo vivo tratado explicitamente: roadmap **nosso** que aponte para REQ dele é
      identificado e a decisão sobre ele é escrita, arquivo a arquivo.
- [ ] **AC6** — O `status` minúsculo (`done`) das seis restantes é reconciliado **ou** declarado fora
      de escopo com motivo — não fica no meio.
- [ ] **AC7** — `trackfw validate`, `check-req-layout.sh`, `check-referential-integrity.sh` e
      `check-subcommand-parity.sh` verdes ao fim, medidos com o binário da árvore reconstruído.

## Negative Scope

- **Não** marcar nem desmarcar AC de REQ herdada. A decisão desta REQ é sobre **onde a governança
  dele mora**, não sobre o estado de entrega dela.
- **Não** tocar produto. Se alguma das 28 for fixture de teste, ela **fica** — e o motivo é escrito.
- **Não** remover nada antes de o AC2 passar. As duas remoções anteriores desta mesma classe
  quebraram gate, e nas duas a causa foi varredura estreita.
- **Não** adotar as 28 movendo-as para outro diretório nosso. Adotar pela porta dos fundos é o que a
  `ADR-2026-08-29` recusa — o mesmo argumento do escopo negativo da
  `REQ-2026-09-05-sete-roadmaps-orfaos`.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md
