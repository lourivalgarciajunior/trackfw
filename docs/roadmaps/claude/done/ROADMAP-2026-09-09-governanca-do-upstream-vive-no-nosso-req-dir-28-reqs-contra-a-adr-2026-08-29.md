---
status: done
date: 2026-09-09
req: "docs/requisições/claude/REQ-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.md"
squad: "claude"
---

# Roadmap: governança do upstream vive no nosso `req_dir` — 28 REQs contra a `ADR-2026-08-29`

> Created: 2026-09-09 | Status: done

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

- [x] As 28 herdadas são identificadas por derivação, com denominador impresso.
- [x] Falsificação prévia na árvore inteira antes de tocar em qualquer arquivo.
- [x] Fixture de teste do produto fica, com o motivo escrito.
- [x] Gates verdes ao fim, com denominador conferido.

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
**Status:** ✅ Concluído
**Files affected:** `docs/requisições/**` (28), `scripts/check-inherited-req.sh`
**Acceptance criteria:**
- [x] A decisão é **uma**, aplicada às 28 — não 28 julgamentos
- [x] As que a Wave 1 vetar ficam, cada uma com o motivo
- [x] Denominador antes e depois; `validate` sem violação

## A decisão

> **As 28 ficam onde estão, e a procedência passa a ser declarada no frontmatter de cada uma:**
> `upstream_origin: "kgsaran/trackfw:docs/req/<basename>"`.

Uma decisão, 28 arquivos, zero julgamento por arquivo — porque a Wave 1 não deixou espaço para
julgar. Remover: vetado em 28 de 28 (26 pelo snapshot congelado do barrier, 2 por ADR nossa). Mover:
proibido pelo escopo negativo, que é onde a `ADR-2026-08-29` recusa a adoção pela porta dos fundos.
O que sobra não é preferência — é a única forma que respeita as duas restrições ao mesmo tempo:
**elas não são nossas, e isso passa a estar escrito no arquivo em vez de num documento à parte.**

**A declaração vive só no frontmatter, e isso foi medido, não escolhido por gosto.** O `req list` dos
três runtimes lê o status de uma linha do **corpo** — `> Date: … | Status: <status>` —, então uma nota
em blockquote logo abaixo do H1 poderia ser capturada por aquele extrator e virar o "status" da REQ.

**Falsificação por efeito, não por leitura:** `trackfw req list` capturado **antes** e **depois** das
28 edições, comparado com `diff`. **Byte a byte idêntico**, 66 linhas de cada lado — e o denominador
está aí de propósito, porque dois arquivos vazios também dão `diff` limpo.

**O gate passa a exigir a declaração** (`check-inherited-req.sh`). Decisão sem gate é decoração:
alguém apaga a linha e nada acusa. Falsificado nas duas direções:

| # | mutação | esperado | medido |
|---|---|---|---|
| G | apagar `upstream_origin` de uma | reprova | `exit 1`, nomeada |
| H | apontar para outra REQ | reprova | `exit 1`, com declarado × esperado |
| I | árvore intacta | passa | `exit 0` |

**Denominador (AC4), comparado por NOME e não por contagem:**

```
REQs em main   66      so em main   0
REQs agora     66      so agora     0
```

🔴 **A primeira leitura deste denominador deu `0` e era artefato meu:** `git ls-tree` escapa caminho
não-ASCII (`docs/requisi\303\247\303\265es`), e o `grep` não casou. Com `-c core.quotepath=false`,
66. Um `0` publicado ali teria virado "removemos todas as REQs".

### ML-2B — Vínculo vivo e `status` minúsculo
**Status:** ✅ Concluído
**Files affected:** —
**Acceptance criteria:**
- [x] Roadmap **nosso** apontando para REQ dele: identificado e decidido, arquivo a arquivo
- [x] Os seis `status: done` minúsculos: reconciliados **ou** declarados fora de escopo com motivo

**Vínculo vivo (AC5) — o resolvedor por nome muda a resposta.**

```
76 roadmaps · 56 resolvem · 19 sem req · 1 irresolvivel
```

🔴 **A primeira varredura acusou 30 irresolvíveis, e era erro meu.** Testei com `[ -f "$req" ]`, mas o
campo `req:` aceita **nome**, não só caminho — o produto resolve por nome dentro do `req_dir`. Trinta
"pendências" eram REQs perfeitamente resolvíveis. É a mesma varredura estreita da terceira medição do
número, agora aplicada a outro campo.

