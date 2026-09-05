---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr.md"
squad: ""
---

# Roadmap: REQs que passam só por prosa — três do acervo sem link real de ADR

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr.md

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
**Files affected:** 7 REQs de docs/requisições/claude/
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Comecei com **3**, achadas por um critério que exigia os DOIS marcadores
desancorados. Ao aplicar o critério correto — cada marcador **separadamente** — apareceram mais
**4**. Total: **7 de 59**. A primeira enumeração estava frouxa, e o número teria saído errado se eu
não tivesse reexecutado depois de corrigir as três.

**2. Threat model — quem esvazia isto sem quebrar regra escrita.**

- 🔴 **Reescrever a prosa em vez de acrescentar o link.** Bastava tirar as crases de `` `ADR:` `` do
  texto para o gate passar a acusar, e aí "corrigir" com o link. Isso trocaria um verde falso por um
  vermelho artificial. Está no escopo negativo.
- **Parar nas 3.** Foi o que quase aconteceu: o critério inicial dava 3, e só o reexame deu 7.
- **Confiar no `✓ No violations found` como prova de fim.** O gate dizia verde **antes** e **depois**;
  ele nunca acusou nenhuma das 7. A prova de fim tem de vir de fora do gate.

**3. Falsificação nas duas direções.**

```
antes    script acha 7 · validate: ✓ No violations found
depois   script acha 0 · validate: ✓ No violations found   <- o validate nao mudou, o acervo mudou
sonda    REQ com NADA alem de uma frase citando `ADR:` e `Roadmap:`
         script acha 1 · validate: ✓ No violations found · 0 violacoes contra a sonda
```

**A sonda é o achado.** Uma REQ sem frontmatter de link, sem marcador, sem nada — só prosa — passa
`req_has_adr` e `req_has_roadmap`. Reprodução mínima, e mais limpa que a que levei ao #278.

**4. Residual declarado.**

- **O critério é regex meu**, reproduzindo `contentHasMarker` mais a exigência de âncora. Não é o
  gate do produto; é o que o gate deveria fazer.
- **Só medi `ADR:` e `Roadmap:`.** O marcador `REQ:` (usado por `wip_has_req`) tem o mesmo mecanismo e
  não foi contado.
- **As ADRs atribuídas às 7 são julgamento meu**, por assunto. Duas eram inequívocas (wizard, serve);
  as outras cinco são a atribuição mais próxima entre as 14 existentes.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
python -c "
import glob,os,re
bad=[]
for p in glob.glob(os.path.join('docs','requisições','**','*.md'),recursive=True):
    c=open(p,encoding='utf-8',newline='').read()
    for m in ('ADR:','Roadmap:'):
        has=m in c; empty=(m+' 
') in c or (m+' 
') in c
        anch=bool(re.search(r'(?m)^'+re.escape(m)+r'[ 	]*(\S.*)$',c))
        if (has and not empty) and not anch: bad.append(p); break
raise SystemExit(1 if bad else 0)"
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1** — As três REQs recebem marcador **ancorado em início de linha e com valor**:
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1** — As três REQs recebem marcador **ancorado em início de linha e com valor**:
- [x] build passes
- [x] tests green

### ML-1B — **AC2** — O linked_roadmap: da validator-improvements deixa de apontar para wip/: o
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2** — O linked_roadmap: da validator-improvements deixa de apontar para wip/: o
- [x] build passes
- [x] tests green

### ML-1C — **AC3** — Zero REQs do nosso acervo passam só por prosa. Falsificação: o mesmo script que achou
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3** — Zero REQs do nosso acervo passam só por prosa. Falsificação: o mesmo script que achou
- [x] build passes
- [x] tests green

### ML-1D — **AC4** — trackfw validate continua sem violação **e** com o denominador intacto (58 REQs),
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4** — trackfw validate continua sem violação **e** com o denominador intacto (58 REQs),
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — A medição completa (a classificação em 4 categorias que fecha em 193) é levada ao
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — A medição completa (a classificação em 4 categorias que fecha em 193) é levada ao
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Nenhum arquivo de produto tocado.
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Nenhum arquivo de produto tocado.
- [x] build passes
- [x] tests green
