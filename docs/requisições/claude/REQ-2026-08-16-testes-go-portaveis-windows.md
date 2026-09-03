---
id: REQ-2026-08-16-testes-go-portaveis-windows
title: Testes de internal/generators não podem escrever no home real nem exigir bit POSIX
status: done
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: Testes de `internal/generators` no Windows

Roadmap: docs/roadmaps/claude/done/testes-go-portaveis-windows-2026-08-16.md

## Problema

`go test ./...` fecha com **10 falhas** em `internal/generators` no Windows. Enquanto isso durar, a
suíte não serve de rede de segurança: nas três entregas anteriores foi preciso comparar contagem de
falhas contra uma baseline em vez de simplesmente exigir verde.

São duas causas independentes.

### Causa A — o override de HOME não funciona no Windows (8 testes)

Os testes fazem `os.Setenv("HOME", tempdir)`. O código de produção chama `os.UserHomeDir()`, que no
Windows lê **`USERPROFILE`**, não `HOME`. O override é ignorado.

A consequência não é apenas o assert falhar no tempdir. **O instalador roda de verdade contra o
home do desenvolvedor.** Saída de `go test -run TestInstallAgents_CriaArquivosEmHome -v` nesta
máquina:

```
  ✓ ~/.claude/agents/trackfw-architect.md (já existe — não sobrescrito)
  ✓ ~/.claude/agents/trackfw-backend.md (já existe — não sobrescrito)
  ...
```

Numa máquina limpa, rodar a suíte instala 10 arquivos de agente em `~/.claude/agents/`, cria
`~/.gemini/skills/` e anexa regras em `~/.codeium/windsurf/memories/global_rules.md`. Teste que
escreve fora da própria sandbox é defeito, independente de estar vermelho ou verde.

Afetados: `TestInstallAgents_*` (3), `TestInstallGemini_*` (3), `TestInstallSkills_*` (1),
`TestInstallWindsurf_*` (1).

Chamadas a `os.UserHomeDir()` em produção: `agents.go:17`, `gemini.go:23`, `scaffold.go:111`,
`windsurf.go:95`.

### Causa B — bit de execução POSIX em NTFS (2 testes)

`TestGenerateCommitMsgHook_Husky` e `_Lefthook` fazem `info.Mode()&0111 == 0` sobre o hook gerado.
NTFS não tem bit de execução; o Go reporta `-rw-rw-rw-`. A asserção é inverificável no Windows por
construção — não há o que consertar no código de produção.

## Requisitos

### R1 — Seam de home dir, sem mudar comportamento de produção
Introduzir um ponto de injeção no pacote (`var userHomeDir = os.UserHomeDir`) usado pelas quatro
chamadas. Produção continua resolvendo exatamente como hoje, em qualquer sistema.

**Não** trocar `os.UserHomeDir()` por leitura direta de `HOME`: no Windows com Git Bash a variável
`HOME` existe e aponta para outro lugar que não `USERPROFILE`, então isso mudaria para onde o
`trackfw` instala de verdade — regressão silenciosa para o usuário.

### R2 — Testes isolam o home pelo seam
Helper de teste que troca `userHomeDir` por um tempdir e restaura no cleanup. Os 8 testes passam a
usá-lo. Nenhum teste do pacote pode tocar o home real.

### R3 — Asserção de bit de execução só onde ela existe
Guardar a verificação com `runtime.GOOS == "windows"`, pulando **apenas essa asserção** — o resto
do teste (conteúdo do hook, caminho, idempotência) continua rodando no Windows.

## Critérios de Aceite

- [x] `go test ./...` verde no Windows, zero falhas
- [x] Nenhum arquivo criado ou alterado em `~/.claude`, `~/.gemini` ou `~/.codeium` durante a suíte
- [x] `go vet ./...` limpo
- [x] Comportamento de produção inalterado: `userHomeDir` continua sendo `os.UserHomeDir`
- [x] A asserção de bit de execução continua ativa fora do Windows
- [x] `check-cli-parity.sh`, `check-validate-parity.sh` e `check-static-assets.sh` passam
