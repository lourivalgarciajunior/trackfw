---
status: done
date: 2026-08-30
req: docs/requisições/claude/REQ-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md
---

# Roadmap: Ruido de gofmt divergindo do upstream

> Created: 2026-08-30 | Status: done

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
