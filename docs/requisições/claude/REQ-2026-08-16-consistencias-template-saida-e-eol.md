---
id: REQ-2026-08-16-consistencias-template-saida-e-eol
title: Quatro inconsistências reveladas na sessão de 2026-08-16 — template, header, saída e EOL
status: approved
priority: medium
type: chore
created: 2026-08-16
author: claude
---

# REQ: Consistências de template, header, saída e EOL

Roadmap: consistencias-template-saida-e-eol-2026-08-16.md

## Problema

Quatro achados registrados como dívida ao longo das cinco entregas anteriores desta sessão. São
independentes entre si e nenhum é grande; ficam numa REQ só porque todos nasceram do mesmo trabalho
e nenhum justifica cerimônia própria.

### D1 — Template de `roadmap new` diverge no Python

O Python gera roadmap com frontmatter e header diferentes dos outros dois runtimes:

| | frontmatter | header humano |
|---|---|---|
| Go (`roadmap.go:92`, `:167`) | `status: backlog` | `> Created: DATE \| Status: backlog` |
| Node.js (`roadmap.js:273`, `:372`) | `status: backlog` | `> Created: DATE \| Status: backlog` |
| **Python** (`roadmap.py:105`, `:112`) | **`status: Backlog`** | **`> Criado em: DATE \| Status: ⬜ Backlog`** |

Nasceu como efeito colateral de `REQ-2026-08-16-roadmap-move-sincroniza-status`: aquele trabalho
alinhou o `move` dos três runtimes em minúsculo, o que deixou o Python incoerente consigo mesmo —
`new` grava `Backlog`, `move` grava `wip`.

### D2 — `move` não sincroniza a linha humana de status

`REQ-2026-08-16-roadmap-move-sincroniza-status` restringiu a reescrita ao frontmatter de propósito,
por ser o único campo que o validator lê. O efeito é que, depois de mover para `done/`, o arquivo
declara `status: done` no frontmatter e continua exibindo `Status: 🔄 WIP` na linha logo abaixo do
título. Quem abre o arquivo lê a linha errada.

Aconteceu neste repositório em todo roadmap fechado nesta sessão — cada um precisou de ajuste
manual da linha.

### D3 — Instalador imprime caminho literal em vez do resolvido

12 `Printf` em `agents.go`, `gemini.go`, `scaffold.go` e `windsurf.go` trazem `~/.claude/…`,
`~/.gemini/…` e `~/.codeium/…` **hardcoded na string**, não o caminho que o instalador resolveu.
Quando o home não é o padrão, a saída afirma um destino que não é o real.

Isso atrapalhou ativamente o diagnóstico de `REQ-2026-08-16-testes-go-portaveis-windows`: durante o
teste, a saída dizia `~/.claude/agents/…` enquanto escrevia num tempdir.

Só afeta o Go — npm e pypi imprimem caminhos de projeto relativos (`.claude/commands/trackfw/`),
que estão corretos.

### D4 — Falta `.gitattributes`, e `gofmt` acusa 22 arquivos

`core.autocrlf=true` sem `.gitattributes` faz o checkout escrever CRLF nos `.go`. `gofmt -l` acusa
22 dos 106 arquivos. É artefato de working copy — o blob commitado vai como LF, e por isso a CI
nunca reclamou — mas polui qualquer verificação local de formatação e mascara desvio de verdade.

## Requisitos

### R1 — Template Python alinhado ao Go e ao Node.js
`status: backlog` no frontmatter e `> Created: DATE | Status: backlog` no header, idênticos aos
outros dois runtimes.

### R2 — `move` sincroniza também a linha humana, nos três runtimes
Reescrever o trecho após `| Status: ` na primeira linha que comece com `> ` e contenha `| Status: `.
Conservador como o helper de frontmatter: linha que não casa o padrão fica intocada, e o arquivo
não ganha a linha se ela não existir.

### R3 — Saída mostra o caminho real, colapsando o home em `~`
Helper que recebe o caminho absoluto e devolve a forma com `~` quando está sob o home resolvido, ou
o absoluto quando não está. No uso normal a saída fica idêntica à de hoje; num home diferente ela
passa a dizer a verdade.

### R4 — `.gitattributes` fixando EOL
`*.go text eol=lf` e as demais extensões de fonte do projeto, mais normalização do working copy
atual.

## Critérios de Aceite

- [ ] `roadmap new` produz frontmatter e header idênticos nos três runtimes
- [ ] Após `roadmap move X done`, a linha `> … | Status:` declara `done` nos três runtimes
- [ ] Roadmap sem a linha de header não é modificado por causa dela
- [ ] Nenhum caminho de home hardcoded em `Printf` no Go; a saída normal segue exibindo `~/…`
- [ ] `.gitattributes` existe e `gofmt -l internal/ cmd/` devolve zero
- [ ] `go test ./...` com zero falhas; suíte pypi na baseline de 6 errors + 1 failure
- [ ] Os três gates de paridade passam sem prefixo de ambiente
