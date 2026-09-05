---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr.md"
---

# REQ: REQs que passam só por prosa — três do acervo sem link real de ADR

> Date: 2026-09-05 | Status: Done

## Motivation

Fechamos hoje a dívida de governança e o `validate` passou a reportar
**`✓ No violations found` com score 100/100**. Ao investigar a única REQ que sobrou `Open`, descobri
que esse verde é **parcialmente vacuoso**.

`REQ-2026-06-13-validator-improvements.md` passa `req_has_adr` e `req_has_roadmap` **porque as
palavras `ADR:` e `Roadmap:` aparecem dentro de prosa**:

```
`validateWIPHasREQ`, `validateREQsHaveADR`, `validateREQsHaveRoadmap`
- [ ] Quando o valor após `REQ:`, `ADR:` ou `Roadmap:` termina em `.md`
```

Ela **não tem link nenhum** — `linked_adr: —`. E o `linked_roadmap:` aponta para `wip/`, onde o
arquivo não está: ele está em `done/`.

O mecanismo é o `contentHasMarker` (`internal/validator/validator.go`), que usa
`strings.Contains(content, "ADR:")` — casa o marcador **em qualquer lugar do arquivo**, inclusive no
meio de um parágrafo. É a direção oposta do defeito que reportei em
[kgsaran/trackfw#278](https://github.com/kgsaran/trackfw/issues/278), e que eu tinha declarado ali
**não ter medido**.

Medido agora, nos dois acervos:

| | arquivos | passam só por prosa |
|---|---|---|
| nosso | 59 | **7** — 3 pelo critério frouxo, mais 4 pelo correto |
| upstream | 193 | **8** |

E a classificação completa do acervo do upstream fecha em 193:

```
ACUSADAS pelo gate                   11
passam com ADR ancorado (legitimo)  116
passam com "ADR:" so em PROSA         8
passam sem valor nenhum              58
                                    ---
                                    193

REQs sem link real de ADR            77     o gate acusa 11 — 14% da divida real
```

**As nossas três são dívida nossa**, independentemente de o upstream corrigir a regra. Corrigir o
acervo não depende de ele aceitar nada.

## Acceptance Criteria

- [x] **AC1** — As três REQs recebem marcador **ancorado em início de linha e com valor**:
      `REQ-2026-06-13-traceid-bidirecional`, `REQ-2026-06-13-v2.4-config-evolution`,
      `REQ-2026-06-13-validator-improvements`.
- [x] **AC2** — O `linked_roadmap:` da `validator-improvements` deixa de apontar para `wip/`: o
      arquivo está em `done/`. E o `status: Open` é resolvido — a entrega existe.
- [x] **AC3** — Zero REQs do nosso acervo passam só por prosa. Falsificação: o mesmo script que achou
      as três tem de devolver **0**, e tem de **continuar achando** uma REQ plantada de propósito com
      `ADR:` só em prosa.
- [x] **AC4** — `trackfw validate` continua sem violação **e** com o denominador intacto (58 REQs),
      medido com o binário da árvore. Verde com denominador menor não conta.
- [x] **AC5** — A medição completa (a classificação em 4 categorias que fecha em 193) é levada ao
      [#278](https://github.com/kgsaran/trackfw/issues/278), onde eu tinha escrito *"vale medir essa
      diferença sobre as 193; eu não medi"*.
- [x] **AC6** — Nenhum arquivo de produto tocado.

## Negative Scope

- **Não** corrigir a regra `contentHasMarker` aqui. É produto, e está reportado no #278.
- **Não** reescrever a prosa das REQs para escapar do casamento — o defeito é do gate, e mudar o
  texto para caber num gate frouxo seria esconder.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr.md
