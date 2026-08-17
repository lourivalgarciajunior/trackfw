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

- [ ] Gate extrai subcomandos dos três formatos de help
- [ ] Detecta faltando e sobrando
- [ ] Divergências conhecidas declaradas com motivo; o gate passa com elas
- [ ] Divergência nova falha, verificado na prática
- [ ] Documentado no `CLAUDE.md`

---

## Wave 1 — O gate

### ML-1 — Extrator e comparação
**Status:** ⬜ Pendente
**Arquivos afetados:** `scripts/check-subcommand-parity.sh` (NOVO)
**Ações:**
1. Extrator por runtime: cobra (`Available Commands:`), commander (`Commands:`, descartando o `help`
   automático), argparse (bloco `positional arguments:` com metavar `COMMAND` ou `SUBCOMMAND`).
2. Filtrar linhas de continuação de descrição longa — só a primeira palavra de linhas que casam
   `^[a-z][a-z0-9-]*$`.
3. Comparar conjuntos nos dois sentidos, por comando, tomando o Go como referência.
4. Mensagem de falha com comando, runtime, subcomando e direção.
**Critérios de aceite:**
- [ ] Extrai os quatro comandos corretamente nos três runtimes
- [ ] Sem o allowlist, o gate acusa exatamente as divergências medidas à mão
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh`

### ML-2 — Allowlist de divergências conhecidas
**Status:** ⬜ Pendente
**Arquivos afetados:** `scripts/check-subcommand-parity.sh`
**Ações:**
1. Declarar as divergências atuais, cada uma com o motivo em comentário.
2. Confirmar que o gate passa com elas e falha sem elas.
**Critérios de aceite:**
- [ ] Gate passa
- [ ] Removendo uma declaração, o gate falha apontando exatamente aquela

---

## Wave 2 — Fechamento

### ML-3 — Documentação e não-regressão
**Status:** ⬜ Pendente
**Arquivos afetados:** `CLAUDE.md`
**Ações:**
1. Acrescentar o gate novo à seção de gates de paridade, com uma linha dizendo o que ele cobre que
   os outros não cobrem.
2. Rodar os quatro gates e as três suítes.
**Critérios de aceite:**
- [ ] `CLAUDE.md` lista os quatro gates
- [ ] Os quatro passam; suítes sem falha nova
**Comandos de validação:** `bash scripts/check-subcommand-parity.sh && bash scripts/check-cli-parity.sh`
