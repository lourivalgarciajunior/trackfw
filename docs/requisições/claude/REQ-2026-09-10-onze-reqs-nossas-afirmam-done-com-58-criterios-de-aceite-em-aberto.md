---
status: Done
date: 2026-09-10
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-10-onze-reqs-nossas-afirmam-done-com-58-criterios-de-aceite-em-aberto.md"
---

# REQ: onze REQs **nossas** afirmam `done` com 58 critérios de aceite em aberto

> Date: 2026-09-10 | Status: Done

## Motivation

A `REQ-2026-09-09-governanca-do-upstream` fechou dizendo que os 227 ACs abertos das 28 REQs herdadas
**não são nossos para marcar** — marcar afirmaria autoria sobre entrega dele.

Ao medir aquilo, sobrou a pergunta que ninguém tinha feito: **e os nossos?**

```
12 REQs NOSSAS (nao herdadas) com checkbox aberto
58 ACs abertos  ·  57 deles SOB bloco de criterio
11 marcadas `done`/`Done`
```

### O que exatamente está errado

Não é desarrumação de checkbox. **Onze REQs declaram entrega concluída com critério substantivo em
aberto** — e o conteúdo desses critérios não é decorativo:

> `- [ ] O comportamento casa com o do Go **por construção**: mesma chamada de sistema
> (`GetConsoleMode`), não uma heurística paralela`

> `- [ ] Gate impede regressão e **falha** com um site restaurado — não-vacuidade verificada`

São afirmações verificáveis, com discriminante escrito. O `status: done` diz que foram atendidas. Os
checkboxes dizem que não. **Uma das duas fontes mente, e nada no sistema nota.**

### É a mesma classe que já corrigimos duas vezes esta semana — a terceira é a maior

| quando | onde | o que dizia | o que era |
|---|---|---|---|
| 2026-09-09 | `ROADMAP-2026-09-05-onda-2`, ML-1B | ✅ Concluído | corpo em branco do template; a REQ dizia "o único em aberto" |
| 2026-09-09 | `REQ-2026-09-09-governanca` | 14 REQs · 109 ACs | 23 · 227, e o par publicado não era reproduzível |
| **aqui** | **11 REQs do nosso acervo** | **`done`** | **58 ACs abertos, 57 sob bloco de critério** |

A **Regra Dura de Reconciliação** deste projeto existe por causa disto, e nomeia o custo: em
2026-09-05 um ML mediu uma coisa e entregou artefato afirmando o contrário; **quem pegou foi uma
auditoria externa**, um dia depois.

### Por que agora, e por que sem depender de ninguém

🔴 **São verificáveis executando o produto de hoje.** Sondado em 2026-09-10, antes de abrir esta REQ:

```
isatty do Python usa GetConsoleMode   pypi/trackfw/tty.py           EXISTE (10 ocorrencias)
geradores Python escrevem LF          generators/adr.py, hooks.py   newline="\n" EXPLICITO
node e python ignoram HOME no Windows npm/src/homedir.js
                                      pypi/trackfw/homedir.py       AMBOS EXISTEM
```

Quatro de quatro sondagens deram sinal. Não é uma REQ que espera resposta do mantenedor: é leitura e
execução do que já está aqui.

### O escopo real, medido

| status | ACs | sob critério | REQ |
|---|---|---|---|
| `Done` | 2 | 2 | `REQ-2026-08-16-consolidar-arvores-governanca` |
| `done` | 7 | 7 | `REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink` |
| `done` | 5 | 5 | `REQ-2026-08-29-geradores-python-escrevem-crlf-no-windows` |
| `done` | 7 | 7 | `REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows` |
| `done` | 8 | 8 | `REQ-2026-08-29-migrar-para-upstream-7.3.0` |
| `done` | 5 | 5 | `REQ-2026-08-29-node-e-python-ignoram-home-no-windows` |
| `done` | 5 | 5 | `REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate` |
| `done` | 6 | 6 | `REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node` |
| `done` | 5 | 5 | `REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream` |
| `done` | 6 | 6 | `REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream` |
| `Done` | 1 | **0** | `REQ-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr` |
| `Open` | 1 | 1 | `REQ-2026-09-05-onda-2` — **fora do escopo**, é o AC2 e está em `blocked/` |

**11 REQs `done` · 57 ACs.** A `onda-2` entra na contagem de 12/58 porque tem checkbox aberto, mas
**não é objeto desta REQ**: ela está `Open`, com causa escrita, e o roadmap dela está em `blocked/`
por priorização. Não há contradição ali.

🔴 **A `reqs-que-passam-so-por-prosa` tem o único AC dos 58 FORA de bloco de critério.** Ela é o caso
que a guarda de reconciliação do `check-inherited-req.sh` nomearia — e por isso não pode ser tratada
em massa com as outras dez.

## Acceptance Criteria

- [x] **AC1** — A lista das 11 é **derivada por script**, com denominador impresso, nunca digitada.
      🔴 O número desta classe já saiu errado **três vezes** neste repositório em quatro dias, e as
      três por varredura mais estreita que o alvo. O entregável é o método, não o par de números.
