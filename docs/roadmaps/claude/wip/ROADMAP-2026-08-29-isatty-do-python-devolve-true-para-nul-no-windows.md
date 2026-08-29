---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows
squad: ""
---

# Roadmap: isatty do Python devolve True para NUL no Windows

> Created: 2026-08-29 | Status: wip

## Context

`sys.stdin.isatty()` devolve `True` para `NUL` no Windows, entao `trackfw init` do Python entra no
wizard de identidade em contexto nao interativo e morre com EOF. Go e Node usam mecanismos
confiaveis. Bloqueia o `check-artifact-parity.sh` e, por tabela, o ML-2A do roadmap do slug.

REQ: docs/requisições/claude/REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows.md

## Acceptance Criteria

- [ ] `init` do Python conclui com stdin nao interativo, em execucao real
- [ ] Casa com o Go por construcao — mesmo `GetConsoleMode`
- [ ] `sys.stdout.isatty()` de `validate.py` recebe o mesmo tratamento
- [ ] POSIX inalterado
- [ ] Gate **falha** com um site restaurado
- [ ] `check-artifact-parity.sh` passa
- [ ] Sem regressao por lista nomeada contra 105 falhas

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** done

#### 1. Completude da enumeracao

| Runtime | Forma | Sites | Confiavel no Windows |
|---|---|---|---|
| Python | `sys.stdin.isatty()` | 7 | **nao** |
| Python | `sys.stdout.isatty()` — cor, `validate.py:24` | 1 | **nao** |
| Node | `process.stdin.isTTY` | 8 | sim (tipo de handle do libuv) |
| Go | `cbterm.IsTerminal` | 5 | sim (`GetConsoleMode`) |

Procurei tambem por `os.isatty`, `TERM`, `CI`, `NO_COLOR` e por deteccao propria de interatividade:
nao ha outra forma no Python. As duas familias sao **stdin** (promptar ou nao) e **stdout** (emitir
cor ou nao) — a segunda e a que some numa varredura que so pensa em wizard.

**Verificacao do mecanismo, antes de prometer:**

```
                     stdin=/dev/null        stdout=arquivo
sys.std*.isatty()    True   <- defeito      False
GetConsoleMode()     False  <- correto      False
```

E o `isTerminal` do Go no Windows e exatamente
`windows.GetConsoleMode(windows.Handle(fd), &st) == nil`
(`charmbracelet/x/term@v0.2.2/term_windows.go:16`). Mesmo syscall.

#### 2. Quem esvazia esta Wave 0 sem quebrar regra escrita

1. **Corrigir so o stdin e deixar o stdout.** O sintoma visivel e o wizard; a cor em arquivo
   redirecionado nao incomoda ninguem hoje. **Coberto:** criterio nomeia `validate.py:24`.
2. **Trocar `isatty()` por `GetConsoleMode` em todo lugar**, inclusive POSIX, onde a funcao nao
   existe — `AttributeError` no Linux. **Coberto:** criterio exige POSIX inalterado; o
   `GetConsoleMode` so estreita o resultado do `isatty()`, nunca o substitui.
3. **Over-correct: devolver sempre False no Windows.** O wizard nunca roda, a identidade fica no
   default neutro em silencio, e o gate fica verde. **Este e o risco real e nao esta coberto por
   gate** — ver residual.
4. **Merge futuro do upstream reintroduz `isatty()` cru.** A CI deles e Linux e nunca ve isto.
   **Coberto:** gate estatico.

#### 3. Alvos de falsificacao, nas duas direcoes

| Regride para | Quebra o que |
|---|---|
| `isatty()` cru (hoje) | `init` prompta em CI e em gate; morre com EOF |
| sempre `False` no Windows | wizard nunca roda; identidade vira default neutro **em silencio** — pior que o erro, porque nao aparece |
| `GetConsoleMode` tambem em POSIX | `AttributeError` no Linux e macOS |
| checar so stdin | cor ANSI escrita para dentro de arquivo redirecionado |

A segunda linha e a que importa: o modo de falha do over-correct e **silencioso**, e um gate que so
verifica "nao prompta" passaria feliz.

#### 4. Residual declarado

**Nao consigo verificar o caso positivo nesta maquina.** Esta sessao nao tem console anexado: ate a
execucao "interativa" mede `isatty()=False`. Provo que o falso positivo some; nao provo que um
terminal de verdade continua promptando.

Mitigacao: casar com o Go por construcao, usando o mesmo `GetConsoleMode`. O que um console real
fizer para o Go, fara para o Python. **Fica como pendencia explicita: um teste manual num terminal
de verdade.** Registrado aqui para nao virar uma suposicao esquecida.

Fora de escopo: Node e Go, que ja usam mecanismo confiavel.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
bash scripts/check-tty-detection.sh
```

## Wave 1 — A correcao
> Dependencies: ML-0A

### ML-1A — Helper de deteccao de TTY no Python
**Status:** pending
**Files affected:** `pypi/trackfw/tty.py` (novo) + os 7 sites de stdin e 1 de stdout
**Actions:**
1. `stdin_is_interactive()` e `stdout_is_interactive()`: `isatty()` como base e, **so no Windows**,
   estreitar com `GetConsoleMode` via `msvcrt.get_osfhandle` + `ctypes`.
2. Falhar para `False` em qualquer excecao — stream substituido em teste nao tem `fileno()`.
**Acceptance criteria:**
- [ ] `init` conclui com stdin nao interativo
- [ ] POSIX inalterado — o ramo Windows so roda em `sys.platform == "win32"`
- [ ] Suite pypi sem regressao por lista nomeada contra 105 falhas

## Wave 2 — A guarda
> Dependencies: ML-1A

### ML-2A — Gate de deteccao de TTY
**Status:** pending
**Files affected:** `scripts/check-tty-detection.sh` (novo)
**Actions:**
1. Por efeito: `init` com stdin nao interativo conclui nos tres runtimes.
2. Estatico: nenhum `isatty()` cru fora do helper.
**Acceptance criteria:**
- [ ] Gate passa depois de ML-1A
- [ ] Gate **falha** com um site restaurado — saida colada aqui
- [ ] `check-artifact-parity.sh` passa, desbloqueando o ML-2A do roadmap do slug
