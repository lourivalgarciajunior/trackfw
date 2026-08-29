---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-geradores-python-escrevem-crlf-no-windows
squad: ""
---

# Roadmap: Geradores Python escrevem CRLF no Windows

> Created: 2026-08-29 | Status: wip

## Context

O CLI Python grava todo arquivo com CRLF no Windows; Go e Node gravam LF. Viola a Regra Dura de
Paridade e quebra os `scripts/*.sh` gerados em qualquer sistema POSIX. Bloqueia o ML-2A do roadmap
do slug.

REQ: docs/requisições/claude/REQ-2026-08-29-geradores-python-escrevem-crlf-no-windows.md

## Acceptance Criteria

- [ ] CLI Python grava LF em todo arquivo que produz, medido por varredura de bytes
- [ ] `scripts/*.sh` com o mesmo shebang nos tres runtimes
- [ ] `check-artifact-parity.sh` sem os 8 drifts `go vs python`
- [ ] Gate **falha** com o CRLF reintroduzido — nao-vacuidade verificada
- [ ] Suite pypi sem regressao contra 198 failed / 1294 passed

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** done

#### 1. Completude da enumeracao

Enumerei **por efeito**, nao por call site: rodei `init` e os quatro `new` num diretorio limpo por
runtime e varri os bytes de tudo que sobrou.

```
py    CRLF=23 arquivos   LF=0
go    CRLF=0             LF=22
```

Zero excecao dos dois lados, o que fecha a questao melhor do que qualquer grep. A contagem estatica
(48 `open(w|a)` sem `newline`, 20 `write_text`, 2 `json.dump`, 18 `print(file=)`) serve para achar
os sites a corrigir, mas **nao** para provar cobertura — `write_text` e `print(file=)` tambem
traduzem, e sao faceis de esquecer numa varredura que so procura `open`.

Os 23 arquivos cobrem cinco familias: os 9 slash commands em `.claude/commands/trackfw/`,
`.claude/settings.json`, `CLAUDE.md`, os 4 artefatos de governanca e os 5 `scripts/*.sh`.

#### 2. Quem esvazia esta Wave 0 sem quebrar regra escrita

1. **Corrigir so os `open()` e deixar `write_text` e `print(file=)`.** Nada proibe, e a varredura
   ingenua por `open` da a sensacao de completude. **Coberto:** o criterio exige varredura de bytes
   do resultado, nao contagem de call site.
2. **Deixar o gate insensivel a EOL** (`diff --strip-trailing-cr`) e declarar resolvido. Some o
   sintoma, fica o `.sh` quebrado em POSIX. **Nao coberto por gate** — fica como proibicao escrita
   aqui: a comparacao continua byte a byte.
3. **Merge futuro do upstream reintroduz.** A CI deles e Linux e nunca ve isso, entao todo arquivo
   novo que eles escreverem vem sem `newline`. **Coberto:** o gate da Wave 0 e estatico e falha em
   qualquer site novo sem `newline`.

#### 3. Alvos de falsificacao, nas duas direcoes

| Regride para | Quebra o que |
|---|---|
| CRLF (hoje) | `.sh` com `bad interpreter: bash^M` em POSIX; 8 drifts no gate de artefato |
| LF via modo binario | some a traducao mas quebra encoding — o `_force_utf8_output` cuida de stdout, nao de arquivo |
| gate insensivel a EOL | verde com o defeito vivo; e o pior estado, porque parece resolvido |
| `newline=""` em uns e `newline="
"` em outros | os dois funcionam para escrita, mas a inconsistencia convida alguem a "padronizar" de volta para `None` |

#### 4. Residual declarado

- **Divergencia de shebang** (`bash` no Python contra `sh` em Go e Node) foi medida aqui mas nao e
  fim de linha. Vai para ML-1B, separada, para nao misturar as duas.
- Leitura de arquivo nao entra: `open(..., "r")` com `newline=None` faz universal newlines, que ja
  aceita os dois. So a escrita diverge.
- Arquivo binario nao entra.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
bash scripts/check-python-writes-lf.sh
```

## Wave 1 — A correcao
> Dependencies: ML-0A

### ML-1A — Escrita de arquivo em LF no Python
**Status:** pending
**Files affected:** `pypi/trackfw/` — os sites de `open(w|a)`, `write_text`, `json.dump` e
`print(file=)` que produzem arquivo
**Actions:**
1. Passar `newline="
"` explicito em toda escrita de texto. Nao `newline=""`: os dois evitam a
   traducao, mas `"
"` diz a intencao.
2. Verificar por varredura de bytes, nao por contagem de call site.
**Acceptance criteria:**
- [ ] `py CRLF=0` na mesma medicao que hoje da 23
- [ ] Suite pypi sem regressao contra 198 failed / 1294 passed

### ML-1B — Shebang identico nos tres runtimes
**Status:** pending
**Files affected:** o gerador de `scripts/*.sh` no Python
**Actions:** Python escreve `#!/usr/bin/env bash`; Go e Node escrevem `#!/usr/bin/env sh`. Alinhar
o Python ao `sh`, que e o mais portavel e ja e maioria.
**Acceptance criteria:**
- [ ] Os cinco `scripts/*.sh` byte a byte identicos nos tres runtimes

## Wave 2 — A guarda
> Dependencies: ML-1A, ML-1B

### ML-2A — Gate de escrita em LF
**Status:** pending
**Files affected:** `scripts/check-python-writes-lf.sh` (novo)
**Actions:**
1. Gate estatico: nenhuma escrita de texto em `pypi/trackfw/` sem `newline` explicito. E o que
   protege contra merge futuro do upstream, que nunca vera o defeito na CI Linux deles.
**Acceptance criteria:**
- [ ] Gate passa depois de ML-1A
- [ ] Gate **falha** com um site sem `newline` reintroduzido — saida colada aqui
- [ ] `check-artifact-parity.sh` sem os 8 drifts, desbloqueando o ML-2A do roadmap do slug
