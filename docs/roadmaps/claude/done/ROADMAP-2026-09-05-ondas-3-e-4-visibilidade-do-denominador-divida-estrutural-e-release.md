---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md"
squad: ""
---

# Roadmap: Ondas 3 e 4 — visibilidade do denominador, dívida estrutural e release

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ]
- [ ]

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** (nenhum de código — os itens pousam em kgsaran/trackfw)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Oito itens no plano para estas duas ondas. Enumerei **antes de medir** e decidi
**depois de medir** — dois produziram achado, seis não. A enumeração não parou na lista: ao medir o
A1 (que era proposta de flag), o defeito da literal apareceu, e ele é maior que a proposta.

**2. Threat model — quem esvazia esta onda sem quebrar regra escrita.**

- 🔴 **Volume.** Havia 5 issues abertas com ele, nenhuma respondida. Abrir 8 mais converteria
  contribuição em ruído — e é a falha que o escopo negativo da onda 1 previu. O contrapeso foi
  entregar 2 e **registrar os 6 com motivo**, em vez de entregar 8 fracos.
- **Proposta de ferramenta vestida de achado.** Metade dos itens é instrumento, não defeito. O
  contrapeso foi a regra que apliquei: sem achado medido, não vira issue. Derrubou F3 e G1.
- **Número de máquina local apresentado como universal.** Derrubou D1 — medir cache no meu CI não
  diz nada sobre o dele. É a lição do 62% × 9% da #273.
- **Medir o que já se sabe.** F1 exigiria rodar o `barrier`, bloqueado pelo corpus acoplado do #277.
  Reportar item bloqueado por outro item aberto meu seria empilhar.

**3. Falsificação nas duas direções.**

```
#278  7 grafias de vazio plantadas: 5 PASSAM, 2 reprovam
      controle: ADR: com valor real continua passando
      executado: 193 REQs do acervo dele, gate acusa 11, sao 69 (11+124+58)
      conta fecha exata; 3 das 58 conferidas a mao
#279  9 skips de plataforma, em 4 arquivos que a #269 nao tocou
      controle: os 22 que o ML-4A converteu nao aparecem na lista
```

**4. Residual declarado.**

- **A classificação das 182 que passam (124 com valor × 58 sem) é regex meu** reproduzindo o
  `contentHasMarker`. As 11 acusadas e o total de 193 são **execução** do binário. Conferi 3 das 58
  à mão, não as 58.
- **Rodei com config default.** Se o `trackfw.yaml` real dele configurar `link_fields` diferente, o
  número muda.
- **Os 9 skips foram contados por grep e classificados por leitura da mensagem**, não por execução —
  algum pode estar atrás de condição que nunca é verdadeira aqui.
- **O remédio que propus no #278 é mais estrito** que o atual (regex ancorado × `Contains` solto), e
  **não medi** quantas das 193 mudariam de veredito por causa disso. Está dito na issue.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
for n in 278 279; do
  gh issue view "$n" --repo kgsaran/trackfw --json number >/dev/null 2>&1 || { echo "issue #$n ausente"; exit 1; }
done
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1 — A1 (visibilidade do denominador).** Entregue como **defeito medido**, não como proposta
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1 — A1 (visibilidade do denominador).** Entregue como **defeito medido**, não como proposta
- [x] build passes
- [x] tests green

### ML-1B — **AC2 — G2 (os t.Skip).** Entregue: **9 skips de classe plataforma sobraram do ML-4A**, em 4
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2 — G2 (os t.Skip).** Entregue: **9 skips de classe plataforma sobraram do ML-4A**, em 4
- [x] build passes
- [x] tests green

### ML-1C — **AC3 — os demais itens ficam registrados como NÃO entregues, com o motivo.** Ver a seção
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3 — os demais itens ficam registrados como NÃO entregues, com o motivo.** Ver a seção
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Cada issue traz o achado medido, o controle na direção oposta, e a ressalva do que a
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Cada issue traz o achado medido, o controle na direção oposta, e a ressalva do que a
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Nada mesclado na nossa main como produto. Divergência de produto continua **zero**.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Nada mesclado na nossa main como produto. Divergência de produto continua **zero**.
- [x] build passes
- [x] tests green
