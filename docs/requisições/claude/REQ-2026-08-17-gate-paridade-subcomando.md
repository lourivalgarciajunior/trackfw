---
id: REQ-2026-08-17-gate-paridade-subcomando
title: Gate de paridade de subcomando entre os três runtimes
status: approved
priority: high
type: feature
created: 2026-08-17
author: claude
---

# REQ: Gate de paridade de subcomando

Roadmap: gate-paridade-subcomando-2026-08-17.md

## Problema

`scripts/check-cli-parity.sh` compara o conjunto de **comandos de primeiro nível** e a saída de
`version`. Não desce em subcomando.

Isso deixou duas lacunas passarem despercebidas nesta sessão: `req move` faltava nos três runtimes
(`REQ-2026-08-17-req-move`) e `req list` faltava no Python
(`REQ-2026-08-17-req-list-python`). Em ambos os casos o comando `req` existia nos três, então a
paridade passava — e as lacunas só apareceram porque alguém tropeçou nelas, não porque um gate
avisou.

O gate atual também só verifica **presença**, com `grep`, contra uma lista fixa. Comando a mais num
runtime não é detectado.

### O que uma medição manual já revelou

Levantando os subcomandos de cada runtime à mão, antes de escrever o gate:

| comando | Go | Node.js | Python |
|---|---|---|---|
| `adr` | list, new | list, new | **new** |
| `req` | list, move, new | list, move, new | list, move, new |
| `roadmap` | list, move, new, show | list, move, new, show | list, move, new, show |
| `plugins` | add, list, remove, search | add, list, remove, search | **list, run** |

Duas divergências reais, nenhuma delas conhecida antes:

- **`adr list` não existe no Python.** Go e Node.js têm.
- **`plugins` diverge inteiro no Python**: faltam `add`, `remove` e `search`, e existe um `run` que
  os outros dois não têm.

## Consequência assumida

O gate nasce **vermelho**. Isso é o ponto — ele existe para tornar visível o que já estava quebrado.

**Corrigir as divergências não é escopo desta REQ.** Ela entrega o gate e a medição; o que fazer com
`adr list` e com `plugins` é decisão separada, e cada uma tem peso próprio — `plugins run` pode ser
capacidade deliberada do Python, não lacuna.

Para o gate poder entrar em CI sem quebrar tudo, ele nasce com uma lista de **divergências
conhecidas** declarada explicitamente no próprio script, com comentário dizendo por que cada uma
está lá. Divergência nova falha; divergência declarada passa. É o mesmo princípio do
`trackfw baseline`.

## Requisitos

### R1 — Extrair o conjunto de subcomandos de cada runtime
Os três formatam o help de forma diferente: cobra usa `Available Commands:`, commander usa
`Commands:`, argparse usa um bloco `positional arguments:` cujo metavar varia entre `COMMAND` e
`SUBCOMMAND`. O extrator normaliza os três para um conjunto de nomes.

Ruído a descartar: o `help` que o commander injeta sozinho, e as linhas de continuação de descrição
longa.

### R2 — Comparar conjuntos, não presença
Diferença nos dois sentidos: subcomando faltando **e** subcomando sobrando. O gate atual só olha
presença contra lista fixa.

### R3 — Divergências conhecidas declaradas no script
Lista explícita, cada entrada com o motivo. Sem arquivo de estado separado — o script é o registro.

### R4 — Cobrir os comandos que têm subcomando
`adr`, `req`, `roadmap` e `plugins`. Comando sem subcomando em runtime nenhum é ignorado.

### R5 — Falhar com mensagem acionável
Dizer o comando, o runtime, o subcomando e a direção (faltando ou sobrando).

## Critérios de Aceite

- [x] `scripts/check-subcommand-parity.sh` existe e roda nos três runtimes
- [x] Extrai corretamente de cobra, commander e argparse, incluindo o metavar variável
- [x] Detecta subcomando faltando **e** sobrando
- [x] Divergências conhecidas declaradas no script, com motivo
- [x] Com as duas divergências atuais declaradas, o gate passa
- [x] Divergência nova falha — verificado removendo temporariamente uma declaração
- [x] Documentado no `CLAUDE.md` junto dos outros três gates
