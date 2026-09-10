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

## Residual declarado

- **O `check-platform-predicates.sh` fica fora, e o motivo já está escrito** no `CLAUDE.md`: 14 das
  20 linhas do corpus só dizem algo no Windows, e a linha do `execbit` reprovaria em `ubuntu-latest`
  por fato de NTFS. É exclusão declarada, não omissão.
- **O CI do fork gasta minuto de runner.** Este trabalho acrescenta um job a cada push e PR. É custo
  aceito: a alternativa medida é um gate vermelho por semanas.
- **Isto não impede vazamento — acusa.** O merge continua podendo trazer governança dele; o que muda
  é o intervalo entre acontecer e alguém saber.
