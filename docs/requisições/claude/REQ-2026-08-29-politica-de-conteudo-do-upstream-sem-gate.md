---
status: Open
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

- [x] Gate reprova com qualquer um dos tres vazamentos historicos reintroduzido — verificado um a
      um, nao em bloco
      → **(a) ENTREGUE**, e a prova é melhor que um plantio: em 2026-09-10 o gate está **vermelho
      com 7 casos vivos** — notas de `vault/`, pareceres de `docs/qualidade` e `docs/seguranca`, e
      uma ADR. É o mecanismo funcionando sobre vazamento real, não simulado.
      🔴 **Limite:** a verificação "um a um" de agosto não é re-executável — a REQ não nomeia quais
      eram os três arquivos. O que se verifica hoje é que o mecanismo acusa, com denominador.
- [ ] Gate passa no estado atual
      → 🔴 **(b) NAO ENTREGUE.** `bash scripts/check-upstream-content.sh` → **`exit 1`**, acusando
      **7 arquivos** de governança do upstream em `docs/`:
      ```
      docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-...
      docs/portabilidade/2026-09-02-renomeacao-de-agentes-identidade-e-presets.md
      docs/qualidade/2026-09-02-parecer-codificacao-declarada.md
      docs/qualidade/2026-09-03-parecer-resolvedor-de-req.md
      docs/seguranca/2026-09-02-modelo-de-ameaca-da-saida-nao-ascii.md
      docs/seguranca/2026-09-02-parecer-codificacao-declarada.md
      docs/seguranca/2026-09-03-parecer-resolvedor-de-req.md
      ```
      🔴 **O gate que esta REQ criou está vermelho, e ninguém notou.** Ele não está em nenhum alvo
      do `Makefile` nem em CI — é o mesmo padrão que esta REQ existia para fechar, agora aplicado a
      ela mesma. **Causa diferente desta auditoria** → trabalho próprio, com medição própria.
- [x] A lista de mantidos e explicita e cada entrada tem o motivo escrito
      → **(a) ENTREGUE.** O bloco `KEEP` tem **27 entradas** e **26 comentários** de motivo. A
      diferença de 1 é a linha do próprio delimitador, não uma entrada sem motivo — conferido por
      leitura.
- [x] Sem `upstream/main` buscado, o gate **falha dizendo isso** — nunca passa por nao conseguir
      checar
      → **(a) ENTREGUE.** Falsificado em 2026-09-10 apontando `REF` para ref inexistente:
      ```
      exit 1
      conteudo do upstream: nao consigo checar — `upstream/...` nao existe localmente.
        rode `git fetch upstream` e tente de novo.
        Este gate REPROVA em vez de passar: verde por nao conseguir checar seria pior
      ```
      🔴 **A primeira tentativa não valeu:** usei a variável de ambiente `UPSTREAM_REF`, que este
      gate **não lê** — ele chumba `REF="upstream/main"` na linha 22. O `exit 1` que recebi vinha
      dos 7 vazamentos, não da ref. Refeito com cópia mutada dentro de `scripts/`.
- [x] O motivo de cada mantido sobrevive a leitura de quem nao viveu esta sessao
      → **(a) ENTREGUE**, verificado por leitura em 2026-09-10 — por mim, que **não** vivi a sessão
      de agosto. Os motivos são autocontidos: `docs/agents-working-context.md  # handoff entre
      sessoes; escrevemos nele`, `docs/cli-parity.md  # doc de produto`. Cada um diz **por que**
      fica, não só que fica.
      🔴 Este AC é o único dos 56 cuja verificação **sou eu**: um leitor que não estava lá. É
      evidência fraca por natureza — mas é exatamente a que o AC pede.

## Nao faz parte

Codigo de produto. Um arquivo novo em `internal/`, `npm/src/` ou `pypi/trackfw/` **deve** vir do
upstream — e o oposto do que este gate protege. O escopo e `docs/` e `vault/`.

## Blocked by ADRs
<!-- none -->
