---
status: Open
date: 2026-08-30
author: claude
adr: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md
---

# REQ: Ruido de gofmt divergindo do upstream

> Date: 2026-08-30 | Status: Open

ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md
Roadmap: docs/roadmaps/claude/wip/ROADMAP-2026-08-30-ruido-de-gofmt-divergindo-do-upstream.md

## Motivation

A auditoria de divergencia entre o fork e a `upstream/main` encontrou **80 arquivos de codigo
diferentes**. Sessenta sao divergencia local deliberada — `homedir`, `newline`, `tty`,
`_force_utf8_output`, slug, gates. **Vinte sao ruido de `gofmt`**, e nao deviam existir.

Origem: rodei `gofmt -w internal/` durante a migracao para a 7.3.0, com **Go 1.26.1**. O upstream
declara **Go 1.25.2** no `go.mod`, e o gofmt das duas versoes formata diferente — reflow de
comentario em lista (`2)` -> `2.`), alinhamento de campo de struct, indentacao de bloco de
comentario, linha em branco.

Alcance medido:

```
nossa arvore, nosso gofmt      0 arquivos fora do formato
arvore do upstream, nosso gofmt   206 arquivos seriam reformatados
```

Os 20 sao apenas os que calhei de tocar. Se eu tivesse rodado na arvore inteira seriam 206.

## Por que corrigir, se nao quebra nada

`make lint` e `go vet`, nao `gofmt` — entao nada reprova hoje. Mas:

1. **Conflitam em todo merge futuro** com o upstream, sem motivo.
2. **Poluiriam qualquer PR** enviado a ele: reformatacao alheia ao assunto, no meio da correcao.
3. Escondem divergencia real no ruido: a auditoria levou tempo para separar 60 de 20.

## Verificacao de que sao mesmo so formatacao

Comparei os 20 diffs anulando espaco. Treze cancelaram na hora. Os outros sete nao cancelaram
**porque o gofmt mexe em marcador de comentario e linha em branco**, nao so em espaco — inspecao
manual confirmou que tambem sao formatacao:

```
-//	2) env vars JIRA_BASE_URL...        internal/sync/jira.go
+//  2. env vars JIRA_BASE_URL...

-		Example:     `adr_dirs:            internal/commands/help.go
+		Example: `adr_dirs:
```

## Acceptance Criteria

- [ ] Os 20 arquivos voltam a formatacao do upstream, byte a byte
- [ ] **Nenhuma divergencia deliberada perdida** — verificado por marcador, nao por confianca
- [ ] `go build ./...` e `go vet ./...` verdes
- [ ] Os sete gates verdes
- [ ] A divergencia de codigo cai de 80 para 60 arquivos
- [ ] Registrado que `gofmt -w` amplo e proibido neste fork enquanto o upstream estiver noutro Go

## Nao faz parte

Alinhar a versao do Go. O `go.mod` ja declara 1.25.2 nos dois; o que difere e o binario instalado
nesta maquina. Trocar o Go local e decisao do usuario, nao consequencia desta REQ.

## Blocked by ADRs
<!-- none -->
