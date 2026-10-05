---
status: Done
date: 2026-10-05
author: ""
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-05-o-claude-md-afirma-como-estado-atual-uma-lista-de-5-scripts-so-nossos-que-hoje-sao-16-e-inclui-um-que-nao-existe.md"
---

# REQ: o CLAUDE.md afirma como estado atual uma lista de 5 scripts so nossos que hoje sao 16 e inclui um que nao existe

> Date: 2026-10-05 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
O `CLAUDE.md` afirma, **em presente e como estado atual**:

> *"Os únicos arquivos só nossos são adições que o upstream não tem — `check-slug-inventory.sh`,
> **`check-subcommand-parity.sh`**, `check-upstream-content.sh`, `upstream-sync.sh` e
> `check-upstream-sync-falsify.sh`."*

🔴 **São 16 hoje, e um dos cinco listados não existe.** O upstream retirou o
`check-subcommand-parity.sh` em 2026-09-16 — e uma nota logo abaixo, no mesmo arquivo, **diz isso** —,
mas a lista nunca foi corrigida.

Não é número desatualizado: é **afirmação falsa sobre o estado atual**, a mesma classe que este
repositório já pagou duas vezes e que o próprio `CLAUDE.md` adverte em letra vermelha — *"documentação
que descreve divergência inexistente faz o próximo merge procurar conflito onde não há"*.

## Acceptance Criteria

- [x] AC1 — A lista enumerada à mão é **substituída pela derivação**
      ✅ a seção passou a trazer o `git ls-tree` + laço que deriva o conjunto, e a apontar o
      `run-local-gates.sh`, cuja guarda de completude **reprova** quando um script só-nosso novo não
      está em `EXECUTAR` nem em `FORA`. 🔴 Trocar 5 por 16 teria sido a mesma armadilha com mais
      itens.
- [x] AC2 — As citações de linha que não batiam viraram âncora de símbolo
      ✅ as quatro foram testadas: `scaffold.go:1875-1879` e `roadmapdoc.go:58` **batem** e ficaram;
      `check-validate-rule-pins.sh:599` e `Makefile:58,60,61` **não batiam** e viraram
      `grep -n pin7-noexec` e `grep -n check-release-tag-parity Makefile`.
- [x] AC3 — Medição de hoje **ao lado** da antiga, com data
      ✅ cinco números: governança do upstream (52/140/142 → **82/249/246**), lint de SO (204/57/4
      em 2 → **242/62/11 em 8**), acervo (`blocked=1` → **0**, `done=69` → **79**), marcador
      ancorado (73/146 → **78/156**) e censo do `Caducou:` (75/7 → **78/6**).
      🔴 Nenhum antigo foi apagado: ele é o registro de quando a seção foi escrita.
- [x] AC4 — O que caducou por resolução ficou marcado, com a medição
      ✅ a seção do `jq` ganhou bloco ✅ dizendo que **nesta máquina** o ponto cego fechou
      (`jq-1.8.2` no `PATH`, medido hoje), que o mecanismo segue válido para máquina sem `jq`, e que
      o mantenedor está removendo a causa na raiz — com o **limite escrito**: a branch dele ainda
      não foi mesclada, e quando for a seção deve ser **medida de novo**, não apagada por fé.
- [x] AC5 — Nenhuma afirmação nova entrou sem medição
      ✅ treze afirmações falsificáveis derivadas uma a uma; **três erradas** (a lista e as duas
      citações de linha), cinco com número envelhecido, e **cinco exatas** — divergência de produto
      zero, 28 herdadas, ratchet em 14 entradas todas `go`, `wip/` vazio, e a nota que já declarava
      o `check-subcommand-parity` retirado. O que estava certo também está escrito: é resultado.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-05-o-claude-md-afirma-como-estado-atual-uma-lista-de-5-scripts-so-nossos-que-hoje-sao-16-e-inclui-um-que-nao-existe.md

## Context

## O que foi verificado, e como

Varredura de **afirmações falsificáveis** do `CLAUDE.md`, cada uma re-derivada contra a árvore de
2026-10-05.

