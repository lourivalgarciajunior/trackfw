---
status: wip
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-onze-reqs-nossas-afirmam-done-com-58-criterios-de-aceite-em-aberto.md"
squad: "claude"
---

# Roadmap: onze REQs **nossas** afirmam `done` com 58 critérios de aceite em aberto

> Created: 2026-09-10 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-09-10-onze-reqs-nossas-afirmam-done-com-58-criterios-de-aceite-em-aberto.md

**Onze REQs do nosso acervo declaram entrega concluída com 57 critérios substantivos em aberto.** Não
são placeholder — 57 dos 58 estão sob bloco de critério, com discriminante escrito e verificável.

> **Gerado com `trackfw roadmap new --title --req` e reescrito.** Os dois defeitos que reportei ao
> mantenedor em 2026-09-09 **reproduzem**: o bloco `Acceptance Criteria` sai com os placeholders do
> template em vez do conteúdo da REQ, e o frontmatter da REQ continua `roadmap: ""`. Um terceiro,
> desta invocação: gerou **um** ML genérico (`build passes` / `tests green` / `validate passes`) em
> vez de um por AC — comportamento diferente do `--from-req`, que em 2026-09-09 gerou um ML por AC.
> Corrigido à mão aqui; a diferença entre as duas invocações não foi reportada porque não a medi.

## Acceptance Criteria

- [ ] A lista das 11 é derivada por script, com denominador impresso.
- [ ] Um veredito por AC, com evidência — nunca em massa.
- [ ] Método de verificação falsificado antes do uso, nas duas direções.
- [ ] REQ que sobrar com AC aberto deixa de ser `done`.
- [ ] Gate impede a reincidência.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia toda a implementação.**

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**

1. **Enumeração derivada.** Script que lista REQ **não-herdada** com checkbox aberto **sob bloco de
   critério**, imprimindo `N varridas · M com AC aberto · K ACs`. 🔴 Reusar a lógica de bloco de
   critério do `check-inherited-req.sh` — ela já custou um defeito para acertar: `### Bloco A`
   zerava o estado, e `[eé]` em classe de caractere não casa UTF-8 no awk desta máquina.

2. **Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita:**

   | forma | remédio |
   |---|---|
   | marcar os 57 em massa "porque o produto tem tudo" | AC2 exige veredito **por AC** com sítio nomeado |
   | reescrever o AC até o estado atual satisfazê-lo | escopo negativo proíbe; abaixar critério é fabricar histórico |
   | usar um verificador cego e marcar tudo | AC3 exige controle **positivo e negativo** por família |
   | contar por arquivo em vez de por AC, e declarar "11 resolvidas" | denominador em **ACs**, impresso, e a lista por nome |
   | tratar a `reqs-que-passam-so-por-prosa` junto das dez | o AC dela está **fora** de bloco de critério; caso próprio |

3. **Falsificação nas duas direções, por família de AC.** Controle positivo: algo que sabidamente
   está no produto tem de ser detectado. Controle negativo: algo que sabidamente não está **não**
   pode ser. 🔴 Só a primeira direção não é prova — foi assim que um "nenhuma" virou vácuo com cara
   de resultado em 2026-09-09, e só o controle positivo salvou.

4. **Residual declarado.** O que este desenho aceita não cobrir.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência, não com asserção de uma linha
- [x] Nenhuma linha de implementação escrita neste ML

---

## 1. Enumeração derivada — e o discriminante que faltava

```
varridas                                67
herdadas (fora pela ADR-2026-08-29)     28
nossas, status NAO-done, com AC aberto   2   <- legitimo, nao e contradicao
ALVO: `done` COM AC aberto              10 REQs · 56 ACs
```

🔴 **A primeira derivação deu 64 ACs e estava errada** — incluía REQs `Open`, e uma REQ `Open` com
critério em aberto **não é contradição nenhuma**. As duas que ela pegava indevidamente:

```
Open   1 AC   REQ-2026-09-05-onda-2               (o AC2, em blocked/ por priorizacao)
Open   7 AC   REQ-2026-09-10-onze-reqs...         (esta propria REQ)
```

O discriminante correto é **`status` minúsculo igual a `done` E checkbox aberto sob bloco de
critério**. Sem ele, o alvo incluiria a própria REQ que o define.

