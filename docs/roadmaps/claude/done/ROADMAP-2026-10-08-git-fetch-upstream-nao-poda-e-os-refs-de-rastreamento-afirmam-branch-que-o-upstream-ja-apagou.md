---
status: done
date: 2026-10-08
req: "docs/requisições/claude/REQ-2026-10-08-git-fetch-upstream-nao-poda-e-os-refs-de-rastreamento-afirmam-branch-que-o-upstream-ja-apagou.md"
squad: "claude"
---

# Roadmap: git fetch upstream nao poda e os refs de rastreamento afirmam branch que o upstream ja apagou

> Created: 2026-10-08 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-10-08-git-fetch-upstream-nao-poda-e-os-refs-de-rastreamento-afirmam-branch-que-o-upstream-ja-apagou.md -->
REQ: docs/requisições/claude/REQ-2026-10-08-git-fetch-upstream-nao-poda-e-os-refs-de-rastreamento-afirmam-branch-que-o-upstream-ja-apagou.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] O passo liga a poda sem rede, e nenhum dos seus caminhos é mudo
- [x] A sequência documentada leva `--prune`, e a medição 135/4/131 está escrita

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model deste roadmap
**Status:** ✅ Concluído
**Files affected:** nenhum (só análise)
**Actions:**

**1. Completude da enumeração — onde mais a leitura de refs velhos morde?**

Derivado, não enumerado à mão: quem lê `refs/remotes/upstream` no repositório.

```
git grep -n "refs/remotes\|for-each-ref\|branch -r\|ls-remote"  -> 0 ocorrencias em scripts/
upstream-sync.sh                 usa apenas $REF (upstream/main) — sempre atualizado pelo fetch
check-inherited-req.sh           usa upstream/main — idem
check-contorno-dos-shims…        usa tags, nao branches
```

> 🔴 **CORRIGIDO no ML-1B, no mesmo dia: esta conclusão estava ESTREITA.** Ela derivou de um
> `git grep` em `scripts/`, e quem também lê os refs de rastreamento é o **próprio produto**
> (`detectPendingSquashMerges`, em `internal/commands/ship.go`). Fica como registro do que a
> varredura alcançou — e do que ela não alcançou.

🔴 **Conclusão que inverte a leitura ingênua: nenhum gate nosso é afetado.** O único consumidor de
"branches do upstream" é a **leitura avulsa do agente** ao responder *"o Kleber evoluiu?"* — por isso
o defeito sobreviveu: ele não tem sítio em arquivo nenhum. É instrumento de sessão, não de CI.

**2. Quem esvazia esta Wave sem quebrar regra escrita?**

Quem ligasse a poda **só nesta máquina** e declarasse o trabalho feito. A config é local ao clone e
não é versionada: clone novo nasce com o defeito. Fechado por desenho — o passo roda **a cada sync**,
em vez de ser instrução de instalação, e a sequência documentada leva `--prune`, que não depende de
config.

**3. Falsificação nas duas direções**

| direção | o que tem de acontecer |
|---|---|
| sem a correção | ref sintética **sobrevive** ao `git fetch` normal |
| com a correção | o **mesmo** `git fetch` normal a **poda** |
| regressão oposta | config já ligada **não** é reescrita, e `fetch.prune` global é respeitado |
| premissa ausente | `--ref` sem remote resolve para **N/A nomeado**, nunca para veredito |

**4. Residual declarado**

- A chave é **config local**; clone novo nasce sem ela. Mitigado pelo passo e pelo `--prune`.
- O passo **não poda agora** (não faz rede, de propósito). Quem quiser a poda na passada corrente
  usa o `--prune` da sequência documentada.
