---
status: wip
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md"
squad: "claude"
---

# Roadmap: baselines de suíte nunca foram versionados, e doze ACs ficaram inauditáveis por construção

> Created: 2026-09-10 | Status: wip

## 🔴 Correção de 2026-09-10 — são cinco ACs, não doze, e estão em `(d)`

O título e o nome deste arquivo dizem **doze**; **são cinco**, um em cada REQ. E eles estão gravados
como `(d)`, não como `(b)` — a conversão é o ML-2A. A derivação, com o comando que a refaz, está na
seção de correção da REQ. O slug fica como está.

## Context

REQ: docs/requisições/claude/REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md

**Cinco ACs, cinco REQs, uma causa:** o critério exige comparação contra **lista nomeada** de uma
corrida de agosto — 95, 105, 198, 199, 297 falhas — e **nenhuma dessas listas foi versionada**.

Medido hoje: a suíte pypi roda em ~5 min e sai com **15 falhas nomeadas**. O critério é
executável; o que faltava era o ponto de referência existir.

## Acceptance Criteria

- [ ] Listas de falha do pypi e do npm geradas hoje, por nome, versionadas.
- [ ] Gate compara por nome nos dois sentidos: nova **e** sumida.
- [ ] Guarda de vacuidade: suíte que não carrega não é suíte sem falhas.
- [ ] Falsificação nas duas direções.
- [ ] Os cinco ACs recebem **(b)**, nenhum marcado como entregue.

## A espera: o que ela comprou, e o que ela invalidou — 2026-09-10

### O que se decidiu, e por quê

Poucas horas depois de esta REQ ser aberta, o mantenedor entregou na branch dele **a mesma solução,
para o mesmo problema, no mesmo dia**: lista de falhas colhida de um run identificado, versionada, com
gate que compara **por nome**. Este roadmap ficou em `backlog/` **por convergência**, não por falta de
trabalho pronto: construir a Wave 0 naquela hora produziria uma **segunda** solução, e o próximo merge
do upstream teria de reconciliar as duas.

A condição de retomada ficou escrita com gatilho — `upstream/main` receber aquele trabalho — e a vigia
armada. Parar sem gatilho não é esperar, é abandonar com outro nome.

### O gatilho disparou

```
20:34 UTC   kgsaran/trackfw#312 mesclada  ->  cd34a2a   trazida pela nossa #93
20:51 UTC   kgsaran/trackfw#313 mesclada  ->  e4d8349   trazida pela nossa #94
```

Cerca de cinco horas entre abrir esta REQ e o trabalho dele estar na nossa `main`.

### O que a espera comprou

| o que chegou | `scripts/check-windows-known-failures.py`, 1446 linhas | cobre |
|---|---|---|
| ratchet por nome | 38 entradas, `_meta.source` com `run_id`, `job_id` e a receita para refazer | AC1, AC2 — o **mecanismo** |
| evento tipado | Go `[setup failed]` · Python exit 2/3/4 × 5 · Node `exitCode` no TAP, com multi-reporter | AC3 |
| remoção exige motivo | `removal_note`: `corrected` \| `renamed` \| `no-longer-runs`, e diff contra o baseline | AC2, lado **sumida** — e melhor que o nosso desenho, que só acusava |
| estabilidade de nome | `d5_decisions`, uma regra por runtime | nada — o nosso desenho **não tinha resposta** para isto |
| guarda do artefato | observação ausente → `exit 1`, em vez de 38 remoções espúrias e `exit 0` | AC3, lado da **observação** |

### E ele já roda aqui — medido na nossa `main`

Run `34530876997`, em `029457b`:

```
windows-full-suites    VERDE     era um dos 3 vermelhos conhecidos; agora sao 2
ML-2A/2B: 30 observed / 38 active / 0 removed
          Go 10/14 · Node-assert 6/10 · Node-load 1/1 · Python 13/13
ML-2B D4: 38 entradas comparadas, nenhuma delecao silenciosa
```

