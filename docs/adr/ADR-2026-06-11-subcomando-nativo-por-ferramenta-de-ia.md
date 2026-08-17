---
status: Accepted
date: 2026-06-11
author: claude
---

# ADR: Um subcomando por ferramenta de IA, emitindo o formato nativo de cada uma

> Date: 2026-06-11 | Status: Accepted

REQ: REQ-multi-ai-support-2026-06-11

> **Reconstrução retroativa, escrita em 2026-08-16.** Decisão tomada em 2026-06-11 e nunca
> registrada. Reconstruída do texto da REQ, do roadmap `roadmap-multi-ai-support-2026-06-11.md` e do
> código atual. Verificado: existem `internal/commands/gemini.go`, `cursor.go`, `copilot.go`,
> `windsurf.go` e `amazonq.go`; os templates por formato estão em
> `internal/generators/templates/{agents,amazonq,copilot,cursor,gemini,windsurf}/`; os instaladores
> são idempotentes. Ver `REQ-2026-08-16-adrs-retroativas`.

## Context

O trackfw instalava contexto de governança e os 10 papéis especializados — architect, backend,
frontend, qa, infra, security, code-quality, dba, ux, data — apenas para o Claude Code. Times reais
usam mais de uma ferramenta, às vezes no mesmo repositório.

Cada ferramenta tem um formato próprio, e as diferenças não são cosméticas:

| Ferramenta | Onde | Formato |
|---|---|---|
| Gemini CLI | `~/.gemini/GEMINI.md`, `~/.gemini/skills/`, `~/.gemini/commands/` | Markdown + comandos em TOML |
| Cursor | `.cursor/rules/*.mdc` | Markdown com frontmatter YAML |
| GitHub Copilot | `.github/copilot-instructions.md`, `.github/instructions/`, `.github/prompts/` | Markdown puro, três diretórios distintos |
| Windsurf | `.windsurf/rules/`, `.windsurf/workflows/` + `global_rules.md` no home | Markdown com frontmatter |
| Amazon Q | `.amazonq/rules/*.md` | Markdown puro |

Variam a extensão, a presença e o schema do frontmatter, a separação entre regra e workflow, e se o
arquivo é do projeto ou do home do usuário. Um denominador comum entre isso tudo seria o mínimo de
cada formato — o que significa entregar para todas as ferramentas a experiência da pior.

## Decision

**Um subcomando por ferramenta**, cada um emitindo o formato nativo dela: `trackfw gemini`,
`trackfw cursor`, `trackfw copilot`, `trackfw windsurf`, `trackfw amazonq`, mais `trackfw agents`
para o Claude Code.

Os templates ficam versionados por ferramenta em `internal/generators/templates/<ferramenta>/`,
embutidos no binário. O que é compartilhado é o **conteúdo** dos 10 papéis; o que é específico é o
empacotamento.

Todo instalador é **idempotente e não-destrutivo**: arquivo que já existe não é sobrescrito, e o
comando reporta `já existe — não sobrescrito` em vez de falhar. Customização do usuário sobrevive a
qualquer reinstalação. Onde o arquivo é compartilhado com o usuário — o `global_rules.md` do
Windsurf — a escrita é cirúrgica: acrescenta o bloco do trackfw se ainda não estiver lá, e não toca
no resto.

Esses subcomandos existem **apenas no binário Go**. Nos pacotes npm e pypi as mesmas integrações são
instaladas por `trackfw init`. É divergência deliberada, documentada em `docs/cli-parity.md`.

## Consequences

**Positivas.** Cada ferramenta recebe o que ela realmente entende — frontmatter onde há frontmatter,
TOML onde há TOML. Adicionar uma ferramenta nova é acrescentar um diretório de template e um
comando, sem tocar em nada existente. E a idempotência torna seguro rodar o instalador de novo, que
é o que o `update` faz.

**Negativas.** Os 10 papéis existem em seis empacotamentos diferentes: mudar o conteúdo de um papel
significa propagar por todos. A `check-static-assets.sh` cobre os assets do `serve`, mas não há gate
equivalente para os templates de papel — a consistência entre eles depende de disciplina. É débito
conhecido.

Além disso, os subcomandos só existirem no Go é uma quebra de paridade assumida: quem usa o CLI npm
ou pypi tem o mesmo resultado, mas por outro caminho (`init`), e precisa saber disso.

## Alternatives Considered

**Um formato genérico único, exportado para todas.** Um só template, um só comando. Descartada
porque o denominador comum entre TOML, Markdown com frontmatter e Markdown puro é Markdown puro —
entregaria para Cursor e Windsurf uma versão degradada, sem o frontmatter que essas ferramentas usam
para decidir quando aplicar a regra.

**Adapters por ferramenta sobre um modelo interno único**, com serialização por formato. É a solução
correta para muitas ferramentas. Descartada para seis: a indireção custaria mais do que os cinco
arquivos de comando que ela substituiria, e o modelo interno teria que acomodar campos que só uma
ferramenta usa. Continua sendo a saída se o número crescer.
