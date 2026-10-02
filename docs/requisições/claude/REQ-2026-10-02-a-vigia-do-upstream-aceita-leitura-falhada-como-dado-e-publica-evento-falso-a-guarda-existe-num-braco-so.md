---
status: Open
date: 2026-10-02
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/wip/ROADMAP-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md"
---

# REQ: a vigia do upstream aceita leitura falhada como dado e publica evento falso: a guarda existe num braco so

> Date: 2026-10-02 | Status: Open
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

- [ ] AC1 — A validação de forma é **por braço e sobre o snapshot inteiro**: `main` casa 40 hexa;
      PRs, `^[0-9]+:(MERGED|OPEN|CLOSED)$` em **todas** as linhas; comentários,
      `^[0-9]+\t[0-9]+\t[^\t]+\t(issue|pull)$` em todas. Uma linha fora da forma invalida o
      **snapshot todo**, não só a linha — filtrar a linha ruim produziria snapshot truncado, que é o
      dano 2.
- [ ] AC2 — Snapshot inválido é tratado como **leitura que falhou**: não entra na comparação e **não
      move a base**. Verificado por efeito, com o corpo de erro real do 503 injetado.
- [ ] AC3 — Transição real continua sendo emitida depois de uma leitura inválida: injetar erro, depois
      devolver leitura válida com uma transição, e ver o evento sair **uma vez**.
- [ ] AC4 — O script passa a viver em `scripts/`, e o `run-local-gates.sh` o declara na lista **FORA
      com motivo** (é daemon de laço infinito, não gate). A guarda de completude do agregador reprova
      script nosso não declarado — então este AC é verificado pelo próprio agregador.
- [ ] AC5 — As duas guardas que já existiam continuam provadas: ordenação `LC_ALL=C` nos dois lados do
      `comm`, e comentário de autoria própria não vira evento.
- [ ] AC6 — Nenhuma chamada de API acrescentada: continua 0 (`git ls-remote`) + 1 (PRs) + 1
      (comentários) por ciclo. Medido por contagem de chamadas no ciclo, não por leitura do código.

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
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md
