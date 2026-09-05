---
status: Open
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/backlog/ROADMAP-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md"
---

# REQ: Procedimento de merge do upstream com retenção da governança local

> Date: 2026-09-05 | Status: Open

## Motivation

A `ADR-2026-08-29` decidiu que **produto vem do upstream e `docs/` é local**. A decisão está certa e
a divergência de produto é **zero** — medido em `a958b57`:

```
git diff --name-only main upstream/main -- internal npm/src pypi/trackfw cmd .github Makefile
  (vazio)
```

O que não existe é o **procedimento**. Quatro merges em 2026-09-04/05 exigiram a mesma sequência
manual, e o custo cresce com o acervo do mantenedor:

| merge | arquivos do merge | de produto | de governança dele |
|---|---|---|---|
| `4f0ad33` | 41 | 4 | **32** |
| `1c16cb0` | 10 | 6 | 4 |
| `6b3ba49` | 42 | 42 | 0 |
| `87aded6` | 14 | 9 | 5 |

O merge de `4f0ad33` produziu **23 conflitos** de `rename/delete` e de localização de arquivo. A causa
é estrutural e não vai embora: com `roadmap_namespacing: by_agent`, o git detecta os roadmaps flat
dele (`docs/roadmaps/wip/`) como **renomeação** dos nossos (`docs/roadmaps/claude/done/`) e tenta
casá-los.

Resolver conflito a conflito é caro e erra fácil — e a resolução correta já está decidida pela ADR,
então não há julgamento a fazer: `docs/` e `vault/` voltam a ser exatamente os nossos.

O risco de não formalizar é concreto e já materializou uma vez neste projeto: em 2026-09-03 a PR
`kgsaran/trackfw#254` chegou a propor **apagar 92 mil linhas** da governança do mantenedor, porque a
`main` do fork foi mesclada numa branch de PR do upstream. A mudança real eram 5 arquivos. É a mesma
fronteira, na direção oposta.

## Acceptance Criteria

- [ ] **AC1** — Existe um comando único (`make upstream-sync` ou `scripts/upstream-sync.sh`) que faz
      merge do upstream, retém `docs/` e `vault/`, e **falha** se sobrar conflito.
- [ ] **AC2** — Ao terminar, o comando **prova** a retenção em vez de afirmá-la:
      `git diff --cached main -- docs vault --stat` tem de sair **vazio**, e o comando aborta se não
      sair. A prova é por efeito, não por intenção.
- [ ] **AC3** — O comando **relata a proporção**: `N arquivos de produto, M de governança retidos`. É
      o discriminante — um merge que fecha com muito mais que uma mão-cheia de arquivos de produto
      indica que algo de `docs/` passou.
- [ ] **AC4** — Falsificação em duas direções: rodar contra `4f0ad33` (32 arquivos de governança) tem
      de reter os 32 e trazer 4; rodar contra `6b3ba49` (zero governança) tem de trazer os 42 **sem
      reter nada** — o procedimento não pode suprimir produto.
- [ ] **AC5** — Verificação pós-merge automatizada: `go build ./...` exit 0 e contagem de violações
      do `validate` **idêntica** antes e depois, medida em worktree destacado com o binário da
      árvore. Falha se divergir.
- [ ] **AC6** — Documentado no `CLAUDE.md`, substituindo a instrução atual de `git merge upstream/<tag>`,
      que não menciona retenção.
- [ ] **AC7** — A seção **"Divergência local deliberada"** do `CLAUDE.md` é corrigida: ela afirma que
      `_force_utf8_output` só existe aqui, mas o upstream **absorveu** (medido: 2 ocorrências em
      `upstream/main:pypi/trackfw/cli.py`). Documentação que descreve divergência inexistente faz o
      próximo merge procurar conflito onde não há.

## Negative Scope

- **Não** resolver com `merge=ours` no `.gitattributes` **sozinho**. Medido: os 23 conflitos eram
  `rename/delete` e localização de arquivo, que o driver de merge **não cobre** — ele atua em
  conflito de conteúdo. O restore explícito de `docs/` é obrigatório.
- **Não** automatizar o `git push`. O merge é revisado por PR, como todo o resto.
- **Não** tocar produto. Se o procedimento precisar de suporte no CLI, isso é REQ separada e vai ao
  upstream.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.md