O único irresolvível de verdade:
`ROADMAP-2026-06-20-gate-pre-trabalho-branch-wip-roadmap-e-fallback-husky-node.md`.

**E ele não é nosso.** Conferido: existe em `upstream/main:docs/roadmaps/done/`. É roadmap **dele**,
apontando para REQ **dele** que nunca foi importada. Então o AC5 se responde sozinho: **nenhum
roadmap nosso aponta para REQ dele.** O caso restante é governança dele inteira — mesma classe das
28, mesma decisão, e fica fora do escopo desta REQ porque roadmap não é REQ.

**Grafia de `status` (AC6) — declarado FORA DE ESCOPO, com motivo medido.**

São **7** entre as 28 com `done` minúsculo, não seis — e a diferença importa menos que o motivo.
Antes de decidir, medi qual é o efeito real da grafia:

| fixture | frontmatter | corpo | `req list` reporta |
|---|---|---|---|
| controle A | `status: Done` | sem linha de status | `unknown` |
| controle B | `status: Done` | `> Date: … \| Status: WIP` | `WIP` |

🔴 **A grafia não é o discriminante.** `Done` maiúsculo também dá `unknown`; o que manda é a linha do
corpo. Minha hipótese inicial — "minúsculo → `unknown`" — foi **falsificada** por `status: Done` em
`discovery-mode-cmdb` aparecendo como `unknown`.

Então normalizar as 7 **não mudaria nada no produto**, e mudaria conteúdo de governança que a decisão
do ML-2A acabou de declarar como dele. Fica fora de escopo, e o motivo é esse.

O `Closed` de `REQ-roadmap-ai-generation-2026-06-11.md` **já estava decidido**: nota escrita no
arquivo em 2026-09-05 explicando a normalização a partir de `abandoned`. Não fica no meio.

O que **não** fica fora de escopo é o defeito que a medição revelou — `req list` contradiz o
frontmatter nos 3 runtimes. Causa diferente, REQ diferente: vai como issue para o upstream.

### ML-2C — Gates
**Status:** ✅ Concluído
**Files affected:** —
**Acceptance criteria:**
- [x] `validate`, `check-req-layout.sh`, `check-referential-integrity.sh` e
      `check-subcommand-parity.sh` verdes, com o binário da árvore reconstruído

Medido com `bin/trackfw` reconstruído por `go build`:

```
validate                     ✓ No violations found
check-req-layout             66 REQ(s) varrida(s) · 0 fora do layout canonico
check-referential-integrity  Referential integrity OK
check-subcommand-parity      8 comando(s) derivado(s) · 24 subcomando(s)
check-inherited-req          66 varridas · 28 herdadas · 28 declaradas · exit 0
```

