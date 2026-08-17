---
status: Accepted
date: 2026-06-12
author: claude
---

# ADR: A REQ descobre as ADRs pendentes, e ADR Draft bloqueia o roadmap

> Date: 2026-06-12 | Status: Accepted

REQ: REQ-req-driven-adr-discovery-2026-06-12

> **Reconstrução retroativa, escrita em 2026-08-16.** Decisão tomada em 2026-06-12 e nunca
> registrada — ironia registrada: é a ADR de uma feature cujo propósito é fazer ADRs existirem.
> Reconstruída do texto da REQ, do roadmap `roadmap-req-driven-adr-discovery-2026-06-12.md` e do
> código atual. Verificado: `generators.DetectDomains` é chamado em `internal/commands/req.go:60` e
> `generators.NewADRDraft` em `:109`; a regra `blocked_by_draft_adr` está no validator com
> severidade `error`. Ver `REQ-2026-08-16-adrs-retroativas`.

## Context

A cadeia do trackfw é `ADR → REQ → ROADMAP`. Ela pressupõe maturidade arquitetural: para escrever a
REQ, o usuário já precisa saber quais decisões existem.

Na prática isso não acontece. Quem não tem essa maturidade escreve a REQ direto, o roadmap sai dela,
o código é implementado — e as decisões arquiteturais foram tomadas assim mesmo, só que
implicitamente, dentro do código, sem registro. O gate `req_has_adr` acusa depois, quando o custo de
voltar atrás já é alto.

Este próprio repositório é a evidência: cinco REQs entregues, zero ADRs, e as decisões só foram
escritas dois meses depois — nestas ADRs retroativas.

Exigir ADR antes da REQ não resolve. Bloqueia quem não sabe o que perguntar, que é exatamente quem
mais precisa de ajuda.

## Decision

O fluxo ganha uma **entrada inversa**: a REQ passa a descobrir as decisões, em vez de pressupô-las.

No wizard do `trackfw req new`, depois que o usuário descreve a intenção:

1. `DetectDomains` varre título e motivação procurando domínios técnicos por palavra-chave —
   autenticação, UI, banco, API, deploy, eventos.
2. Para cada domínio detectado, o wizard faz uma pergunta-chave sobre a decisão latente daquele
   domínio.
3. Cada decisão que o usuário não resolve na hora vira um ADR `Draft` via `NewADRDraft`, já vinculado
   à REQ.

O acoplamento com o gate é o que dá dente à coisa: a regra `blocked_by_draft_adr` é `error`. Uma REQ
que linka ADR em `Draft` não passa no `validate` — na prática, o roadmap não avança enquanto a
decisão estiver aberta.

O caminho direto continua existindo: quem já sabe o que está fazendo passa `--adr` e não vê probe
nenhum.

## Consequences

**Positivas.** A decisão arquitetural é registrada no momento em que ainda é barata — antes do
roadmap, antes do código. O usuário menos experiente é conduzido pelas perguntas do seu contexto sem
precisar saber que elas existiam. E o `Draft` é honesto: registra que a decisão foi *identificada*
sem fingir que foi *tomada*.

**Negativas.** A detecção é por palavra-chave, então erra dos dois lados — perde domínio descrito com
vocabulário incomum, e dispara probe irrelevante em texto que só mencionou a palavra de passagem. O
custo do falso positivo é um ADR `Draft` indesejado que **bloqueia o roadmap** até ser resolvido ou
apagado. Isso transforma um erro de heurística em obstáculo de fluxo, e é a parte frágil do desenho.

O wizard também fica mais longo, o que pesa contra quem cria REQ com frequência — mitigado pelo
caminho direto, mas só para quem sabe que ele existe.

## Alternatives Considered

**Exigir ADR antes da REQ, sem probes.** Coerente com a cadeia declarada e trivial de implementar.
Descartada porque bloqueia exatamente quem o recurso pretende ajudar: quem não sabe quais decisões
existem não consegue escrever a ADR que destravaria a REQ.

**Detectar domínios por LLM em vez de palavra-chave.** Muito mais preciso, e resolveria os dois lados
do erro de detecção. Descartada pelas mesmas restrições de
`ADR-2026-06-11-roadmap-derivado-sem-llm`: o trackfw roda como gate, precisa funcionar offline, sem
credencial e de forma reprodutível.

**Emitir os `Draft` como aviso em vez de erro.** Removeria o custo do falso positivo. Descartada
porque esvazia o mecanismo: um aviso que não bloqueia é ignorado, e a decisão volta a ser tomada
implicitamente dentro do código — que é o problema original.
