---
status: done
date: 2026-09-09
req: "docs/requisições/claude/REQ-2026-09-09-gate-de-paridade-de-subcomando-compara-3-de-8-comandos-e-a-lista-e-literal.md"
squad: "claude"
---

# Roadmap: o gate de paridade de subcomando compara 3 de 8 comandos, e a lista é literal

> Created: 2026-09-09 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-09-09-gate-de-paridade-de-subcomando-compara-3-de-8-comandos-e-a-lista-e-literal.md

O `check-subcommand-parity.sh` tem `commands=(adr req roadmap)` chumbado. Medido por execução:
**8 comandos têm subcomando**, então 5 ficam sem verificação de paridade. O mantenedor devolveu o
limite que declarei no #298 como requisito: *"herdar essa limitação seria fechar o buraco
reproduzindo a causa."*

## Acceptance Criteria

- [x] Lista derivada por execução, com guarda de reconciliação e denominador impresso.
- [x] Falsificação nas duas direções — faltando e sobrando — mais o controle.
- [x] Os 5 comandos hoje fora entram; nenhuma divergência real encontrada.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**
1. **Enumeração — feita antes de escrever a REQ, e por execução.** Para cada comando de primeiro
   nível, a linha `Usage:` do CLI diz se há subcomando:

   ```
   declarados no gate   adr req roadmap                        3
   FORA do gate         branch note release agents skills      5
   corretamente fora    update (Usage: [mode], nao [command])  1
                                                              ---
   comandos com subcomando                                     8
   ```

2. **Duas derivações erradas, tentadas e descartadas — registradas para não serem re-tentadas:**

   | tentativa | por que falha |
   |---|---|
   | `--help` da raiz por indentação | a descrição de `ship` e `commit` **continua no recuo 2**, indistinguível de comando. Devolveu `already`, `the`, `for`, `has`, `happens`, `skeleton`, `without` como comandos |
   | fonte, por padrão de registro | três padrões diferentes (`.command(`, `AddCommand(`, `add_subparsers(`) **e** dois falsos positivos — `integrations` e `thirdparty`, onde o nome do arquivo ≠ nome do comando |

   🔴 Trocar uma lista literal de 3 por **três padrões literais** não é derivar. A que funciona é
   execução: exigir que a `Usage:` **nomeie o candidato** e contenha `[command]`. Prosa é filtrada
   por construção — `already --help` cai no help da raiz, cuja `Usage:` não contém `already`.

3. **Quem esvazia esta wave sem quebrar regra escrita?**

   | forma | remédio |
   |---|---|
   | derivar zero comandos e sair 0 | denominador impresso, falha se `N == 0` |
   | derivar e não comparar, ou comparar subconjunto | guarda de reconciliação do ML-1B |
   | contar o `help` do framework como subcomando | exclusão escrita com motivo (ML-1A) |
   | falsificar só uma direção | ML-1C exige faltando **e** sobrando — foi o limite que declarei no #298 |

4. **Residual declarado.** O critério `Usage: … [command]` é do `commander`/`cobra`. Se um runtime
   mudar de framework, o detector precisa ser remedido — e isso é sítio de manutenção **nomeado**,
   não silencioso: sem `[command]` o comando cai fora do conjunto derivado e a guarda de
   reconciliação acusa a diferença contra a execução dos outros dois runtimes.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
- [x] Nenhuma linha de implementação escrita neste ML

## Wave 1 — Derivação, guarda e cobertura

### ML-1A — Lista derivada por execução, `help` excluído
**Status:** ✅ Concluído
**Files affected:** `scripts/check-subcommand-parity.sh`
**Actions:**
1. `commands=(...)` sai. Entra derivação: candidatos do help da raiz, cada um **validado por
   execução** (`Usage:` nomeia o candidato **e** contém `[command]`).
2. `help` sai dos conjuntos comparados, com o motivo escrito: é injetado pelo framework.
**Acceptance criteria:**
- [x] O conjunto derivado é `{adr, agents, branch, note, release, req, roadmap, skills}` — **8**
- [x] Denominador impresso, e falha se `N == 0`:
      `check-subcommand-parity: 8 comando(s) derivado(s) [...] · 24 subcomando(s) comparado(s)`
- [x] `update` **não** entra — controle negativo confirmado

🔴 **O extrator precisou de QUATRO iterações, e cada uma consertou um runtime quebrando outro.**
Registrado porque o padrão é o achado, não o código final:

