---
status: backlog
date: 2026-08-30
req: docs/requisições/claude/REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md
---

# Roadmap: Ruido de gofmt divergindo do upstream

> Created: 2026-08-30 | Status: backlog

## Context

20 dos 80 arquivos de divergencia sao so formatacao, vindos de um `gofmt -w` rodado com Go 1.26.1
contra um upstream em 1.25.2. Nao quebram, mas conflitam em todo merge e poluiriam PR.

REQ: docs/requisições/claude/REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md

## Acceptance Criteria

- [x] 20 arquivos na formatacao do upstream
- [x] Nenhuma divergencia deliberada perdida, verificado por marcador
- [x] build, vet e os sete gates verdes
- [x] Divergencia de codigo cai de 80 para 60

## Wave 1 — A limpeza

### ML-1A — Reverter os 20 e provar que nada se perdeu
**Status:** ✅ Concluído
**Actions:**
1. Restaurar cada um dos 20 a partir de `upstream/main`.
2. Contar os marcadores das divergencias deliberadas ANTES e DEPOIS — igualdade e a prova.
3. build, vet, sete gates.
**Acceptance criteria:**
- [x] Contagem de marcadores identica antes e depois
- [x] Divergencia cai para 60

---

## Resultado

```
divergencia de codigo   80 -> 61 arquivos
```

**Foram 19, nao 20.** O `internal/generators/roadmap_move_test.go` **nao existe no upstream** — e
arquivo nosso, o teste local que sobreviveu a poda da migracao. Eu o tinha classificado como ruido
de gofmt; a tentativa de restaurar falhou com "nao existe no upstream" e denunciou o erro. Ficou de
fora, corretamente.

## A prova de que nada se perdeu

Contei os marcadores de cada divergencia deliberada **antes e depois**, e a igualdade e a prova —
nao a confianca:

```
homedir.Dir()          21 -> 21
homedir()              28 -> 28
home_dir()             24 -> 24
expand_path(           12 -> 12
_is_interactive()      10 -> 10
_force_utf8_output      2 -> 2
newline=               75 -> 75
log_basename = agent    1 -> 1
```

> A primeira contagem deu `newline= 0`, o que nao batia com os 68 sites que eu sabia existir. Era
> artefato do meu `grep -F` com aspas na string de busca. Se eu tivesse aceitado o zero, teria
> "provado" que nada se perdeu com um marcador que nao media nada.

## Verificacao

`go build ./...` e `go vet ./...` verdes. Os sete gates verdes. Suites dos pacotes revertidos
(`sync`, `serve`, `config`) passando.

## Regra que fica

**`gofmt -w` amplo e proibido neste fork** enquanto o upstream estiver noutro Go. Medido: nossa
arvore esta limpa no Go 1.26.1 local, e esse mesmo gofmt reformataria **206 arquivos** na arvore
dele, que declara 1.25.2. Tocar um arquivo Go para um PR ao upstream exige formatar com o gofmt
**dele**.

## Wave 0 — Threat Model

**Não houve, e esta seção declara a ausência em vez de inventar o conteúdo.**

Este roadmap é de 2026-08-30, anterior à `ADR-2026-09-18` decisão 8, que passou a exigir Wave 0 antes de
qualquer implementação. A transição para `done` a cobra **estruturalmente** (`AC7-bis`, em
`internal/generators/roadmap.go:722`), e a cobrança não tem corte por data — diferente do
`req_has_roadmap`, cujo corte de 2026-09-03 está declarado em
`internal/validator/validator_req_roadmap_cutoff.go`.

🔴 **Escrever um threat model agora afirmaria uma análise que não aconteceu.** O trabalho deste
roadmap foi entregue antes da regra existir; o que esta seção registra é exatamente isso. Quem ler
daqui a um ano tem de poder distinguir "houve Wave 0" de "a seção existe porque a ferramenta a exige".

## Veredito da varredura de caducidade — 2026-10-03

**Veredito: (a) entregue**

**Medido em 2026-10-03, e o número é o veredito:**

```
gofmt -l internal cmd                        39 arquivos
desses, que diferem do upstream               0
```

O `gofmt` acusa 39 arquivos, e **nenhum deles é nosso** — todos byte a byte iguais aos de
`upstream/main`. O ruído que este roadmap atacava era divergência **nossa** de formatação, e ela é
zero; o que resta é estilo do upstream, que não é objeto deste roadmap. Os 6 critérios já estavam
marcados.

### Emenda do mesmo dia — por que este roadmap NÃO pode ir para `done/`

🔴 **O trabalho foi entregue, e ainda assim `done/` seria uma afirmação falsa.** A REQ ligada tem
critério de aceite que **não pode ser fechado honestamente**: `Nenhuma divergencia deliberada perdida — verificado por marcador` e `Os sete gates verdes` — não há divergência deliberada a perder (divergência de produto medida hoje: **0**), e o conjunto de "sete gates" de agosto de 2026 não existe mais como tal — o agregador de hoje executa 12.

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