### 🔴 Defeito: afirmação falsa sobre o estado atual

| | |
|---|---|
| afirmava | "os únicos arquivos só nossos" são **5**, um deles `check-subcommand-parity.sh` |
| real | **16**, e o `check-subcommand-parity.sh` **não existe** desde 2026-09-16 |
| janela | ~3 semanas com a lista errada, enquanto a nota de retirada convivia no mesmo arquivo |

**O remédio não é uma lista de 16** — seria a mesma armadilha com mais itens. A seção passa a trazer a
**derivação**, e aponta para o `run-local-gates.sh`, que já reprova quando um script só-nosso novo não
está declarado. Lista enumerada à mão sobre conjunto que cresce **apodrece por construção**.

### 🔴 Defeito: citações de linha que não batem mais

```
check-validate-rule-pins.sh:599  (pin7-noexec)        NAO bate
Makefile:58,60,61 (gates de PATH curado)              NAO bate
scaffold.go:1875-1879 (fallback sed do guard)         bate
roadmapdoc.go:58 (LapsedContinuationRe)               bate
```

As duas primeiras foram trocadas por **âncora de símbolo** (`grep -n pin7-noexec`,
`grep -n check-release-tag-parity Makefile`). É a regra que este arquivo **já aplica** ao baseline do
lint de SO — *"granularidade de arquivo, não de linha — número de linha muda a cada merge e viraria
ruído"* —, agora aplicada às citações.

### Números que mudaram, e ficaram lado a lado com a data

| afirmava | em 2026-10-05 |
|---|---|
| upstream: 52 ADRs · 140 REQs · 142 roadmaps | **82 · 249 · 246** |
| lint de SO: 204 sítios · 57 D1 · 4 D2 em 2 arquivos | **242 · 62 D1 · 11 D2 em 8 arquivos** |
| acervo: `wip=0 blocked=1 done=69` | `wip=0 blocked=0 done=79 abandoned=7` |
| marcador ancorado: 73 REQs · 146 marcadores | 78 · 156 |
| censo do `Caducou:`: 75 REQs · 7 não-`done` | 78 · 6 |

🔴 **O número antigo não foi apagado em nenhum caso.** Ele é o registro de quando a seção foi escrita;
o novo entra ao lado, com data. Apagar faria a seção parecer sempre atual — que é como ela chegou a
afirmar cinco scripts.

**E o lint de SO merece a leitura certa:** D2 subiu de 4 para 11 e os arquivos declarados de 2 para 8,
**com o ratchet fechado** (`Nenhum sitio de classificacao fora do baseline`). Os sítios novos entraram
**declarados**, um a um — não houve afrouxamento. O número que importa ali é o **zero de
não-declarados**, não o total.

### Caducou por resolução, e está marcado como tal

A seção *"sem `jq`, a cerca de git falha ABERTA"* descreve um ponto cego que **nesta máquina não
existe mais**: `jq-1.8.2` está no `PATH`, medido hoje. O mecanismo continua verdadeiro para máquina sem
`jq`, então a seção fica — com um bloco dizendo que não é mais o estado desta máquina, e registrando
que o mantenedor está removendo a causa na raiz (`feat/hooks-de-guard-executam-no-windows`, 7 commits,
guards em Go). 🔴 **A branch dele ainda não foi mesclada** — quando for, a seção caduca inteira e deve
ser **medida de novo**, não apagada por fé.

### O que foi verificado e estava EXATO

Isto também é resultado, e por isso fica escrito: divergência de produto **zero** (ancorada na base de
merge), **28** REQs herdadas, ratchet de Windows em **14 entradas ativas, todas `go`**, `wip/` vazio, e
a nota de 2026-09-16 que já declarava o `check-subcommand-parity.sh` retirado.

## Escopo negativo

- 🔴 **Nenhuma seção é apagada por estar velha.** As que caducaram viram registro com a medição que as
  aposentou — é a forma que este arquivo já usa para o `_force_utf8_output`, para os "8 mascarados" e
  para o `pin7-noexec`.
- Não se corrigem números em seções que **se declaram datadas** sem acrescentar a data nova ao lado.