- 🔴 **Não há gate.** Em runner limpo os refs chegam frescos: um gate passaria descrevendo o vazio —
  mesmo precedente do `check-copia-do-path-esta-atras.sh` e do `check-platform-predicates.sh`.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência, não com asserção de uma linha
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
test 0 = "$(git grep -c -e 'refs/remotes/upstream' -- scripts | wc -l)"
```

## Wave 1 — Implementação
> Dependencies: ML-0A

### ML-1A — O passo no `upstream-sync.sh` e a sequência documentada
**Status:** ✅ Concluído
**Files affected:** `scripts/upstream-sync.sh`, `CLAUDE.md`
**Actions:**
> 🔴 **CORRIGIDO no ML-1C: derivar do `$REF` deixava o `origin` DESCOBERTO por construção.**
> O passo passou a ligar `fetch.prune` e a enumerar por `git remote`. Fica como registro.

1. `poda_refs_de_rastreamento`: deriva o remote de `$REF`, lê `remote.<remote>.prune` e `fetch.prune`,
   liga a primeira quando nenhuma vale, e **diz** o que encontrou e o que fez.
2. A sequência documentada no `CLAUDE.md` passa a `git fetch upstream --prune`.
3. Seção nova no `CLAUDE.md` com a medição, a diferença de causa contra a REQ-2026-10-05 e a
   falsificação.

**Medição:**
```
135 refs locais · 4 branches reais · 131 podados          4 + 131 = 135
as 4 mais novas da leitura local: 404 na API, uma a uma
5 return 0 · 5 com `say` imediatamente antes (awk, retorno-a-retorno)
fetch normal, config vazia  -> ref sintetica SOBREVIVE
depois do passo, MESMO fetch -> PODADA
```

**Acceptance criteria:**
- [x] Os cinco caminhos exercitados um a um, nenhum mudo
- [x] Falsificado com o remoto real, sem `git update-ref` (bloqueado pelo hook, e contornar é vetado)
- [x] `bash -n` do script passa

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
bash -n scripts/upstream-sync.sh
test 5 = "$(awk '/^poda_refs_de_rastreamento\(\) \{/,/^\}/' scripts/upstream-sync.sh | grep -c 'return 0')"
grep -q 'git fetch upstream --prune' CLAUDE.md
```

### ML-1B — A enumeração do ML-0A ficou ESTREITA: o PRODUTO também lê `refs/remotes`
**Status:** ✅ Concluído
**Files affected:** `CLAUDE.md` (parágrafo novo); nenhum arquivo de produto — o sítio é do upstream
**Actions:**

🔴 **Correção datada do ML-0A, não apagamento.** A seção 1 dele concluiu *"nenhum gate nosso é
afetado"* derivando de `git grep` em **`scripts/`**. O escopo estava estreito: quem mais lê os refs
de rastreamento é o **próprio `trackfw`**, e o achado apareceu **no push deste trabalho**, não na
análise.

```
internal/commands/ship.go  detectPendingSquashMerges
  git branch -r --no-merged origin/main      <- TODOS os remote-tracking, nao so os do origin
  shortName = TrimPrefix(candidate, "origin/")   <- 'upstream/foo' atravessa com o prefixo
  evaluateBranchWithForge(..., "origin/"+shortName, ...)  -> 'origin/upstream/foo', que nao existe
```

**Medido agora, com a poda já feita:**

```
trackfw push   4 avisos "appears to have unmerged changes vs origin/main"
               os 4 nomeiam branch do UPSTREAM, nao do origin
origin/fix/criterio-de-adr-por-prefixo existe?        NAO
commits NOSSOS em upstream/fix/criterio-de-adr…       0
```

Ou seja: **falso positivo puro** — o comando avisa sobre trabalho que não é nosso, em branch que o
`origin` não tem. Antes da poda eram **135 refs** entrando nesse laço em vez de 5.

**O que isto muda na leitura do defeito:** ele deixa de ser só "a leitura avulsa do agente" e passa
a ter um consumidor **no produto**, visível ao usuário a cada `trackfw push`. Reforça a correção em
vez de contradizê-la.

