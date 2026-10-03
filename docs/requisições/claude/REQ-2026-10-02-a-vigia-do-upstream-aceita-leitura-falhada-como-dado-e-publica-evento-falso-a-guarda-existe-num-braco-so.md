---
status: Done
date: 2026-10-02
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md"
---

# REQ: a vigia do upstream aceita leitura falhada como dado e publica evento falso: a guarda existe num braco so

> Date: 2026-10-02 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation

A vigia do upstream (`vigia3.sh`) é o instrumento com que este fork responde *"o mantenedor
evoluiu?"*. Ela tem **três braços de leitura** — `main` por `git ls-remote`, PRs e comentários por
REST — e a guarda *"leitura que falhou não é dado"* existe **em um só**: o de comentários.

🔴 **Medido em 2026-10-01.** Um 503 do GitHub no braço de PRs fez o corpo de erro chegar ao
comparador, e a vigia publicou um **evento falso** antes de morrer:

```
PR #{"message" -> ...
(depois, exit 255)
```

Dois danos, e o segundo é pior:

1. **Evento falso** — eu fui conferir um PR que não havia mudado.
2. 🔴 **Baseline envenenado.** O comparador move a base para o que leu. Uma leitura truncada ou
   corrompida vira a nova referência, e aí: as transições reais daquele ciclo somem (não há com o que
   comparar), e quando a leitura volta ao normal **o acervo inteiro reaparece como novidade**. Foi
   exatamente o modo de falha que a guarda do braço de comentários já existia para impedir — a mesma
   causa, em sítio não coberto.

O mesmo vale para o braço da `main`: ele aceita o que o `awk` devolver. Leitura degradada ali produz
`MAIN do upstream mudou: <lixo> -> <lixo>`.

**E o script vive no scratchpad da sessão**, então morre com ela: a correção não sobrevive, e a
próxima sessão herda o defeito. Pela decisão da `ADR-2026-08-29`, acrescentar arquivo em `scripts/`
não cria divergência de produto — é o precedente do `upstream-sync.sh`, que também é ferramenta e não
gate.

## Acceptance Criteria

- [x] AC1 — A validação de forma é **por braço e sobre o snapshot inteiro**: `main` casa 40 hexa;
      PRs, `^[0-9]+:(MERGED|OPEN|CLOSED)$` em **todas** as linhas; comentários,
      `^[0-9]+\t[0-9]+\t[^\t]+\t(issue|pull)$` em todas. Uma linha fora da forma invalida o
      **snapshot todo**, não só a linha — filtrar a linha ruim produziria snapshot truncado, que é o
      dano 2.
      ✅ `RE_MAIN` (40 hexa), `RE_PRS` e `RE_COM` em `scripts/vigia-do-upstream.sh`, aplicados pelo
      `valida_forma` ao snapshot **inteiro**. Caso 7 do `check-vigia-forma.sh`: snapshot misto
      (2 boas + 1 ruim) sai vazio. Sabotagem que troca a invalidação total por filtro de linha
      **reprova** nos casos 7 e 7b.
- [x] AC2 — Snapshot inválido é tratado como **leitura que falhou**: não entra na comparação e **não
      move a base**. Verificado por efeito, com o corpo de erro real do 503 injetado.
      ✅ Caso 13: `ciclo()` com leitura inválida devolve `|<base>` — zero evento, base intacta. O
      corpo injetado é o do 503 real.
- [x] AC3 — Transição real continua sendo emitida depois de uma leitura inválida: injetar erro, depois
      devolver leitura válida com uma transição, e ver o evento sair **uma vez**.
      ✅ Casos 8, 9 e 13: transição `508 OPEN -> MERGED` emite **uma** vez, segundo ciclo sem
      mudança emite nada, e leitura válida move a base.
- [x] AC4 — O script passa a viver em `scripts/`, e o `run-local-gates.sh` o declara na lista **FORA
      com motivo** (é daemon de laço infinito, não gate). A guarda de completude do agregador reprova
      script nosso não declarado — então este AC é verificado pelo próprio agregador.
      ✅ `scripts/vigia-do-upstream.sh` na árvore, declarado FORA com motivo, e
      `scripts/check-vigia-forma.sh` em EXECUTAR. Agregador: `12 executado(s) · 0 falha(s)`,
      local e no `gates-locais` do CI do #193.
- [x] AC5 — As duas guardas que já existiam continuam provadas: ordenação `LC_ALL=C` nos dois lados do
      `comm`, e comentário de autoria própria não vira evento.
      ✅ Caso 12 (entrada invertida não inventa evento) e casos 10-11 (comentário de outro autor
      emite, o nosso não).
- [x] AC6 — Nenhuma chamada de API acrescentada: continua 0 (`git ls-remote`) + 1 (PRs) + 1
      (comentários) por ciclo. Medido por contagem de chamadas no ciclo, não por leitura do código.
      ✅ Nenhuma chamada acrescentada: `snap_main` segue em `git ls-remote` (0 API), `snap_prs` e
      `snap_com` em uma chamada REST cada. O `valida_forma` é filtro local, não faz I/O de rede.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

A `ADR-2026-08-29` decide **adotar o upstream como base e sincronizar por merge**, e é dela que sai o
fluxo que esta vigia serve: saber quando há o que trazer. É dela também o precedente de que
acrescentar arquivo em `scripts/` não cria divergência de produto — a política de resolução por área
dá o `scripts/` ao fork quando o arquivo é só nosso, como o `upstream-sync.sh`.

🔴 **O limite da citação:** a ADR não decide nada sobre validação de leitura nem sobre a vigia, que
não existia quando ela foi escrita. O que ela governa aqui é **onde o script mora** e **por que o fork
observa o upstream**; a decisão de forma do snapshot é desta REQ.

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md

## Fechamento — 2026-10-02/03

Entregue pelo [#193](https://github.com/lourivalgarciajunior/trackfw/pull/193), mesclado em
`d81e03ff` com CI 24/24 verde e comparação por nome contra a linha de base (22 nomes = 17 da base +
5 nossos, nenhum job deixou de rodar).

🔴 **O achado desta REQ não foi o defeito, foi o teste do defeito.** A primeira versão do
`check-vigia-forma.sh` exercitava `valida_forma` **direto** e nunca os braços: remover
`| valida_forma "$RE_PRS"` de `snap_prs` — o defeito original de volta — deixava o gate verde com
`15 casos · 0 falhas`. Quem pegou foi a sabotagem, não a leitura, e a Wave 0 desta própria REQ havia
nomeado esse modo de esvaziamento. Os casos 14-17 fecharam, substituindo `gh` e `git` por função.

**Resíduo que fica aberto de propósito:** a validação é de **forma**, não de **verdade**. Corpo
bem-formado e errado passa, e não há como distinguir sem uma segunda fonte. Declarado, não coberto —
se algum dia houver segunda fonte, é REQ nova, com medição.
