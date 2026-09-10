---
status: wip
date: 2026-09-09
req: "docs/requisições/claude/REQ-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md"
squad: "claude"
---

# Roadmap: governança do upstream vive no nosso `req_dir` — 28 REQs contra a `ADR-2026-08-29`

> Created: 2026-09-09 | Status: wip

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
**Status:** ✅ Concluído
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
- [x] As quatro seções respondidas com evidência, não com asserção de uma linha
- [x] Nenhuma linha de implementação escrita neste ML

**Falsificação executada em 2026-09-09 — seis direções, não duas:**

| # | o que foi plantado / mutado | esperado | medido |
|---|---|---|---|
| A | REQ herdada real (`REQ-2026-06-19-architect-command-guidelines-ML-1B.md`) fora do baseline | reprova | `exit 1`, nomeada |
| B | REQ só nossa, nome inexistente no upstream | passa, não conta | `exit 0`, herdadas seguem 28 |
| C | `UPSTREAM_REQ_DIR` apontando para diretório inexistente | reprova | `exit 1` com a razão |
| D | `UPSTREAM_REF` inexistente | reprova | `exit 1` com a razão |
| E | baseline esvaziado no lugar de derivar | reprova | `exit 1`, 28 nomeadas |
| F | detector de bloco de critério cegado (`if (0)`) | resíduo visível | `0 sob · 229 total`, 23 avisos |

🔴 **A direção E não valeu na primeira tentativa.** Copiei o script mutado para o scratchpad; ele
calcula `ROOT_DIR` a partir do próprio caminho, não achou o `trackfw.yaml` e saiu 1 — **o exit code
certo pelo motivo errado**. Só apareceu porque conferi a linha de saída em vez do código. Refeito
dentro de `scripts/`, deu `exit 1` com as 28 nomeadas.

**Residual declarado deste ML:** a derivação compara por **basename**. Uma REQ herdada renomeada aqui
dentro deixa de ser detectada, e o gate a contaria como nossa. Comparar por conteúdo (hash da seção
de critério, digamos) cobriria isso; não foi feito, e o custo é conhecido: uma renomeação silenciosa
esvazia o baseline sem que a guarda de vacuidade dispare, porque `herdadas` continuaria > 0.

## Wave 1 — Medir antes de tocar

### ML-1A — Lista derivada, com denominador
**Status:** ✅ Concluído
**Files affected:** `scripts/check-inherited-req.sh`
**Acceptance criteria:**
- [x] `N varridas · M herdadas` impresso; falha se `M == 0`
- [x] A lista bate com a medição desta REQ (65 varridas · 28 herdadas) **ou** a diferença é explicada

**Resultado:** `66 varridas · 28 herdadas · 28 declaradas`. A diferença de 65 → 66 é **esta própria
REQ**, criada depois daquela medição; as herdadas não mudaram.

🔴 **E o censo de critério aberto NÃO bateu: 23 REQs · 227 ACs, contra as 14 · 109 publicadas.**
Nenhuma das quatro varreduras candidatas testadas reproduz o par publicado — ele foi escrito à mão.
A correção está na REQ, com a tabela das quatro medições.

**Defeito encontrado pela própria guarda de reconciliação, durante este ML.** A primeira versão do
detector devolveu `0 sob bloco de critério` para 23 arquivos que têm o bloco. Duas causas somadas:

1. `## Critérios de Aceite` seguido de `### Bloco A` — o subheading zerava o estado. Medido em
   `REQ-2026-06-13-python-cli-nativo.md`, que põe 26 checkboxes sob seis subheadings.
2. `[eé]` numa classe de caractere não casa UTF-8 no awk desta máquina.

Sem a reconciliação, isso teria saído como `verde, nada sob critério` — um número menor, com aparência
de resultado. É o motivo de a guarda existir.

### ML-1B — Varredura de referência na árvore inteira
**Status:** ✅ Concluído
**Files affected:** —
**Acceptance criteria:**
- [x] Para cada uma das 28: `grep -r` em **todo** o repositório, incluindo `scripts/testdata/`,
      `docs/roadmaps/`, `vault/` e o snapshot congelado do barrier
- [x] 🔴 Referência no **snapshot congelado** não autoriza edição do snapshot — ela **veta a
      remoção** da REQ, ou exige decisão escrita. Regenerar o snapshot é o que não se faz

