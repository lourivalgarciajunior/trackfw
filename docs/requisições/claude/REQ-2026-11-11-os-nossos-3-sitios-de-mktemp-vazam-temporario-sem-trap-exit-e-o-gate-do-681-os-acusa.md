---
status: Done
date: 2026-11-11
author: "claude"
adr: "docs/adr/ADR-2026-11-11-limpeza-garantida-de-mktemp-nos-nossos-scripts-e-por-trap-exit-que-cita-a-variavel-e-o-rm-explicito-fica.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-11-11-os-nossos-3-sitios-de-mktemp-vazam-temporario-sem-trap-exit-e-o-gate-do-681-os-acusa.md"
---

# REQ: os nossos 3 sitios de mktemp vazam temporario sem trap EXIT e o gate do 681 os acusa

> Date: 2026-11-11 | Status: Done
| Linear Issue:
| Jira Issue:

## Motivation

O upstream mesclou o [#681](https://github.com/kgsaran/trackfw/pull/681) em 11/11/2026 às
16:51 (local), fechando a **nossa** [#676](https://github.com/kgsaran/trackfw/issues/676), e com
ele chegou o gate `scripts/check-mktemp-cleanup.sh`, ligado no `make parity-rest` — alvo que o
`quality.yml` compartilhado roda no job `parity-other-gates`, com o `parity` dependendo dele.

🔴 **Medido por efeito ANTES do sync**, rodando o gate dele (extraído do `356fb79b`, conferido
`cmp`-idêntico ao da branch que eu havia medido) sobre a **nossa** árvore:

```
rc=1 · 15 achados em 10 arquivos
  dele, e o #681 CONSERTA        7 arquivos
  🔴 NOSSOS, e ninguem conserta  3 arquivos / 3 achados      3+7+0 = 10 ✓
o mesmo gate sobre a arvore DELE    rc=0 · 0 achados · self-test 32/0
```

Os três sítios:

```
scripts/anexa-crlf.sh:110                          T=$(mktemp -d) || exit 1
scripts/check-contorno-dos-shims-caducou.sh:223    TMPP=$(mktemp -d 2>/dev/null) || TMPP=""
scripts/check-copia-do-path-esta-atras.sh:164      TMPD=$(mktemp -d 2>/dev/null) || TMPD=""
```

**A acusação é verdadeira, não ruído de gate novo.** Os três têm **`0 traps`** de qualquer sinal,
e o vazamento foi provado por efeito: o diretório aparece em ~50 ms e **sobrevive ao kill**.

🔴 **E três sondas minhas mentiram antes de uma acertar** — isto entra na REQ porque é o que
explica por que o defeito sobreviveu a uma primeira leitura:

| sonda | disse |
|---|---|
| rodar o self-test normalmente | **0 vazado** — mediu o caminho **feliz**, onde o `rm` explícito do fim roda |
| `timeout -s INT` a 0,35 s | 0 — matava **antes** do `mktemp` (os self-tests levam 4,7–7,1 s) |
| `timeout -s INT` a 2 s | 0 nas três, e **1** numa repetição da mesma linha — não reproduz |
| vigiar o `TMPDIR` e matar **pelo PID** no instante em que o diretório aparece | 🔴 **vaza** |

A primeira é a lição: eu quase registrei *"o vazamento é teórico"* medindo justamente o caminho em
que o `rm` roda — e o que o gate afirma é o outro. A divergência do `timeout` fica **declarada como
causa desconhecida**, pela mesma regra do `validate 1 antes · 0 depois` do sync do #557.

**Por que isto é REQ nossa e não ML na REQ dele:** a causa é a mesma (`mktemp` sem limpeza
garantida), mas os sítios são **nossos** — scripts que só existem neste fork — e o escopo negativo
desta casa manda achado em produto do upstream virar issue, não correção local. O inverso também
vale: sítio nosso não entra na REQ dele.

## Acceptance Criteria

- [x] AC1 — os 3 sítios têm limpeza garantida de EXIT no mesmo escopo, e o gate **em árvore**
      (depois do sync) sai `rc=0` com `0 achados` sobre a nossa árvore inteira
- [x] AC2 — o fechamento do vazamento é provado **por efeito**, com o instrumento que acertou
      (vigiar o `TMPDIR`, matar pelo PID no instante em que o diretório aparece), e a medição
      pré-conserto fica ao lado como **controle**
- [x] AC3 — o `trap` **não altera o código de saída** dos três scripts, provado nas duas direções:
      self-test que passa continua `rc=0`, e caso que reprova continua reprovando
- [x] AC4 — a enumeração fica **declarada fechada**: as 9 ocorrências de `mktemp` nos nossos
      scripts classificadas em 3 acusados + 5 cobertos + 1 prosa, e o denominador reconcilia
- [x] AC5 — o sync do `356fb79b` entra **no mesmo PR**, com retenção provada por efeito e
      **zero** conflito de produto
- [x] AC6 — `trackfw validate` com 0 violações, e a contagem de avisos **derivada da saída**,
      nunca digitada ao lado de um `rc`
- [x] AC7 — `scripts/run-local-gates.sh` sobre a árvore **final** (não mista), com o denominador
      impresso
- [x] AC8 — `docs/agents-working-context.md` atualizado, carregando o que **não** se deriva: a
      medição, o motivo e as sondas que mentiram

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-11-11-limpeza-garantida-de-mktemp-nos-nossos-scripts-e-por-trap-exit-que-cita-a-variavel-e-o-rm-explicito-fica.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-11-11-os-nossos-3-sitios-de-mktemp-vazam-temporario-sem-trap-exit-e-o-gate-do-681-os-acusa.md
