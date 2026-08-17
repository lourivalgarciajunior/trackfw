---
name: adrs-retroativas-2026-08-16
title: "ADRs retroativas das 5 REQs sem decisão registrada"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-adrs-retroativas
branch: docs/adrs-retroativas
---

# Roadmap: ADRs retroativas

> Created: 2026-08-16 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-16-adrs-retroativas.md`

## Diagnóstico / Contexto

O repositório não tem nenhuma ADR; cinco REQs disparam `req_has_adr`. Cada ADR é reconstruída de
três fontes — texto da REQ, roadmap e código atual — e **o código vence** quando divergem. Método e
o caso em que ele já pagou (a REQ de geração por IA, marcada `done` para trabalho que não
aconteceu) estão na REQ.

Origem: item 5 da dívida acumulada nesta sessão.

## Critérios de Aceite

- [ ] 5 ADRs em `docs/adr/` com `status: Accepted` e nota de reconstrução
- [ ] Link bidirecional REQ ↔ ADR nas cinco
- [ ] `req_has_adr` de volta a `error`
- [ ] `trackfw validate` limpo de violações e avisos
- [ ] Suítes e gates verdes

---

## Wave 1 — Escrever as ADRs

> Uma por REQ. Independentes entre si.

### ML-1 — ADR do wizard interativo e da fronteira command/generator
**Status:** ⬜ Pendente
**Origem:** `REQ-req-wizard-e-list-2026-06-11`
**Evidência no código:** `internal/commands/req.go` usa `huh` (linha 42); `internal/generators/req.go`
recebe `REQContent` e não faz prompt; `newReqListCmd` registrado.
**Decisão a registrar:** todo I/O interativo vive no command layer; generators recebem struct
preenchida e nunca perguntam nada. É o que torna os generators testáveis sem TTY.
**Critérios de aceite:**
- [ ] ADR criada com as quatro seções e `status: Accepted`
- [ ] Alternativa descartada registrada (wizard dentro do generator)

### ML-2 — ADR da geração de roadmap sem LLM
**Status:** ⬜ Pendente
**Origem:** `REQ-roadmap-ai-generation-2026-06-11`
**Evidência no código:** `internal/ai/` **não existe**; nenhuma menção a anthropic/openai em Go;
`go.mod` sem dependência de IA; `--from-req` deriva MLs dos critérios de aceite nos três runtimes.
**Decisão a registrar:** o roadmap é derivado deterministicamente da REQ, não gerado por LLM. A ADR
diverge do que a REQ pediu, de propósito, e diz por quê.
**Critérios de aceite:**
- [ ] ADR registra a decisão do código, não a da REQ
- [ ] A divergência entre REQ e código está explícita na ADR

### ML-3 — ADR dos testes de API sem servidor
**Status:** ⬜ Pendente
**Origem:** `REQ-2026-06-14-serve-api-tests-nodejs`
**Evidência no código:** `npm/tests/serve_api.test.js` importa `handleBoard`, `handleFile`,
`handleMetrics` e `getAttention` direto — nenhum `listen`, nenhuma porta.
**Decisão a registrar:** os handlers do `serve` são funções sobre um diretório de fixture, testáveis
sem subir servidor nem bindar porta.
**Critérios de aceite:**
- [ ] ADR criada com as quatro seções

### ML-4 — ADR do subcomando nativo por ferramenta de IA
**Status:** ⬜ Pendente
**Origem:** `REQ-multi-ai-support-2026-06-11`
**Evidência no código:** `internal/commands/{gemini,cursor,copilot,windsurf,amazonq}.go`; templates
por formato em `internal/generators/templates/`; instaladores idempotentes.
**Decisão a registrar:** um subcomando por ferramenta emitindo o formato nativo dela, em vez de um
exportador genérico. Cada instalador é idempotente e nunca sobrescreve customização do usuário.
**Critérios de aceite:**
- [ ] ADR criada com as quatro seções
- [ ] Alternativa descartada registrada (formato único genérico)

### ML-5 — ADR da descoberta de ADR guiada pela REQ
**Status:** ⬜ Pendente
**Origem:** `REQ-req-driven-adr-discovery-2026-06-12`
**Evidência no código:** `generators.DetectDomains` chamado em `internal/commands/req.go:60`;
`generators.NewADRDraft` em `:109`; regra `blocked_by_draft_adr` como `error` no validator.
**Decisão a registrar:** o fluxo `ADR → REQ` ganha a entrada inversa: a REQ detecta domínios e emite
ADRs `Draft`, e o roadmap fica bloqueado enquanto houver Draft. O caminho direto continua existindo.
**Critérios de aceite:**
- [ ] ADR criada com as quatro seções
- [ ] A relação com a regra `blocked_by_draft_adr` está explícita

---

## Wave 2 — Fechamento

### ML-6 — Links, regra e gate
**Status:** ⬜ Pendente
**Arquivos afetados:** as 5 REQs, `trackfw.yaml`
**Ações:**
1. Linha `ADR:` em cada uma das 5 REQs.
2. `req_has_adr` de volta a `error` no `trackfw.yaml`, removendo o comentário que explicava o
   rebaixamento.
3. `trackfw validate` — zero violações e zero avisos.
4. Suítes dos três runtimes e os três gates.
**Critérios de aceite:**
- [ ] `req_has_adr` em `error` e nenhuma violação
- [ ] `adr_orphan` não dispara — as 5 ADRs são referenciadas
- [ ] Suítes e gates verdes
**Comandos de validação:** `trackfw validate && go test ./...`
