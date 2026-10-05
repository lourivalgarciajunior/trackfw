---
status: Done
date: 2026-10-05
author: ""
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-05-as-14-branches-upstream-pr-sao-todas-terminais-e-o-acervo-de-branches-mente-sobre-trabalho-vivo.md"
---

# REQ: as 14 branches upstream-pr sao todas terminais e o acervo de branches mente sobre trabalho vivo

> Date: 2026-10-05 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
O acervo de branches **afirmava quatorze propostas pendentes ao upstream**, e nenhuma estava
pendente. Artefato cujo estado contradiz o que ele afirma é a mesma classe de defeito que o
`check-req-done-com-criterio-aberto.sh` existe para fechar — aqui no acervo de branches em vez de
no de REQs.

## Acceptance Criteria

- [x] AC1 — Cada uma das 14 tem veredito **escrito** com o PR nomeado, e o denominador reconcilia
      ✅ tabela de 14 linhas acima, uma por branch, com o número do PR e o estado; 10 + 4 = 14.
- [x] AC2 — As 14 são removidas do local **e** do `origin`, sem contornar o hook de git
      ✅ `antes: local=14 origin=14` → `depois: local=0 origin=0`, com **14 removidas · 0 falhas**.
      Remoto por `MSYS_NO_PATHCONV=1 gh api -X DELETE`, local por `git branch -D`; o hook não foi
      tocado.
- [x] AC3 — O `CLAUDE.md` registra o que foi removido e **onde o conteúdo sobrevive**
      ✅ seção nova antes do ratchet de Windows, com a tabela, os dois achados que invertem a
      leitura ingênua, e a prova por efeito: **depois** da remoção, `pulls/222` ainda serve o diff
      (`refs/pull/222/head` persiste).
- [x] AC4 — `git branch` passa a listar só branches de trabalho corrente
      ✅ restam `main` e a branch deste trabalho. Zero `upstream-pr/*`.


## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-05-as-14-branches-upstream-pr-sao-todas-terminais-e-o-acervo-de-branches-mente-sobre-trabalho-vivo.md

## Context

Quatorze branches `upstream-pr/*` vivem no local **e no `origin`** desde a campanha de contribuição
de agosto/setembro. A instrução em vigor era *"vamos deixar como está"*, e ela fazia sentido enquanto
não se soubesse o que cada uma era.

🔴 **O custo não é o espaço: é o acervo de branches AFIRMAR trabalho vivo que não existe.** Quem abre
`git branch` lê quatorze propostas pendentes ao upstream. Nenhuma está pendente. É a mesma classe de
defeito que o `check-req-done-com-criterio-aberto.sh` existe para fechar — artefato cujo estado
contradiz o que ele afirma —, só que no acervo de branches em vez de no de REQs.

## Medição — 2026-10-05

Discriminante: **PR terminal no upstream** (merged ou closed), reforçado por `git cherry` (patch-id)
quando o merge foi por squash e o patch-id não bate.

| branch (sem o prefixo) | PR | `git cherry` | veredito |
|---|---|---|---|
| `gate-do-barrier-morre-em-cp1252` | #238 MERGED | 2 `+` | (a) entregue |
| `gate-doctor-remote-nao-roda-sem-symlink` | #245 MERGED | 1 `+` | (a) entregue |
| `other-bucket-no-status-de-go-e-node` | #263 MERGED | 1 `-` | (a) entregue |
| `package-lock-parado-em-6-1-0` | #249 MERGED | 1 `-` | (a) entregue |
| `slug-do-python-deleta-em-vez-de-colapsar` | #247 MERGED | 1 `-` | (a) entregue |
| `teste-do-gitattributes-fixa-o-arquivo-inteiro` | #254 MERGED | 1 `-` | (a) entregue — `c9438bd8` |
| `gitattributes-test-limpa` | **nenhuma** | 1 `-` | (a) entregue — **duplicata** do commit acima |
| `testes-de-sincronia-de-status-no-move-do-roadmap` | #248 MERGED | 1 `-` | (a) entregue |
| `tripwire-de-disco-trunca-o-corpus-congelado` | #257 MERGED | 3 `+` | (a) entregue |
| `write-fixture-crlf-corrompe-nao-ascii` | #240 MERGED | 4 `+` | (a) entregue |
| `geradores-python-escrevem-crlf` | #225 CLOSED | 1 `+` | (c) caducou — v8 apagou o CLI Python |
| `tty-do-python-no-windows` | #224 CLOSED | 2 `+` | (c) caducou — idem |
| `utf8-do-cli-python` | #223 CLOSED | 1 `+` | (c) caducou — idem |
| `windows-home-e-bit-de-execucao` | #222 CLOSED | 3 `+` | (c) caducou **em parte absorvida** — ver abaixo |

**Dez entregues, quatro caducadas, zero vivas.** O denominador reconcilia: 14 = 10 + 4.

### 🔴 O `-` do `git cherry` não é o discriminante sozinho, e o `+` não significa "não entregue"

Seis das dez entregues saem `+` — **merge por squash reescreve o patch**, então o patch-id deixa de
bater mesmo com o conteúdo lá dentro. Usar só `git cherry` teria classificado seis branches entregues
como pendentes. O PR terminal é quem decide; o `cherry` só confirma as que entraram verbatim.

### A #222 é a única que exigiu olhar o conteúdo, e o resultado inverte a aparência

A PR foi **fechada**, o que sugeriria proposta recusada. Não é:

```
upstream/main:internal/homedir/homedir.go  contém o NOSSO texto:
  "The trackfw test suites isolate the home directory"
  "%USERPROFILE% on Windows"
```

A metade **Go** foi absorvida — reimplementada pelo mantenedor, com a justificativa que escrevemos. A
metade do **bit de execução** virou a [#421](https://github.com/kgsaran/trackfw/issues/421), hoje
**CLOSED** pelo [#522](https://github.com/kgsaran/trackfw/pull/522). As metades **Node e Python** não
têm mais onde existir.

🔴 **Lição: PR fechada não é igual a trabalho descartado.** Quatro das nossas PRs fecharam sem merge e
pelo menos uma teve o conteúdo absorvido por outra via. Classificar pelo estado do PR sem olhar o
produto teria registrado como perdido algo que está em produção.

## Escopo negativo

- 🔴 **Não se reabre nada.** Se alguma das quatro caducadas voltar a importar, o caminho é issue nova
  com medição nova — não ressuscitar branch de agosto contra uma árvore cinco majors adiante.
- Não se mexe nas branches do upstream (`upstream/*`): não são nossas.
