---
status: done
date: 2026-08-29
req: docs/requisições/claude/REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md
---

# Roadmap: Trazer o barrier dialeto canonico do upstream

> Created: 2026-08-29 | Status: done

## Context

Segundo merge do upstream, um commit. Governanca enxuta: a maquinaria de gates ja existe.

REQ: docs/requisições/claude/REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream.md

## Acceptance Criteria

- [x] Merge sem conflito pendente
- [x] Sete gates verdes, com as perdas e quem as acusou
- [x] O gate de conteudo do upstream barra o `vault/notes/index.md` do diff
- [x] Build verde e suite pypi sem regressao por lista nomeada

## Wave 1 — O merge

### ML-1A — Mesclar e verificar
**Status:** ✅ Concluído
**Actions:** `git merge upstream/main`; governanca e conteudo do upstream fora, pela ADR; rodar os
sete gates e registrar o que caiu.
**Acceptance criteria:**
- [x] Sem marcador de conflito
- [x] Tabela de perda/gate escrita

---

## O gate de conteudo do upstream se pagou na estreia

Resolvi tudo o que o git apontou — `vault/notes/index.md` em conflito, duas REQs e um roadmap do
upstream — e **achei que estava limpo**. O `check-upstream-content.sh` acusou **sete arquivos que eu
nao tinha visto**, todos entrados sem conflito:

```
docs/adr/ADR-2026-08-29-dialeto-canonico-...      ADR do upstream
vault/notes/ambiente-do-dev-e-mais-rico-...
vault/notes/barrier-crlf-divergencia-node-regex-...
vault/notes/barrier-fence-closing-trailing-content-...
vault/notes/barrier-trust-check-fail-open-em-tmpdir-...
vault/notes/gates-da-wave-sao-um-comando-por-linha-...
vault/notes/paridade-cross-runtime-dentro-do-go-test-...
```

Sem ele, seriam a quarta e a quinta vez que conteudo do upstream entra sem ninguem ver.

## Regressao: zero

```
antes (pos 1o merge)  100 failed / 1445 passed
depois                105 failed / 1451 passed
novas: 5    resolvidas: 0
```

As **5 sao testes que o proprio commit trouxe** — `git show e0f8543:pypi/tests/test_barrier.py` nao
tem nenhum deles. Falham pela parede de encoding do Windows: o commit introduziu `⬜` no vocabulario
de status do barrier, e o harness le a saida com o padrao da plataforma.

Contra a `upstream/main` **pura**, nos mesmos dois arquivos: **17 falhas la, 7 aqui.** Nossa arvore
e melhor.

## Duas medicoes minhas que estavam erradas

1. **Baseline errado.** Comparei contra as 95 de antes do *primeiro* merge, misturando dois merges.
   O certo eram as 100.
2. **Medicao contaminada por bytecode obsoleto.** Havia **13 `__pycache__`** apontando para
   `C:\Indieexpert\GitHub\` — o caminho de antes de o repositorio mudar de pasta. Um teste falhava
   so por isso. O numero 106 que reportei primeiro nao valia; o que vale e 105, depois de limpar.

## Uma regressao que e minha

`test_wave_argumento_invalido_mensagem_pinada_literalmente` falha **so aqui**:

```
- ... "2-BIS" ? not a valid wave label     (nossa)
+ ... "2-BIS" — not a valid wave label     (esperado)
```

Consequencia do `_force_utf8_output`: o CLI passou a emitir UTF-8 e o harness le com o padrao da
plataforma. **Antes, `--help` e `validate` morriam com `UnicodeEncodeError`; agora funcionam, e um
teste que captura saida ve mojibake.** Troca de uma classe de falha por outra menor, e fica escrito.
A correcao certa e o harness decodificar UTF-8 explicitamente — vai para a issue.

## O `check-artifact-parity` oscila

Reprovou na primeira medicao e passou nas duas seguintes, com a **mesma arvore**. Gate que oscila e
gate em que nao se confia. Fica registrado; nao investiguei a causa.
