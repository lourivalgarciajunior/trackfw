---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md"
squad: ""
---

# Roadmap: Onda 2 de contribuição ao upstream — fechar as classes de defeito em vez dos casos

> Created: 2026-09-05 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md

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
**Files affected:** scripts/testdata/platform-predicates.tsv (artefato de medição)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Não parti da lista da REQ. Varri as três árvores por primitiva: 84 usos de
predicado dependente de SO e 49 sítios de enumeração perto de `req_dir`/`roadmap_dir`. Foi essa
varredura — e não a lista — que produziu o **sexto** sítio da classe `ENOTDIR`, em
`internal/integrations/manager.go:477`, fora de `internal/validator/` onde toda a atenção esteve.

**2. Threat model — quem esvazia esta onda sem quebrar regra escrita.**

- **Gate que não acha nada e é reportado como sucesso.** O C1 caiu exatamente aqui: a varredura não
  achou sítio novo. O contrapeso é o AC5 — reportar "a lista está completa" **é** o resultado, e o
  valor do gate passa a ser impedir o quinto, não achar o quinto.
- **Grep como prova.** Toda a evidência de B2 e C1 é análise estática. Um sítio que monte o caminho
  indiretamente escapa da janela de ±6 linhas. Declarado nas duas issues.
- **Propor gate que ele não pediu.** Três dos quatro itens são instrumentos, não defeitos. O
  contrapeso foi ancorar cada um num defeito **medido** — o sexto sítio, os 108 basenames — em vez de
  vender a ferramenta.
- **Duplicar o acervo dele.** O AC6 achou a `REQ-2026-09-01` (`In Progress`) adjacente ao B1, e o
  C1 já tinha issue minha. Nenhum dos dois virou report novo.

**3. Falsificação nas duas direções.**

```
B1  tabela de contrato, familia anchored, em Windows real:
      predicado NOVO   7/7        predicado ANTIGO  5/7   <- o antigo TEM de reprovar
B2  6 sitios da classe ENOTDIR, e o controle medido:
      arquivo-como-dir  IsNotExist=true  Is(ENOENT)=false  -> deve REPORTAR
      inexistente       IsNotExist=true  Is(ENOENT)=true   -> deve SUPRIMIR
C1  acusa os 4 conhecidos · NAO acusa o resolvedor
E2  108 de 144 ausentes num consumidor · 1 falha (era 6 antes da #257)
```

**Hipótese descartada, registrada:** procurei violação do D4 por **duplicação** do resolvedor, que
grep de enumeração não pega. O candidato (`generators/roadmap.py:535`, docstring dizendo *"espelhando
exatamente `resolve_req_files`"*) **chama** o resolvedor na linha seguinte. Falso positivo, e está na
issue porque a frase induz ao erro.

**4. Residual declarado.**

- **Nada foi medido por execução do produto**, exceto a tabela do B1 em Node e Python. O predicado
  novo do **Go é não-exportado** e exigiria teste dentro do pacote — não rodei.
- **A família `direrr` da tabela está declarada, não executada** nos 3 runtimes.
- **O E2 foi medido por leitura do gate mais a contagem dos ausentes**, sem rodar a suíte completa
  (~16 min no CI Linux, mais em Windows). O caminho de código é direto e sem ramo alternativo, mas
  não executei.
- **Os 78 usos restantes de predicado de SO não foram classificados.** Só afirmo os 6 que guardam
  leitura de diretório.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
for n in 276 277 268; do
  gh issue view "$n" --repo kgsaran/trackfw --json number >/dev/null 2>&1 || { echo "issue #$n ausente"; exit 1; }
done
test -s scripts/testdata/platform-predicates.tsv || { echo "tabela de contrato ausente"; exit 1; }
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
- [x] build passes
- [x] tests green

### ML-1B — **AC2 — B2: lint contra predicado de SO em sítio de classificação.** Gate que reprova
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC2 — B2: lint contra predicado de SO em sítio de classificação.** Gate que reprova
- [x] build passes
- [x] tests green

### ML-1C — **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de req_dir/roadmap_dir fora
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de req_dir/roadmap_dir fora
- [x] build passes
- [x] tests green

### ML-1D — **AC4 — E2: corpus do barrier-contract desacoplado da governança.** Medir o custo real para
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4 — E2: corpus do barrier-contract desacoplado da governança.** Medir o custo real para
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Cada item vira issue no kgsaran/trackfw com o achado **medido**, o controle na
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Cada item vira issue no kgsaran/trackfw com o achado **medido**, o controle na
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
- [x] build passes
- [x] tests green

### ML-1G — **AC7** — Nenhum item é mesclado na nossa main como produto. Falsificação: a divergência de
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC7** — Nenhum item é mesclado na nossa main como produto. Falsificação: a divergência de
- [x] build passes
- [x] tests green

## Desfecho de cada item (AC5, AC6)

| item | desfecho | onde |
|---|---|---|
| **B1** tabela de contrato | fundido ao B2 — a tabela é o instrumento, o sexto sítio é a evidência | [#276](https://github.com/kgsaran/trackfw/issues/276) |
| **B2** lint de predicado de SO | **achado novo**: `manager.go:477`, fora do validator, e o comentário da `2451` que nomeia `ENOTDIR` | [#276](https://github.com/kgsaran/trackfw/issues/276) |
| **C1** ponto único de leitura | **varredura completa, zero sítio novo** — reportado como comentário no AC3 dele, não como issue | [#268](https://github.com/kgsaran/trackfw/issues/268#issuecomment-5553347715) |
| **E2** corpus do barrier | **acoplamento persiste** pós-#257: 108 de 144 ausentes, 1 falha em vez de 6 | [#277](https://github.com/kgsaran/trackfw/issues/277) |

**B1 e B2 viraram uma issue só** porque a tabela sozinha é proposta de ferramenta; com o sexto sítio
ao lado, é defeito medido com o instrumento que o teria achado antes.

**Nenhum item mesclado na nossa `main` como produto (AC7).**
