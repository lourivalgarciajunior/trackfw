---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink
squad: ""
---

# Roadmap: Atualizar para a upstream main com o fix de symlink

> Created: 2026-08-29 | Status: wip

## Context

Primeiro `git merge upstream/main` real depois da ancestralidade. Traz correcao de escrita
arbitraria por symlink (HIGH) mais dois pins de versao. Oito arquivos em colisao com os fixes
locais de CRLF, `homedir` e `tty`.

REQ: docs/requisições/claude/REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink.md

## Acceptance Criteria

- [ ] Merge concluido, sem marcador de conflito
- [ ] Os seis gates verdes
- [ ] Cada fix local derrubado tem o gate que o acusou registrado — ou o buraco declarado
- [ ] `go build ./...` verde
- [ ] Suite pypi sem regressao por lista nomeada contra 95 falhas
- [ ] Symlink verificado como corrigido em execucao real, nos tres runtimes
- [ ] Governanca do upstream fora, conforme a ADR

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** done

#### 1. Completude da enumeracao

**O que o merge traz.** 2 commits depois da `v7.3.0`, sem tag. Fora de `docs/`, `vault/` e
`.claude/` — que nao importamos — o upstream toca **29 arquivos**: o fix de symlink em
`update`/`discover` nos tres runtimes, o pin de versao do gate de CI, o `install.sh`, e dois gates
novos.

**O que ele pode derrubar.** Nao basta olhar os 8 em colisao: o perigo e funcao reescrita, onde o
fix local some **sem conflito**. Capturei o estado dos marcadores antes do merge, para diff depois:

| arquivo | homedir | newline | tty |
|---|---|---|---|
| `internal/generators/scaffold.go` | 1 | — | — |
| `internal/generators/update.go` | 4 | — | — |
| `npm/src/commands/update.js` | 2 | — | — |
| `npm/src/generators/init.js` | 2 | — | — |
| `pypi/trackfw/commands/discover.py` | 0 | 8 | — |
| `pypi/trackfw/commands/update.py` | 3 | 4 | — |
| `pypi/trackfw/generators/init_gen.py` | 0 | 15 | — |
| `pypi/trackfw/integrations/scaffold_doctor.py` | 0 | 1 | — |

Nenhum dos oito usa o helper de `tty` — a superficie de TTY nao esta em colisao.

#### 2. Quem esvazia esta Wave 0 sem quebrar regra escrita

1. **Resolver os conflitos tomando `--ours` em bloco.** Preserva os fixes locais e **descarta o fix
   de symlink**, que e o motivo da REQ. O merge fica verde e a vulnerabilidade continua.
   **Coberto:** criterio exige verificacao por efeito do symlink, nao leitura de diff.
2. **Resolver com `--theirs` em bloco.** Traz o fix e derruba os locais. Os gates pegam — se
   cobrirem. **Coberto parcialmente:** e exatamente o que o criterio de "qual gate acusou" mede.
3. **Rodar os gates e reaplicar em silencio**, sem registrar o que caiu. Perde-se o unico dado que
   este merge produz: se os gates cobrem o que dizem cobrir. **Coberto:** a tabela do ML-1B e
   criterio de aceite.
4. **Contar falha de suite em vez de comparar lista nomeada.** Ja mordeu nesta sessao — o instavel
   de skew de relogio move o total sozinho. **Coberto:** criterio exige lista nomeada.

#### 3. Alvos de falsificacao, nas duas direcoes

| Regride para | Quebra o que |
|---|---|
| sem o fix de symlink | `update` sobrescreve alvo de symlink fora do projeto; `discover --init` cria arquivo la |
| sem os fixes locais | volta CRLF, home nao isolada, `isatty` — e o `check-artifact-parity` reprova de novo |
| gate reprova mas o fix e reaplicado sem registro | perde-se a medicao de cobertura, que e o produto mais valioso deste merge |
| fix local sumiu e **nenhum** gate reprovou | buraco de cobertura — e o achado mais importante possivel aqui, e o mais facil de nao notar |

A ultima linha e a que orienta o ML-1B: a pergunta nao e "os gates passam", e "os gates pegaram o
que sumiu".

#### 4. Residual declarado

- Os dois gates novos do upstream vao rodar. Se falharem no Windows, viram registro — nao entram
  como trabalho, pela mesma politica dos sete de kgsaran/trackfw#216.
- A suite npm **nao completa nesta maquina** em nenhum estado. Nao havera total de npm; o que der
  para comparar sera dito com o escopo explicito.
- `upstream/main` nao tem tag. Aceito conscientemente: a vulnerabilidade pesa mais que a
  preferencia por versao marcada.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
# A superficie esta enumerada quando os 8 arquivos em colisao continuam sendo os 8 —
# um nono significa que o upstream mexeu onde este repo tambem mexeu, sem ninguem ver.
comm -12 \
  <(git diff --name-only v7.3.0..upstream/main | grep -vE '^docs/|^vault/|^\.claude/' | sort) \
  <(git diff --name-only v7.3.0..HEAD -- npm/src pypi/trackfw internal scripts | sort) \
  | wc -l | grep -qx 8
```

## Wave 1 — O merge
> Dependencies: ML-0A

### ML-1A — Merge e resolucao
**Status:** pending
**Files affected:** os 8 em colisao, mais o que o merge trouxer limpo
**Actions:**
1. `git merge upstream/main`.
2. Resolver tomando o upstream como base e reaplicando os fixes locais por cima — mesma politica da
   ADR: produto vem do upstream, divergencia local e reaplicada com o motivo escrito.
3. Manter a governanca do upstream fora.
**Acceptance criteria:**
- [ ] Nenhum marcador de conflito em arquivo versionado
- [ ] `docs/` continua com a governanca local apenas
- [ ] `go build ./...` verde

### ML-1B — Recuperar o que o merge derrubou
**Status:** pending
**Actions:**
1. Rodar os seis gates. Para cada reprovacao, reaplicar o fix local.
2. **Registrar qual gate acusou cada perda.** Se um fix sumir sem nenhum gate reprovar, isso e
   buraco de cobertura e entra como achado, nao como detalhe.
**Acceptance criteria:**
- [ ] Seis gates verdes
- [ ] Tabela de "o que caiu / qual gate pegou" escrita aqui

## Wave 2 — Verificacao
> Dependencies: ML-1A, ML-1B

### ML-2A — Symlink e regressao
**Status:** pending
**Actions:**
1. Reproduzir a vulnerabilidade em arvore pre-merge e confirmar que some pos-merge, nos tres
   runtimes — verificacao por efeito, nao por leitura do diff.
2. Suite pypi por lista nomeada contra 95 falhas.
**Acceptance criteria:**
- [ ] Symlink apontando para fora do projeto **nao** e mais sobrescrito por `update`
- [ ] Symlink pendurado **nao** faz `discover --init` criar arquivo fora do projeto
- [ ] Zero falhas novas na lista nomeada
