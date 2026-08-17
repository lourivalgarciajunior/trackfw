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

- [ ] `go test ./...` verde no Windows, zero falhas
- [ ] Nenhum arquivo tocado em `~/.claude`, `~/.gemini` ou `~/.codeium` durante a suíte
- [ ] Comportamento de produção inalterado
- [ ] `go vet ./...` limpo e gates de paridade passam

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
**Status:** ⬜ Pendente
**Arquivos afetados:** `internal/generators/agents_test.go`, `gemini_test.go`, `scaffold_test.go`
(ou onde vivem `TestInstallSkills_*`), `windsurf_test.go`
**Ações:**
1. Criar helper `withTempHome(t) string` — cria tempdir, aponta `userHomeDir` para ele, restaura no
   `t.Cleanup`, devolve o caminho.
2. Substituir o `os.Setenv("HOME", ...)` dos 8 testes pelo helper. Manter o `Setenv` junto, para
   que o isolamento valha também em sistemas onde `os.UserHomeDir` lê `HOME`.
3. Rodar a suíte e conferir que os 8 passam.
**Critérios de aceite:**
- [ ] Os 8 testes passam
- [ ] Nenhum `os.Setenv("HOME"` sozinho como único mecanismo de isolamento no pacote
**Comandos de validação:** `go test ./internal/generators/`

---

## Wave 2 — Bit de execução e fechamento

### ML-3 — Asserção de bit de execução guardada por sistema
**Status:** ⬜ Pendente
**Arquivos afetados:** `internal/generators/commitmsghook_test.go`
**Ações:**
1. Guardar **apenas** a verificação `info.Mode()&0111` com `runtime.GOOS != "windows"`, deixando o
   resto do teste rodando normalmente.
2. Comentar o porquê no código: NTFS não tem bit de execução, a asserção é inverificável ali.
**Critérios de aceite:**
- [ ] Os 2 testes passam no Windows
- [ ] A asserção continua ativa fora do Windows (verificada por leitura do guard)
**Comandos de validação:** `go test ./internal/generators/ -run CommitMsgHook`

### ML-4 — Suíte verde e verificação de não-poluição
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `go test ./...` — exigir **zero** falhas, não mais comparar com baseline.
2. Provar a não-poluição: gravar o estado de `~/.claude/agents`, `~/.gemini/skills` e
   `~/.codeium/windsurf/memories` antes e depois da suíte e comparar.
3. Os três gates de paridade.
**Critérios de aceite:**
- [ ] `go test ./...` sem nenhuma falha
- [ ] Snapshot do home idêntico antes e depois
- [ ] Gates passam
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh`
