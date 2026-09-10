---
status: Done
date: 2026-09-10
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum-e-ficou-vermelho-por-semanas.md"
---

# REQ: o `check-upstream-content` não roda em lugar nenhum, e ficou vermelho por semanas

> Date: 2026-09-10 | Status: Done

## Motivation

Em 2026-09-10, auditando critérios de aceite de outra REQ, rodei
`scripts/check-upstream-content.sh` **à mão** e ele estava **vermelho**: 7 arquivos de governança do
upstream em `docs/`, incluindo uma ADR que **5 REQs nossas citavam como se fosse nossa**.

O vazamento foi corrigido no ML-3A da `REQ-2026-09-09-governanca`. **Esta REQ é sobre a outra
metade:** por que ninguém soube dele.

### O gate funciona. Ninguém o executa.

```
Makefile                nao tem alvo para ele
.github/workflows/*     nenhum job o invoca
```

Ele foi escrito em 2026-08-29 pela `REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate`,
justamente para que a política de conteúdo **deixasse de depender de alguém lembrar**. E então ficou
dependendo de alguém lembrar de rodá-lo.

🔴 **Um gate que ninguém executa é pior que gate nenhum**, porque produz a sensação de cobertura. Os
7 arquivos entraram por merges ao longo de semanas, e cada merge passou por `validate`, por `go
build`, pelos gates do `parity-rest` — e por nenhum que fizesse esta pergunta.

### Não é caso isolado: são DEZ, e nenhum roda

Derivado em 2026-09-10 por `git ls-tree` — **10 scripts em `scripts/` são só nossos**, de 71 no
total. E a medição de quem os invoca:

```
                                        Makefile   CI   outro script
check-inherited-req.sh                       0      0        1
check-platform-predicates.sh                 0      0        0
check-req-done-com-criterio-aberto.sh        0      0        0
check-req-layout.sh                          0      0        0
check-slug-inventory.sh                      0      0        0
check-subcommand-parity.sh                   0      0        0
check-upstream-content.sh                    0      0        0
check-upstream-sync-falsify.sh               0      0        1
measure-os-predicate-sites.sh                0      0        0
upstream-sync.sh                             0      0        1
```

🔴 **Nenhum dos dez é executado por automação nenhuma.** Não é "quatro gates esquecidos": é o
conjunto inteiro do que este fork construiu para se governar, rodando **só quando alguém lembra**.

Um deles — `check-platform-predicates.sh` — tem a decisão de ficar de fora **escrita e medida** no
`CLAUDE.md`. É o contraste que mostra que os outros nove são omissão, não escolha.

🔴 **Correção de número:** a primeira redação desta REQ dizia *"6 scripts só nossos"*, herdado de uma
frase do `CLAUDE.md` que envelheceu. O valor derivado é **10**. Contar à mão o que um comando deriva
foi o defeito que este repositório pagou três vezes esta semana.

### Por que a correção não é "põe no Makefile"

O `Makefile` e os **7 workflows** são **arquivos compartilhados com o upstream** — conferido com
`git ls-tree`, não com `cat-file`. Hoje a divergência de produto é **zero**, e o `CLAUDE.md` registra
que os gates ficam fora do `Makefile` **de propósito**, porque modificá-lo criaria divergência que
todo merge futuro pagaria.

O precedente do repositório é claro: **10 scripts só nossos, 0 arquivos compartilhados diferindo.**
Adição não é divergência.

