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
