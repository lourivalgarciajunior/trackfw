---
status: backlog
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md"
squad: "claude"
---

# Roadmap: baselines de suíte nunca foram versionados, e doze ACs ficaram inauditáveis por construção

> Created: 2026-09-10 | Status: backlog

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
   lista para este fork teria de ser colhida do **nosso** CI, não herdada do dele.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia a implementação.**

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ⬜ Pendente
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
- [ ] As quatro seções respondidas com evidência
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — Os baselines

### ML-1A — Gerar e versionar, por nome
**Status:** ⬜ Pendente
**Files affected:** `scripts/testdata/`
**Acceptance criteria:**
- [ ] `pypi` e `npm`, uma falha por linha, ordenado, formato estável
- [ ] O comando que gera fica **escrito no cabeçalho do próprio baseline** — baseline sem receita
      envelhece e ninguém sabe refazer
- [ ] Denominador impresso: quantos testes rodaram, quantos falharam

### ML-1B — O gate
**Status:** ⬜ Pendente
**Files affected:** `scripts/`
**Acceptance criteria:**
- [ ] Compara por **conjunto**: acusa **nova** e **sumida**, separadamente
- [ ] Diz explicitamente que saldo zero não é conjunto igual
- [ ] Falha se a suíte não rodar, se o baseline estiver vazio, ou se o extrator devolver zero nomes
- [ ] 🔴 Falha **sumida** também é achado, não boa notícia: pode ser teste removido, renomeado, ou
      suíte que deixou de carregar

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

- **Um baseline de hoje não valida o passado.** Ele fecha a auditabilidade daqui para a frente. A
  afirmação de agosto morre como não verificada, e isso é o resultado honesto.
- **As 15 falhas do pypi ficam.** São produto do upstream; corrigi-las aqui criaria divergência.
- **Suíte com teste instável move o baseline sozinha.** Um dos ACs de agosto já registrava isso —
  *"a suíte pypi tem teste instável de skew de relógio que move o total sozinho"*. Comparar por nome
  reduz o problema mas não o elimina: um teste instável entra e sai do conjunto. Se aparecer, é
  declarado, não silenciado.