| iteração | o que quebrou | causa medida |
|---|---|---|
| 1 | primeira palavra de qualquer linha | devolvia prosa: `executed`, `slug`, `and`, `never`, `only`, `two-phase` |
| 2 | coluna (2+ espaços), recuo fixo em 2 | perdeu `roadmap new` — o arg é `[title]`, e o padrão só admitia um `[options]` seguido de `<arg>` |
| 3 | recuo generalizado | perdeu `list [options]` do Node, que **não tem descrição**, logo não tem corrida de 2 espaços |
| 4 | regra combinada | `third-party` do Go é o nome **mais longo** do bloco, e o cobra alinha deixando **um** espaço só |

A regra final usa a segunda palavra como discriminante: descrição começa em maiúscula ou é grupo
`[...]`/`<...>`; prosa continua em minúscula. Cada cláusula existe por um caso medido, nenhuma por
precaução.

### ML-1B — Guarda de reconciliação
**Status:** ✅ Concluído
**Files affected:** `scripts/check-subcommand-parity.sh`
**Actions:**
1. O gate reprova se um comando derivado não for contabilizado — o padrão que o mantenedor descreveu
   no `check-git-branch-guard-hook-schema.sh`: *"detecta o que não conhece"*.
**Acceptance criteria:**
- [x] 🔴 Falsificação: injetando `validate` na lista derivada (ele **não** tem subcomando):

      ```
      ✗ RECONCILIACAO: 'validate' foi derivado como tendo subcomando, mas o
        extrator do Go devolveu conjunto VAZIO                          exit 1
      ```

      O `continue` silencioso que existia neste ponto era o buraco: um comando derivado cujo
      extrator falhasse sairia da comparação **sem deixar rastro**.

### ML-1C — Falsificação nas duas direções
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**
1. Subcomando **faltando** num runtime → reprova. Já medido no #298 com `req list` removido do Node.
2. Subcomando **sobrando** num runtime → reprova. **Não foi falsificado no #298**, e é o limite que
   virou requisito.
**Acceptance criteria:**
- [x] As duas direções reprovam, cada uma com a saída registrada:

      | direção | mutação | saída | exit |
      |---|---|---|---|
      | faltando | `new Command('prune')` → `'prune-REMOVIDO'` no Node | `✗ branch: 'prune' faltando no runtime node` | **1** |
      | sobrando | `adr sonda-extra` plantado só no Node | `✗ adr: 'sonda-extra' sobrando no runtime node` | **1** |
      | controle | árvore intacta | `8 comandos · 24 subcomandos` | **0** |

- [x] Controle: árvore intacta passa

🔴 **Duas sondas minhas falharam antes de a falsificação valer, e as duas do mesmo jeito — medindo
a coisa errada:**

1. `sed` procurando `cmd.command('prune')`, quando `branch.js` usa `new Command('prune')`. **A
   mutação nunca aplicou**, e o `exit 0` parecia gate cego. Peguei conferindo se o padrão existia.
2. O worktree foi criado de `HEAD`, mas o gate novo estava **sem commit** na árvore principal — a
   falsificação rodou contra a versão ANTIGA do gate, que não deriva `branch`. Peguei porque a
   linha de denominador não apareceu na saída.

Sem essas duas conferências eu teria reportado "o gate não pega subcomando faltando".

### ML-1D — Os 5 comandos entram
**Status:** ✅ Concluído
**Files affected:** `scripts/check-subcommand-parity.sh`
**Actions:**
1. Rodar o gate com o conjunto de 8 e medir o que aparece.
**Acceptance criteria:**
- [x] 🔴 Divergência achada **não é corrigida aqui** — não houve nenhuma a corrigir.
- [x] **Resultado: os 8 comandos concordam nos 3 runtimes.** 24 subcomandos comparados, zero
      divergência real.

      Fica escrito porque **gate sem achado é resultado, não fracasso**: a Regra Dura de Paridade
      está sendo cumprida nos 5 comandos que nunca tinham sido verificados. O que o gate mudou não
      foi o veredito sobre o produto — foi passar a **poder** dar um veredito sobre 5 comandos onde
      antes não havia nenhum.

      As 11 "divergências" que apareceram nas iterações 1 a 4 eram **todas** artefato do extrator,
      confirmado por execução direta dos três CLIs lado a lado. Nenhuma virou issue, e é bom que
      não: seriam 11 falsos positivos publicados.

## Residual declarado

- O detector depende de `commander`/`cobra` imprimirem `[command]` na `Usage:`. Nomeado no ML-0A.
- Este gate é **nosso**. O #298 já está aberto no upstream e o mantenedor disse que a análise entrou
  no artefato dele; empurrar código por cima seria ruído.
