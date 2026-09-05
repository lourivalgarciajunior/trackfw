---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-residuo-de-docs-req-do-upstream-quebra-integridade-referencial-no-parity.md"
squad: ""
---

# Roadmap: Resíduo de `docs/req/` do upstream quebra integridade referencial no `parity`

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-residuo-de-docs-req-do-upstream-quebra-integridade-referencial-no-parity.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-residuo-de-docs-req-do-upstream-quebra-integridade-referencial-no-parity.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ]
- [ ]

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** docs/req/*.md (5 removidos)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Desta vez a varredura de referência foi da **árvore inteira**, não de um diretório
escolhido — foi exatamente esse recorte que produziu a regressão. E fui ler **o gate**, em vez de
supor o que ele checa: `scripts/check-referential-integrity.sh:10` varre `docs/req/*.md`, **chumbado**,
ignorando o `req_dir` configurado. É por isso que ele via os 5 resíduos e o `validate` não.

**2. Threat model — quem esvazia isto sem quebrar regra escrita.**

- 🔴 **Restaurar os 7 roadmaps para calar o erro.** É o remédio mais rápido e o errado: eles são
  governança do upstream, a remoção foi correta, e o que estava errado era o resíduo do outro lado.
- **Mudar `req_dir` para incluir `docs/req/`.** Faria o `validate` enxergar e adotaria a governança
  dele. Escopo negativo.
- **Confiar no `validate` local como prova.** É o que me cegou: ele diz `✓ No violations found`
  porque `req_dir: docs/requisições` e o resolvedor não olha `docs/req/`. **A prova tem de vir do CI**,
  que caminha diferente.
- **Corrigir o que a minha simulação achou a mais.** Meu script achou uma referência quebrada em
  `docs/cli-parity.md`; o gate real **não a vê**, porque só varre `docs/req/`. Corrigir por simulação
  mais larga que o gate seria trabalho sem sinal.

**3. Falsificação nas duas direções.**

```
ANTES, por arquivo:  existe em docs/req/ do upstream       5 de 5
                     referencias de governanca na ARVORE    0 de 5
DEPOIS:              check-referential-integrity.sh  ->  "Referential integrity OK"
                     validate                        ->  sem violacao
                     REQs 61 · roadmaps 71               (denominador intacto)
```

E o controle histórico, que é o que prova a causa:

```
17:23  parity  erros de integridade referencial: 0
17:34  parity  erros de integridade referencial: 2   <- o merge da PR #50
19:49  parity  erros de integridade referencial: 2
```

**4. Residual declarado.**

- **O AC3 não foi cumprido nesta branch.** Só o run do CI dirá se o `parity` passa dessa etapa e
  chega ao gate do barrier — e é isso que responde a pergunta do #277. Fica para o run pós-merge.
- **A referência quebrada em `docs/cli-parity.md`** existe e não é vista por gate nenhum. Registrada,
  não corrigida: é doc, não governança, e nenhuma regra a lê.
- **O gate varre `docs/req/` chumbado**, ignorando `req_dir`. É a mesma família do `sync` que reportei
  no #268 — e **não medi** se os outros gates de `scripts/` fazem o mesmo.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
bash scripts/check-referential-integrity.sh
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — Os 5 resíduos saem de docs/req/. Falsificação prévia: cada um existe em
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — Os 5 resíduos saem de docs/req/. Falsificação prévia: cada um existe em
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — O parity deixa de reportar erro de integridade referencial. Verificado **no CI**,
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — O parity deixa de reportar erro de integridade referencial. Verificado **no CI**,
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — Com o parity passando dessa etapa, medir **se o gate do barrier reprova** — e com
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — Com o parity passando dessa etapa, medir **se o gate do barrier reprova** — e com
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — Nenhum arquivo de produto tocado.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — Nenhum arquivo de produto tocado.
- [x] build passes
- [x] tests green
