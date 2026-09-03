---
status: Done
date: 2026-08-30
author: ""
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-08-30-homedir-so-prefere-home-no-windows.md"
---

# REQ: homedir so prefere HOME no Windows

> Date: 2026-08-30 | Status: Done

## Motivation

`trackfw.homedir.home_dir()` lê `os.environ["HOME"]` antes de `os.path.expanduser("~")`
em **toda** plataforma. Foi escrito assim para corrigir o Windows, onde `expanduser`
resolve `%USERPROFILE%` e a isolação de home dos testes não isola nada.

Em Linux e macOS a preferência não corrige nada — o `expanduser` já lê `$HOME` — e
**quebra** a isolação de vários testes do upstream, que isolam a home patchando a
**função**, não a variável:

```python
monkeypatch.setattr("os.path.expanduser",
                    lambda p: str(home) if p == "~" else os.path.expanduser(p))
```

Ler a variável antes passa por cima desse patch, e a produção vai para a home REAL
do runner.

**Medido na CI Linux deste fork** (run 33350020370), três testes reprovando só aqui
enquanto o `Quality` do upstream está verde na `main` dele:

| teste | sintoma |
|---|---|
| `test_identity_wizard.py::test_agents_install_with_existing_identity_and_no_flag_does_not_invoke` | `assert True is False` — o wizard foi invocado |
| `test_scope_resolution.py::test_targets_flag_with_tty_and_no_scope_still_triggers_scope_resolver` | `SystemExit: 2` |
| `test_thirdparty.py::test_install_global_scope_requires_its_own_confirmation` | arquivo esperado sob a home do teste não existe |

Um deles falha com `OSError: pytest: reading from stdin while output is captured!` —
a produção achou a home errada, não encontrou a identidade que o teste tinha gravado,
e foi promptar.

## Por que passou despercebido

A medição da correção original foi feita **só no Windows**, e ali esses três já
falhavam **antes** — pelo próprio defeito que a correção conserta. Comparação por
lista nomeada não acusa regressão em teste que já estava vermelho.

Generaliza: **lista nomeada só protege dentro da plataforma onde foi colhida.**

## Acceptance Criteria

- [x] `home_dir()` só prefere `$HOME` quando `sys.platform == "win32"`
- [x] Em Linux e macOS o comportamento é byte a byte igual ao do upstream
- [x] `scripts/check-homedir-parity.sh` continua verde nos 3 runtimes
- [x] Os 3 testes acima passam na CI Linux deste fork (sonda run 33351916177)
- [x] A mesma correção é levada para `kgsaran/trackfw#222` (commit `20d5e4e`)

## Linked ADR

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-30-homedir-so-prefere-home-no-windows.md
docs/roadmaps/claude/done/ROADMAP-2026-08-30-homedir-so-prefere-home-no-windows.md

## Escopo declarado como fora

Go e Node **não** precisam da guarda: `os.UserHomeDir()` e `os.homedir()` já leem
`$HOME` em POSIX, então preferir a variável ali é no-op, e as suítes dos dois isolam
por variável de ambiente, não por patch de função. Verificado no
`check-homedir-parity.sh`, que cobre os três.