🔴 **Oito das 38 não falharam no nosso runner** — 4 Go e 4 Node, todas de renderização, CRLF ou golden.
O ratchet as reporta como aviso de "sumida" e o job fica verde. **A causa não foi medida.**

O que isso já prova, sem precisar da causa: **a lista dele não se transfere como conteúdo nem entre dois
repositórios no mesmo tipo de runner.** É o argumento da `d2_note` dele, aplicado agora à lista **dele**
no **nosso** CI. O mecanismo se transfere; o conteúdo, não.

*(Corrigido em 2026-09-10 no ML-0A: a causa foi medida, e é outra. O **nosso** `.gitattributes`
mascara aqui um defeito de produto que o CI dele expõe. A lista dele está certa; quem diverge é a
configuração deste fork. Ver o resultado do ML-0A.)*

### O que a espera invalidou: o AC1, por mérito

O AC1 pede as listas *"geradas hoje"* e versionadas em `scripts/testdata/`, e foi escrito com a medição
**desta máquina** — 15 falhas na pypi, 292 s. A `d2_note` do mantenedor decide o contrário, e decide
certo: *"List extracted from CI run, not from developer machine"*. Ela cita o nosso próprio relato de que
esta máquina **não é o runner**.

A medição local de hoje confirma pelo nosso lado: `go test ./...` dá 7 vermelhos aqui, e **só 5 estão
na lista dele**. Os 2 que sobram morrem no arranjo por falta de privilégio de symlink
([kgsaran/trackfw#315](https://github.com/kgsaran/trackfw/issues/315)) — fato desta máquina, não do produto.

🔴 **Isto não é reescrever o critério para caber no estado atual** — a saída que o
`check-req-done-com-criterio-aberto` recusa, e que a auditoria desfez em dez REQs. É o contrário: o AC1
estava **errado no mérito**, porque pedia a lista da máquina que não é o runner. A reescrita dele vem
depois da leitura inteira do script, e cita esta seção como a razão.

### O que a chegada revelou

- [kgsaran/trackfw#314](https://github.com/kgsaran/trackfw/issues/314) — o `--self-test` do ratchet morre
  com `UnicodeEncodeError` em `cp1252`. Com `PYTHONIOENCODING=utf-8`: 23 PASS, 0 FAIL.
- [kgsaran/trackfw#315](https://github.com/kgsaran/trackfw/issues/315) — dois testes Go transformam "sem
  privilégio" em "reprovou".
- **O self-test nem roda no nosso CI.** O `parity-rest` morre antes, na linha 78 do `Makefile`
  (`check-roadmap-barrier-contract.sh`, o snapshot congelado que não regeneramos) — igual antes e depois
  do merge, nos runs `34504117506` e `34530876997`.

### O que NÃO mudou

🔴 **Os cinco ACs continuam abertos, gravados como `(d)`** — a conversão para `(b)` é o ML-2A, e
não foi feita. *(Corrigido em 2026-09-10: esta linha dizia "os doze" e "continuam `(b)`".)*
Nenhum foi marcado, nenhum foi reescrito. A
espera era sobre **como** construir o gate, não sobre o veredito — e o veredito nunca dependeu dele.

### Próximo passo

Ler o `check-windows-known-failures.py` **inteiro** antes de desenhar qualquer coisa. Depois dele:

1. reescrever o AC1 citando esta seção;
2. decidir a convergência de AC2 a AC4 — e a primeira pergunta já está posta pelos oito "sumidos": uma
   lista para este fork teria de ser colhida do **nosso** CI, não herdada do dele. *(Respondida no
   ML-0A, e ao contrário: colher do nosso CI gravaria o mascaramento na lista. Não se colhe.)*

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia a implementação.**

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**

1. **Enumeração derivada.** Os ACs, localizados por varredura das cinco REQs — não pela lista
   desta REQ, que foi escrita à mão. 🔴 O denominador desta classe já saiu errado três vezes esta
   semana, e as três por contagem digitada. **Feito em 2026-09-10: são cinco, não doze** — a quarta
   vez, e a contagem digitada era a desta REQ. Tabela e comando na seção de correção da REQ.

2. **Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita:**

   | forma | remédio |
   |---|---|
   | gerar o baseline e marcar os cinco como entregues | AC5: todos recebem **(b)**; o baseline é novo, o passado não foi verificado |
   | comparar por contagem "porque é mais simples" | AC2 exige os dois sentidos, e o texto do gate diz que saldo zero não é conjunto igual |
   | rodar a suíte, ela não carregar, e gravar baseline vazio | AC3: guarda de vacuidade, e é a distinção da #274 |
   | reescrever o AC de agosto para caber no baseline novo | escopo negativo; é o que a auditoria de hoje desfez em dez REQs |
   | versionar só o pypi porque o npm é lento | AC6: exclusão é **declarada com o motivo medido**, nunca omitida |

3. **Falsificação nas duas direções.** Baseline com uma falha a mais → acusa "sumida"; com uma a
   menos → acusa "nova"; intacto → passa.

4. **Residual declarado.**

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência — ver o resultado abaixo
- [x] Nenhuma linha de implementação escrita neste ML

#### Resultado do ML-0A — 2026-09-10

**1. Enumeração derivada.** Cinco ACs, um por REQ, todos gravados como `(d)`. Derivado na #95, com o
comando escrito na seção de correção da REQ; a derivação reproduz os 11 `(d)` da auditoria.

**2. O ratchet do upstream, lido inteiro.** As 1446 linhas do `check-windows-known-failures.py` e a
ligação no job `windows-full-suites`. Ele cobre AC1 a AC4 por desenho; a tabela de convergência, AC por
AC, está na REQ.

**3. Falsificação — a causa dos 8, medida nas duas direções.** Mesma máquina, mesmo git, mesmo
`core.autocrlf=true`, dois worktrees:

| worktree | arquivos rastreados com `\r` (integrations + npm) | 4 testes Go | 4 testes Node |
|---|---|---|---|
| nosso, `9e7044e` | 0 de 172 | 4 PASS | 4 ok |
| dele, `e4d8349` | 65 de 172 — assets de agents e skills, nos dois runtimes | 4 FAIL | 4 not ok |

A diferença é o `.gitattributes`. O nosso tem `*.md text eol=lf` (ML-4, `da4f439`, 2026-08-16). O
dele exclui essa regra **de propósito, e por medição**: há uma seção que lista, arquivo por arquivo,
`*/integrations/assets/**` e `internal/integrations/testdata/*.golden.*` como entradas que o produto
processa. O motivo, nas palavras dele: *"O parser de frontmatter é CEGO A CRLF"*. Forçar LF no checkout
esconderia o defeito em vez de curá-lo — e é exatamente o que o nosso bloco faz aqui.

🔴 **Um remédio foi falsificado antes de virar issue.** Com uma linha só,
`internal/integrations/testdata/** text eol=lf`, os goldens ficaram LF (187 `\r` → 0) e **os 8
continuaram falhando**: o renderizador lê os assets (`//go:embed assets`), não só os goldens. A issue
que eu ia abrir pediria ao mantenedor que escondesse um defeito que ele documentou para não esconder.

Os 8 nomes, que o ratchet reporta aqui como "sumidos":

```
go    TestRenderOpenCodeAgent_CRLFSourceMatchesLF
go    TestRenderSubagentRouteInjectsIdentity_CRLFSourceMatchesLF
go    TestRenderWithoutIdentityMatchesFrozenGoldens
go    TestResolveAgentModelMatchesRender
node  gemini e kiro (mesma representação agent-markdown do cursor) permanecem bit-a-bit inalterados
node  opencode-agent renderer: source CRLF renderiza byte-idêntico ao source LF (ADR CRLF)
node  renderers produce native deterministic formats
node  sem identidade — saída idêntica ao comportamento pré-existente (não-regressão)
```

**4. Residual e o que isso muda.**

- 🔴 **Os 8 avisos de "sumida" dizem, na prática, "corrigido" sobre um defeito que está mascarado.**
  O ratchet sugere mover os 8 para `removed` com `removal_note`; aqui, a nota verdadeira seria
  "escondido pela configuração do fork", que não existe no vocabulário dele — e com razão.
- A `ADR-2026-08-29` classifica o `.gitattributes` como **local**, "configuração deste repositório". A
  medição mostra que ele **não é inerte**: muda o resultado de 8 testes de produto no Windows. É **outra
  causa** — configuração local mascarando defeito de produto — e não fecha com nenhum ML desta REQ.
  Pela Regra de Causa Raiz, vai para REQ própria, com este mecanismo escrito nela (ML-1B).
- **Não medido:** que o runner Windows do CI tenha `core.autocrlf=true`. O log não imprime. A ligação
  com o CI é por **consistência**: exatamente estes 8 falham no CI dele e passam no nosso.

## Wave 1 — Convergência com o ratchet do upstream (reescrita em 2026-09-10, no ML-0A)

A versão anterior desta wave construía um gate **nosso**: listas em `scripts/testdata/` e um
comparador próprio. O ML-0A mediu que o ratchet do upstream já roda no nosso CI e satisfaz AC1 a AC4
por desenho — construir o nosso seria a segunda solução. Ficam só as lacunas do fork.

### ML-1A — O self-test do ratchet passa a rodar no nosso CI
**Status:** ✅ Concluído
**Files affected:** `.github/workflows/local-gates.yml` (só nosso)
**Acceptance criteria:**
- [x] `python3 scripts/check-windows-known-failures.py --self-test` roda no `local-gates.yml`, em
      `ubuntu-latest`. Hoje não roda em lugar nenhum do nosso CI: o `parity-rest` morre na linha 78,
      antes de chegar a ele
- [x] Falsificado nos dois sentidos: com um caso do self-test quebrado o job reprova; intacto, passa
- [x] Nenhum arquivo compartilhado tocado

#### Resultado do ML-1A — 2026-09-11

O passo "Self-test do ratchet de Windows do upstream" entrou no `local-gates.yml`, depois dos gates
locais. O script do upstream só é executado; nenhum arquivo compartilhado mudou.

| rodada | run | job | passo | resumo | anotações de erro |
|---|---|---|---|---|---|
| intacto, 1ª | 34596903146 | success | success | 27 PASS, 0 FAIL | **10**, dos casos sintéticos |
| quebrado, 1ª (T2 invertido) | 34596996983 | failure | failure | 26 PASS, 1 FAIL | — |
| intacto, 2ª | 34598001245 | success | success | 27 PASS, 0 FAIL | **0** |
| quebrado, 2ª (T2 invertido) | 34598044479 | failure | failure | 26 PASS, 1 FAIL | 2: a do runner e a nossa |

🔴 **A primeira rodada achou um defeito no próprio passo.** O self-test imprime `::error::` nos casos
sintéticos que exercitam os caminhos de erro do ratchet, e o GitHub converteu cada um em anotação: um
job **verde** com 10 erros vermelhos, que engana quem revisa. Os comandos do GitHub agora ficam
desligados (`stop-commands`) enquanto o self-test roda, e o passo emite um erro só, o nosso, quando
ele reprova.

**A guarda do denominador** (zero PASS não é verde) foi falsificada **localmente**, com resumos
sintéticos: `0 PASS`, resumo ausente e `1 FAIL` reprovam; `27 PASS, 0 FAIL` passa. No CI ela não
disparou em nenhuma rodada, e é o esperado: no quebrado, o passo reprova antes, pelo código de saída
do próprio self-test.

🔴 **Uma medição minha errou no caminho.** A primeira contagem de "guarda disparou" deu 1 nos dois
runs, porque o log do GitHub ecoa o corpo do `run:` antes de executá-lo, e o `grep` contou o
código-fonte. Refeita sem o eco, deu 0 nos dois.

As branches descartáveis da falsificação (`chore/falsify-ml-1a-self-test-quebrado` e `…-2`) nunca
viraram PR.

### ML-1B — Os 8 mascarados vão para REQ própria
**Status:** ✅ Concluído
**Files affected:** `docs/requisições/claude/`, este roadmap
**Acceptance criteria:**
- [x] REQ própria aberta para a causa — configuração local mascarando defeito de produto —, com o
      mecanismo medido no ML-0A escrito nela
- [x] A decisão sobre o nosso `.gitattributes` é dessa REQ, não desta: alinhar ao do upstream desfaz o
      mascaramento, mas muda o fim de linha dos nossos `docs/*.md` no Windows, que os nossos gates leem
- [x] 🔴 Nenhuma edição no `.github/windows-known-failures.json`: é arquivo compartilhado, e a lista
      dele está **certa**

#### Resultado do ML-1B — 2026-09-11

REQ própria aberta: `REQ-2026-09-11-o-gitattributes-do-fork-mascara-um-defeito-de-produto-que-o-upstream-mantem-exposto-de-proposito`, com roadmap em `backlog/`. Ela carrega o mecanismo medido no ML-0A,
a premissa da `ADR-2026-08-29` que a medição derruba, e três opções — alinhar ao upstream, manter o
nosso, ou `eol=lf` só na governança — **sem escolher nenhuma**. Decidir exige medir antes o efeito de
docs em CRLF nos nossos gates, e é o AC2 dela.

Nenhum arquivo compartilhado foi tocado neste ML.

## Wave 2 — Os cinco ACs

### ML-2A — Veredito, um por AC
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/claude/**`
**Acceptance criteria:**
- [ ] Cada um dos cinco recebe **(b) não entregue**, apontando para esta REQ
- [ ] 🔴 Nenhum marcado como entregue; nenhum reescrito
- [ ] Fica escrito, por AC, que **a afirmação sobre agosto é irrecuperável**

### ML-2B — Execução
**Status:** ⬜ Pendente
**Files affected:** `scripts/run-local-gates.sh`, `CLAUDE.md`
**Acceptance criteria:**
- [ ] O gate entra no agregador **ou** é declarado fora com o motivo medido
- [ ] 🔴 Se ficar fora por custo, o custo é **medido em segundos**, não estimado — a pypi levou 292s
      hoje, a npm estourou 300s sem terminar

## Residual declarado

- **Os 8 mascarados** (ML-0A): enquanto a REQ própria (`REQ-2026-09-11-o-gitattributes-do-fork-mascara-um-defeito-de-produto-que-o-upstream-mantem-exposto-de-proposito`) não fechar, o ratchet aqui não vê regressão
  nesses 8 nomes, e os avisos de "sumida" que ele emite sobre eles não significam correção.
- **Sumida é aviso, não reprovação** — decisão escrita do mantenedor, e aceita: consertar um teste não
  pode quebrar o CI. A distinção entre corrigido, renomeado e não-executa fica na `removal_note`.
- **Um baseline de hoje não valida o passado.** Ele fecha a auditabilidade daqui para a frente. A
  afirmação de agosto morre como não verificada, e isso é o resultado honesto.
- **As 15 falhas do pypi ficam.** São produto do upstream; corrigi-las aqui criaria divergência.
- **Suíte com teste instável move o baseline sozinha.** Um dos ACs de agosto já registrava isso —
  *"a suíte pypi tem teste instável de skew de relógio que move o total sozinho"*. Comparar por nome
  reduz o problema mas não o elimina: um teste instável entra e sai do conjunto. Se aparecer, é
  declarado, não silenciado.