**Reconciliação com o número publicado na REQ (11 · 57):** batem.
`10 + 1 = 11` e `56 + 1 = 57` — a diferença é a `REQ-2026-09-05-reqs-que-passam-so-por-prosa`, cujo
único AC está **fora** de bloco de critério e por isso não entra nesta contagem. Ela é o **ML-2B**.

## 2. Modelo de ameaça — respondido

| forma | está fechada por |
|---|---|
| marcar os 56 em massa | ML-2A exige veredito por AC **com sítio nomeado**; sem sítio, não marca |
| reescrever o AC até ser satisfeito | escopo negativo da REQ; e o diff do PR expõe qualquer reescrita |
| verificador cego marcando tudo | §3 abaixo: controle positivo **e** negativo por família, executados |
| contar por arquivo e declarar "10 resolvidas" | denominador em **ACs**, e a lista sai por nome |
| tratar a `prosa` junto das dez | ela nem entra na derivação — o discriminante a exclui por construção |
| **incluir REQ `Open` e inflar o alvo** | 🔴 **não estava previsto, e aconteceu.** Fechado pelo discriminante de `status` |

A última linha é o resultado real desta wave: o modelo de ameaça previu cinco formas e a medição
encontrou **uma sexta**, cometida por mim na primeira tentativa.

## 3. Falsificação do método — sete famílias, controle nas duas direções

Os 56 ACs se agrupam em sete famílias por **como se verifica**, não por assunto:

| # | família | controle positivo | controle negativo |
|---|---|---|---|
| **F1** | comando executável (`go build`, `validate`, gates, `version`) | `go build ./...` → `exit 0` | `go build ./inexistente` → `exit 1` |
| **F2** | presença/ausência no fonte | `GetConsoleMode` em `pypi/trackfw/tty.py` → **5** | string inventada → **0 arquivos** |
| **F3** | estado do repositório | ADRs em `docs/adr` → **15** | ADRs em `docs/adr-fake` → **0** |
| **F4** | não-vacuidade de gate | gate intacto → `exit 0` | gate mutado → `exit 1` |
| **F5** | regressão contra **corrida anterior** | — | — |
| **F6** | comportamento em **Linux/macOS** | — | — |
| **F7** | AC que **se auto-declara** não atingido | — | — |

**F1 a F4 têm as duas direções verdes, medidas.** Um verificador cego marcaria 56 ACs por engano, e é
por isso que estes controles vêm antes de qualquer veredito.

**F5 e F6 não têm controle possível aqui, e o motivo é medido:**

- **F5** — os ACs falam de *"sem regressão por lista nomeada contra 95 / 105 / 198 falhas"*. A busca
  por essas listas no acervo versionado devolve **só** o `os-predicate-sites-baseline.txt`, que é de
  outra REQ e de ontem. **As listas de agosto não foram versionadas** — então a comparação por nome
  que o próprio AC exige é impossível de refazer. Veredito **(d)**, e a razão é essa.
- **F6** — esta máquina é Windows/MSYS. AC que afirma *"em Linux e macOS continua sendo `isatty()`
  puro"* não é verificável daqui. Veredito **(d)**.

🔴 **F7 é achado, não família de verificação.** Dois dos 56 ACs **escrevem no próprio texto** que não
foram atingidos:

```
- [ ] `trackfw validate` com zero violations — **não atingido**: 20 → 5
- [ ] `go test ./...` verde — **não atingido**: 10 falhas em internal/generators
```

E a REQ que os contém está com **`status: Done`**. Não é ambiguidade de leitura nem defeito de
ferramenta: o artefato afirma `Done` e, três linhas abaixo, escreve que o critério não foi atingido.
Veredito **(b)** sem necessidade de verificação — a evidência é o próprio texto.

## 4. Residual declarado

- **Este ML não julga nenhum AC.** Ele estabelece o alvo, o método e os controles.
- **A família F4 exige mutar gates**, e mutação é cara. Se algum gate não puder ser mutado sem tocar
  produto, o AC correspondente cai em **(d)** com essa razão escrita — não em **(a)** por
  conveniência.
- **O veredito `(c) caducou` é o mais perigoso** e não tem controle mecânico: é sempre julgamento.
  Cada uso dele no ML-2A escreve o que mudou no mundo, não só que mudou.