- [x] **AC2** — **Um veredito por AC, com evidência de execução ou de leitura de fonte** — nunca em
      massa. O veredito é um destes quatro, e cada um exige coisa diferente:
      **(a) entregue** → marca `[x]` com o sítio no produto que o comprova;
      **(b) não entregue** → fica `[ ]`, e a REQ perde o `done`;
      **(c) caducou** → o critério não se aplica mais, e o **porquê** é escrito;
      **(d) não verificável aqui** → declarado, com o que faltaria para verificar.
- [x] **AC3** — 🔴 **Falsificação do método de verificação, antes de usá-lo.** Para cada família de
      AC, um **controle positivo** — algo que sabidamente está no produto tem de ser detectado — e um
      **controle negativo** — algo que sabidamente não está **não** pode ser. Verde sobre método cego
      marcaria 57 ACs por engano, e essa é a forma mais cara de errar aqui.
- [x] **AC4** — O `status` de cada uma das 11 é **reconciliado com o resultado**: REQ que sobrar com
      AC aberto **deixa de ser `done`**. 🔴 Não vale o inverso — abaixar o critério para manter o
      `done` é o defeito que esta REQ existe para fechar.
- [x] **AC5** — A grafia minúscula (`done`) é normalizada **nestas 11**, que são **nossas**. Isso é
      deliberadamente o oposto da decisão da `REQ-2026-09-09-governanca`, onde as 7 minúsculas
      **ficaram** por serem governança dele — e a diferença fica escrita para não parecer incoerência.
- [x] **AC6** — **Gate que impede a reincidência**: REQ com `status: Done` e checkbox aberto sob bloco
      de critério reprova. Falsificação nas duas direções, denominador impresso, e falha se varrer
      zero.
- [x] **AC7** — `trackfw validate`, `check-req-layout.sh`, `check-referential-integrity.sh`,
      `check-inherited-req.sh` e o gate novo verdes ao fim, com o binário da árvore reconstruído, e
      divergência de produto **zero**.

## Resultado

**56 ACs julgados, um por um.** `(a) 35 · (b) 9 · (c) 1 · (d) 11`.

As dez REQs perderam o `done`; os dez roadmaps saíram de `done/` para `backlog/`. O gate
`check-req-done-com-criterio-aberto.sh`, que reprovava com `10 REQs · 56 ACs`, sai `exit 0`.

🔴 **O achado estrutural está nos `(d)`.** A maior causa isolada — **cinco** dos 11, um por REQ — é a mesma: o AC exige comparação
contra **lista nomeada** de uma corrida de agosto — 95, 105, 198, 199, 297 falhas — e **nenhuma
dessas listas foi versionada**. O próprio AC proíbe comparar por contagem, que é a única coisa
reproduzível hoje. *(Corrigido em 2026-09-10: dizia "a maioria dos 11"; são cinco, derivado na
`REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados`.)*

**Uma REQ cujo critério depende de artefato não versionado é inauditável por construção.** Não é
falta de esforço: é desenho. E explica por que dez REQs puderam ficar `done` com critério aberto sem
que ninguém percebesse — parte delas nunca teve como ser conferida.

### Três achados de produto → issue no upstream

1. `check-python-writes-lf` **não pega CRLF explícito** — testa presença de `newline`, não o valor.
   **79 sítios** expostos.
2. `trackfw-validate.sh` gerado **diverge**: `go=sh · node=sh · python=bash`.
3. `init` do Python cria **um ADR a mais** que Go e Node.

### Um achado nosso, de outra causa

`check-upstream-content.sh` está **vermelho** com 7 arquivos de governança do upstream em `docs/`,
incluindo a `ADR-2026-09-03`, que **5 REQs nossas citam como se fosse nossa**. Mesma causa da
`REQ-2026-09-09-governanca`. **Trabalho próprio** — não foi corrigido aqui.

### Sete medições minhas erradas, nenhuma publicada como veredito

64 ACs no alvo · "o Go não usa `GetConsoleMode`" · "o gate de tty é cego" · "o gate falha sem a ref"
· "o slug do Python diverge" · "1 checkbox fora de critério" · e um `rm -f` que apagou
`docs/agents-working-context.md`, restaurado.

Sete, num trabalho cujo objeto é exatamente **artefato que afirma mais do que mediu**. Estão todas
escritas no roadmap, com o que cada uma teria custado.

## Negative Scope

- **Não** tocar nas 28 herdadas. A `REQ-2026-09-09-governanca` decidiu que os 227 ACs delas não são
  marcados nem desmarcados, e o gate exige a procedência. Esta REQ é sobre o **nosso** acervo.
- **Não** tocar produto. Se a verificação achar critério **não** atendido por defeito real do
  produto, isso é achado — vira issue no upstream com a medição, não correção local.
- **Não** marcar em massa. É a tentação óbvia — 57 checkboxes, 11 arquivos — e é exatamente o ato que
  produziria a mesma mentira em outra direção.
- **Não** abaixar critério para poder marcar. Reescrever um AC para que o estado atual o satisfaça é
  fabricar histórico, e é pior que deixá-lo aberto.
- **Não** decidir o AC2 da `onda-2` aqui. Ele tem REQ própria, ADR própria e roadmap em `blocked/`.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-10-onze-reqs-nossas-afirmam-done-com-58-criterios-de-aceite-em-aberto.md