> 🔴 **Nota de método.** A primeira verificação de quais workflows eram dele usou
> `git cat-file -e upstream/main:.github/workflows/<x>.yml` e devolveu *"só nosso"* para **todos os
> 7** — o que era falso. O MSYS converteu `upstream/main:.github/...` em
> `upstream\main;.github\...` quando o caminho após os dois-pontos **começa com ponto**. Caminhos
> como `docs/...` e `scripts/...` passam intactos. É a mesma família do achado que levamos ao
> upstream na [#308](https://github.com/kgsaran/trackfw/issues/308).
>
> **Os dois gates que usam esse padrão não são afetados**: ambos só consultam `docs/req/`, e a
> pré-condição deles falha **fechada** se a resolução quebrar. Verificado, não presumido.

## Acceptance Criteria

- [x] **AC1** — Existe **um** ponto de entrada que executa os gates só nossos, e ele é **arquivo só
      nosso**. Divergência de produto ao fim: **zero**, medida por arquivo compartilhado que difere,
      não por contagem de arquivos.
- [x] **AC2** — O ponto de entrada roda **em CI, em push e em PR** — não por `workflow_dispatch`. 🔴
      Disparo manual é o que esta REQ existe para eliminar: os dois workflows de Windows são
      `workflow_dispatch` e é por isso que o ramo Windows dos gates de PATH curado nunca foi
      exercitado.
- [x] **AC3** — **Falsificação nas duas direções, em CI**: com um vazamento plantado o job **reprova**;
      com a árvore limpa ele passa. Não vale só a segunda.
- [x] **AC4** — 🔴 **A lista de gates executados é derivada ou tem guarda de completude.** Um gate
      novo em `scripts/` que ninguém acrescentar à lista voltaria a não rodar — que é exatamente o
      defeito desta REQ, reintroduzido pela correção dela.
- [x] **AC5** — Gate que **não pode** rodar em CI (Linux) é **declarado com o motivo**, não omitido em
      silêncio. Hoje há um: `check-platform-predicates.sh`, cujo motivo já está escrito no `CLAUDE.md`.
- [x] **AC6** — Existe entrada por `make` **sem tocar no `Makefile` compartilhado**.
- [x] **AC7** — `validate` e os seis gates verdes ao fim, com o binário da árvore reconstruído, e
      divergência de produto **zero**.

## Resultado

**Três arquivos, todos adições. Divergência de produto: zero.** O CI roda em `push` e `pull_request`,
e as duas direções do AC3 foram observadas **lá**, não deduzidas daqui.

```
arvore limpa       success   9 executados · 0 falhas · 0 compartilhados diferindo
vazamento          failure   FAIL check-upstream-content  docs/analise-cmdb/README.md
revertido          success
```

**A enumeração corrigiu o número:** são **11** scripts só nossos de 72, e **nenhum** era invocado por
automação nenhuma. A primeira redação desta REQ dizia *"6"*, herdado de uma frase do `CLAUDE.md` que
envelheceu.

### 🔴 Pôr o gate no CI descobriu quatro defeitos que estavam invisíveis

O job reprovou **seis vezes** antes de passar, e a causa raiz é uma linha de configuração:
**`Committer identity unknown`** — o runner não tem `user.email`, e `git merge --no-commit` exige
identidade mesmo sem commitar.

Entre o sintoma e a causa havia **quatro camadas de stderr descartado**, e cada uma parecia um achado
diferente. Uma delas chegou a ser escrita no roadmap como *"o `upstream-sync` suprime produto em
Linux"*. **Não era.**

As três correções de diagnóstico ficam — elas não eram o defeito, eram o que impedia enxergá-lo:

| script | mudança |
|---|---|
| `check-upstream-sync-falsify.sh` | caminho do worktree portátil; captura a saída do sync |
| `upstream-sync.sh` | 🔴 **o `git merge` passa a falhar alto** — antes, falha sem conflito produzia `0 de produto trazidos` como se fosse medição |
| `run-local-gates.sh` | pré-condição dos runtimes: morte silenciosa vira falha nomeada |

A do `upstream-sync.sh` é a mais séria: **o script que governa todo merge do upstream neste fork
podia reportar "trouxe zero" quando o merge nem tinha acontecido.**

## Negative Scope

- **Não** tocar no `Makefile` nem em nenhum dos 7 workflows do upstream. A decisão do usuário em
  2026-09-10 foi explícita: arquivos só nossos, divergência zero.
- **Não** propor o gate ao upstream nesta REQ. Se couber no produto dele, é issue própria, depois de
  medido aqui.
- **Não** corrigir vazamento nenhum aqui. O vazamento dos 7 já foi tratado no ML-3A da
  `REQ-2026-09-09-governanca`. Esta REQ é sobre **execução**, não sobre conteúdo.
- **Não** pôr o `check-platform-predicates.sh` no CI. A decisão de mantê-lo local é medida e escrita:
  14 das 20 linhas do corpus só dizem algo no Windows, e a linha do `execbit` reprovaria em
  `ubuntu-latest` por fato de NTFS.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum-e-ficou-vermelho-por-semanas.md
