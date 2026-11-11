---
status: Accepted
date: 2026-11-11
author: "claude"
---

# ADR: limpeza garantida de mktemp nos nossos scripts e por trap EXIT que cita a variavel e o rm explicito fica

> Date: 2026-11-11 | Status: Accepted

## Context

O [#681](https://github.com/kgsaran/trackfw/pull/681) do upstream mesclou em 11/11/2026 às 16:51
(local), fechando a **nossa** [#676](https://github.com/kgsaran/trackfw/issues/676), e trouxe o gate
`scripts/check-mktemp-cleanup.sh` ligado no `make parity-rest` — alvo que o `quality.yml`
compartilhado roda no `parity-other-gates`, com o `parity` dependendo dele.

Rodado sobre a **nossa** árvore antes do sync, o gate dele acusa **3 sítios que só existem neste
fork**, com `0 traps` de qualquer sinal:

```
scripts/anexa-crlf.sh:110                          T=$(mktemp -d) || exit 1
scripts/check-contorno-dos-shims-caducou.sh:223    TMPP=$(mktemp -d 2>/dev/null) || TMPP=""
scripts/check-copia-do-path-esta-atras.sh:164      TMPD=$(mktemp -d 2>/dev/null) || TMPD=""
```

A acusação é **verdadeira**: o diretório aparece em ~50 ms e **sobrevive ao kill**, medido vigiando
o `TMPDIR` e matando pelo PID. O `rm -rf` que existe no fim do caminho normal **não é limpeza
garantida** — ele não roda quando o script sai entre o `mktemp` e ele.

A enumeração está **fechada em 3**: das 9 ocorrências de `mktemp` nos 23 scripts só nossos, 5 já
têm trap e 1 é prosa (a justificativa do `FORA` no `run-local-gates.sh`).

## Decision

**D1 — A forma é `trap` de EXIT citando a variável, imediatamente após o `mktemp`, no mesmo
escopo.** Das quatro formas que o gate aceita como cobertura (DIRECT, ALIAS, FUNCTION, CONTAINED),
adotamos **DIRECT**: o corpo do trap cita `$V`, `${V}`, `${V:-}` ou `${V:-x}`. É a única que não
depende de ordem de escrita de apelido nem de indireção por função — as duas que o próprio gate
declara como fonte dos residuais.

**D2 — A citação usa `${V:-}`, não `$V`.** Os três scripts rodam com `set -uo pipefail`. Se o trap
disparar antes da atribuição, `$V` morre em variável não vinculada **dentro do trap**, que é o pior
lugar para falhar. `${V:-}` é aceita pelo gate como DIRECT e é imune a isso.

**D3 — O `rm -rf` explícito do caminho normal FICA.** Ele deixa de ser a limpeza e passa a ser
limpeza antecipada; `rm -rf` de diretório inexistente sai 0, então o trap rodar depois é inócuo.
Remover o `rm` daria um diff maior sem nenhum ganho medido.

**D4 — O trap tolera string vazia e silencia erro.** Em dois dos três sítios o `mktemp` pode
falhar (`|| TMPP=""`), e `rm -rf ""` erra. A forma é `rm -rf "${V:-}" 2>/dev/null || :`, que
preserva a citação exigida por D1/D2.

**D5 — O código de saída dos scripts é invariante, e isso se MEDE nas duas direções.** Trap que
altere `rc` produziria **verde falso** num gate — o modo de falha caro. Não basta que o self-test
continue passando: um caso que reprova tem de continuar reprovando.

**D6 — Sítio nosso é REQ nossa; sítio do upstream é issue.** A causa é a mesma do #676, mas os 3
sítios são de scripts que só existem aqui. Pela Regra Dura de Causa Raiz, mesma causa fica na mesma
REQ — e a REQ **dele** governa os sítios **dele**. O escopo negativo desta casa (achado em produto
do upstream vira issue, não correção local) tem o inverso: achado nosso não entra na REQ dele.

**D7 — O sync e o conserto vão no mesmo PR, com o sync primeiro.** Um PR só com o sync nasceria
vermelho no `parity-other-gates`; um PR só com o conserto não teria o gate em árvore para provar
nada. E o veredito final é do gate **em árvore**, nunca da cópia extraída para o scratchpad, que
serviu só para prever.

## Consequences

**Positivas.** O vazamento fecha nos 3 sítios, que é defeito real independente do gate. O sync
entra verde. E a cobertura passa a ser **verificável por instrumento do upstream**, não por
inspeção nossa — o gate roda em todo PR, então regressão futura é acusada por nome e arquivo.

**Negativas, declaradas.**

- Os **residuais R1 a R4 do gate** (trap em subshell de `d=$(fn)`, reatribuição em laço, `exec`
  substituindo o shell, indireção de dois níveis) continuam fora de alcance. Nenhum dos nossos 3
  cai neles — conferido: os três são atribuição direta em escopo **global** dentro de um `if`, com
  as funções fechadas antes.
- `mktemp` em script **não rastreado** não é visto, porque o gate varre `git ls-files`. É o mesmo
  limite já declarado no `check-os-predicate-classification.sh`.
- 🔴 A decisão **não** cria gate nosso. O instrumento é o do upstream, e isso é deliberado: um
  segundo gate para a mesma propriedade seria a segunda solução de um problema que já tem uma.
  O custo é que a propriedade depende do gate dele continuar existindo — se ele o remover, a
  cobertura deixa de ser verificada e nada acusa.

## Alternatives Considered

**A1 — Mover o `rm` para mais perto do `mktemp`.** Rejeitada: encurta a janela sem fechá-la, e o
gate continuaria acusando — corretamente.

**A2 — Declarar os 3 como exceção, por serem caminho de `--self-test`.** Rejeitada por duas razões.
O vazamento é real nos três e foi medido por efeito; e o gate **não tem** mecanismo de exceção —
afrouxá-lo exigiria mexer em arquivo do upstream, criando divergência de produto onde hoje ela é
zero.

**A3 — `trap` citando um apelido (`printf -v A '%q' "$V"`), que é a forma ALIAS do gate.**
Rejeitada: o próprio gate declara que a cobertura por apelido depende de haver **exatamente uma**
escrita no apelido e de ela preceder o trap. É mais regra para honrar, em troca de nada aqui.

**A4 — Levar os 3 sítios ao upstream como ML na REQ dele.** Rejeitada por D6: os arquivos não
existem lá, então o PR seria de código que o upstream não tem.
