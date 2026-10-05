---
status: wip
date: 2026-10-05
req: "REQ-2026-10-05-a-vigia-do-upstream-ve-pr-novo-e-nao-ve-issue-nova"
squad: "claude"
---

# Roadmap: a vigia do upstream ve PR novo e nao ve issue nova

> Created: 2026-10-05 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-10-05-a-vigia-do-upstream-ve-pr-novo-e-nao-ve-issue-nova.md

Ver a REQ. Em uma frase: **a vigia cobre commit, PR e comentario, e nao cobre issue CRIADA** — e foi
por isso que a #526 do upstream, aberta as 17:27 local de 2026-10-05, passou com a vigia viva.

## Acceptance Criteria

- [x] AC1 a AC6 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model do braco novo
**Status:** ✅ Concluído
**Files affected:** nenhum (medicao e decisao)
**Actions:**

**1. A enumeracao dos sinais esta fechada?** Derivada do script, nao da lembranca: `snap_main`
(commit), `snap_prs` (PR, inclusive novo), `snap_com` (comentario de outro autor). Procurado no
arquivo por qualquer leitura de lista de issues — zero. Os sinais do GitHub que um vigia deste repo
poderia querer e que continuam FORA depois desta REQ: release/tag, Discussion, review de PR, e label.
Ficam declarados como residuo, nao como esquecimento.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem acrescentar o braco **filtrando por
autor**, por simetria com o `diff_com`. Fica consistente na leitura e **cego para o unico caso
medido** — a #526 e da nossa propria conta. A simetria e a armadilha; a razao da assimetria vai
escrita no script.

E quem acrescentar o braco **sem filtrar pull request**: o endpoint `/issues` do GitHub devolve PR na
mesma lista, entao cada PR novo sairia duas vezes por ciclo, com vocabulario de estado diferente nas
duas. Passaria por "cobertura melhor".

**3. Falsificacao nas duas direcoes, por afirmacao.** Issue nova emite / issue nova de autor nosso
tambem emite / PR na carga do braco de issues NAO emite / corpo de erro do 503 invalida o snapshot
inteiro / snapshot invalido nao move a base e nao emite / leitura valida atravessa intacta. O lado
negativo de cada par e o que separa o gate de um teste decorativo: sem o "leitura valida atravessa",
a correcao segura seria um braco que recusa tudo.

**4. Residuo declarado.** O custo por ciclo sobe de 2 para 3 chamadas de API — ~120/hora no ciclo de
90 s, contra as 46 por ciclo que estouraram o limite secundario em 2026-09-29. A guarda de forma
valida FORMA, nao VERDADE: corpo bem-formado de outro repositorio passaria, e a vigia tem uma fonte
so. E issue EDITADA (titulo trocado) nao e evento — so criacao e mudanca de estado.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia derivada do script, nao por assercao
- [x] Nenhuma linha de implementacao escrita neste ML

**Gates da wave:**
```bash
bash scripts/check-vigia-forma.sh
```

## Wave 1 — O braco de issues
> Dependencies: Wave 0

### ML-1A — `snap_issues`, `diff_issues` e os casos que os afirmam
**Status:** ✅ Concluído
**Files affected:** `scripts/vigia-do-upstream.sh`, `scripts/check-vigia-forma.sh`
**Actions:**
1. `snap_issues()` lendo `repos/$REPO/issues?state=all&per_page=15`, com
   `select(.pull_request == null)` para excluir PR, uma linha por issue na forma
   `<numero>:<OPEN|CLOSED>:<autor>`, ordenada e passada por `valida_forma "$RE_ISSUES"`.
2. `RE_ISSUES` declarada ao lado das outras tres formas.
3. `diff_issues()` emitindo `ISSUE #N aberta por <autor>` para numero novo e `ISSUE #N -> <estado>`
   para estado mudado, **sem filtro de autor**, com a razao da assimetria escrita no comentario.
4. O braco entra no laco com as mesmas duas linhas de guarda dos outros: so compara e so move a base
   quando a leitura e nao-vazia.
5. Cabecalho: o invariante de custo passa de 2 para 3 chamadas por ciclo, com a decomposicao.
6. `check-vigia-forma.sh`: casos novos para as seis afirmacoes do item 3 da Wave 0, `snap_issues` e
   `diff_issues` na lista de funcoes exigidas, `RE_ISSUES` na de formas, e a guarda de vacuidade
   subindo do minimo atual para o novo.

**Acceptance criteria:**
- [x] AC1 a AC6 da REQ
- [x] `bash scripts/check-vigia-forma.sh` verde, com o numero de casos impresso maior que o de antes
- [x] A sabotagem do braco novo reprova o gate — removido o `select(.pull_request == null)`, o gate
      falha nomeando o caso; e removido o `| valida_forma`, tambem. Sem esta verificacao o gate seria
      decorativo, que e o defeito que a propria primeira versao dele teve em 2026-10-02

**Gates da wave:**
```bash
bash scripts/check-vigia-forma.sh
grep -q 'pull_request == null' scripts/vigia-do-upstream.sh
grep -q 'RE_ISSUES' scripts/check-vigia-forma.sh
```

## Medicao do ML-1A

```
check-vigia-forma           31 caso(s) · 0 falha(s)     (eram 19)
sabotagem 1  tirar o select(.pull_request == null)  -> reprova em "o PR 527 da carga NAO aparece"
sabotagem 2  tirar o | valida_forma do braco novo   -> reprova em "snap_issues com corpo de erro"
sabotagem 3  filtrar $ME no diff_issues             -> reprova em "issue nossa emite igual"
arvore byte a byte identica depois das tres
```

**Contra a API real do upstream**, nao so contra fixture: `snap_issues` devolveu 5 issues com
`per_page=30`, e a sobreposicao com o snapshot de PRs e **zero** — o filtro de `pull_request` provado
por efeito contra a carga de verdade.

🔴 **E o teste real achou um limite que a fixture nao mostrava:** dos 15 primeiros itens do `/issues`,
**13 eram PR**, porque o endpoint mistura os dois. Com `per_page=15` sobravam 2 issues na janela. A
janela foi para 30 e as duas propriedades desiguais ficaram **declaradas no script**: criacao e sempre
vista (ordem por criacao decrescente poe issue nova na posicao 1), mudanca de estado so para issue
dentro da janela.
