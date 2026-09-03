---
status: Open
date: 2026-08-29
author: claude
adr: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
roadmap: ROADMAP-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink
---

# REQ: Atualizar para a upstream main com o fix de symlink

> Date: 2026-08-29 | Status: Open

## Motivation

Primeiro exercicio real da ancestralidade estabelecida em
`ADR-2026-08-29-adotar-upstream-como-base`: `git merge upstream/main` agora funciona sem flag.

Ha **2 commits** depois da `v7.3.0`, sem tag nova. Um e governanca do upstream (nao importamos). O
outro, `e0f8543` (PR #215 deles), traz tres coisas — e a primeira e o motivo desta REQ.

### 1. Escrita arbitraria por symlink — HIGH, reproduzida nos tres CLIs

Da nota do revisor deles
(`.claude/agent-memory/hades-tf/project_update_discover_symlink_follow_arbitrary_write.md`):

> As checagens de presenca (`os.Stat` / `fs.existsSync` / `os.path.isfile`) e as escritas
> (`os.WriteFile` / `fs.writeFileSync` / `open(...,'w')`) seguem symlink por padrao, sem nenhuma
> guarda de `lstat` em `internal/generators/update.go`, `npm/src/commands/update.js`,
> `pypi/trackfw/commands/update.py`, nem nos irmaos `discover.*`.

- Symlink vivo em `.github/workflows/trackfw-validate.yml` apontando para fora do projeto, mais um
  `trackfw update` — **mesmo com `ci: none` no `trackfw.yaml`** — sobrescreve o alvo com o template
  de CI do trackfw.
- Symlink pendurado no mesmo caminho, mais `trackfw discover --init`, **cria** arquivo no caminho
  escolhido pelo atacante, fora do projeto.

Classificado HIGH e nao CRITICAL porque o conteudo escrito e sempre o template fixo do trackfw,
nunca conteudo do atacante. Ainda assim e escrita fora do projeto, e **este repositorio roda
`update` e `discover`** ao fazer dogfooding.

### 2 e 3. Pin de versao

O gate de CI passa a nascer pinado na versao que o gerou, e o `install.sh` honra
`TRACKFW_VERSION`. Mais dois gates: `check-ci-workflow-pin-parity.sh` e
`check-install-version-pin.sh`.

## Risco: oito arquivos em colisao

O upstream e este repo tocaram os mesmos arquivos. Sao exatamente onde vivem os fixes locais de
CRLF, `homedir` e `tty`:

```
internal/generators/scaffold.go        pypi/trackfw/commands/discover.py
internal/generators/update.go          pypi/trackfw/commands/update.py
npm/src/commands/update.js             pypi/trackfw/generators/init_gen.py
npm/src/generators/init.js             pypi/trackfw/integrations/scaffold_doctor.py
```

Onde o upstream reescreveu funcao inteira, o fix local **some em silencio** — nao ha conflito para
avisar.

**E para exatamente isto que os quatro gates locais existem.** `check-python-writes-lf`,
`check-homedir-parity`, `check-tty-detection` e `check-slug-inventory` sao estaticos porque a CI do
upstream e Linux e nunca vera esses defeitos; eles pegam no merge, que e onde a regressao nasce.
**Este merge e o primeiro teste real deles**, e isso vale mais do que o resultado: se um fix sumir
sem gate reprovar, o gate e que esta errado.

## Acceptance Criteria

- [ ] `git merge upstream/main` concluido, sem marcador de conflito em arquivo versionado
- [ ] Os **seis** gates verdes: `slug-inventory`, `python-writes-lf`, `homedir-parity`,
      `tty-detection`, `artifact-parity`, `subcommand-parity`
- [ ] Para cada fix local que o merge derrubar, registrar **qual gate acusou** — ou, se nenhum
      acusou, tratar como buraco de cobertura e dizer isso
- [ ] `go build ./...` verde
- [ ] Suite pypi sem regressao por **lista nomeada** contra 95 falhas, nunca so por contagem
- [ ] A vulnerabilidade de symlink verificada como corrigida em execucao real, nos tres runtimes
- [ ] Governanca do upstream continua fora, conforme a ADR

## Nao faz parte

Os dois gates novos do upstream (`ci-workflow-pin-parity`, `install-version-pin`) vem junto e serao
executados, mas fazer eles passarem no Windows nao entra: se falharem, viram registro, como os sete
ja levantados em kgsaran/trackfw#216.

## Linked ADR

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink.md
