---
name: gate-paridade-subcomando-2026-08-17
title: "Gate de paridade de subcomando"
status: wip
date: 2026-08-17
req: REQ-2026-08-17-gate-paridade-subcomando
branch: feat/gate-paridade-subcomando
---

# Roadmap: gate de paridade de subcomando

> Created: 2026-08-17 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-17-gate-paridade-subcomando.md`

## Diagnóstico / Contexto

`check-cli-parity.sh` compara só comandos de primeiro nível, e só presença. Foi por isso que
`req move` e `req list` faltaram sem nenhum gate avisar. A medição manual feita antes de escrever o
gate já achou duas divergências novas — `adr list` ausente no Python e o `plugins` divergindo
inteiro. Tabela completa na REQ.

O gate nasce vermelho de propósito, com as divergências atuais declaradas no próprio script para
poder entrar em CI. Corrigi-las é decisão separada.

## Critérios de Aceite

- [x] Gate extrai subcomandos dos três formatos de help
- [x] Detecta faltando e sobrando
- [x] Divergências conhecidas declaradas com motivo; o gate passa com elas
- [x] Divergência nova falha, verificado na prática
- [x] Documentado no `CLAUDE.md`

---

## Wave 1 — O gate

### ML-1 — Extrator e comparação
**Status:** ✅ Concluído
**Arquivos afetados:** `scripts/check-subcommand-parity.sh` (NOVO)
**Ações:**
1. Extrator por runtime: cobra (`Available Commands:`), commander (`Commands:`, descartando o `help`
   automático), argparse (bloco `positional arguments:` com metavar `COMMAND` ou `SUBCOMMAND`).
2. Filtrar linhas de continuação de descrição longa — só a primeira palavra de linhas que casam
   `^[a-z][a-z0-9-]*$`.
3. Comparar conjuntos nos dois sentidos, por comando, tomando o Go como referência.
4. Mensagem de falha com comando, runtime, subcomando e direção.
**Critérios de aceite:**
- [x] Extrai `adr`, `req`, `roadmap` e `plugins` nos três formatos de help
- [x] Sem o allowlist, o gate acusa **exatamente** as 5 divergências medidas à mão:

```
✗ adr: 'list' faltando no runtime python
✗ plugins: 'add' faltando no runtime python
✗ plugins: 'remove' faltando no runtime python
✗ plugins: 'search' faltando no runtime python
✗ plugins: 'run' sobrando no runtime python
```

- [x] O metavar do argparse varia entre `COMMAND` e `SUBCOMMAND` conforme o comando — o extrator
      ancora em `positional arguments:` em vez do metavar, senão o `roadmap` do Python sairia vazio
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh`

### ML-2 — Allowlist de divergências conhecidas
**Status:** ✅ Concluído
**Arquivos afetados:** `scripts/check-subcommand-parity.sh`
**Ações:**
1. Declarar as divergências atuais, cada uma com o motivo em comentário.
2. Confirmar que o gate passa com elas e falha sem elas.
**Critérios de aceite:**
- [x] Gate passa com as 5 declaradas
- [x] Removendo só a de `adr:python:list`, o gate falha apontando exatamente ela — 1 divergência,
      não 5
- [x] Declaração obsoleta gera aviso sem falhar: declarei `req:python:move:faltando`, que já não
      existe, e o gate respondeu
      `⚠ divergência declarada já não existe … — remova do allowlist` com rc=0. Evita que a lista
      apodreça depois que alguém corrigir a divergência

---

## Wave 2 — Fechamento

### ML-3 — Documentação e não-regressão
**Status:** ✅ Concluído
**Arquivos afetados:** `CLAUDE.md`
**Ações:**
1. Acrescentar o gate novo à seção de gates de paridade, com uma linha dizendo o que ele cobre que
   os outros não cobrem.
2. Rodar os quatro gates e as três suítes.
**Critérios de aceite:**
- [x] `CLAUDE.md` lista os quatro gates, com um parágrafo dizendo o que este cobre que o
      `check-cli-parity.sh` não cobre, citando os dois casos que passaram batido
- [x] Os quatro gates passam; `go test ./...` zero falhas; `trackfw validate` rc=0
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh && bash scripts/check-cli-parity.sh`
