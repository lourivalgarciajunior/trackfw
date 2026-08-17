---
id: REQ-2026-08-16-aspas-em-itens-de-lista
title: Remover aspas de itens de lista em adr_dirs e agents no parser de trackfw.yaml
status: approved
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: Aspas em itens de lista do `trackfw.yaml`

Roadmap: aspas-em-itens-de-lista-2026-08-16.md

## Problema

O parser de `trackfw.yaml` remove as aspas envolventes de forma **inconsistente entre blocos**, nos
três runtimes igualmente:

| Bloco | Aspas removidas? | Go | npm | Python |
|---|---|---|---|---|
| escalares top-level (`req_dir`, `roadmap_dir`, …) | sim | `splitKV` (`config.go:318`) | `index.js:169` | `config.py` |
| `rules:` valores | sim | via `splitKV` | `index.js:130` | `config.py` |
| `acceptance_markers:` itens | sim | `config.go:186` | `index.js:120` | `config.py` |
| `link_fields:` itens | sim | `config.go:200` | — | `config.py` |
| **`adr_dirs:` itens** | **não** | `config.go:172` | `index.js:111` | `config.py` |
| **`agents:` itens** | **não** | `config.go:178` | `index.js:115` | `config.py` |

YAML trata `- claude` e `- "claude"` como o mesmo valor. O parser do trackfw não: nos dois blocos
acima o valor fica com as aspas literais grudadas.

### Impacto — falha silenciosa

Com `roadmap_namespacing: by_agent`, o nome do agente é usado para montar o caminho dos artefatos.
Um agente escrito como `- "claude"` nunca casa com `docs/requisições/claude/` nem com
`docs/roadmaps/claude/`, então **todo o namespace daquele agente desaparece da validação**:

```
agents:
  - claude      → trackfw validate encontra 5 achados
  - "claude"    → trackfw validate encontra 3 achados
```

Medido neste repositório com o binário Go compilado do fonte e com o CLI npm 2.12.4 — resultado
idêntico nos dois. As 20 REQs de `docs/requisições/claude/` somem sem erro, sem aviso e sem
qualquer sinal: o gate fica verde por não estar olhando. É o pior modo de falha possível numa
ferramenta cujo propósito é ser gate.

O mesmo vale para `adr_dirs:` — um diretório de ADR entre aspas simplesmente não é varrido.

### Por que os gates de paridade não pegam

Os três runtimes erram da mesma forma, então `scripts/check-validate-parity.sh` compara duas saídas
igualmente erradas e passa. Não é quebra de paridade — é bug replicado. Só aparece contra um
fixture que use aspas, que hoje não existe.

## Requisitos

### R1 — Remover aspas envolventes nos itens de `adr_dirs` e `agents`
Mesmo tratamento já aplicado em `acceptance_markers`: `strings.Trim(val, "\"'")` no Go,
`.replace(/^["']|["']$/g, '')` no npm, `.strip('"\'')` no Python. Aspas simples e duplas.

### R2 — Paridade tri-runtime
A correção entra nos três: `internal/config/config.go`, `npm/src/config/index.js`,
`pypi/trackfw/config.py`.

### R3 — Teste em cada runtime
Um teste por runtime que carrega um `trackfw.yaml` com `adr_dirs` e `agents` entre aspas (simples e
duplas) e assevera que os valores chegam limpos. Sem esse teste o bug volta.

## Critérios de Aceite

- [x] `- "claude"` e `- 'claude'` produzem o agente `claude` nos três runtimes
- [x] `- "docs/adr"` produz o diretório `docs/adr` nos três runtimes
- [x] Teste novo em `internal/config/`, `npm/tests/config.test.js` e `pypi/tests/test_config.py`
- [x] `go build ./...` verde e `go test ./internal/config/` verde
- [x] `node npm/tests/config.test.js` verde — 13 passed, 0 failed
- [x] `python -m unittest tests.test_config` verde (pytest não instalado no ambiente; o arquivo
      usa unittest da stdlib)
- [x] `bash scripts/check-cli-parity.sh` e `bash scripts/check-validate-parity.sh` passam
- [x] `trackfw validate` acha o mesmo número de itens com e sem aspas no `agents:`
