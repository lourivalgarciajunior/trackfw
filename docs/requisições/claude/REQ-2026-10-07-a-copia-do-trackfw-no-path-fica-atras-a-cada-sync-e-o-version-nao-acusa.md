---
status: Done
date: 2026-10-07
author: ""
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-07-a-copia-do-trackfw-no-path-fica-atras-a-cada-sync-e-o-version-nao-acusa.md"
---

# REQ: a copia do trackfw no PATH fica atras a cada sync e o --version nao acusa

> Date: 2026-10-07 | Status: Open
| Linear Issue: 
| Jira Issue: 

## Motivation

O `upstream-sync.sh` recompila `bin/trackfw` e `bin/trackfw.exe` depois do merge (AC5), mas **não**
refaz a cópia em `%APPDATA%/npm/trackfw.exe` — que é o binário que o **PATH** entrega e, desde o
[#527](https://github.com/kgsaran/trackfw/pull/527), o que **todos** os hooks de guard executam, em
todos os projetos desta máquina.

Então a cada sync a cerca passa a rodar por um binário **atrasado**, em silêncio.

🔴 **E o teste óbvio não detecta.** Medido em 2026-10-07, com a cópia de 06/10 22:17 e a árvore de
07/10 14:32:

```
trackfw --version  (copia velha)   trackfw 9.2.0
trackfw --version  (arvore nova)   trackfw 9.2.0     <- MESMA string
cmp dos dois binarios              DIFEREM (20.439.040 vs 20.459.520 bytes)
regra nova do #528 pela copia      0 avisos          <- velho
regra nova do #528 pela arvore     2 avisos          <- novo
```

O `--version` não distingue porque o #527 e o #528 entraram **depois** da tag `v9.2.0`. Quem
distingue é o conteúdo (`cmp`) e o **efeito** (comportamento que só o binário novo tem).

**Hoje quem pegou a defasagem foi o usuário**, pedindo a recópia. É a mesma forma do contorno dos
shims, que nasceu sem alarme e cuja falta também foi o usuário quem notou — e a mesma forma do
`docs/roadmaps/done/.gitkeep`, que ficou doze dias depois de o upstream consertar a causa. Em todos,
o que faltou não foi medição: foi **alguém notar que o mundo mudou**.

## Acceptance Criteria

- [x] AC1 — O `upstream-sync.sh` refaz a cópia do PATH no mesmo passo em que reconstrói o `bin/`,
      **só** quando o contorno dos shims estiver em vigor nesta máquina
- [x] AC2 — A troca é **verificada por efeito** depois de feita (`guard --help` pelo caminho de
      destino) e, se a verificação falhar, a cópia anterior é **restaurada** e o sync aborta
      nomeando o motivo — cópia quebrada deixa TODAS as cercas inertes
- [x] AC3 — Existe gate que acusa a defasagem, e ele **nunca** usa `--version` como discriminante
- [x] AC4 — O gate declara **N/A com a razão** quando a premissa não existe (não é Windows, o
      contorno não está em vigor, o binário da árvore não foi construído) — nunca verde por vazio
- [x] AC5 — Falsificado nas **duas** direções, com cópia igual e cópia diferente
- [x] AC6 — Declarado em `FORA` do `run-local-gates.sh` **com o motivo escrito**, porque o agregador
      roda em `ubuntu-latest`, onde não há cópia nenhuma — e a guarda de completude continua fechada

## Context

## Por que o gate fica FORA do agregador, e isso não é desistência

O agregador roda em `ubuntu-latest`. Lá não existe `%APPDATA%/npm`, o contorno dos shims não está em
vigor e **nenhum** cenário seria exercitado. Um gate que passa descrevendo o vazio é pior que gate
nenhum — é o defeito que o próprio `run-local-gates.sh` existe para fechar.

É o mesmo precedente, pelo mesmo motivo, do `check-platform-predicates.sh`: 14 das 20 linhas do
corpus dele só dizem algo no Windows, e ele está em `FORA` com a razão escrita.

🔴 **Então o instrumento que age automaticamente é o passo no sync, não o gate.** O passo roda
exatamente no momento em que a defasagem é criada; o gate é o alarme para quem quiser conferir fora
desse momento, e é ele que torna a propriedade verificável em vez de confiada.

## O discriminante do gate

Conteúdo e efeito, nunca a string de versão:

| | serve? |
|---|---|
| `trackfw --version` | 🔴 **não** — medido: as duas versões dizem `9.2.0` |
| `cmp` do binário da árvore contra o que o PATH resolve | sim |
| comportamento que só o binário novo tem | sim, e é o que prova por efeito |

## Escopo negativo

- 🔴 **O gate não copia nada.** Ele acusa; copiar é do sync, que é ferramenta. Gate que conserta
  sozinho esconde a mudança — a mesma decisão do `check-contorno-dos-shims-caducou.sh`.
- Não se mexe no `~/.claude/settings.json` nem em nada fora do repositório por conta deste trabalho.
  A cópia em `%APPDATA%` é tocada **apenas** pelo passo do sync, que é o sítio onde o usuário já
  autoriza uma ferramenta a modificar a árvore e o ambiente dele.
- Não se tenta resolver a causa raiz — que é o produto não publicar release com `guard`. Isso já tem
  alarme próprio (`check-contorno-dos-shims-caducou.sh`) e o roteiro de reversão no `CLAUDE.md`.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md

🔴 **Por que esta ADR, e não a `ADR-2026-08-29`.** O `[ -f ]` do MSYS respondendo
VERDADE para um arquivo que o Win32 nega é **mais uma linha da tabela desta ADR** —
predicado cujo nome promete uma pergunta e cuja resposta muda com o sistema
operacional. E a decisão dela, *"o defeito se mede nela, não se contorna"*, é o que
justifica um gate que roda **no Windows** e se declara N/A em outro lugar, em vez de
um gate cross-SO que passaria descrevendo o vazio.

A `ADR-2026-08-29` também governa, por ser dona do `upstream-sync.sh` como instrumento
do fork consumidor — mas o discriminante deste trabalho é de plataforma.

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-07-a-copia-do-trackfw-no-path-fica-atras-a-cada-sync-e-o-version-nao-acusa.md
