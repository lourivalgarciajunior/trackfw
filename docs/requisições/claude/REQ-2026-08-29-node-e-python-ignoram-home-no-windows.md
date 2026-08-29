---
status: Open
date: 2026-08-29
author: claude
adr: ""
roadmap: ROADMAP-2026-08-29-node-e-python-ignoram-home-no-windows
---

# REQ: Node e Python ignoram HOME no Windows

> Date: 2026-08-29 | Status: Open

## Motivation

`os.homedir()` no Node e `os.path.expanduser("~")` no Python leem `%USERPROFILE%` no Windows e
**ignoram `$HOME`**. Reproduzido diretamente:

```
node   os.homedir()        com HOME=/c/tmp/fake  ->  C:/Users/louri
py     expanduser("~")     com HOME=/c/tmp/fake  ->  C:/Users/louri
```

Consequencias medidas:

1. **Teste e gate nao conseguem isolar a home.** Todo teste que faz
   `t.Setenv("HOME", tmp)` / equivalente continua lendo e escrevendo a home real do
   desenvolvedor. Foi assim que uma rodada de `go test` nesta maquina criou ADR,
   `integrations-manifest.json` e dois scripts de guard **dentro de `~/.trackfw`**, e tocou os
   seis arquivos de config global de agente — antes de o Go ser corrigido.

2. **O `check-artifact-parity.sh` nao passa no Windows.** Ele exporta `HOME="$WORK/home"` e roda
   `validate --json` num fixture; o Node devolve nao-zero citando `~/.trackfw/scripts/` da home
   **real**, e com `set -euo pipefail` o gate aborta. Isso **bloqueia o ML-2A** de
   `REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node`, que existe justamente para
   impedir a divergencia de slug de voltar.

3. **Paridade quebrada entre os tres runtimes.** O Go ja foi corrigido na migracao para a 7.3.0,
   com `internal/homedir.Dir()` preferindo `$HOME` (ver `REQ-2026-08-29-migrar-para-upstream-7.3.0`,
   ML-6). Node e Python ficaram para tras, entao hoje os tres resolvem home de formas diferentes.

No Linux e no macOS nada disso aparece: `expanduser` e `os.homedir()` ja consultam `$HOME` la. E
por isso que a CI do upstream nunca viu.

## Superficie

| Runtime | Forma | Sites |
|---|---|---|
| Node | `os.homedir()` | 24 |
| Node | `expandPath()` em `src/config/index.js:8` | 1 funcao, consome `os.homedir()` |
| Python | `os.path.expanduser("~")` — "me de a home" | 17 |
| Python | `os.path.expanduser(p)` — "expanda o `~` deste caminho" | 10 |
| Python | `Path.home()` em `integrations/manager.py:32` | 1 |
| Go | `homedir.Dir()` — **ja corrigido**, referencia | 21 |

As duas familias do Python precisam das duas correcoes: `adr_dirs: ~/algo` no `trackfw.yaml`
tambem resolve pelo `USERPROFILE` hoje.

## Acceptance Criteria

- [ ] Com `HOME` apontado para um diretorio temporario, os tres runtimes resolvem a home **para
      ele**, verificado em execucao real e nao so em teste unitario
- [ ] `expandPath` / expansao de `~` em caminho de config honra `$HOME` nos tres
- [ ] `check-artifact-parity.sh` passa no Windows, desbloqueando o ML-2A do roadmap do slug
- [ ] Gate impede regressao, e **falha** com um site restaurado para a forma antiga —
      nao-vacuidade verificada, nao assumida
- [ ] Sem regressao nas suites npm e pypi, medido por **lista nomeada** contra a corrida anterior
      (npm 297 falhas; pypi 199 falhas), nunca so por contagem — a suite pypi tem teste instavel
      de skew de relogio que move o total sozinho

## Nao faz parte

O comportamento em Linux e macOS nao muda: `$HOME` ja e a primeira fonte la. A correcao so torna o
Windows consistente com as outras plataformas, que e o mesmo criterio usado no `internal/homedir`
do Go.

## Linked ADR

ADR: 

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-08-29-node-e-python-ignoram-home-no-windows.md