**Divergência de produto: 1 arquivo — e não é nossa.** `.github/workflows/windows-probe.yml`
aparece porque o `upstream/main` andou **2 commits** durante este ML (os PRs #304 e #305 dele).
Provado por efeito: `git diff $(git merge-base HEAD upstream/main) HEAD -- internal npm pypi cmd
.github Makefile` devolve **vazio** — nós não tocamos em produto. Trazer esses 2 commits é trabalho
próprio, com medição própria.

## Wave 3 — reaberta em 2026-09-10: a governança dele também estava em `docs/`, fora do `req_dir`

> **Por que esta wave existe, e por que aqui e não em REQ nova.** A auditoria da
> `REQ-2026-09-10-onze-reqs` rodou o `check-upstream-content.sh` e o encontrou **vermelho**: 7
> arquivos de governança do upstream em `docs/`, **fora** do `req_dir` que esta REQ varreu.
>
> **Mesma causa** — governança dele vivendo na nossa árvore —, então é ML aqui, não REQ nova. A
> Regra Dura de Causa Raiz manda mover o roadmap de volta para `wip/`, e foi o que foi feito.
>
> 🔴 **O AC1 desta REQ era estreito.** Ele derivava por `git cat-file -e upstream/main:docs/req/<b>`
> — só o `req_dir`. Nada em `docs/adr/`, `docs/qualidade/`, `docs/seguranca/` ou
> `docs/portabilidade/` seria alcançado. O gate que pegou é outro, e existia desde agosto: estava
> **vermelho e ninguém olhava**, porque não está em alvo nenhum do `Makefile` nem em CI.

### ML-3A — Os 7 de `docs/`, decididos por dependência
**Status:** ✅ Concluído
**Files affected:** `docs/portabilidade/**`, `docs/qualidade/**`, `docs/seguranca/**`, `docs/adr/**`, `scripts/check-upstream-content.sh`

**Medição — os 7 são importação pura:**

```
todos os 7   byte a byte IDENTICOS ao upstream, no MESMO caminho
```

Nada nosso dentro deles. Não há trabalho a perder.

**O discriminante não é "tem referência" — é o TIPO de referência.** Todos os 7 são citados por
artefatos nossos, entre 2 e 5 vezes cada. Mas citar não é depender:

| | referência | decisão |
|---|---|---|
| `ADR-2026-09-03-layout-canonico-...` | **dependência dura**: 5 REQs a citam no campo `adr:` do frontmatter, e o `req_has_adr` do `validate` cobra | **FICA** |
| os outros 6 | **menção em prosa**: aparecem em listas dentro de duas REQs que documentam o próprio vazamento | **SAEM** |

🔴 **Se eu tivesse parado em "tem referência, logo está vetado"** — o critério que usei para as 28 —
os 7 ficariam, e 6 deles ficariam por engano. A pergunta certa é *"o que quebra se eu remover?"*, e a
resposta é diferente para a ADR e para os pareceres.

**O que foi feito:**

1. **Seis removidos** — `docs/portabilidade/` e `docs/qualidade/` ficaram vazios; `docs/seguranca/`
   manteve o `2026-08-15-skills-de-terceiro-via-url.md`, que **já estava no `KEEP`** com o motivo
   escrito (*"lido por internal/thirdparty; teste quebra sem ele"*).
2. **A ADR fica, com procedência declarada** no frontmatter —
   `upstream_origin: "kgsaran/trackfw:docs/adr/..."` —, o mesmo mecanismo das 28.
3. **E declarada no `KEEP` do gate, com o motivo**, que é a saída que o próprio gate oferece.

**Falsificação — gates antes e depois:**

| gate | antes | depois |
|---|---|---|
| `check-upstream-content` | **1** | **0** |
| `check-req-layout` | 0 | 0 |
| `check-referential-integrity` | 0 | 0 |
| `check-inherited-req` | 0 | 0 |
| `check-req-done-com-criterio-aberto` | 0 | 0 |
| `check-subcommand-parity` | 0 | 0 |
| `validate` | 0 | 0 |

**As duas remoções anteriores desta classe quebraram gate.** Esta não quebrou nenhum — e a diferença
é que a varredura de referência veio **antes**, com o tipo de dependência medido por arquivo.

**Residual deste ML:** o `AC1` desta REQ continua estreito por construção — ele deriva só sobre o
`req_dir`. Um vazamento novo em `docs/` seria pego pelo `check-upstream-content.sh`, **se alguém o
rodar**. Ele não está no `Makefile` nem em CI, e ficou vermelho por semanas sem ninguém notar. Pôr
esse gate onde ele seja executado é trabalho próprio, e não foi feito aqui.

## Residual declarado

- **Esta REQ não decide o estado de entrega das 28.** O trabalho foi entregue — verificado
  executando o produto. O que se decide aqui é **onde a governança dele mora**.
- **Os 227 ACs abertos não são marcados nem desmarcados.** Marcar afirmaria autoria nossa sobre
  entrega dele. (Eram "109" quando este roadmap foi escrito; o número derivado é 227.)
- **A derivação compara por basename.** Uma das 28 renomeada aqui dentro deixa de ser detectada e o
  gate a contaria como nossa — e a guarda de vacuidade **não** dispara, porque `herdadas` continua
  maior que zero. Comparar por conteúdo cobriria; não foi feito.
- **A grafia `done` minúsculo em 7 das 28 fica.** Medido: não muda nada no produto — o `req list`
  ignora o frontmatter. O que fica é o risco para varredura **nossa** case-sensitive, que já errou
  uma vez; o remédio escolhido foi comparar por `tolower()` nos gates, não editar governança dele.
- **`scripts/check-gates-falsify.sh:1822` escreve um arquivo com o nome de uma das 28** em diretório
  temporário. Não lê a nossa, então não veta a decisão — mas o nome está acoplado.
- **O defeito do `req list` não é corrigido aqui.** Causa diferente, REQ diferente: vai como issue
  para o upstream, com as duas fixtures de controle e a medição nos 3 runtimes.
