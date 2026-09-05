---
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-06-20-codex-agent-integrations.md"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
id: REQ-2026-06-20-attention-hooks-agent-clis
title: Attention hooks — banner de atenção no board quando o agente precisa do usuário
status: done
priority: medium
type: feature
created: 2026-06-20
author: claude
---

# REQ: Attention hooks nos CLIs de agente

> **Reconstrução retroativa (2026-08-16).** Esta REQ não existia no repositório — o roadmap
> `ROADMAP-2026-06-20-codex-agent-integrations.md` a referenciava e o link estava quebrado desde
> a criação. O conteúdo abaixo foi reconstruído a partir do próprio roadmap, que já trazia a
> pesquisa de hooks por CLI, a estratégia e os critérios de aceite. Ver
> `REQ-2026-08-16-consolidar-arvores-governanca`.

## Problema

Quando um agente de IA para no meio de uma execução esperando resposta do usuário — uma pergunta,
um pedido de permissão, uma confirmação — nada disso é visível fora do terminal daquele agente.
Quem acompanha o trabalho pelo board do `trackfw serve` não tem como saber que a entrega parou
por falta de uma resposta humana, e o roadmap segue aparentando progresso.

## Requisitos

### R1 — Sinal de atenção em arquivo
Um arquivo `.trackfw-attention.json` escrito no `roadmap_dir` (com fallback para `docs/roadmaps`
quando `trackfw.yaml` não define) marca que um agente está aguardando o usuário. O board do
`serve` lê esse arquivo e exibe um banner ao vivo.

### R2 — Scripts compartilhados e idempotentes
`trackfw-attention-signal.sh` (escreve o sinal) e `trackfw-attention-cleanup.sh` (remove).
Ambos verificam a existência de `trackfw.yaml` antes de agir — em projeto sem trackfw são
no-op seguro. Re-executar não pode quebrar nada.

### R3 — Hook config por CLI
Instalação do par sinal/limpeza no mecanismo nativo de cada CLI suportado:

| CLI | Hook pré-tool | Arquivo de config | Nota |
|-----|--------------|-------------------|------|
| Claude Code | `PreToolUse` (matcher por nome da tool) | `.claude/settings.json` | `AskUserQuestion` é tool nomeada → matcher exato |
| Codex CLI | `PermissionRequest` | `.codex/hooks.json` | evento nativo de aprovação |
| Gemini CLI | `Notification[ToolPermission]` | `.gemini/settings.json` | evento observável de permissão |
| Kiro | `PreToolUse` | `.kiro/hooks/` | config declarativa versionável |
| GitHub Copilot | `preToolUse` | `.github/hooks/*.json` | fail-closed |
| Cursor | `preToolUse` (genérico) | `.cursor/hooks.json` | mais completo dos editores |
| Windsurf | por tipo de ação (sem genérico) | `.windsurf/hooks.json` | outlier — apenas instrução textual |

Para CLIs com `PreToolUse` genérico o hook dispara em qualquer tool call; no Claude Code o matcher
`AskUserQuestion` é preciso.

### R4 — Instalação e atualização
Os hook configs são gerados por `trackfw init` e `trackfw discover --init`, e re-aplicados por
`trackfw update` seguindo o mesmo padrão de `InjectRulesDetected`.

### R5 — Paridade tri-runtime
Geradores equivalentes em Go, Node.js e Python.

## Critérios de Aceite

- [x] `.trackfw-attention.json` aparece no board quando o agente executa tool call interativa
- [x] Banner some automaticamente quando a interação termina (PostToolUse/AfterTool)
- [x] Hook configs gerados por `trackfw init` e `trackfw discover --init`
- [x] `trackfw update` atualiza hooks detectados
- [x] Scripts idempotentes
- [x] Paridade Go + Node.js + Python nos geradores
- [x] Testes verdes

## Nota de verificação

Os critérios foram marcados em 2026-08-16 por **inspeção do entregável**, não por execução:
`hooks.go`/`hooks_test.go`/`codex.go` em `internal/generators/`, `hooks.js`/`codex.js` em
`npm/src/generators/` e `hooks.py`/`codex.py` em `pypi/trackfw/generators/`. Não houve conferência
critério a critério.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-06-20-codex-agent-integrations.md
