---
status: done
date: 2026-10-08
req: "docs/requisições/claude/REQ-2026-10-08-roadmap-done-com-ml-pendente-nao-tem-gate-e-a-premissa-ingenua-acusaria-17-legitimos.md"
squad: "claude"
---

# Roadmap: roadmap done com ML pendente nao tem gate e a premissa ingenua acusaria 17 legitimos

> Created: 2026-10-08 | Status: done

## Context
<!-- Derived from REQ -->
REQ: docs/requisições/claude/REQ-2026-10-08-roadmap-done-com-ml-pendente-nao-tem-gate-e-a-premissa-ingenua-acusaria-17-legitimos.md

## Acceptance Criteria
- [x] A premissa ingênua está medida e recusada, com o denominador decomposto
- [x] O gate existe, com marca explícita, derivação de herdada e duas guardas de vacuidade

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model deste roadmap
**Status:** ✅ Concluído
**Files affected:** nenhum (só análise)
**Actions:**

**1. Completude da enumeração — que outra forma de "ML não concluído" existe?**

Derivada do protocolo escrito no `CLAUDE.md` (item 5 do Agent Protocol), não enumerada de memória:

```
git grep -ohE '^\*\*Status:\*\* .*' docs/roadmaps | sort | uniq -c | sort -rn
   ✅ Concluído · ⬜ Pendente · 🔄 Em andamento · ❌ Bloqueado
```

🔴 **E a derivação corrigiu a minha primeira versão deste ML.** Eu escrevi que "as quatro" formas
estão no acervo e pus isso como gate da wave — o gate **reprovou**: no acervo real só existem
**duas** (`✅ Concluído` e `⬜ Pendente`). O protocolo declara quatro; o acervo exercita duas.

**Consequência, e é ela que justifica o self-test:** `🔄 Em andamento` e `❌ Bloqueado` em `done/`
**não têm nenhum caso real** que os exercite. O gate da wave passou a afirmar a propriedade do
**instrumento** — o classificador conhece as três formas de não-concluído —, que é o que este ML
concluiu, em vez de uma propriedade do acervo que eu não tinha medido.

**2. Quem esvazia esta Wave sem quebrar regra escrita?**

Quem acrescentasse a marca `fechamento-retroativo` **sem** nomear o sítio do entregável — a marca
viraria senha. Mitigado só em parte: o gate exige a marca, e o **texto** dela é leitura humana.
Declarado como limite na REQ em vez de fingido como coberto.

**3. Falsificação nas duas direções**

| direção | o que tem de acontecer |
|---|---|
| sem a marca | acusa **por nome**, `rc=1` |
| com a marca | `rc=0` |
| prosa citando a marca | **não** conta como declaração (caso de self-test) |
| premissa ausente (`upstream/main`) | falha **dizendo o motivo**, nunca deriva zero e passa |

**4. Residual declarado**

- O gate não confere se o entregável citado existe.
- Ele vê só conteúdo **no disco**; roadmap novo não commitado passa — mesmo limite já declarado no
  `check-os-predicate-classification.sh`, e em CI não é limitação porque lá tudo chega commitado.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
test 3 = "$(grep -oE 'Pendente|Em andamento|Bloqueado' scripts/check-roadmap-done-com-ml-pendente.sh | sort -u | wc -l)"
```

## Wave 1 — Implementação
> Dependencies: ML-0A

### ML-1A — O gate, a marca nos dois roadmaps e o consumidor
**Status:** ✅ Concluído
**Files affected:** `scripts/check-roadmap-done-com-ml-pendente.sh` (novo),
`scripts/run-local-gates.sh`, `.github/workflows/local-gates.yml`, os dois roadmaps de junho
**Actions:**
1. O gate, com `roadmap_dir` lido do `trackfw.yaml`, derivação de herdada por `git cat-file`,
   reconciliação dos quatro baldes e duas guardas de vacuidade.
2. A marca `<!-- fechamento-retroativo: … -->` nos dois roadmaps que já declaravam em prosa.
3. `EXECUTAR` do agregador (o consumidor que o `check-orphan-gates.sh` exige) e passo de
   `--self-test` no `local-gates.yml`, com guarda sobre o denominador.

**Medição:**
```
88 varridos · 71 sem ML pendente · 15 herdados · 2 declarados · 0 acusados
self-test            14 de 14 casos
agregador            16 executados · 0 falhas
check-orphan-gates   OK
falsificacao         marca removida -> acusa por nome (rc=1); restaurada -> rc=0
```

🔴 **A primeira falsificação estava ERRADA e teria passado por boa:** apaguei as linhas 1–3 e a
marca estava na **6**, então o gate seguiu verde — corretamente, por eu não ter mexido no que dizia
medir. É `controle-raso-inclua-sempre-o-caso-minimo` aplicado a mim mesmo; o conserto foi apagar a
**linha da marca**, derivada por `grep -v`.

**Acceptance criteria:**
- [x] 14 casos de self-test, com piso de vacuidade em 14
- [x] Falsificado com o arquivo real, nas duas direções
- [x] Consumidor declarado e `check-orphan-gates` conferido

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
bash scripts/check-roadmap-done-com-ml-pendente.sh --self-test
bash scripts/check-roadmap-done-com-ml-pendente.sh
grep -q check-roadmap-done-com-ml-pendente.sh scripts/run-local-gates.sh
```
