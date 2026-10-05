---
status: done
date: 2026-10-05
req: "REQ-2026-10-05-as-14-branches-upstream-pr-sao-todas-terminais-e-o-acervo-de-branches-mente-sobre-trabalho-vivo"
squad: "claude"
---

# Roadmap: as 14 branches upstream-pr sao todas terminais e o acervo de branches mente sobre trabalho vivo

> Created: 2026-10-05 | Status: done

## Context

Ver a REQ para a tabela das 14 com veredito por branch. Em uma frase: **dez entregues por PR mesclada,
quatro caducadas com o produto que as carregava, zero vivas.**

## Acceptance Criteria

- [x] AC1 a AC4 da REQ, verificados por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model da remoção
**Status:** ✅ Concluído
**Files affected:** nenhum (medição e decisão)
**Actions:**

**1. O que se perde ao apagar uma branch, e onde o conteúdo sobrevive.**

```
13 das 14 têm PR no upstream  ->  refs/pull/<N>/head persiste no GitHub mesmo
                                  depois de a branch de origem sumir
 1 (gitattributes-test-limpa) ->  sem PR, mas o MESMO commit entrou como
                                  c9438bd8 pela #254; conteúdo em upstream/main
10 entregues                  ->  o conteúdo está na main do upstream, que é
                                  ancestral da nossa
```

Nenhuma das 14 é o único portador do seu conteúdo. A remoção apaga **ponteiro**, não trabalho.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem apagar por contagem — *"são 14, todas
antigas"* — em vez de por veredito. Foi exatamente assim que seis branches **entregues** apareceram
como `+` no `git cherry`: um critério só, aplicado em bloco, classifica errado. O ônus é por branch.

**3. A operação é irreversível no remoto, e o hook de git bloqueia o atalho.** `git push --delete` é
bloqueado aqui. O caminho é `MSYS_NO_PATHCONV=1 gh api -X DELETE .../git/refs/heads/<branch>`, que é a
via declarada, **não um contorno**. 🔴 Contornar o hook continua vetado — inclusive para isto.

**4. Resíduo declarado.** A remoção é por nome, uma chamada por branch. Se o nome estiver errado, a
chamada falha com 422 em vez de apagar outra coisa — o modo de falha é seguro. O que **não** há é
desfazer: a lista é conferida contra a medição antes de rodar, e o resultado é conferido depois.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
      ✅ (1) onde o conteúdo sobrevive, por classe, com a prova por efeito depois da remoção;
      (2) o esvaziador nomeado — apagar por contagem em vez de por veredito, que é o erro que o
      `git cherry` sozinho produziria em 6 das 10; (3) a via declarada para o remoto, e o veto ao
      contorno do hook mantido; (4) resíduo: falha por nome é 422, modo de falha seguro.
- [x] Nenhuma branch removida neste ML
      ✅ o ML-0A é prosa e tabela; a remoção inteira aconteceu no ML-1A.

**Gates da wave:**
> 🔴 O gate afirma que a TABELA tem 14 linhas, não que existam 14 branches. A primeira versão
> exigia `git branch --list 'upstream-pr/*' | wc -l` igual a 14 — e a Wave 1 deste mesmo roadmap
> as apaga, então o gate reprovaria no `roadmap move ... done` por ter cumprido o seu objetivo.
> É a premissa que envelhece com o trabalho, o mesmo defeito já registrado no `CLAUDE.md` para o
> roadmap de `backlog/` cuja colisão "tem de ser 8" hoje é 914.
```bash
test "$(grep -c '^| `' "docs/requisições/claude/REQ-2026-10-05-as-14-branches-upstream-pr-sao-todas-terminais-e-o-acervo-de-branches-mente-sobre-trabalho-vivo.md")" -eq 14
```

## Wave 1 — Remoção
> Dependencies: Wave 0

### ML-1A — As 14 saem do local e do `origin`
**Status:** ✅ Concluído
**Files affected:** nenhum na árvore (operação sobre refs)
**Actions:**
1. Remover do `origin` por `gh api -X DELETE`, uma por vez, conferindo o código de retorno.
2. Remover do local com `git branch -D` — `-D` e não `-d`, porque elas **não** são ancestrais da
   nossa `main`: o conteúdo foi para a `main` do **upstream**, por squash, e o `-d` recusaria.
3. Conferir o denominador depois: zero `upstream-pr/*` local e zero no `origin`.
**Acceptance criteria:**
- [x] AC2 e AC4 da REQ, com a contagem antes e depois
      ✅ `antes: local=14 origin=14` · `depois: local=0 origin=0` · 14 removidas, 0 falhas.
**Gates da wave:**
```bash
test "$(git branch --list 'upstream-pr/*' | wc -l)" -eq 0
```

### ML-1B — O rastro fica escrito
**Status:** ✅ Concluído
**Files affected:** `CLAUDE.md`
**Actions:**
1. Registrar a varredura com a tabela de vereditos e **onde o conteúdo sobrevive**.
2. Registrar as duas lições: o `+` do `git cherry` em merge por squash, e PR fechada ≠ trabalho
   descartado.
**Acceptance criteria:**
- [x] AC1 e AC3 da REQ
      ✅ tabela por branch na REQ, e a seção do `CLAUDE.md` com onde o conteúdo ficou.
**Gates da wave:**
```bash
grep -q 'upstream-pr' CLAUDE.md
```
