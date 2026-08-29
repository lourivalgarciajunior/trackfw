---
status: Open
date: 2026-08-29
author: claude
adr: ""
roadmap: ROADMAP-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows
---

# REQ: isatty do Python devolve True para NUL no Windows

> Date: 2026-08-29 | Status: Open

## Motivation

`sys.stdin.isatty()` devolve `True` para `NUL` no Windows. `NUL` e um character device, e o Windows
reporta character device como TTY. Medido:

```
                     stdin de /dev/null
python  sys.stdin.isatty()      True
node    process.stdin.isTTY     undefined
```

Consequencia: `trackfw init` do Python entra no wizard de identidade em contexto **nao interativo**
e morre com `trackfw init: EOF when reading a line`. A guarda existe —
`pypi/trackfw/commands/init.py:117` faz `if not skip_identity_wizard and sys.stdin.isatty()` — ela
so nao funciona nesta plataforma.

Go e Node nao tem o problema, e por motivos diferentes de sorte:

- Go usa `cbterm.IsTerminal`, que no Windows e literalmente
  `windows.GetConsoleMode(handle, &st) == nil`
  (`charmbracelet/x/term@v0.2.2/term_windows.go`).
- Node usa `process.stdin.isTTY`, que vem do tipo de handle do libuv.

O `isatty()` do Python e o unico que confia na classificacao de character device.

### Por que aparece so agora

Estava mascarado enquanto o Python lia a home real: `_identity_file_exists(home)` era verdadeiro,
`skip_identity_wizard` virava `True` e o wizard nunca rodava. Depois de
`REQ-2026-08-29-node-e-python-ignoram-home-no-windows` o Python passou a ver home vazia de verdade,
e o caminho do wizard passou a ser exercitado.

### O que isso bloqueia

`scripts/check-artifact-parity.sh` roda `python3 -m trackfw init` num fixture e aborta com
`set -euo pipefail` quando o init sai nao-zero. Enquanto isso existir, o gate nao passa no Windows e
o **ML-2A** de `REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node` segue bloqueado —
pela terceira parede: primeiro o CRLF, depois a home, agora esta.

## Superficie

| Runtime | Forma | Sites | Confiavel no Windows |
|---|---|---|---|
| Python | `sys.stdin.isatty()` | 7 | **nao** |
| Python | `sys.stdout.isatty()` (cor em `validate.py:24`) | 1 | **nao** |
| Node | `process.stdin.isTTY` | 8 | sim |
| Go | `cbterm.IsTerminal` | 5 | sim |

## Acceptance Criteria

- [ ] Com stdin nao interativo, `trackfw init` do Python **conclui** em vez de promptar, verificado
      em execucao real
- [ ] O comportamento casa com o do Go **por construcao**: mesma chamada de sistema
      (`GetConsoleMode`), nao uma heuristica paralela
- [ ] `sys.stdout.isatty()` de `validate.py` recebe o mesmo tratamento — hoje ele emitiria cor para
      dentro de arquivo redirecionado
- [ ] O caminho POSIX nao muda: em Linux e macOS continua sendo `isatty()` puro
- [ ] Gate impede regressao e **falha** com um site restaurado — nao-vacuidade verificada
- [ ] `check-artifact-parity.sh` passa, desbloqueando o ML-2A do slug
- [ ] Sem regressao na suite pypi por lista nomeada contra 105 falhas

## Risco declarado

**Nao consigo verificar o caso positivo nesta maquina.** Esta sessao nao tem console anexado: ate a
execucao "interativa" mede `isatty()=False`. Consigo provar que o falso positivo some, nao que um
terminal de verdade continua promptando.

A mitigacao e casar com o Go por construcao, usando o mesmo `GetConsoleMode`: o que um console real
fizer para o Go, fara para o Python. Um teste manual num terminal de verdade fecha o buraco e fica
registrado como pendencia da REQ.

## Linked ADR

ADR: 

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows.md
