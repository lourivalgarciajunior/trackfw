---
status: done
date: 2026-08-29
author: claude
adr: ""
roadmap: ROADMAP-2026-08-29-geradores-python-escrevem-crlf-no-windows
---

# REQ: Geradores Python escrevem CRLF no Windows

> Date: 2026-08-29 | Status: Open

## Motivation

O CLI Python grava **todo** arquivo com CRLF no Windows; Go e Node gravam LF. Medido rodando
`init` e depois `adr|req|roadmap|note new` num diretorio limpo por runtime, e varrendo os bytes de
tudo que ficou:

```
py    CRLF=23 arquivos   LF=0
go    CRLF=0             LF=22
```

Nao ha excecao dos dois lados. Causa: `open(path, "w")` do Python usa `newline=None`, que traduz
`
` para `os.linesep`. Go e Node escrevem bytes direto. Invisivel para o upstream porque na CI
Linux o `os.linesep` ja e LF.

Isso viola a **Regra Dura de Paridade** do `CLAUDE.md`: os tres CLIs produzem artefato diferente
byte a byte para a mesma entrada.

### Nao e cosmetico — quebra script de shell

Entre os 23 arquivos estao os cinco `scripts/*.sh` que o `trackfw init` gera. O shebang sai assim:

```
py     b'#!/usr/bin/env bash'
go     b'#!/usr/bin/env sh'
node   b'#!/usr/bin/env sh'
```

Um `.sh` com CR no shebang falha em qualquer sistema POSIX com `bad interpreter: bash^M`. Quem
roda `trackfw init` pelo CLI Python no Windows e commita o resultado entrega hooks de guard
quebrados para todo mundo que der checkout em Linux, macOS ou WSL.

### Segunda divergencia, independente, encontrada no mesmo arquivo

O Python escreve `#!/usr/bin/env bash`; Go e Node escrevem `#!/usr/bin/env sh`. Nao e fim de linha,
e interpretador diferente. Entra nesta REQ porque foi medida aqui e vive no mesmo gerador.

### Por que agora

O `scripts/check-artifact-parity.sh` compara os artefatos byte a byte e por isso acusa **8 drifts
`go vs python`** nesta maquina — `adr`, `note`, `note_index`, `req`, `roadmap`, `roadmap_flags`,
`roadmap_from_req`, `slash_roadmap`. Todos sao este defeito. Enquanto ele existir, aquele gate nao
passa no Windows e nao serve como guarda de nada, o que **bloqueia o ML-2A** de
`REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node`.

E o quinto bloqueio estrutural de Windows da 7.3.0, junto com o UTF-8 do CLI, o `homedir`, o
`credential_guard_hook_resolvable` e o `check-parity-contract-coverage.sh`.

## Acceptance Criteria

- [ ] O CLI Python grava LF em todo arquivo que produz, no Windows, medido por varredura de bytes
      do resultado de `init` + os quatro `new` — nao por contagem de call site
- [ ] `scripts/*.sh` gerados saem com o mesmo shebang nos tres runtimes
- [ ] `check-artifact-parity.sh` deixa de acusar os 8 drifts `go vs python`
- [ ] O gate **falha** com o CRLF reintroduzido — nao-vacuidade verificada, nao assumida
- [ ] Nenhuma regressao na suite pypi contra a medicao de 2026-08-29 (198 failed / 1294 passed)

## Nao faz parte

A saida de terminal ja e tratada por `_force_utf8_output` em `pypi/trackfw/cli.py`, que passa
`newline="
"` para stdout e stderr. Esta REQ e sobre **escrita de arquivo**, que aquele fix nao
alcanca.

## Linked ADR

ADR: 

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-geradores-python-escrevem-crlf-no-windows.md
