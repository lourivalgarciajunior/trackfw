---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md"
squad: ""
---

# Roadmap: Onda 1 de contribuição ao upstream — sinal honesto no CI e no `sync`

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-onda-1-de-contribuicao-ao-upstream-sinal-honesto-no-ci-e-no-sync.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] **AC1** — Cada um dos 4 itens tem issue no `kgsaran/trackfw` com: defeito medido, controle na direção oposta, e proposta de remédio. Issue sem medição não conta.
- [x] **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR existentes). Se já houver registro, o entregável é **correção de escopo**, não report novo — foi o que aconteceu na `#268`, onde a REQ dele já existia e o valor esteve em mostrar que o AC1 podia ser satisfeito **sem corrigir o defeito**.
- [x] **AC3** — Onde ele pedir PR, a implementação sai em branch `upstream-pr/*` criada **a partir de `upstream/main`**, nunca da nossa `main`. Falsificação obrigatória antes de abrir: `git diff --stat upstream/main...<branch>` bate com a mudança real.
- [x] **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na issue com a ressalva do que ela **não** prova.
- [x] **AC5** — Nenhum dos 4 é mesclado na nossa `main` por fora. Volta só pelo merge do upstream. Falsificação: a divergência de produto continua **vazia** ao fim da onda.
- [x] **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele. **Recusa é desfecho legítimo** e fecha o ML; o que não pode é ficar aberto sem resposta.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** (nenhum de código — os 4 itens pousam em kgsaran/trackfw)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Antes de escrever qualquer issue, varri o acervo do upstream — `docs/req` do
`upstream/main` e as issues abertas e fechadas. Não confiei na lista da REQ. Resultado: **um dos
quatro já estava registrado** (`REQ-2026-08-20`, para o `branch_has_wip_roadmap`), e outro já tinha
issue minha (`#268`, para o `sync`). Dois eram novos de fato. Sem essa varredura, dois dos quatro
teriam saído como duplicata.

**2. Threat model — quem esvazia esta onda sem quebrar regra escrita.**

- **Reportar como novo o que ele já tem.** É o caminho mais fácil e o que mais custa confiança. O
  contrapeso é o AC2, e ele pegou 2 de 4.
- **Medir e reportar o número dramático.** Aconteceu comigo aqui: a primeira contagem do
  `branch_has_wip_roadmap` deu **62%** de branches rejeitadas, e estava errada — incluía `chore/`,
  que a regra não governa. O número honesto é **9%**. Um relatório com 62% teria feito ele priorizar
  errado.
- **Propor o que ele já mediu e descartou.** Contrapeso: o escopo negativo da REQ lista os quatro
  (`make -j`, matriz de shards, forçar o bit, trocar `IsAbs` na travessia).
- **Deixar ML aberto esperando resposta dele.** Contrapeso: o AC6 — recusa e silêncio são desfechos
  registráveis; o ML fecha quando a issue sai, não quando ele responde.

**3. Falsificação nas duas direções.** Em cada item, medi o controle, não só o defeito:

```
F2  falso-negativo   3 casos · falso-positivo  slug curto casa 9 de 64
    e o candidato dele (fronteira) medido nos DOIS: nao corrige nenhum negativo,
    e quase nao move o positivo (req 9->8, python 8->8, windows 6->6)
A2  arquivo nao carrega  tests 1 · pass 0 · fail 1   |  teste reprova  tests 2 · pass 1 · fail 1
    mesmo exit code — e um caso REAL na arvore, com 61 subtestes ✓ e "fail 1"
A3  a contagem escondeu 1 regressao em 3 merges medidos por nome (#271)
```

**4. Residual declarado.**

- **O corpus do F2 é o deste fork (64 roadmaps), não o dele (127+).** Os números absolutos da direção
  frouxa **não transferem** — `guard` casa 0 aqui e 11 lá. O que transfere é a comparação entre
  relações, que é aritmética. Está dito na issue.
- **As relações do F2 foram reimplementadas em Python a partir da leitura do Go**, não medidas pelo
  binário. Declarado na issue como tal.
- **A lista de vermelhos do A3 é a da minha máquina**, que não é o runner dele. Sustenta a
  necessidade do ratchet, não o conteúdo da lista.
- **O A2 foi medido em Node 22 no Windows.** Não verifiquei estabilidade do formato do sumário entre
  versões — se o passo do CI casar por texto, vira dependência frágil.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
for n in 273 274 275 268; do
  gh issue view "$n" --repo kgsaran/trackfw --json number >/dev/null 2>&1 || { echo "issue #$n ausente"; exit 1; }
done
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Cada um dos 4 itens tem issue no `kgsaran/trackfw` com: defeito medido, controle na…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — Cada um dos 4 itens tem issue no kgsaran/trackfw com: defeito medido, controle na
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — Antes de abrir, cada item é conferido contra o acervo dele (REQ, issue, ADR
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — Onde ele pedir PR, a implementação sai em branch `upstream-pr/*` criada **a partir de…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — Onde ele pedir PR, a implementação sai em branch upstream-pr/* criada **a partir de
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Cada item é medido **nesta máquina Windows** antes de sair, e a evidência entra na
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Nenhum dos 4 é mesclado na nossa `main` por fora. Volta só pelo merge do upstream.…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Nenhum dos 4 é mesclado na nossa main por fora. Volta só pelo merge do upstream.
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele.…
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Cada ML fecha com desfecho registrado — mesclado, recusado, ou assumido por ele.
- [x] build passes
- [x] tests green

## Desfecho de cada item (AC6)

| item | desfecho | onde |
|---|---|---|
| **F2** `branch_has_wip_roadmap` | **correção de escopo** — a REQ dele já existia desde 20/08; entreguei a medição do AC4 dela e mostrei que o candidato 1 não corrige nenhuma das duas direções | [#273](https://github.com/kgsaran/trackfw/issues/273) |
| **A2** suíte não carregou | **report novo**, com discriminante medido e um caso real na árvore | [#274](https://github.com/kgsaran/trackfw/issues/274) |
| **A3** ratchet por nome | **report novo**, sustentado pela regressão que a contagem escondeu na #271 | [#275](https://github.com/kgsaran/trackfw/issues/275) |
| **C2** `sync` e o `req_dir` | **já entregue** em 2026-09-04; ele assumiu e ampliou o AC3 com os três sítios | [#268](https://github.com/kgsaran/trackfw/issues/268) |

**Nenhum foi mesclado na nossa `main` (AC5).** Divergência de produto continua **zero**.

