---
id: REQ-2026-08-16-cli-python-utf8-windows
title: CLI Python quebra com UnicodeEncodeError em console Windows
status: approved
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: CLI Python e a saída não-ASCII no Windows

Roadmap: docs/roadmaps/claude/done/cli-python-utf8-windows-2026-08-16.md

## Problema

Num console Windows padrão, `sys.stdout.encoding` é **cp1252**. O CLI Python escreve setas (`→`),
marcas (`✓`, `✅`, `⚠`), caixas (`──`, `⚙`) e texto acentuado em português — nada disso existe em
cp1252. O resultado é `UnicodeEncodeError` e saída de erro no lugar do conteúdo.

Não é só o `--help`. Medido nesta máquina, a partir de `pypi/`:

| Comando | Go | Node.js | Python |
|---|---|---|---|
| `--help` | rc=0 | rc=0 | **rc=1** |
| `status` | rc=0 | rc=0 | **rc=1** |
| `validate` | rc=0 | rc=0 | **rc=1** |
| `version` | rc=0 | rc=0 | rc=0 |
| `adr --help` | rc=0 | rc=0 | rc=0 |

```
UnicodeEncodeError: 'charmap' codec can't encode character '→' in position 98
UnicodeEncodeError: 'charmap' codec can't encode character '✓' in position 0
```

`status` e `validate` são os dois comandos mais usados da ferramenta. **Na prática o runtime Python
é inutilizável num Windows recém-instalado** — só funciona para quem já sabe exportar
`PYTHONIOENCODING=utf-8` ou `PYTHONUTF8=1`.

O sintoma foi encontrado primeiro como atrito de CI local: `scripts/check-cli-parity.sh` só passa
nesta máquina quando precedido de `PYTHONIOENCODING=utf-8`. Isso é a ponta do problema, não o
problema.

### Por que Go e Node.js não sofrem

Ambos escrevem bytes UTF-8 direto no stdout, sem consultar codepage. Só o Python interpõe um
`TextIOWrapper` com a codificação herdada do console. Ou seja, **o comportamento correto já é o dos
outros dois runtimes** — é o Python que está fora de linha.

## Requisitos

### R1 — Forçar UTF-8 no stdout e stderr do CLI
No ponto de entrada, reconfigurar os dois streams para UTF-8 antes de qualquer escrita, alinhando o
runtime Python ao Go e ao Node.js.

### R2 — Degradar, nunca abortar
Usar `errors="replace"` na reconfiguração. Se algum ambiente ainda assim não conseguir representar
um caractere, ele vira `?` — o usuário perde um glifo, não o comando inteiro.

### R3 — Não quebrar quando stdout não é um console
Testes e pipelines substituem `sys.stdout` por objetos sem `reconfigure` (`StringIO`, por
exemplo). A reconfiguração precisa ser condicional e silenciosa nesses casos.

### R4 — Não depender de variável de ambiente
`PYTHONIOENCODING` e `PYTHONUTF8` continuam funcionando, mas deixam de ser necessários. O gate
`check-cli-parity.sh` deve passar sem prefixo nenhum.

## Critérios de Aceite

- [x] `python -m trackfw --help`, `status` e `validate` retornam rc=0 sem nenhuma variável de ambiente
- [x] Nenhum `UnicodeEncodeError` na saída dos três
- [x] `bash scripts/check-cli-parity.sh` passa **sem** `PYTHONIOENCODING`/`PYTHONUTF8`
- [x] `bash scripts/check-validate-parity.sh` passa sem prefixo
- [x] Suíte pypi sem falha nova: baseline atual é 6 errors + 1 failure pré-existentes
- [x] `go test ./...` segue com zero falhas
- [x] Teste cobrindo o caso de `sys.stdout` sem `reconfigure`
