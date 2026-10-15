---
status: Done
date: 2026-10-15
author: "claude"
adr: "docs/adr/ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-15-o-classificador-de-predicado-de-so-acusa-seam-e-entrada-externa-como-classificacao.md"
---

# REQ: o classificador de predicado de SO acusa seam e entrada externa como classificacao

> Date: 2026-10-15 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation

O sync do [#562](https://github.com/kgsaran/trackfw/pull/562) do upstream trouxe
`internal/agentconfig/agentconfig.go`, e o `scripts/check-os-predicate-classification.sh`
**reprovou** nomeando dois sítios:

```
FAIL check-os-predicate-classification   exit=1
  internal/agentconfig/agentconfig.go:89   return runtime.GOOS
  internal/agentconfig/agentconfig.go:282  filepath.IsAbs(cleaned)
```

A `ADR-2026-09-09` decide que o discriminante é **a origem do argumento**, não a intenção do
autor. Os dois sítios foram lidos um a um — e os vereditos **divergem**, que é justamente o que
a leitura em bloco teria perdido:

| sítio | veredito | por quê |
|---|---|---|
| `:89` `return runtime.GOOS` | **seam, não classificação** | é o corpo de `effectiveGOOS()`, o getter que `SetPlatformForTest` sobrescreve. Ponto único por onde a plataforma entra; sem string autorada e sem comparação |
| `:282` `filepath.IsAbs(cleaned)` | **classificação, de verdade** | `cleaned` vem de `os.Getenv("CLAUDE_CONFIG_DIR")`, e é a **mesma forma** dos nove sítios já declarados no baseline |

🔴 **A primeira leitura declarou os DOIS como falso positivo, e a medição do baseline desmentiu
metade.** O que corrigiu foi olhar a forma dos nove já declarados: `IsAbs(clean)` no
`credential.go` e `IsAbs(f)` no `sync.go` são a mesma construção do `IsAbs(cleaned)` do
`agentconfig.go`. E o `credential.go` carrega **explorabilidade medida** exatamente nessa forma —
`/c/...` sai `rc=0` e `C:\...` sai `rc=2`, porque o `IsAbs` exige letra de unidade no Windows.
Tratar o `:282` como seam teria **afrouxado o ratchet** na classe que já custou uma issue
(kgsaran/trackfw#544).

## Acceptance Criteria

- [x] O classificador reconhece o **getter de plataforma** como costura (D3), e a regra é estreita:
      aceita `return <predicado>` sozinho na linha e **recusa** a forma com comparação. Entregue em
      `scripts/check-os-predicate-classification.sh`, na alínea (c) de `eh_d3_costura`, com o motivo
      e a medição escritos no próprio comentário.
- [x] O sítio de `IsAbs` sobre valor de variável de ambiente entra no **BASELINE com o motivo
      escrito**, por ser a mesma classe dos nove anteriores — e o motivo registra que a primeira
      leitura o classificou errado, e o que desmentiu. Entregue na entrada
      `internal/agentconfig/agentconfig.go` do `BASELINE`.
- [x] O gate volta a `rc=0` **com o denominador reconciliando**: 186 + 64 + 7 + 27 + 14 = 298,
      medido em 2026-10-15.
- [x] A regra nova é falsificada nas **duas direções**, com as formas que importam — 7 formas,
      7 acertos, incluindo as cinco que comparam ou embrulham a plataforma e têm de ser recusadas.

## Linked ADR

ADR: docs/adr/ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor.md

## Blocked by ADRs
<!-- none -->

## Escopo negativo

🔴 **Nenhuma linha de produto do upstream muda.** Os dois sítios estão em
`internal/agentconfig/agentconfig.go`, que é dele; a divergência de produto aqui é **zero** e
continua zero. A ADR oferece como saída 1 *"o sítio passa a usar o resolvedor canônico"* — isso
seria mudança no produto, vetada pelo escopo negativo de sempre: achado vira **issue**, não
correção local. Aqui não houve achado a reportar: o `:282` é uso correto do `IsAbs`, e o `:89` é
o seam que o próprio produto desenhou para ser sobrescrito em teste.

## Limite declarado

**O cego do `effectiveGOOS() ==` continua aberto, e é maior que esta REQ.** Duas linhas abaixo do
`:89` há `effectiveGOOS() == "windows"` — **a comparação de verdade** —, e o gate **não a vê**,
porque ela não usa nenhum dos nove predicados da lista. Medido em 2026-10-15: **2 ocorrências**,
as duas em `internal/agentconfig/agentconfig.go`.

🔴 Isto não entrou aqui por decisão de escopo, não por esquecimento: ensinar o gate a ver o getter
*derivado* faria o ratchet acusar sítios hoje invisíveis em todo o acervo, e **cada um precisaria
de veredito próprio**. A classe fica nomeada e medida, para quem a abrir ter o número de partida.

## Linked Roadmap

Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-15-o-classificador-de-predicado-de-so-acusa-seam-e-entrada-externa-como-classificacao.md
