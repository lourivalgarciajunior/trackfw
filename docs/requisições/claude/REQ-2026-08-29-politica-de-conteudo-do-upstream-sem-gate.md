---
status: done
date: 2026-08-29
author: claude
adr: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-politica-de-conteudo-do-upstream-sem-gate.md
---

# REQ: Politica de conteudo do upstream sem gate

> Date: 2026-08-29 | Status: Open

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-08-29-politica-de-conteudo-do-upstream-sem-gate.md

## Motivation

A `ADR-2026-08-29-adotar-upstream-como-base` diz que produto vem do upstream e que a governanca e o
conteudo dele **nao sao importados**. A politica esta escrita e **nao e auto-aplicavel**: conteudo
do upstream entrou **tres vezes** nesta sessao, sempre sem gerar conflito.

| PR | O que entrou | Como foi notado |
|---|---|---|
| #28 | `vault/notes/index.md` | por acaso, durante a resolucao |
| #29 | 2 notas de `vault/` | reparei depois do merge |
| #31 | 1 ADR do upstream | o `validate` acusou ADR sem REQ |

O mecanismo e sempre o mesmo: **caminho novo nao colide com nada.** Removemos o `vault/` na #19,
entao um arquivo novo em `vault/notes/` nao gera conflito — o git so adiciona. Nao ha o que
resolver, e a politica so vale se alguem reparar.

A terceira so apareceu porque produziu efeito colateral visivel. Nao ha razao para supor que a
quarta produza.

## Desenho: proveniencia, nao lista de caminhos

Lista de caminhos proibidos envelhece a cada release do upstream. O sinal estavel e outro:

> **Arquivo sob `docs/` ou `vault/` que exista tambem em `upstream/main` e conteudo do upstream** —
> a menos que esteja declarado como mantido de proposito.

Medido hoje: **10 arquivos** coincidem, e os 10 sao legitimos.

```
docs/agents-working-context.md          handoff, escrevemos nele
docs/cli-parity.md                      doc de produto
docs/gate-design-principles.md          doc de produto
docs/demo.gif                           doc de produto
docs/schema/{adr,req,roadmap}.schema.json   schema de produto
docs/visao-projeto/VISION.md            doc de produto
docs/seguranca/2026-08-15-skills-de-terceiro-via-url.md   lido por teste Go
docs/roadmaps/.trackfw-log              nosso, coincide no caminho
```

Contra os tres vazamentos historicos, o desenho pega os tres: as notas de `vault/` e a ADR existem
em `upstream/main` e nao estariam na lista de mantidos.

## Acceptance Criteria

- [ ] Gate reprova com qualquer um dos tres vazamentos historicos reintroduzido — verificado um a
      um, nao em bloco
- [ ] Gate passa no estado atual
- [ ] A lista de mantidos e explicita e cada entrada tem o motivo escrito
- [ ] Sem `upstream/main` buscado, o gate **falha dizendo isso** — nunca passa por nao conseguir
      checar
- [ ] O motivo de cada mantido sobrevive a leitura de quem nao viveu esta sessao

## Nao faz parte

Codigo de produto. Um arquivo novo em `internal/`, `npm/src/` ou `pypi/trackfw/` **deve** vir do
upstream — e o oposto do que este gate protege. O escopo e `docs/` e `vault/`.

## Blocked by ADRs
<!-- none -->
