---
status: done
date: 2026-09-18
req: "docs/requisições/claude/REQ-2026-09-18-upstream-sync-retem-o-trackfw-yaml-do-fork-como-retem-docs.md"
squad: "claude"
---

# Roadmap: upstream-sync retém o trackfw.yaml do fork como retém docs

> Created: 2026-09-18 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-09-18-upstream-sync-retem-o-trackfw-yaml-do-fork-como-retem-docs.md

## Acceptance Criteria

- [x] AC1 — retenção do `trackfw.yaml` provada por efeito
- [x] AC2 — diff do upstream impresso quando ele muda o arquivo
- [x] AC3 — terceiro caso na falsificação, com controle
- [x] AC4 — sync do #393 com `validate` inalterado

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Actions:**
1. **Enumeração.** Arquivos de governança **fora** de `docs/` que o sync trataria como produto: o
   `trackfw.yaml`. Os demais só nossos em `scripts/` e `.github/workflows/local-gates.yml` são
   **adições** — o upstream não os tem, então não há o que mesclar.
2. **Quem esvazia isto.** Reter em silêncio esconderia chave nova do upstream que nos interessasse;
   por isso o sync imprime o diff dele (AC2).
3. **Falsificação.** O merge real do #393 como caso, com controle sem a retenção.
4. **Residual.** Chave nova útil do upstream só entra por decisão de quem lê o diff, em commit
   próprio.
**Acceptance criteria:**
- [x] The four sections above answered with evidence
- [x] No implementation line written for this ML

## Wave 1

### ML-1A — retenção do trackfw.yaml no upstream-sync
**Status:** ✅ Concluído
**Files affected:** `scripts/upstream-sync.sh`, `scripts/check-upstream-sync-falsify.sh`
**Acceptance criteria:**
- [x] AC1, AC2 e AC3 medidos

## Evidência — 2026-09-18

**O defeito, medido.** `upstream-sync.sh` sobre `9651f905` (#393 do upstream): `trackfw.yaml`
`Unmerged`, `conflito de PRODUTO remanescente`, árvore devolvida. O upstream acrescentou
`lenient_until: "2027-12-31"` abaixo do `governance_mode: lenient` dele; o nosso tem
`governance_mode: strict` e o trecho diverge.

| caso da falsificação | sync novo | controle: sync sem a retenção |
|---|---|---|
| `bfeea12...4f0ad33` (governança pesada) | OK | — |
| `01086b5...6b3ba49` (produto puro) | OK | — |
| `65cb024b...9651f905` (**o #393, trackfw.yaml em conflito**) | OK — retido 20, trazido 22, `trackfw.yaml` idêntico à base | **rc=1** — `trackfw.yaml Unmerged`, `RETENÇÃO NÃO PROVADA` |

**Frase por teste:** o terceiro caso afirma que o sync retém o `trackfw.yaml` do fork mesmo quando o
upstream o muda em linhas que colidem com as nossas; o controle afirma que, sem a retenção, o mesmo
merge não passa.

**AC4 — sync real do #393 (2026-09-18).** `upstream-sync.sh` sobre `9651f905`: 22 de produto trazidos, 20 retidos, `trackfw.yaml` retido com o diff do upstream impresso; `validate` 0 antes · 0 depois, e `No violations found` com o binário do #393.

### ML-1B — o `CLAUDE.md` entra na retenção, pela MESMA causa
**Status:** ✅ Concluído
**Files affected:** `scripts/upstream-sync.sh`
**Actions:**

🔴 **Mesma causa, mesma REQ, ML novo — e o roadmap voltou de `done/` para `wip/` para isto.** Em
2026-10-09 o [#550](https://github.com/kgsaran/trackfw/pull/550) do upstream reescreveu o protocolo
**gerado** (`AGENTS.md`, `GEMINI.md`, `README.md` e o `CLAUDE.md` da raiz) e colidiu com o nosso,
reescrito duas horas antes no nosso PR #240. O sync abortou com a MESMA mensagem de 2026-09-18:

```
upstream-sync: CLAUDE.md
upstream-sync: conflito de PRODUTO remanescente. Resolva a mao. Arvore devolvida.   rc=1
```

**A mudança é de um token, e o mecanismo já existia:**

```
GOVERNANCA_FORA_DE_DOCS="trackfw.yaml"  ->  "trackfw.yaml CLAUDE.md"
```

O laço do script já iterava a variável (`for g in $GOVERNANCA_FORA_DE_DOCS`), então a prova de
retenção por efeito (AC1) e a impressão do diff dele (AC2) passaram a valer para o novo arquivo
**sem uma linha de lógica nova** — o que é o teste de que o ML-1A resolveu a classe, e não o caso.

**Por que o `CLAUDE.md` é governança, e não produto:** são ~2000 linhas de medição nossa — as
regras duras, os pontos cegos medidos, as armadilhas pagas. O do upstream é **template gerado**;
o nosso é **acervo**. A `ADR-2026-08-29` decide que governança é local, e é a mesma leitura que
trouxe o `trackfw.yaml` para cá.

**Medição — 2026-10-09:**

```
sync ANTES do ML    rc=1, aborta nomeando CLAUDE.md (e so ele)
sync DEPOIS do ML   produto trazido 25 - governanca retida 9 (de 34)
                    ⚠ o upstream mudou governanca que este fork RETEM (CLAUDE.md). O diff dele:
                      - req new -> roadmap new -> roadmap move -> git checkout -b
                      + req new -> roadmap move <name> wip -> trackfw branch new <type>/<slug>
                    Retido o nosso.
validate            0 violacoes antes - 0 depois
```

🔴 **E a previsão desta colisão estava escrita ANTES**, no nosso PR #242, por merge de ensaio em
worktree descartável: ela nomeou o `CLAUDE.md` como o único conflito que o sync não resolve, e os
outros cinco como governança dele retida por `docs/`. Bateu nos dois.

**Acceptance criteria:**
- [x] O arquivo entra na retenção sem lógica nova, provando que o ML-1A resolveu a classe
- [x] O diff dele é impresso (AC2 vale para o arquivo novo, por construção)
- [x] A convergência com o texto dele foi **medida**, não suposta — nada a trazer à mão

**Gates da wave:**
```bash
# each line runs as a separate sh -c — see docs/cli-parity.md rule 5
grep -q 'GOVERNANCA_FORA_DE_DOCS="trackfw.yaml CLAUDE.md"' scripts/upstream-sync.sh
bash -n scripts/upstream-sync.sh
```
