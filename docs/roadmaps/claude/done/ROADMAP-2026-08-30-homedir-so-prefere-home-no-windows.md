---
status: done
date: 2026-08-30
req: "docs/requisições/claude/REQ-2026-08-30-homedir-so-prefere-home-no-windows.md"
squad: ""
---

# Roadmap: homedir so prefere HOME no Windows

> Created: 2026-08-30 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-08-30-homedir-so-prefere-home-no-windows.md

`home_dir()` prefere `$HOME` em toda plataforma. Em POSIX isso é no-op para a
produção e **quebra** a isolação dos testes do upstream que patcham
`os.path.expanduser`. Três testes reprovam na CI Linux deste fork e passam no
upstream.

## Acceptance Criteria

- [x] A preferência por `$HOME` fica atrás de `sys.platform == "win32"`
- [x] `check-homedir-parity.sh` verde nos 3 runtimes
- [x] Os 3 testes nomeados na REQ passam na CI Linux
- [x] Correção levada para `kgsaran/trackfw#222` (commit `20d5e4e`)

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Superfície e modelo de ameaça
**Status:** ✅ Concluído
**Files affected:** `pypi/trackfw/homedir.py`, `internal/homedir/homedir.go`, `npm/src/homedir.js`

**Actions:**

**1. Completude da enumeração.** Quais runtimes têm o problema? Busca pelo padrão de
isolação, não só pelos arquivos citados:

```
grep -rn 'setattr("os.path.expanduser"' pypi/tests/   → test_identity_wizard.py, test_thirdparty.py
grep -rn 'Setenv("HOME"'                internal/     → isolação por variável
grep -rn "env.HOME"                     npm/tests/    → isolação por variável
```

Só o Python isola patchando a **função**. Go e Node isolam pela **variável**, que a
correção original honra. Lista fechada: 1 arquivo.

**2. Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita?** Quem
medir de novo só no Windows. Os três testes já falham lá pelo defeito original, então
uma lista nomeada colhida no Windows mostra `0 regressões` para uma regressão real.
Foi exatamente o que aconteceu.

**3. Alvos de falsificação nos dois sentidos.**
- Se regride para "prefere `$HOME` sempre": os 3 testes da REQ voltam a falhar na CI Linux.
- Se regride para "nunca prefere `$HOME`": `check-homedir-parity.sh` reprova no Windows,
  porque o runtime deixa de resolver para o tempdir.

**4. Residual declarado.** A verificação de que os 3 testes passam **não é possível
nesta máquina** — no Windows eles falham por outro motivo e não discriminam. O veredito
vem da CI Linux deste fork, e está registrado como critério em aberto até chegar.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
# A enumeração é fechada: só o Python isola a home patchando a função.
# O gate falha se aparecer um segundo runtime com o mesmo padrão.
test "$(grep -rl 'setattr("os.path.expanduser"' pypi/tests/ internal/ npm/ 2>/dev/null | grep -c .)" -le 2
```

## Wave 1 — Correção
> Dependencies: ML-0A

### ML-1A — Guarda por plataforma em home_dir()
**Status:** ✅ Concluído
**Files affected:** `pypi/trackfw/homedir.py`

**Actions:**
1. `home_dir()` só consulta `os.environ["HOME"]` quando `sys.platform == "win32"`.
2. Doc da função registra o motivo e o seam que se quebrava, com o `monkeypatch` literal.
3. Aguardar o veredito da CI Linux deste fork.
4. Levar a mesma correção para `kgsaran/trackfw#222`.

**Acceptance criteria:**
- [x] build passes (`python -c "import trackfw"`)
- [x] `check-homedir-parity.sh` verde
- [x] Os 3 testes da REQ verdes na CI Linux — sonda run 33351916177: `python (3.10)` e `(3.12)` SUCCESS
- [x] `trackfw validate` sem violação nova — 15 antes e depois

## Resultado — e o erro de atribuição no caminho

A guarda foi verificada por sonda de uma variável: branch com **só** a correção, sem
os arquivos de governança. `python (3.10)` e `(3.12)` **SUCCESS** — as 3 falhas do
Linux viraram 0.

A PR original mostrava **8 falhas diferentes**, e eu li a sonda como prova de que
vinham dos arquivos de governança. Errado: **a sonda mudou duas variáveis** — tirou
os arquivos *e* trocou o nome da branch de `fix/` para `chore/`.

A causa era o nome da branch. `validate_branch_has_wip_roadmap` dispara em branch
`feat/fix/refactor` e devolve `list[str]` onde toda outra regra devolve `list[dict]`;
`_enrich_items` deixa passar, e o helper dos testes faz `item["message"]`.
Reproduzido localmente, sem CI:

```
sem TRACKFW_BRANCH             7 passed
TRACKFW_BRANCH=fix/qualquer    7 failed
```

Registrado como achado 15 em kgsaran/trackfw#216.

**Uma sonda de uma variável que muda duas não é sonda.** Foi o segundo erro do mesmo
tipo no mesmo dia — o primeiro foi medir a correção original só no Windows, onde os
testes que ela quebrava já estavam vermelhos.