**Acceptance criteria:**
- [x] O segundo consumidor está nomeado por símbolo e medido por efeito
- [x] A conclusão estreita do ML-0A está **datada e explicada**, não apagada
**Residual declarado, e NÃO escrito como critério:** o defeito é do **produto do upstream**, e o
escopo negativo da REQ manda que achado ali vire **issue**, não correção local. 🔴 **Não virou
checkbox de propósito** — inventar critério para o trabalho seguinte faria este roadmap fechar com
critério aberto, que é o defeito que o `check-req-done-com-criterio-aberto.sh` existe para recusar.
✅ **Aberta: [#547](https://github.com/kgsaran/trackfw/issues/547)**, com esta medição, o controle negativo (`upstream/main` **não** avisa — o predicado funciona, está aplicado sobre a população errada) e a prova de que **nenhuma fixture de teste devolve remote que não seja o `origin`**, que é por que o ramo sobreviveu.

**Limite declarado:** 🔴 **a contagem de avisos ANTES da poda não é re-mensurável.** As 131 refs
foram podadas antes de o segundo consumidor ser descoberto, e as branches não existem mais no
remoto para refetch. O que está medido é o **mecanismo** (o laço itera todo remote-tracking) e o
estado de **agora** (4 avisos, 4 falsos).

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
grep -q 'detectPendingSquashMerges' internal/commands/ship.go
grep -q 'trackfw push' CLAUDE.md
```

### ML-1C — A poda cobria SÓ o `upstream`; o `origin` estava descoberto por construção
**Status:** ✅ Concluído
**Files affected:** `scripts/upstream-sync.sh`, `CLAUDE.md`
**Actions:**

🔴 **O ML-1A derivava o remote de `$REF`** (`upstream/main`), então o `origin` **nunca** seria
tocado. Medido na varredura de *"o que ficou pendente"*, **60 minutos** depois de eu declarar a
Wave 0 fechada:

```
remote.upstream.prune  true
remote.origin.prune    VAZIO     <- descoberto POR CONSTRUCAO
origin/chore/sync-do-546-o-c-barra-na-segunda-camada   ref local EXISTE
  a mesma branch no GitHub                              404
```

1. O passo passou a ligar **`fetch.prune`**, que cobre todos os remotes — inclusive os que ainda não
   existem — em vez de um por vez.
2. Enumera por **`git remote`**, nunca `origin`/`upstream` chumbados.
3. Quando há `remote.<r>.prune=false`, **não afirma cobertura**: diz `🔴 AINDA DESCOBERTO` nomeando
   o remote e dá o `--unset` como remédio.

**Falsificado em seis direções** (repositório temporário): nenhum remote → N/A nomeado; dois
descobertos → liga e **nomeia quais eram**; já coberto → idempotente; um por chave própria e o outro
não; `false` explícito → avisa que segue descoberto; **três** remotes com o terceiro acrescentado
depois → já coberto, que é o caso que prova que a **classe** fechou.

**A premissa de precedência foi medida POR EFEITO, com o remoto real, nas duas direções** — não lida
na documentação do git:

```
fetch.prune=true + remote.upstream.prune=false   ref sintetica SOBREVIVE  <- a do remote GANHA
fetch.prune=true + chave do remote removida      ref sintetica PODADA
```

**E o resíduo do `origin` fechou por efeito, com `fetch` sem flag nenhuma:**

```
git fetch origin
 - [deleted]  (none) -> origin/chore/sync-do-546-o-c-barra-na-segunda-camada
refs de origin: 2 -> 1
```

**Acceptance criteria:**
- [x] O passo cobre todos os remotes e os enumera por derivação
- [x] O caso em que o git **recusa** a cobertura é dito, não escondido
- [x] A premissa de precedência está medida por efeito, nas duas direções
- [x] Os 5 `return 0` têm `say` imediatamente antes (awk, retorno-a-retorno)

**Residual declarado:** a chave continua **config local do clone**. Clone novo nasce sem ela — por
isso o passo roda a cada sync. 🔴 **Terceira ocorrência do mesmo sintoma em um dia** (as 14
`upstream-pr/*`, os 131 refs do `upstream`, o `origin`): o que muda a cada vez é só **quem** deixou
de podar, e é por isso que a correção foi para a **classe**, não para o remote.

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
grep -q 'fetch.prune' scripts/upstream-sync.sh
test 5 = "$(awk '/^poda_refs_de_rastreamento\(\) \{/,/^\}/' scripts/upstream-sync.sh | grep -c 'return 0')"
test 0 = "$(awk '/^poda_refs_de_rastreamento\(\) \{/,/^\}/' scripts/upstream-sync.sh | grep -c 'remote.origin')"
```
