---
status: wip
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum-e-ficou-vermelho-por-semanas.md"
squad: "claude"
---

# Roadmap: o `check-upstream-content` não roda em lugar nenhum, e ficou vermelho por semanas

> Created: 2026-09-10 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum-e-ficou-vermelho-por-semanas.md

**Cinco dos seis gates só nossos não são executados por nada** — nem `Makefile`, nem CI. O sexto tem
a decisão escrita. O `check-upstream-content.sh` ficou **vermelho por semanas** e só apareceu porque
eu o rodei à mão numa auditoria de outra REQ.

## Acceptance Criteria

- [x] Um ponto de entrada, em arquivo só nosso, com divergência de produto zero.
- [x] Roda em push e PR — nunca `workflow_dispatch`.
- [ ] Falsificado nas duas direções **em CI** — 🔴 só a direção local foi medida; ver ML-2B.
- [x] Guarda de completude: gate novo em `scripts/` não fica de fora em silêncio.
- [x] Gate que não pode rodar em Linux é declarado com o motivo.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia a implementação.**

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**

1. **Enumeração derivada.** Quais scripts em `scripts/` são **só nossos**, e quais deles são gates
   (reprovam) contra medidores (informam). 🔴 Derivar por `git ls-tree`, **não** por
   `git cat-file -e` — medido em 2026-09-10: o MSYS converte `ref:.caminho` quando o caminho começa
   com ponto, e a checagem devolve "só nosso" para arquivo que é dele.

2. **Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita:**

   | forma | remédio |
   |---|---|
   | listar os gates à mão e esquecer o próximo | AC4 exige derivação ou guarda de completude |
   | pôr em `workflow_dispatch` e chamar de CI | AC2 exige push **e** PR |
   | job que roda mas com `continue-on-error` | falsificação em CI: com vazamento plantado tem de **reprovar** |
   | job verde porque o script não existe no runner | guarda de vacuidade: falha se a lista executada for vazia |
   | tocar no `Makefile` "só uma linha" | escopo negativo, e a decisão do usuário é explícita |

3. **Falsificação nas duas direções, em CI.** Plantar vazamento → reprova. Árvore limpa → passa.
   🔴 **Tem de ser em CI, não local**: o defeito desta REQ é precisamente "funciona onde ninguém
   roda".

4. **Residual declarado.**

**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — O ponto de entrada

### ML-1A — Agregador em arquivo só nosso
**Status:** ✅ Concluído
**Files affected:** `scripts/` (agregador novo), `Makefile.local`
**Acceptance criteria:**
- [ ] Executa os gates só nossos que **podem** rodar em Linux, e reporta cada um por nome
- [ ] Imprime denominador: quantos executados, quantos declarados N/A
- [ ] Falha se a lista executada for **vazia**
- [ ] `Makefile.local` dá a entrada por `make -f Makefile.local`, **sem tocar no `Makefile`**

### ML-1B — Guarda de completude
**Status:** ✅ Concluído
**Files affected:** `scripts/`
**Acceptance criteria:**
- [ ] Gate novo em `scripts/` que não esteja na lista **reprova o agregador**
- [ ] Exclusão é **declarada com motivo**, nunca silenciosa
- [ ] 🔴 Falsificado plantando um `scripts/check-zz-novo.sh`: o agregador tem de acusar

## Wave 2 — CI

### ML-2A — Workflow só nosso, em push e PR
**Status:** ✅ Concluído
**Files affected:** `.github/workflows/` (arquivo novo)
**Acceptance criteria:**
- [ ] `on: [push, pull_request]` — **não** `workflow_dispatch`
- [ ] Faz `git fetch upstream` antes, porque dois dos gates dependem da ref e **falham fechados** sem ela
- [ ] Arquivo **novo**: adição, não modificação de workflow dele
- [ ] Divergência de produto ao fim: **zero**, medida por arquivo compartilhado que difere

### ML-2B — Falsificação em CI
**Status:** ⬜ Pendente
**Files affected:** —
**Acceptance criteria:**
- [ ] Vazamento plantado num branch → o job **reprova**, e o log nomeia o arquivo
- [ ] Árvore limpa → passa
- [ ] 🔴 As duas direções observadas **no CI**, não deduzidas do comportamento local

## Resultado — 2026-09-10

**Três arquivos, todos adições. Divergência de produto: zero, medida por arquivo compartilhado que
difere.**

```
scripts/run-local-gates.sh          agregador, com guarda de completude
Makefile.local                      entrada por `make -f Makefile.local gates`
.github/workflows/local-gates.yml   on: push, pull_request
```

**A enumeração corrigiu o número da REQ:** são **11** scripts só nossos (era 10 antes deste
agregador), de 72 em `scripts/`. A primeira redação dizia *"6"*, herdado de uma frase do `CLAUDE.md`
que envelheceu.

```
9 executados  ·  3 declarados FORA com motivo  ·  0 falhas
```

### A guarda de completude pegou a si mesma, na primeira execução

```
✗ COMPLETUDE: 'scripts/run-local-gates.sh' e so nosso e nao esta nem em EXECUTAR nem em FORA
```

O agregador é um script só nosso, e não estava listado. Ele **reprovou**, e a entrada dele no `FORA`
— *"executá-lo a partir de si mesmo seria recursão infinita"* — é a prova de que a guarda funciona,
não um contorno dela.

**Falsificado também com gate plantado:** `scripts/check-zz-novo.sh` não listado → `exit 1` nomeando
o arquivo; removido → `exit 0`.

### Os três declarados fora, com motivo

