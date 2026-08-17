---
name: testes-go-portaveis-windows-2026-08-16
title: "Testes de internal/generators portáveis no Windows"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-testes-go-portaveis-windows
branch: fix/testes-go-portaveis-windows
---

# Roadmap: testes Go portáveis no Windows

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-testes-go-portaveis-windows.md`

## Diagnóstico / Contexto

10 falhas em `internal/generators` no Windows, por duas causas independentes: o override de `HOME`
não funciona porque `os.UserHomeDir()` lê `USERPROFILE`, e duas asserções checam bit de execução
POSIX que NTFS não tem. Diagnóstico completo, com a prova de que os testes escrevem no home real,
está na REQ.

Origem: item 2 da lista de dívida de `REQ-2026-08-16-consolidar-arvores-governanca`. Enquanto
existir, `go test ./...` não serve de rede de segurança — as três entregas anteriores tiveram que
comparar contagem de falhas contra baseline.

Só afeta o runtime Go: os testes de npm e pypi não têm equivalente para esses instaladores.

## Critérios de Aceite

- [x] `go test ./...` verde no Windows, zero falhas
- [x] Nenhum arquivo tocado em `~/.claude`, `~/.gemini` ou `~/.codeium` durante a suíte
- [x] Comportamento de produção inalterado — `userHomeDir` continua sendo `os.UserHomeDir`
- [x] `go vet ./...` limpo e os três gates de paridade passam

---

## Wave 1 — Seam e adoção

> ML-2 depende do ML-1.

### ML-1 — Seam `userHomeDir` no pacote
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/home.go` (NOVO), `agents.go`, `gemini.go`,
`scaffold.go`, `windsurf.go`
**Ações:**
1. Criar `home.go` com `var userHomeDir = os.UserHomeDir`, documentando que existe para permitir
   isolamento em teste e que produção não muda.
2. Trocar as quatro chamadas `os.UserHomeDir()` por `userHomeDir()`.
3. Conferir que nenhuma outra chamada ficou para trás no pacote.
**Critérios de aceite:**
- [x] `go build ./...` e `go vet ./internal/generators/` limpos
- [x] `grep` não acha mais `os.UserHomeDir()` em produção — só em `home.go`, onde é a definição
**Comandos de validação:** `go build ./... && go vet ./...`

### ML-2 — Testes usam o seam e param de tocar o home real
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/agents_test.go`, `gemini_test.go`, `scaffold_test.go`
(ou onde vivem `TestInstallSkills_*`), `windsurf_test.go`
**Ações:**
1. Criar helper `withTempHome(t) string` — cria tempdir, aponta `userHomeDir` para ele, restaura no
   `t.Cleanup`, devolve o caminho.
2. Substituir o `os.Setenv("HOME", ...)` dos 8 testes pelo helper. Manter o `Setenv` junto, para
   que o isolamento valha também em sistemas onde `os.UserHomeDir` lê `HOME`.
3. Rodar a suíte e conferir que os 8 passam.
**Critérios de aceite:**
- [x] Os 8 testes passam — 11 blocos de setup substituídos em 4 arquivos
- [x] Nenhum `os.Setenv("HOME"` fora do helper; o seam é o mecanismo, o Setenv virou reforço
- [x] Helper coberto por teste próprio (`TestUseTempHome_IsolaOResolvedor`): sem isso, um seam
      quebrado voltaria a escrever no home real em silêncio
**Comandos de validação:** `go test ./internal/generators/`

---

## Wave 2 — Bit de execução e fechamento

### ML-3 — Asserção de bit de execução guardada por sistema
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/commitmsghook_test.go`
**Ações:**
1. Guardar **apenas** a verificação `info.Mode()&0111` com `runtime.GOOS != "windows"`, deixando o
   resto do teste rodando normalmente.
2. Comentar o porquê no código: NTFS não tem bit de execução, a asserção é inverificável ali.
**Critérios de aceite:**
- [x] Os 2 testes passam no Windows
- [x] A asserção continua ativa fora do Windows: o guard é
      `runtime.GOOS != "windows" && info.Mode()&0111 == 0`, então em Linux e macOS a condição
      original é avaliada igual a antes
**Comandos de validação:** `go test ./internal/generators/ -run CommitMsgHook`

### ML-4 — Suíte verde e verificação de não-poluição
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `go test ./...` — exigir **zero** falhas, não mais comparar com baseline.
2. Provar a não-poluição: gravar o estado de `~/.claude/agents`, `~/.gemini/skills` e
   `~/.codeium/windsurf/memories` antes e depois da suíte e comparar.
3. Os três gates de paridade.
**Critérios de aceite:**
- [x] `go test ./...` com **zero** falhas — primeira vez na história recente deste repo no Windows
- [x] `go vet ./...` limpo
- [x] Snapshot do home idêntico: 36 arquivos em `~/.claude/{agents,skills}`, `~/.gemini/skills` e
      `~/.codeium/windsurf/memories` com caminho, tamanho e mtime inalterados após a suíte completa
- [x] Os três gates passam

**Prova do antes/depois.** O snapshot sozinho não bastaria: os instaladores são idempotentes, então
num home que já tem os arquivos eles não mudariam mtime de qualquer jeito. O que fecha o caso é a
troca de mensagem do próprio instalador durante o teste — de `✓ … (já existe — não sobrescrito)`,
que só aparece quando ele encontra o home real povoado, para `✅ …`, que é a criação num diretório
limpo.

**Achado de passagem (fora de escopo):** o instalador imprime `~/.claude/agents/` como **literal
hardcoded** (`internal/generators/agents.go:39` e `:50`), não o caminho que resolveu. A saída
mente sobre o destino quando o home não é o padrão. Cosmético, mas atrapalha exatamente este tipo
de diagnóstico. Candidato a REQ própria.

**Achado de passagem 2:** `gofmt -l` acusa 17 dos 104 arquivos `.go` — todos por CRLF, efeito de
`core.autocrlf=true` sem `.gitattributes` no repo. É artefato de working copy: o blob commitado
vai como LF, e por isso a CI nunca reclamou. `go build`, `go vet` e `go test` passam. Um
`.gitattributes` com `*.go text eol=lf` resolveria. Candidato a REQ própria.
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh`
