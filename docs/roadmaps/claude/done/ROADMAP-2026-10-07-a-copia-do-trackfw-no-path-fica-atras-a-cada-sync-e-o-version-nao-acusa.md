---
status: done
date: 2026-10-07
req: "docs\requisições\claude/REQ-2026-10-07-a-copia-do-trackfw-no-path-fica-atras-a-cada-sync-e-o-version-nao-acusa.md"
squad: "claude"
---

# Roadmap: a copia do trackfw no PATH fica atras a cada sync e o --version nao acusa

> Created: 2026-10-07 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-10-07-a-copia-do-trackfw-no-path-fica-atras-a-cada-sync-e-o-version-nao-acusa.md -->
REQ: docs\requisições\claude/REQ-2026-10-07-a-copia-do-trackfw-no-path-fica-atras-a-cada-sync-e-o-version-nao-acusa.md

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
**Files affected:** (nenhum — este ML não escreve implementação)
**Actions / respostas com evidência:**

**1. Completude da enumeração.** A lista não parou nos arquivos que a REQ nomeia. Procurei no
repositório por **todo** sítio que reconstrói o binário ou que fala da cópia do PATH:

```
go build -o bin/trackfw      upstream-sync.sh: 2 sitios (baseline linha ~108/113, pos-merge ~218/219)
make build                   Makefile (do upstream) — NAO roda aqui: `make: command not found`
pre-guard-bak                CLAUDE.md (roteiro de reversao) · check-contorno-dos-shims-caducou.sh
%APPDATA%/npm                CLAUDE.md apenas — nenhum script escrevia la antes deste ML
```

🔴 **O sítio do baseline (antes do merge) foi deliberadamente deixado de fora**, e isso é decisão:
ali o binário é construído para **medir** o estado anterior, e refazer a cópia do PATH naquele ponto
a poria adiantada em relação à árvore pós-merge. O passo entra **depois** do merge, uma vez.

**2. Quem esvazia esta wave sem quebrar regra escrita.** Três formas, e as três estão fechadas:

| forma | o que fecharia o furo |
|---|---|
| `SKIP_VERIFY=1` no sync | o passo não roda — **aceito e declarado**: sem verificação não há rebuild, logo não há defasagem nova criada por este sync |
| remover o shim `*.pre-guard-bak` | o passo vira no-op e o gate diz **N/A com a razão**, não "em dia" |
| o PATH deixar de resolver `trackfw` | idem: N/A nomeado, nunca verde |

**3. Alvos de falsificação, nas duas direções.** Feitas com o **binário velho de verdade**, não com
caso sintético:

```
cópia já igual     -> passo diz "ja em dia"            · gate rc=0 "em dia"
cópia atrasada     -> passo "refeita e verificada"     · gate rc=1 ATRAS (antes do passo)
                      cmp independente confirma        · resíduo: UM backup rolante
regressão inversa  -> se o passo copiasse sempre, o caso "ja em dia" imprimiria troca
                      inexistente; é por isso que o `cmp` vem ANTES da cópia
```

**4. Resíduo declarado.**

- O passo **não** cobre quem instalar `npm i -g trackfw` por fora: isso recria os shims, o `.ps1`
  volta a ganhar do `.exe` no PowerShell, e nenhuma das duas peças percebe. O alarme dessa classe é o
  `check-contorno-dos-shims-caducou.sh`, que é de outra pergunta (release com `guard`).
- O gate afirma **igualdade de bytes**, não que o binário do PATH funcione. Quem responde isso é o
  efeito — o hook bloqueando —, e esse teste é manual.
- 🔴 **Correção pós-CI:** este resíduo dizia *"o gate não roda em CI, por desenho"* — era
  **falso**. O `check-orphan-gates.sh` do upstream reprova `check-*.sh` sem consumidor, e `FORA`
  do agregador não conta (a lista é sem `.sh`, e ele procura o basename). O gate passou a rodar
  no job `gates-windows` do `local-gates.yml`, onde o passo **reprova se a saída não contiver
  `N/A`** — afirmando o AC4 num lugar onde a premissa está genuinamente ausente. O remédio já
  estava escrito no comentário daquele job, e eu projetei sem lê-lo: custou dois jobs vermelhos.
- O gate não roda no **agregador**, que é em `ubuntu-latest`. Está em `FORA` com o motivo escrito.

**Acceptance criteria:**
- [x] The four sections above answered with evidence, not a one-line assertion
      — enumeração com os quatro sítios e o denominador, três formas de esvaziamento, falsificação
      nas duas direções com artefato real, e três resíduos nomeados
- [x] No implementation line written for this ML

**Gates da wave:**
```bash
bash scripts/check-copia-do-path-esta-atras.sh --self-test
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: Wave 0

### ML-1A — O passo no sync e o gate que o torna verificável
**Status:** ✅ Concluído
**Files affected:**
- `scripts/upstream-sync.sh` (função `refaz_copia_do_path`, chamada após a verificação pós-merge)
- `scripts/check-copia-do-path-esta-atras.sh` (novo)
- `scripts/run-local-gates.sh` (entrada em `FORA`, com motivo)
- `CLAUDE.md`, `docs/agents-working-context.md`

**O que este ML afirma, por artefato novo** (Regra Dura de Reconciliação):

| artefato | a conclusão do ML que ele afirma |
|---|---|
| `--self-test` do gate, 10 casos | que premissa ausente produz **N/A nomeado** e nunca "ATRAS", e que leitura fora do domínio não vira veredito |
| caso "o resolvedor contra o ambiente REAL" | que o caminho devolvido **existe** — o caso que pegou o `[ -f ]` mentiroso do MSYS |
| falsificação do passo com o binário velho | que a defasagem é **detectada e corrigida**, e que a correção é verificada por efeito |

**Acceptance criteria:**
- [x] AC1 — passo no `upstream-sync.sh`, no mesmo bloco do rebuild, só com o contorno em vigor
- [x] AC2 — verificação por efeito (`cmp` + `guard --help`) com restauração e `die` nomeando o motivo
- [x] AC3 — o gate **não** usa `--version`; medido que as duas versões dizem `9.2.0`
- [x] AC4 — N/A com a razão em três premissas ausentes, impresso como "NAO leia isto como em dia"
- [x] AC5 — falsificado nas duas direções, com o binário velho real
- [x] AC6 — em `FORA` do `run-local-gates.sh` com motivo; agregador 15 executados · 0 falhas

**Gates da wave:**
```bash
bash scripts/check-copia-do-path-esta-atras.sh --self-test
bash scripts/check-copia-do-path-esta-atras.sh
bash -n scripts/upstream-sync.sh
bash scripts/run-local-gates.sh
```
