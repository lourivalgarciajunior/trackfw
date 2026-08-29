---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-node-e-python-ignoram-home-no-windows
squad: ""
---

# Roadmap: Node e Python ignoram HOME no Windows

> Created: 2026-08-29 | Status: wip

## Context

`os.homedir()` (Node) e `os.path.expanduser` (Python) leem `%USERPROFILE%` no Windows e ignoram
`$HOME`. O Go ja foi corrigido na migracao com `internal/homedir.Dir()`. Enquanto os outros dois
nao forem, teste nao isola home e o `check-artifact-parity.sh` nao passa — o que bloqueia o ML-2A
do roadmap do slug.

REQ: docs/requisições/claude/REQ-2026-08-29-node-e-python-ignoram-home-no-windows.md

## Acceptance Criteria

- [ ] Com `HOME` em tempdir, os tres runtimes resolvem para ele, em execucao real
- [ ] Expansao de `~` em caminho de config honra `$HOME` nos tres
- [ ] `check-artifact-parity.sh` passa no Windows
- [ ] Gate **falha** com um site restaurado para a forma antiga
- [ ] Sem regressao por lista nomeada — npm 297 falhas, pypi 199 falhas

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** done

#### 1. Completude da enumeracao

Procurei por **todas** as formas de obter home, nao so as duas obvias, nos tres runtimes:

| Runtime | Forma | Sites |
|---|---|---|
| Node | `os.homedir()` | 24 |
| Node | `expandPath()` em `src/config/index.js:8` | 1 funcao (consome `os.homedir()`) |
| Node | `process.env.HOME` | 1 — **so num comentario**, nao e codigo |
| Node | `process.env.USERPROFILE` | 0 |
| Python | `expanduser("~")` — "me de a home" | 17 |
| Python | `expanduser(p)` — "expanda o `~` deste caminho" | 10 |
| Python | `Path.home()` | 1, em `integrations/manager.py:32` |
| Python | `environ["HOME"]`, `USERPROFILE`, `HOMEDRIVE` | 0 |
| Go | `homedir.Dir()` | 21 — **ja corrigido**, e a referencia |

**As duas familias do Python sao distintas e as duas importam.** `expanduser("~")` pede a home;
`expanduser(p)` expande `~` num caminho que veio do `trackfw.yaml` (`adr_dirs: ~/algo`). O segundo e
facil de esquecer numa varredura que so procura `expanduser("~")`, e resolve pelo `USERPROFILE`
igual. O Go trata os dois: `config.ExpandPath` usa `homedir.Dir()` desde a migracao
(`internal/config/config.go:621`).

#### 2. Quem esvazia esta Wave 0 sem quebrar regra escrita

1. **Corrigir so os 24 `os.homedir()` do Node e os 17 `expanduser("~")` do Python**, deixando os 10
   de caminho de config e o `Path.home()`. A varredura ingenua da sensacao de completude.
   **Coberto:** o criterio exige verificacao em execucao real com `HOME` em tempdir, incluindo um
   `adr_dirs: ~/...`, nao contagem de call site.
2. **Fazer o gate de artefato ignorar o `validate` que falha** (`|| true`). Some o sintoma, fica o
   teste escrevendo na home real. **Nao coberto por gate** — proibicao escrita aqui.
3. **Merge futuro do upstream reintroduz.** A CI deles e Linux e nunca ve isto; todo arquivo novo
   chega com `os.homedir()` cru. **Coberto:** o gate do ML-2A e estatico e falha em qualquer site
   novo.
4. **Corrigir Node e Python com regra diferente da do Go.** Ex.: aceitar `HOME` vazio como valido,
   ou preferir `USERPROFILE` quando os dois existem. Os tres passariam a "honrar HOME" com
   comportamentos distintos. **Coberto:** o criterio compara os tres na mesma execucao.

#### 3. Alvos de falsificacao, nas duas direcoes

| Regride para | Quebra o que |
|---|---|
| ignorar `$HOME` (hoje) | teste escreve na home real; gate de artefato aborta; ML-2A do slug fica bloqueado |
| honrar `$HOME` mas com string vazia valida | `HOME=""` passa a resolver para `""`, e caminho de config vira relativo silenciosamente |
| honrar `$HOME` so em Windows | Linux e macOS ja o fazem; um `if windows` cria dois caminhos de codigo onde um basta |
| Go regride para `os.UserHomeDir()` | os tres voltam a divergir; e a direcao que ninguem vigia, porque o Go "ja esta certo" |

A ultima linha e a que importa: o gate precisa cobrir os **tres** runtimes, nao so os dois que
estao sendo corrigidos agora.

#### 4. Residual declarado

- **Comportamento em Linux e macOS nao muda** — `$HOME` ja e a primeira fonte la. A correcao so
  alinha o Windows, mesmo criterio do `internal/homedir` do Go.
- **`HOMEDRIVE`/`HOMEPATH`** (o fallback antigo do Windows) fica fora: `os.homedir()` e
  `expanduser` continuam sendo o fallback quando `$HOME` nao esta definido, e eles ja consultam
  esses.
- Nao entra deteccao de `HOME` apontando para diretorio inexistente. Se o usuario define `HOME`
  errado, o erro e dele e aparece na primeira escrita.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
bash scripts/check-homedir-parity.sh
```

## Wave 1 — A correcao
> Dependencies: ML-0A

### ML-1A — `homedir` no Node
**Status:** pending
**Files affected:** `npm/src/homedir.js` (novo) + os 24 sites de `os.homedir()`
**Actions:** helper que devolve `process.env.HOME` quando definido e nao vazio, senao
`os.homedir()`. Espelha `internal/homedir/homedir.go`. `expandPath` herda pelo consumo.
**Acceptance criteria:**
- [ ] Com `HOME` em tempdir, `os.homedir()` deixa de aparecer no comportamento observavel
- [ ] Suite npm sem regressao por lista nomeada contra 297 falhas

### ML-1B — `homedir` no Python
**Status:** pending
**Files affected:** `pypi/trackfw/homedir.py` (novo) + os 17 `expanduser("~")`, os 10
`expanduser(p)` e o `Path.home()`
**Actions:** `home_dir()` e `expand_path(p)`, espelhando `homedir.Dir()` e `config.ExpandPath` do
Go. As duas familias, nao so a primeira.
**Acceptance criteria:**
- [ ] `adr_dirs: ~/algo` no `trackfw.yaml` resolve para o `HOME` de teste
- [ ] Suite pypi sem regressao por lista nomeada contra 199 falhas

## Wave 2 — A guarda
> Dependencies: ML-1A, ML-1B

### ML-2A — Gate de paridade de home
**Status:** pending
**Files affected:** `scripts/check-homedir-parity.sh` (novo)
**Actions:**
1. Por efeito: com `HOME` em tempdir, os tres runtimes devem resolver para ele. Cobre os **tres**,
   nao so os dois corrigidos — a falsificacao mais provavel e o Go regredir sem ninguem olhar.
2. Estatico: nenhum `os.homedir()` / `expanduser` cru fora do helper de cada runtime.
**Acceptance criteria:**
- [ ] Gate passa depois de ML-1A e ML-1B
- [ ] Gate **falha** com um site restaurado para a forma antiga — saida colada aqui
- [ ] `check-artifact-parity.sh` passa, desbloqueando o ML-2A do roadmap do slug
