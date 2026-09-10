---
status: done
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum-e-ficou-vermelho-por-semanas.md"
squad: "claude"
---

# Roadmap: o `check-upstream-content` não roda em lugar nenhum, e ficou vermelho por semanas

> Created: 2026-09-10 | Status: done

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
**Status:** ✅ Concluído
**Acceptance criteria:**
- [x] Vazamento plantado num branch → o job **reprova**, e o log nomeia o arquivo
- [x] Árvore limpa → passa
- [x] As duas direções observadas **no CI**, não deduzidas do comportamento local

```
arvore limpa          conclusion: success   9 executados · 0 falhas
vazamento plantado    conclusion: failure   FAIL check-upstream-content
                                            docs/analise-cmdb/README.md
revertido             conclusion: success
```

### 🔴 O que a investigação encontrou: quatro camadas de stderr descartado

O CI reprovou **seis vezes** antes de passar, e cada falha escondia a seguinte. A primeira redação
deste ML chegou a registrar *"o `upstream-sync` suprime produto em Linux"* como defeito dependente de
plataforma. **Não era.**

| # | o que aparecia | o que era |
|---|---|---|
| 1 | `subcommand-parity` `exit=1`, **zero linhas** | job sem `npm ci`; o gate faz `node … 2>/dev/null` e `set -e` mata calado |
| 2 | `npm ci` → `EUSAGE` | o lock mora em `npm/`; copiei o comando dele e não o `working-directory` |
| 3 | `falsify` `exit=128` · *"worktree em bfeea12"* | `WT="/c/tfwfalsify"` cravado; `/c` não existe em Linux. **A mensagem culpava o commit** |
| 4 | `falsify` · *"PRODUTO suprimido"* | o `upstream-sync` **ignorava o exit code do merge** e reportava `0 de produto trazidos` como resultado |
| 5 | `falsify` · *"upstream-sync abortou"* | o gate **descartava a saída do sync** |
| 6 | — | **`Committer identity unknown`** |

**A causa raiz é uma linha de configuração:** o runner não tem `user.email`, e
`git merge --no-commit --no-ff` exige identidade **mesmo sem commitar**. A máquina de
desenvolvimento tem — e é exatamente por isso que o gate passava local e reprovava lá.

🔴 **Cada elo parecia um achado diferente.** O #4 chegou a ser escrito neste roadmap como defeito de
produto dependente de plataforma. As três correções de diagnóstico (#3, #4, #5) **ficam**: elas não
eram o defeito, eram o que impedia enxergá-lo.

**É a quinta, sexta e sétima instância da mesma família nesta semana** — guarda que descarta o
próprio stderr e publica diagnóstico errado. As anteriores: *"git does not resolve"* que era o
`python3`, *"gate cego"* que era mutação inválida, e o número `14 · 109` que ninguém conseguia
reproduzir.

**Nota de escopo, medida de passagem:** logo após plantar o vazamento, o gate **local** devolveu
`exit 0` — o arquivo ainda estava **não rastreado**, e o `check-upstream-content` compara conteúdo
rastreado. Só depois do commit ele aparece. Não é defeito; é o escopo do gate, e fica escrito.

## Residual declarado

- **O `check-platform-predicates.sh` fica fora, e o motivo já está escrito** no `CLAUDE.md`: 14 das
  20 linhas do corpus só dizem algo no Windows, e a linha do `execbit` reprovaria em `ubuntu-latest`
  por fato de NTFS. É exclusão declarada, não omissão.
- **O CI do fork gasta minuto de runner.** Este trabalho acrescenta um job a cada push e PR. É custo
  aceito: a alternativa medida é um gate vermelho por semanas.
- **Isto não impede vazamento — acusa.** O merge continua podendo trazer governança dele; o que muda
  é o intervalo entre acontecer e alguém saber.
