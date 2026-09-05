---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-tres-reqs-de-docs-req-sao-lidas-por-teste-de-produto-nos-tres-runtimes.md"
---

# REQ: Três REQs de `docs/req/` são lidas por teste de produto nos três runtimes

> Date: 2026-09-05 | Status: Open

## Motivation

**Segunda regressão minha em cadeia, e ela revela algo maior que o próprio erro.**

Ao remover os 5 resíduos de `docs/req/` para consertar a integridade referencial
(`REQ-2026-09-05-residuo-de-docs-req-do-upstream`), quebrei `go`, `node` e `python` no CI — e com
eles o `parity`, que **depende** dos três (`needs: [go, node, python, package-smoke,
windows-integrations-resolve]`) e passou a sair `skipped`.

A causa:

```go
// internal/validator/validator_test.go:2122
func TestExtractRefPath_TresREQsReaisDoRepositorio(t *testing.T) {
	reqs := []string{
		"docs/req/REQ-2026-07-27-roadmap-move-sincroniza-o-status-do-artefato.md",
		"docs/req/REQ-2026-07-27-integridade-das-referencias-e-ciclo-de-vida-da-req.md",
		"docs/req/REQ-2026-07-27-convergencia-dos-templates-de-artefato-do-cli-python.md",
	}
```

O mesmo bloco, com os mesmos três caminhos chumbados, existe em `npm/tests/validator.test.js:2197` e
`pypi/tests/test_validator.py:599`.

### Isto é a família do #277, num lugar pior

O [#277](https://github.com/kgsaran/trackfw/issues/277) reporta que o gate do `barrier` congela um
corpus dos roadmaps do próprio repositório e por isso não fecha num consumidor. **Aqui é a suíte de
testes do produto**, não um gate: três artefatos de governança do mantenedor são **fixtures de
teste** — lidas por caminho literal, nos três runtimes.

A consequência para um fork consumidor é mais dura que a do corpus: mexer no **próprio** `docs/req/`
reprova `go test`, `node --test` e `pytest`. E `docs/req/` **não é o nosso `req_dir`** — o nosso é
`docs/requisições/`. São artefatos que só existem aqui como resíduo de merge, e que a suíte do
produto exige que continuem existindo.

Elas foram escolhidas por serem *"as 3 REQs reais do repositório sem `adr:` no frontmatter, cujo ADR
só é referenciado no corpo entre backticks"* — ou seja, o teste depende de uma **propriedade
acidental do acervo do mantenedor**, não de uma fixture construída para o caso.

### Decisão local: restaurar as 3, manter removidas as 2

Os 5 removidos se dividem:

| | |
|---|---|
| **3** `REQ-2026-07-27-*` | lidas pelos testes → **restauradas** |
| **2** `REQ-2026-09-02-*` | quebravam a integridade referencial → **seguem removidas** |

Os dois gates ficam verdes ao mesmo tempo, e isso foi medido antes de commitar.

Não corrijo o teste aqui: é produto, e a correção certa é fixture própria em `testdata/`, que é
decisão do mantenedor. Vai como issue.

## Acceptance Criteria

- [x] **AC1** — As 3 REQs lidas pelos testes voltam a `docs/req/`; as 2 que quebravam a integridade
      seguem removidas.
- [x] **AC2** — Os dois gates passam **ao mesmo tempo**: `check-referential-integrity.sh` diz
      `Referential integrity OK` **e** o teste dos três runtimes passa. Medido local antes do PR.
- [x] **AC3** — `validate` sem violação e denominador conferido.
- [ ] **AC4** — O acoplamento vira issue no upstream, com a medição — é instância mais forte do #277
      e deve ser reportada como tal, não como bug isolado.
- [x] **AC5** — Nenhum arquivo de produto tocado aqui.

## Negative Scope

- **Não** corrigir o teste no nosso fork. Fixture própria em `testdata/` é a correção certa e é
  produto — criar divergência local por isso custaria em todo merge futuro.
- **Não** remover as 3 de novo até o upstream desacoplar o teste.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-tres-reqs-de-docs-req-sao-lidas-por-teste-de-produto-nos-tres-runtimes.md
