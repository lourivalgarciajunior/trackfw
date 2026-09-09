---
status: Done
date: 2026-09-09
author: "claude"
adr: "docs/adr/ADR-2026-09-05-paridade-tri-runtime-e-a-regra-de-que-nenhuma-mudanca-de-comportamento-entra-num-cli-so.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-09-gate-de-paridade-de-subcomando-compara-3-de-8-comandos-e-a-lista-e-literal.md"
---

# REQ: o gate de paridade de subcomando compara 3 de 8 comandos, e a lista é literal

> Date: 2026-09-09 | Status: Done

## Motivation

Abrimos o [#298](https://github.com/kgsaran/trackfw/issues/298) no upstream mostrando que o
`check-cli-parity.sh` dele compara só o primeiro nível, e oferecemos o nosso
`check-subcommand-parity.sh` como referência de desenho. Declarei ali, como limite:

> *"A lista de comandos é literal e não descobre um quarto sozinha — é um sítio de manutenção, e
> vale dizer isso na entrada em vez de deixar para o dia em que falhar."*

**Ele devolveu esse limite como requisito, e com a frase que motiva esta REQ:**

> *"🔴 Herdar essa limitação seria **fechar o buraco reproduzindo a causa**."*

Fui medir o custo real da nossa lista literal. **Não é um risco futuro: é um ponto cego ativo.**

### Medido por execução, não por leitura de fonte

Para cada comando de primeiro nível, a linha `Usage:` do próprio CLI diz se ele tem subcomando:

```
adr          TEM subcomando   Usage: trackfw adr [options] [command]      <- declarado
req          TEM subcomando   Usage: trackfw req [options] [command]      <- declarado
roadmap      TEM subcomando   Usage: trackfw roadmap [options] [command]  <- declarado
branch       TEM subcomando   Usage: trackfw branch [options] [command]   <- FORA
note         TEM subcomando   Usage: trackfw note [options] [command]     <- FORA
release      TEM subcomando   Usage: trackfw release [options] [command]  <- FORA
agents       TEM subcomando   Usage: trackfw agents [options] [command]   <- FORA
skills       TEM subcomando   Usage: trackfw skills [options] [command]   <- FORA
update       sem subcomando   Usage: trackfw update [options] [mode]
```

**O gate compara 3 de 8.** Cinco comandos têm o conjunto de subcomandos **não verificado** entre os
três runtimes — e a Regra Dura de Paridade vale para eles igual.

### Duas derivações erradas que eu tentei antes de achar a certa

Registradas para não serem re-tentadas:

**1. Derivar do `--help` da raiz por indentação.** Falha. Os comandos ficam no recuo 2, mas a
descrição de alguns — `ship`, `commit` — **tem continuação no recuo 2**, indistinguível de um
comando. A derivação ingênua devolveu `already`, `always`, `the`, `for`, `has`, `happens`,
`skeleton`, `without` como se fossem comandos.

**2. Derivar do fonte por padrão de registro.** Funciona por runtime, mas com **três padrões
diferentes** (`.command(` no Node, `AddCommand(` no Go, `add_subparsers(` no Python), e produziu
**falso positivo**: `integrations` e `thirdparty` apareceram porque o nome do **arquivo** não é o
nome do comando. Trocar uma lista literal de 3 por três padrões literais não é derivar.

**A que funciona é execução:** rodar `<candidato> --help` e exigir que a linha `Usage:` **nomeie o
candidato** e contenha `[command]`. Prosa é filtrada por construção — `already --help` cai no help
da raiz, cuja `Usage:` não contém `already`.

### O `help` do framework não conta

Correção do mantenedor no #298, conferida aqui: minha contagem de **12** subcomandos incluía os três
`help` que o `commander` injeta. O número real é **9** (`adr` 2, `req` 3, `roadmap` 4).

> *"Contar o `help` faria o gate exigir paridade de algo que o **framework** gera, não nós."*

## Acceptance Criteria

- [x] **AC1** — A lista de comandos-com-subcomando é **derivada por execução**, não literal. O
      critério é a linha `Usage:` nomear o comando **e** conter `[command]`.
- [x] **AC2** — 🔴 **Guarda de reconciliação**, no padrão que o mantenedor descreveu: o gate reprova
      se um comando **derivado** não estiver contabilizado. Um nono comando amanhã **não passa em
      silêncio**. Falsificação obrigatória: introduzir um comando com subcomando e o gate tem de
      reprovar **antes** de comparar conjuntos.
- [x] **AC3** — O `help` injetado pelo framework é **excluído** dos conjuntos comparados, e a
      exclusão é escrita com o motivo.
- [x] **AC4** — Falsificação nas **duas** direções, que era o limite declarado no #298: subcomando
      **faltando** num runtime reprova, **e** subcomando **sobrando** reprova. Mais o controle: a
      árvore intacta passa.
- [x] **AC5** — Denominador impresso: `N comandos derivados · M subcomandos comparados`. Verde sem
      denominador não conta.
- [x] **AC6** — Os 5 comandos hoje fora (`branch`, `note`, `release`, `agents`, `skills`) passam a
      ser comparados. 🔴 Se algum deles **divergir** entre runtimes, isso é achado — vai para issue
      no upstream com a medição, não é corrigido aqui.
- [x] **AC7** — `trackfw validate` sem violação, denominador conferido, e divergência de produto
      **zero** (o gate é adição só nossa).

## Negative Scope

- **Não** tocar produto. Se a comparação achar divergência real entre runtimes, ela vira **issue**,
  não correção local — é produto do upstream.
- **Não** derivar por leitura de fonte. Medido: três padrões e dois falsos positivos.
- **Não** propor este gate ao upstream nesta REQ. O #298 já está aberto e ele já disse que a
  análise entrou no artefato dele; empurrar código por cima seria ruído.

## Resultado

**Os 8 comandos concordam nos 3 runtimes.** 24 subcomandos comparados, zero divergência real — e o
AC6 previa que divergência viraria issue. Não houve nenhuma.

Isso é resultado, não fracasso: o gate passou a **poder** dar veredito sobre 5 comandos onde antes
não havia nenhum. O que mudou não foi o estado do produto, foi a cobertura da verificação.

## Residual declarado

- **O extrator precisou de 4 iterações**, cada uma consertando um runtime e quebrando outro (ver
  ML-1A). A regra final é heurística — cada cláusula justificada por um caso medido —, e parsing de
  `--help` continua sendo fonte frágil por natureza. Se um runtime trocar de framework, o detector
  precisa ser remedido; a guarda de reconciliação é o que garante que isso apareça em vez de
  silenciar.
- **As 11 "divergências" das iterações intermediárias eram artefato**, confirmado por execução
  direta dos três CLIs lado a lado. Nenhuma foi publicada — teriam sido 11 falsos positivos no
  upstream.
- **Não medi em Linux nem macOS.** O gate lê `--help`, e o formato não tem predicado de plataforma
  óbvio, mas isso é leitura e não medição.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-paridade-tri-runtime-e-a-regra-de-que-nenhuma-mudanca-de-comportamento-entra-num-cli-so.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-09-gate-de-paridade-de-subcomando-compara-3-de-8-comandos-e-a-lista-e-literal.md
