---
status: Done
date: 2026-10-06
author: ""
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-06-a-secao-do-jq-do-claude-md-descreve-falha-aberta-que-o-527-removeu.md"
---

# REQ: a secao do jq do CLAUDE.md descreve falha aberta que o 527 removeu

> Date: 2026-10-06 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation

O `CLAUDE.md` tem uma secao inteira — *"Ponto cego local: sem `jq`, a cerca de git falha ABERTA"* —
descrevendo um defeito do produto que **o upstream removeu na raiz** com a
[#527](https://github.com/kgsaran/trackfw/pull/527), mesclada em 2026-10-06 21:00 local e trazida para
ca no sync de `27db2a22`.

A propria secao previu este momento e deixou a ordem escrita:

> *"quando for, esta secao caduca inteira e deve ser medida de novo, nao apagada por fe."*

🔴 **E ha mais do que a caducidade.** O merge mudou o hook de `.sh` autocontido para
`trackfw guard <nome>`, resolvido no PATH — e com isso a cerca ficou **inerte nesta maquina** ate o
binario com `guard` entrar no PATH. Isso e estado novo, nao previsto por nenhuma secao, e precisa
ficar escrito: o ponto cego mudou de lugar, de "sem `jq`" para "sem `guard` no PATH".

## Acceptance Criteria

- [x] AC1 — A secao do `jq` e marcada como caducada **com a medicao que a aposentou**, no formato que
      este arquivo ja usa para o `_force_utf8_output`, os "8 mascarados" e o `pin7-noexec` — registro
      mantido, nunca apagado
- [x] AC2 — O ponto cego NOVO fica escrito: hook resolve `trackfw` no PATH, e PATH sem `guard`
      significa cerca inerte — com a medicao das tres configuracoes
- [x] AC3 — A armadilha de resolucao do PowerShell (`.ps1` ganha do `.exe` na mesma pasta) entra, com
      a consequencia pratica de que copiar o `.exe` nao sombreia nada
- [x] AC4 — Fica escrito que os shims do npm estao MOVIDOS para `*.pre-guard-bak` e que isso **se
      reverte** quando sair release com `guard`, com o comando da reversao
- [x] AC5 — A afirmacao de que o padrao `jq`-ou-`sed` sobre `tool_input` tem **sitio unico** e
      re-derivada, nao copiada: o que sobrou e onde
- [x] AC6 — Nenhuma afirmacao nova entra sem ter sido medida nesta frente, e os numeros antigos ficam
      ao lado dos novos com data

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-06-a-secao-do-jq-do-claude-md-descreve-falha-aberta-que-o-527-removeu.md

## Context

## O que foi medido, e com que instrumento

### A cerca, por efeito, no PowerShell — que e o ambiente REAL do hook

A linha do hook usa `$LASTEXITCODE`, entao ela roda em PowerShell. Medir em Git Bash responderia
outra pergunta.

```
git push origin main              rc=2  BLOQUEIA
git commit -m x                   rc=2  BLOQUEIA
git checkout -b feat/x            rc=2  BLOQUEIA
git status                        rc=0  passa          <- controle negativo
echo oi 
 git push origin main   rc=2  BLOQUEIA       <- era rc=0 sem jq
echo oi 
 git commit -m x        rc=2  BLOQUEIA       <- era rc=0 sem jq
```

As duas ultimas linhas sao **o mecanismo da #507**: comando na segunda linha de um multilinha passava
porque o fallback por `sed` nao desescapava o `
` literal. Elas sao a medicao que aposenta a secao.

### O padrao `jq`-ou-`sed` sobre `tool_input`: re-derivado

```
scaffold.go                      6 ocorrencias de `jq` (eram 16)
  1102-1104  attention-signal    o irmao que SEMPRE fez o certo — fallback por python3
  1221,1337,1426  comentario e lista de inspetores (cat|head|tail|jq|grep) do credential
sed sobre tool_input, ao vivo    NENHUM
sed sobre tool_input, congelado  internal/pathguard/testdata/corpus-pre-fix/...scaffold.go.txt
```

🔴 **O mecanismo sobrevive como FIXTURE do estado pre-conserto**, e isso e prova a favor, nao contra:
ele foi movido para um corpus congelado em vez de apagado.

### O guard em Go le JSON com parser, nao com regex

`internal/guard/payload.go` usa `encoding/json` com `map[string]json.RawMessage` em todos os niveis,
case-sensitive e **last-wins** — e ha teste afirmando que
`{"tool_input":{"command":"git push","Command":"echo ok"}}` **nega**, fechado.

### O ponto cego NOVO, nas tres configuracoes possiveis

```
binario da arvore (9.2.0 + merge)     push rc=2 · status rc=0        correto
binario do PATH (9.1.0 do npm)        TUDO rc=1                      FALHA ABERTA
involucro .sh de 13 linhas            TUDO rc=2                      bloquearia git status
```

Nenhuma versao publicada tem `guard`: o `npm latest` e **9.2.0** e o #527 entrou **depois** da tag.

### A armadilha de resolucao, medida

No PowerShell o **`.ps1` ganha do `.exe`** na mesma pasta. Copiar so o `.exe` para
`%APPDATA%
pm` deixou o `Get-Command trackfw` apontando para `trackfw.ps1` e o `--version` em
**9.1.0**. Foi preciso **mover** os tres shims para `*.pre-guard-bak`.

## Escopo negativo

- 🔴 **A secao nao e apagada.** Ela vira registro com a medicao que a aposentou — e a forma que este
  arquivo ja usa tres vezes, e a que a propria secao pediu.
- Nao se roda `trackfw update harness` nesta frente: ele escreve em arquivo do usuario
  (`~/.copilot`, `~/.kiro`, `~/.trackfw/scripts`), fora do repositorio. Os 14 avisos novos do
  `validate` ficam declarados, nao resolvidos aqui.
- Nao se mexe em `.claude/settings.json` para apontar de volta ao `.sh`: medido, o involucro falha
  FECHADO em tudo e bloquearia `git status`.

## Onde cada AC foi entregue

| AC | sitio no `CLAUDE.md` |
|---|---|
| AC1 | bloco `✅ CADUCOU em 2026-10-06` no topo da secao do `jq`, com a tabela de rc e as duas linhas do multilinha |
| AC2 | secao nova *"O ponto cego MUDOU DE LUGAR"*, com as tres configuracoes medidas |
| AC3 | *"Armadilha de resolucao, medida"* — o `.ps1` ganha do `.exe`, e copiar so o `.exe` nao sombreia |
| AC4 | os tres `*.pre-guard-bak` nomeados e o roteiro de reversao escrito |
| AC5 | o censo re-derivado: 6 `jq` em `scaffold.go` (eram 16), `sed` sobre `tool_input` so em `corpus-pre-fix` |
| AC6 | `git diff --numstat` = 91/0 — nada apagado; e o conserto do CI entrou com a reproducao nas duas direcoes |
