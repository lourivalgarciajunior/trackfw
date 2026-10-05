---
status: Done
date: 2026-10-05
author: ""
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-05-publiquei-678s-como-o-custo-de-um-gate-a-partir-de-uma-passada-e-o-numero-nao-reproduz-e-o-custo-real-e-criar-processo-nao-o-git.md"
---

# REQ: publiquei 678s como o custo de um gate a partir de uma passada e o numero nao reproduz, e o custo real e criar processo nao o git

> Date: 2026-10-05 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
Em 2026-10-04, às ~00:00, cronometrei **uma** passada do
`check-req-done-com-criterio-aberto.sh` em **678 s** e publiquei esse número como *o custo do gate* —
no corpo de um PR, em dois commits, numa seção do `CLAUDE.md`, no cabeçalho de um script novo e numa
memória. **Decisão de desenho foi construída em cima dele** (os dois casos de ponta a ponta da
falsificação viraram funções para poderem rodar separados, "porque juntos custam ~23 min").

No dia seguinte, às 11:00, o mesmo gate na mesma árvore deu **29, 39, 42 e 40 s**.

## Acceptance Criteria

- [x] AC1 — O número é corrigido **em todos os sítios** que o repetem, e cada um diz a **faixa**
      ✅ três sítios, enumerados por busca: o cabeçalho do `check-req-done-caducou-falsify.sh`, a
      evidência da AC2 no `ROADMAP-2026-10-04-…caducou…`, e a seção do `Caducou:` no `CLAUDE.md`
      (onde a **atribuição** também estava errada). Os três dizem **29 a 42 s** e **registram o
      erro** em vez de apagá-lo. Fora do repo: a memória e o corpo do PR #200, corrigidos na hora.
- [x] AC2 — A hipótese óbvia (contenção) é **testada**, não suposta, e o resultado fica escrito
      ✅ **duas passadas concorrentes somam 60 s** — 1,5× uma passada, não 20×. **Falsificada.** O
      que mudou entre 00:00 e 11:00 foi o estado da máquina, e isso fica declarado como **não
      determinado**, em vez de receber explicação plausível e não testada.
- [x] AC3 — O custo real é **decomposto por tipo de processo**, e o denominador reconcilia
      ✅ `awk` 7 294 ms · `sed+head` 5 636 · `printf+tr` 5 340 · `git cat-file` 5 149 ·
      `basename` 3 051 = **26,5 s**, contra **29 s** do gate inteiro. Criar processo custa
      **40–95 ms**; `git ls-tree` uma vez custa 82 ms e `${f##*/}` custa 0,5 ms.
- [x] AC4 — Os processos removíveis saem do laço nos **dois** gates, com a saída **idêntica**
      ✅ o controle é a versão **anterior do script rodada na árvore de agora** — `git show HEAD:` →
      `scripts/.ctl-*.sh`, executada de dentro de `scripts/` porque o script deriva `ROOT_DIR` do
      próprio caminho. `diff` **vazio** nos dois.
      🔴 **E o primeiro `diff` parecia regressão** (`76` → `77` REQs) — era o **acervo crescendo**:
      a REQ desta frente nasceu entre a baseline e a medição. Sem o controle na mesma árvore eu
      teria lido o denominador novo como defeito do patch.

      | gate | antes | depois |
      |---|---|---|
      | `check-inherited-req` | 23 s | **5–9 s** |
      | `check-req-done-com-criterio-aberto` | 29–42 s | **9–15 s** |
- [x] AC5 — O que **não** foi removido fica declarado com o motivo
      ✅ o `sed -n | head -1` e o `awk` **ficam**: fundi-los numa passada mudaria o contrato da
      função `censo`, que o `check-req-done-caducou-falsify.sh` extrai esperando quatro campos — é
      outra mudança, com outra falsificação. O `check-release-tag-parity.sh` fica fora por ser **do
      upstream**. O laço do `upstream-sync.sh` fica por ter **um** elemento: não escala com o
      acervo, então é a mesma forma e não o mesmo defeito.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-05-publiquei-678s-como-o-custo-de-um-gate-a-partir-de-uma-passada-e-o-numero-nao-reproduz-e-o-custo-real-e-criar-processo-nao-o-git.md

## Context

**As duas medições são reais.** O que está errado é ter publicado **uma amostra** como se fosse uma
constante do gate — e, pior, ter atribuído o custo ao `git cat-file` por lembrança de uma lição escrita
no `run-local-gates.sh`, sem medir.

### A hipótese óbvia foi testada, e é falsa

Contenção era o suspeito: o 678 s foi cronometrado logo depois de uma tarefa de segundo plano ser
morta no limite de 30 min, e a morte por limite **não roda `trap`**, deixando o processo interno vivo.

```
duas passadas CONCORRENTES do mesmo gate:  60 s no total   ->  1,5x, não 20x
```

**Falsificada.** Contenção custa metade de uma passada, não vinte. O que mudou entre 00:00 e 11:00 foi
o estado da máquina — varredura, indexação, atualização —, e isso **não é verificável depois**. Fica
declarado como não determinado, em vez de receber uma explicação plausível e não testada.

### O custo real, decomposto — e o denominador fecha

Medido em 2026-10-05, 76 REQs, cada linha com 76 iterações:

| o que | custo | por iteração |
|---|---|---|
| `awk` (a função `censo`) | 7 294 ms | 95 ms |
| `sed -n … \| head -1` | 5 636 ms | 74 ms |
| `printf \| tr` | 5 340 ms | 70 ms |
| `git cat-file -e` | 5 149 ms | 67 ms |
| `basename` | 3 051 ms | 40 ms |
| **soma** | **26,5 s** | |
| `git ls-tree` **uma vez** | 82 ms | — |
| `${f##*/}` (sem processo) | 42 ms | 0,5 ms |

**O gate inteiro mede 29 s.** A soma das partes dá 26,5 s — reconcilia, e por isso a decomposição é
evidência e não ilustração.

🔴 **O `git cat-file` é 19% do custo, não a causa.** A causa é haver ~5 processos por iteração, e
criar processo no MSYS custar **40–95 ms**. Eu ia "corrigir" só o git, pela lição que já estava escrita
— e teria publicado um remédio para 19% do problema anunciando-o como a solução.

### O que continua valendo

A assimetria MSYS ↔ CI é real e **vem de log, não de cronômetro**: no `ubuntu-latest` o agregador
inteiro (13 gates) fecha em **7 s**, e este gate em **~1 s**. O que caiu foi a magnitude, não o fato.

## Escopo negativo

- Não se mexe no `scripts/check-release-tag-parity.sh`, que também tem `git cat-file` em laço: ele é
  **do upstream** (conferido por `git cat-file -e upstream/main:…`), e editá-lo criaria divergência de
  produto, que hoje é zero.
- O laço do `upstream-sync.sh` fica como está: `PRODUTO_EM_DOCS` tem **um** elemento
  (`docs/cli-parity.md`), então não escala com o acervo — não é o mesmo defeito, é a mesma forma.