- **A derivação usa `status` minúsculo `done`.** Uma REQ com `status: Concluído` ou outra grafia fora
  do par da `ADR-2026-09-03` escaparia do alvo sem que nada acusasse. Medido: hoje não existe nenhuma
  assim, mas o gate do ML-3A precisa cobrir isso ou declarar que não cobre.

## Wave 1 — Medir antes de julgar

### ML-1A — Lista derivada, com denominador
**Status:** ⬜ Pendente
**Files affected:** `scripts/` (script novo)
**Acceptance criteria:**
- [ ] `N varridas · M com AC aberto · K ACs` impresso; falha se `M == 0` ou `N == 0`
- [ ] Bate com a medição desta REQ (**11 REQs · 57 ACs**, mais a `onda-2` fora de escopo) **ou** a
      diferença é explicada
- [ ] A lista sai **por nome**, para a próxima comparação ser de conjunto e não de contagem

### ML-1B — Falsificação do verificador, por família
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Para cada família de AC, controle **positivo** e **negativo**, ambos executados
- [ ] 🔴 O controle negativo usa algo que **sabidamente não existe** no produto — não uma string
      inventada que também não casaria por erro de sintaxe
- [ ] O resultado dos controles fica escrito **antes** de qualquer veredito ser dado

## Wave 2 — O veredito, um por AC

### ML-2A — As dez de agosto
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/claude/**`
**Acceptance criteria:**
- [ ] Cada um dos 56 ACs recebe **(a) entregue**, **(b) não entregue**, **(c) caducou** ou
      **(d) não verificável aqui** — com evidência por veredito
- [ ] `(a)` nomeia o sítio no produto; `(c)` escreve **por que** caducou; `(d)` escreve o que faltaria
- [ ] 🔴 Nenhum veredito em massa, e nenhum AC reescrito

### ML-2B — A `reqs-que-passam-so-por-prosa`, sozinha
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/claude/**`
**Acceptance criteria:**
- [ ] Tratada **separada** das dez: o AC dela é o único dos 58 **fora** de bloco de critério
- [ ] Decidido se é critério real mal formatado ou prosa com checkbox — e o veredito segue disso

### ML-2C — `status` reconciliado com o resultado
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/claude/**`
**Acceptance criteria:**
- [ ] REQ que sobrar com AC aberto **deixa de ser `done`**
- [ ] Grafia minúscula normalizada **nestas 11** — e a diferença para a decisão da
      `REQ-2026-09-09-governanca` (onde as 7 minúsculas **ficaram**) escrita, para não parecer
      incoerência

## Wave 3 — Impedir a reincidência

### ML-3A — Gate de REQ `Done` com critério aberto
**Status:** ⬜ Pendente
**Files affected:** `scripts/` (gate novo), `CLAUDE.md`
**Acceptance criteria:**
- [ ] REQ **não-herdada** com `status: Done` e checkbox aberto sob bloco de critério **reprova**
- [ ] Falsificação nas duas direções: plantar o caso reprova nomeando o arquivo; a árvore corrigida
      passa
- [ ] Denominador impresso; falha se varrer zero
- [ ] 🔴 As **28 herdadas** ficam fora por construção, não por allowlist — a exclusão é derivada do
      mesmo `git cat-file` do `check-inherited-req.sh`

### ML-3B — Gates
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] `validate`, `check-req-layout.sh`, `check-referential-integrity.sh`, `check-inherited-req.sh`,
      `measure-os-predicate-sites.sh` e o gate novo verdes, com o binário reconstruído
- [ ] Divergência de produto **zero**

## Residual declarado

- **Esta REQ não corrige produto.** Se um AC não estiver atendido por defeito real do produto do
  upstream, isso é achado — vira issue, não correção local.
- **O veredito `(d) não verificável aqui`** é uma saída legítima e vai existir: parte destes ACs fala
  de comportamento em Linux/macOS, e esta é uma máquina Windows. Declarar é honesto; marcar seria
  mentira, e deixar em silêncio seria pior que as duas.
- **A `onda-2` fica fora.** Ela está `Open`, com causa escrita e roadmap em `blocked/`. Não há
  contradição ali para reconciliar.