**Método.** `git grep -a -l -F` por **basename e por slug**, sobre os **1187 arquivos rastreados**,
excluindo a própria REQ. `git grep` em vez de `grep -r` de propósito: o conteúdo rastreado **é** o
repositório, e assim `node_modules/` fica fora sem que eu precise inventar um `--exclude-dir` que
depois viraria a varredura estreita da próxima vez.

**O método foi falsificado antes de ser usado** — porque um alvo que não casa devolve "sem
referência", que é indistinguível de "seguro para remover":

| # | alvo | esperado | medido |
|---|---|---|---|
| A | `multi-ai-support`, que sabidamente aparece no snapshot | acha | 11 arquivos |
| B | `REQ-INEXISTENTE-CONTROLE-2026` | 0 | 0 |
| C | `npm/src/validator/index.js`, o arquivo que o `grep` comum pula | lê | lê, com e sem `-a` |

🔴 **A direção C não valeu na primeira tentativa, duas vezes seguidas.** Primeiro procurei `prune`,
que não está no arquivo — vazio não prova leitura. Depois a extração do alvo falhou e devolveu
string **vazia**, e `git grep -F -- ""` casa com tudo: os dois "achados: 1" eram vácuo. Só com
`require(` (len=8) a checagem disse alguma coisa. Medido de passagem: o arquivo é `text: auto` e não
tem NUL nos primeiros 8000 bytes, então a armadilha documentada do `grep` binário **não se aplica ao
`git grep`** aqui.

**Resultado — decisivo:**

```
28 herdadas varridas · 28 com referencia · 0 sem
82 arquivos distintos referenciam alguma das 28

   30  nosso roadmap
   30  SNAPSHOT CONGELADO do barrier
    9  nossa ADR
    7  nossa REQ
    3  outro docs/
    3  raiz (CLAUDE.md, check-gates-falsify.sh, check-inherited-req.sh)
```

🔴 **26 das 28 são referenciadas pelo snapshot congelado do barrier.** Pelo critério escrito acima,
isso **veta a remoção** delas — e não autoriza tocar no snapshot.

**As outras 2 também estão vetadas, por mecanismo diferente:**

| REQ | vetada por |
|---|---|
| `REQ-roadmap-ai-generation-2026-06-11.md` | `docs/adr/ADR-2026-06-11-roadmap-derivado-sem-llm.md` — **ADR nossa** — mais um roadmap nosso em `abandoned/` e três em `done/` |
| `REQ-req-driven-adr-discovery-2026-06-12.md` | `docs/adr/ADR-2026-06-12-descoberta-de-adr-guiada-pela-req.md` — **ADR nossa** — mais dois roadmaps nossos |

**Então: nenhuma das 28 pode ser removida.** Não é conclusão de opinião, é o AC2 aplicado a 28 de 28.

**Achado lateral:** `scripts/check-gates-falsify.sh:1822` **escreve** um
`$T12/docs/req/REQ-adr-wizard-e-list-2026-06-11.md` num diretório temporário. Não lê a nossa, então
não veta — mas o **nome** está acoplado num script de falsificação, e isso fica escrito aqui para não
ser redescoberto como surpresa.

### ML-1C — Fixture de teste do produto
**Status:** ✅ Concluído
**Files affected:** —
**Acceptance criteria:**
- [x] Checado se alguma das 28 é lida por caminho literal em `internal/`, `npm/` ou `pypi/`
- [x] O resultado fica escrito **mesmo se for "nenhuma"** — gate sem achado é resultado

**Resultado: nenhuma. Zero das 28 é citada em `internal/`, `npm/`, `pypi/` ou `cmd/`.**

🔴 **E o "nenhuma" só vale porque o controle positivo dispara.** As três REQs de `docs/req/` que
**são** fixture conhecida foram passadas pelo mesmo método:

```
REQ-2026-07-27-convergencia-dos-templates-...   produto=3
REQ-2026-07-27-integridade-das-referencias-...  produto=3
REQ-2026-07-27-roadmap-move-sincroniza-...      produto=3
```

Três cada — um por runtime, como a `REQ-2026-09-05-tres-reqs-de-docs-req` mediu. Se o método não
enxergasse fixture, esses três dariam zero também, e o "nenhuma" das 28 seria vácuo com cara de
resultado. É o erro que já cometi duas vezes num dia e que virou remédio errado publicado em issue.

Medido junto, para dimensionar: **118 arquivos de produto citam `docs/req`** — o `req_dir` **default**
do produto, não o nosso. As 28 vivem em `docs/requisições`, e é por isso que nenhuma é alcançada.

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