| script | motivo |
|---|---|
| `check-platform-predicates` | só diz algo no Windows — 14 das 20 linhas do corpus divergem entre `esperado` e `nativo_windows`, e a linha do `execbit` reprovaria em `ubuntu-latest` por fato de NTFS |
| `upstream-sync` | não é gate, é ferramenta: faz merge e **modifica a árvore** |
| `run-local-gates` | é o próprio agregador |

### Guardas do agregador, e o modo de falha que cada uma fecha

| guarda | fecha |
|---|---|
| ref do upstream ausente → `exit 1` | derivar sem poder comparar faria **todo** script parecer só nosso |
| `ls-tree` vazio → `exit 1` | mesmo efeito, por outra via |
| zero só-nossos derivados → `exit 1` | este fork tem gates próprios; zero é derivação quebrada |
| zero executados → `exit 1` | verde por não ter feito nada |
| listado em `EXECUTAR` mas arquivo ausente → falha | lista que aponta para nada |

### 🔴 O que NÃO foi verificado, e é o AC3

**A falsificação em CI não aconteceu.** As duas direções foram medidas **localmente**; o workflow
nunca rodou. Marcar o AC3 seria afirmar o que não medi — e num trabalho cujo objeto é *"gate que
ninguém executa"*, isso seria a ironia exata.

**O ML-2B fica pendente**, e ele só fecha depois do primeiro push: o job precisa aparecer verde com a
árvore limpa, e vermelho com vazamento plantado.

### ML-2B — Falsificação em CI
**Status:** 🔄 Em andamento — **uma direção fechada, a outra bloqueada por achado novo**

**Direção "árvore limpa passa": 8 dos 9 gates verdes em CI.** Levou **quatro** corridas, e cada
falha foi um defeito real que só o CI mostrava:

| # | sintoma | causa medida |
|---|---|---|
| 1 | `check-subcommand-parity` `exit=1`, **zero linhas de saída** | job sem `npm ci`. O gate faz `node ... 2>/dev/null`; sem os módulos o node falha, o stderr some, e `set -euo pipefail` mata sem mensagem |
| 2 | `npm ci` → `EUSAGE` | o `package-lock.json` mora em `npm/`; copiei o comando dele e não o `working-directory` |
| 3 | `check-upstream-sync-falsify` `exit=128`, *"FAIL: worktree em bfeea12"* | 🔴 **a mensagem apontava para o commit, e a causa era o destino**: `WT="/c/tfwfalsify"` é caminho cravado do Windows, e `/c` não existe em `ubuntu-latest`. O `2>/dev/null` escondia o `fatal:` |
| 4 | o mesmo gate, agora `exit=1` | **achado novo, abaixo** |

🔴 **A #3 é o terceiro caso da mesma família nesta semana.** Guarda que descarta o stderr do próprio
comando produz diagnóstico errado: o *"git does not resolve"* que era o `python3`, o *"gate cego"*
que era mutação inválida, e agora *"worktree em bfeea12"* — com o commit perfeito, provado por um
passo que fez o **mesmo** `worktree add` com sucesso no **mesmo** runner.

### 🔴 Achado novo: o `upstream-sync` suprime produto em Linux, e não no Windows

Com o caminho corrigido, o gate **rodou pela primeira vez em Linux** — e reprovou por lógica própria:

```
── caso: governanca pesada (41 arquivos, 4 de produto)
  FAIL: PRODUTO suprimido / produto NAO trazido:
      .claude/agent-memory/artemis-tf/MEMORY.md
      .claude/agent-memory/artemis-tf/feedback_assinatura_de_saida_antes_de_hipotese.md
      .github/workflows/quality.yml
      scripts/windows-repro/run.ps1
  ok  docs/ e vault/ identicos a base

── caso: produto puro (52 arquivos, 42 de produto)
  FAIL: PRODUTO suprimido:
      .github/workflows/quality.yml
      internal/commands/execbit_probe_test.go
```

**O mesmo gate passa no Windows.** Medido sobre os arquivos citados:

- os quatro **mudaram de verdade** entre base e ref — blobs diferentes, não são falso positivo;
- o modo é `100644` nos dois lados — **não é bit de execução**;
- `core.fileMode` é `false` aqui e `true` no runner, mas os modos coincidem, então isso não explica.

**Não sei a causa, e não vou chutar.** O que é seguro afirmar: o `upstream-sync.sh` — o script que
governa **todo** merge do upstream neste fork — tem comportamento **dependente de plataforma** que
nunca foi exercitado, porque o gate que o falsifica só rodava no Windows.

**Decisão explícita: o gate NÃO é declarado FORA.** Silenciá-lo agora seria exatamente o ato que esta
REQ existe para impedir — e seria pior que o original, porque agora há um achado medido por trás do
vermelho. **O CI fica vermelho até a causa ser medida**, e isso é informação, não incômodo.

**Fica aberto:** falsificação da direção "vazamento plantado reprova" — ela não pôde ser exercitada
porque o job já está vermelho por outro motivo, e um vermelho sobre vermelho não distingue nada.

## Residual declarado

- **O `check-platform-predicates.sh` fica fora, e o motivo já está escrito** no `CLAUDE.md`: 14 das
  20 linhas do corpus só dizem algo no Windows, e a linha do `execbit` reprovaria em `ubuntu-latest`
  por fato de NTFS. É exclusão declarada, não omissão.
- **O CI do fork gasta minuto de runner.** Este trabalho acrescenta um job a cada push e PR. É custo
  aceito: a alternativa medida é um gate vermelho por semanas.
- **Isto não impede vazamento — acusa.** O merge continua podendo trazer governança dele; o que muda
  é o intervalo entre acontecer e alguém saber.
