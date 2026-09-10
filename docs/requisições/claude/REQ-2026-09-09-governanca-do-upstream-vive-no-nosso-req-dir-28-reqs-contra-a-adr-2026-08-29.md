---
status: Open
date: 2026-09-09
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md"
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
REQs no nosso acervo         66   (65 + esta)
que existem no upstream      28   <- governanca DELE
so nossas                    38

das 28:  23 com criterio aberto (227 ACs)  ·  5 sem
```

🔴 **Este número foi corrigido TRÊS vezes, e as três por varredura minha mais estreita que o alvo:**

| medição | resultado | o que estava estreito |
|---|---|---|
| PR #65 | 6 REQs · 54 ACs | glob de **um nível** — não descia em `<agente>/backlog/` |
| comentário na #65 | 8 REQs · 70 ACs | comparação `= "Done"` — perdeu seis com `status: done` **minúsculo** |
| primeira versão desta REQ | 14 REQs · 109 ACs | 🔴 **não reproduzível.** Em 2026-09-09 testei quatro varreduras candidatas — qualquer checkbox, só sob heading inglês, `status` exato, `status` case-insensitive — e **nenhuma** chega nesse par. O número foi escrito à mão |
| derivado por `scripts/check-inherited-req.sh` | **23 REQs · 227 ACs** | — |

A segunda é instrutiva: eu **normalizei** quatro `done`→`Done` na `REQ-2026-09-08-sete-reqs`, e não
percebi que existiam mais seis, porque a mesma comparação case-sensitive que criou o problema foi a
que usei para medi-lo.

E a terceira produziu a quarta armadilha **na própria conferência**: ao checar de onde vinha o
14/109, meu primeiro grep de heading procurou `Critérios de Aceite` com **A maiúsculo** e devolveu 18
arquivos "sem bloco de critério". São 13 que escrevem `Critérios de aceite` com **a minúsculo**.
Mesma classe de erro, mesmo dia, dentro do ato de corrigi-la.

**Por isso o AC1 não pede um número: pede um script.** Enquanto a medição for um grep digitado na
hora, ela erra do mesmo jeito toda vez, e erra em silêncio.

### Os 2 checkboxes que NÃO são AC

227 sob bloco de critério, **229 no total**. Os dois de diferença estão em
`REQ-roadmap-ai-generation-2026-06-11.md`, dentro de um **template de roadmap embutido** na própria
REQ (`### ML-1A — <título>`, `- [ ] build sem erros`). São placeholder de exemplo, não critério.

O gate **não adivinha isso** — ele nomeia o resíduo e deixa a leitura para quem lê. Absorver os dois
no total daria 229 sem dizer de onde vieram; descartá-los daria 227 pelo mesmo silêncio. As duas
formas de errar já aconteceram neste acervo.

### 4. É a mesma classe que já tratamos duas vezes

Em 2026-09-05 removemos **7 roadmaps órfãos** e **5 resíduos** de `docs/req/` pelo mesmo motivo: eram
governança dele, entrada por merge, que a ADR diz não importar. As 28 são o mesmo resíduo — num lote
maior, mais antigo, e que ninguém tinha medido.

E as duas remoções anteriores **quebraram gate**, cada uma de um jeito. É o motivo de o AC2 desta REQ
existir.

## Acceptance Criteria

- [x] **AC1** — A lista das REQs herdadas é **derivada por comparação com o upstream**
      (`git cat-file -e upstream/main:docs/req/<basename>`), nunca escrita à mão. O denominador —
      quantas varridas, quantas herdadas — é impresso.
      → `scripts/check-inherited-req.sh`, 2026-09-09. Saída:
      `66 REQ(s) varrida(s) em 'docs/requisições' · 28 herdada(s) do upstream · 28 declarada(s)` ·
      `23 REQ(s) herdada(s) · 227 sob bloco de critério · 229 checkbox(es) no total`.
      O `req_dir` vem do `trackfw.yaml`, nunca chumbado; a varredura é recursiva; o `UPSTREAM_REQ_DIR`
      é parametrizado porque um rename lá dentro tornaria toda REQ "só nossa" em silêncio.
      🔴 O gate **congela** o conjunto: uma 29ª herdada reprova. Não fecha a REQ — impede que o
      próximo merge acrescente ao problema enquanto ela está aberta.
- [x] **AC2** — 🔴 **Falsificação prévia obrigatória, na árvore inteira.** Para cada candidata:
      varredura de referência com `grep -r` em **todo** o repositório, não num diretório escolhido.
      É o erro exato que produziu a `REQ-2026-09-05-residuo-de-docs-req` — lá varri
      `docs/requisições/` e não varri `docs/req/`, e o `parity` quebrou.
      → 2026-09-09, `git grep -a -l -F` por basename **e** slug sobre os 1187 arquivos rastreados.
      Método falsificado antes do uso (alvo conhecido acha 11; controle negativo acha 0).
      **Resultado: 28 de 28 têm referência, 0 sem.** 82 arquivos distintos referenciam alguma delas.
- [x] **AC3** — 🔴 **Nenhuma REQ que seja fixture de teste do produto é tocada.** Três de
      `docs/req/` são lidas por caminho literal nos 3 runtimes
      (`REQ-2026-09-05-tres-reqs-de-docs-req`); a checagem tem de cobrir também as 28, e o resultado
      fica escrito mesmo se for "nenhuma".
      → **Nenhuma.** Zero das 28 é citada em `internal/`, `npm/`, `pypi/` ou `cmd/`. O controle
      positivo dispara: as três fixtures conhecidas dão `produto=3` cada, uma por runtime — sem isso
      o "nenhuma" seria vácuo com cara de resultado.

### 🔴 O que o AC2 decidiu, e que a Wave 2 herda

**Nenhuma das 28 pode ser removida.** Por dois mecanismos, sem sobra:

| | quantas | vetadas por |
|---|---|---|
| referenciadas no **snapshot congelado do barrier** | **26** | ML-1B: referência no snapshot veta a remoção e **não** autoriza regenerar o snapshot |
| `REQ-roadmap-ai-generation` e `REQ-req-driven-adr-discovery` | **2** | **ADR nossa** apontando para cada uma (`ADR-2026-06-11-roadmap-derivado-sem-llm`, `ADR-2026-06-12-descoberta-de-adr-guiada-pela-req`), mais roadmaps nossos |

Somado ao escopo negativo — que já proíbe **mover** as 28 para outro diretório nosso, porque adotar
pela porta dos fundos é o que a ADR recusa —, a decisão da Wave 2 fica reduzida a **uma** opção
viável: **elas ficam onde estão, e a procedência passa a ser declarada no próprio arquivo.**

Isso não é derrota do AC2: é o AC2 **funcionando**. Ele existe porque as duas remoções anteriores
desta mesma classe quebraram gate, e desta vez o veto apareceu **antes** de alguém apagar 28
arquivos.
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
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md
