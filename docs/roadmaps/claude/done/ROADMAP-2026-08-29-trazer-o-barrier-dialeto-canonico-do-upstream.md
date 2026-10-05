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

## Wave 0 — Threat Model

**Não houve, e esta seção declara a ausência em vez de inventar o conteúdo.**

Este roadmap é de 2026-08-29, anterior à `ADR-2026-09-18` decisão 8, que passou a exigir Wave 0 antes de
qualquer implementação. A transição para `done` a cobra **estruturalmente** (`AC7-bis`, em
`internal/generators/roadmap.go:722`), e a cobrança não tem corte por data — diferente do
`req_has_roadmap`, cujo corte de 2026-09-03 está declarado em
`internal/validator/validator_req_roadmap_cutoff.go`.

🔴 **Escrever um threat model agora afirmaria uma análise que não aconteceu.** O trabalho deste
roadmap foi entregue antes da regra existir; o que esta seção registra é exatamente isso. Quem ler
daqui a um ano tem de poder distinguir "houve Wave 0" de "a seção existe porque a ferramenta a exige".

## Veredito da varredura de caducidade — 2026-10-03

**Veredito: (a) entregue**

**Sítio que comprova:** o barrier é produto vigente — 204 arquivos de `upstream/main` o citam, e o
`check-roadmap-barrier-contract.sh` roda no `parity`. Os 6 critérios já estavam marcados. Mesmo caso
do anterior: estado desencontrado do trabalho.

### Emenda do mesmo dia — por que este roadmap NÃO pode ir para `done/`

🔴 **O trabalho foi entregue, e ainda assim `done/` seria uma afirmação falsa.** A REQ ligada tem
critério de aceite que **não pode ser fechado honestamente**: `Suite pypi sem regressao por lista nomeada contra 95 falhas` — não existe suíte `pypi` desde a v8.0.0 — medido: `pypi/` tem 5 arquivos, todos casquinha de canal.

A cadeia é fechada pelos dois lados, e os dois estão certos:

```
o produto    recusa REQ `Open` com roadmap em done/        (validate: 6 violacoes)
o nosso gate recusa REQ `done` com criterio em aberto      (check-req-done-com-criterio-aberto)
```

Então marcar o roadmap `done` exigiria marcar a REQ `Done`, o que exigiria **fechar um critério que
não foi atendido** — a terceira saída que o nosso próprio gate recusa, e com razão.

**Fica em `backlog/`, agora com o motivo escrito.** O que mudou nesta varredura não é o estado: é que
o estado deixou de ser inexplicado. Antes, um leitor via trabalho entregue parado em `backlog` sem
saber por quê.

🔴 **E isto é uma lacuna do modelo, não deste roadmap:** não existe estado para *"entregue, com
critério de verificação permanentemente inverificável"*. `done` afirma demais, `backlog` afirma
trabalho pendente, `abandoned` afirma que não será feito. Os três erram, e o menos errado é o que
deixa a prosa corrigir — registrado aqui para quem for decidir a convenção.
