---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-residuo-de-docs-req-do-upstream-quebra-integridade-referencial-no-parity.md"
---

# REQ: Resíduo de `docs/req/` do upstream quebra integridade referencial no `parity`

> Date: 2026-09-05 | Status: Open

## Motivation

**Isto é regressão minha, introduzida hoje, e o `validate` local não a enxerga.**

Ao remover os 7 roadmaps órfãos de `docs/roadmaps/wip/`
(`REQ-2026-09-05-sete-roadmaps-do-upstream-orfaos`), quebrei duas referências. O `make parity` do CI
reprova desde então:

```
referential integrity failed: docs/req/REQ-2026-09-02-slugify-do-python-... roadmap
  "docs/roadmaps/wip/ROADMAP-2026-09-02-slug-de-artefato-colapsa-..." does not exist
referential integrity failed: docs/req/REQ-2026-09-02-teste-do-gitattributes-... roadmap
  "docs/roadmaps/wip/ROADMAP-2026-09-02-o-teste-do-gitattributes-..." does not exist
```

Medido nos runs do nosso CI, no mesmo branch `main`:

```
17:23  parity=failure  erros de integridade referencial: 0
17:34  parity=failure  erros de integridade referencial: 2   <- depois do merge da PR #50
19:49  parity=failure  erros de integridade referencial: 2
```

### Por que a falsificação do AC1 não pegou

O AC1 daquela REQ exigia *"zero REQs deste acervo os referenciam"*, e eu varri
`docs/requisições/` — **o nosso `req_dir`, 53 arquivos**. Não varri `docs/req/`, que tem **5 REQs
resíduo do upstream** e não é `req_dir` de ninguém aqui.

**E o `trackfw validate` diz `✓ No violations found`**, porque `req_dir: docs/requisições` e o
resolvedor não olha `docs/req/`. O verde local era sobre um denominador que exclui os 5 arquivos que
quebraram — a mesma vacuidade que passei o dia reportando, agora na minha própria verificação.

O `make parity` pegou porque caminha diferente do resolvedor.

### O que os 5 são

Todos os 5 de `docs/req/` **existem em `docs/req/` do upstream**. São governança dele que entrou por
merge antes do `upstream-sync.sh`, exatamente como os 7 roadmaps — e pela `ADR-2026-08-29` não
deveriam estar aqui. A única razão de nunca terem incomodado é que o resolvedor não os lê.

### O que isto bloqueia agora

O job `parity` do nosso CI morre nesses 2 erros e **não chega ao gate do barrier**. Enquanto isso, a
pergunta que o mantenedor fez na [issue #277](https://github.com/kgsaran/trackfw/issues/277) — *"se o
acoplamento estiver te bloqueando no fork agora, diz que a gente reprioriza"* — **não é respondível**:
a minha regressão mascara o resultado.

## Acceptance Criteria

- [x] **AC1** — Os 5 resíduos saem de `docs/req/`. Falsificação prévia: cada um existe em
      `docs/req/` do upstream **e** a varredura de referência é da **árvore inteira** (`grep -r . `),
      não de um diretório escolhido — é o erro que produziu esta REQ.
- [x] **AC2** — O `parity` deixa de reportar erro de integridade referencial. Verificado **no CI**,
      não localmente: o `validate` local não enxerga `docs/req/` e por isso não serve de prova aqui.
- [ ] **AC3** — Com o `parity` passando dessa etapa, medir **se o gate do barrier reprova** — e com
      isso responder a pergunta do #277 com dado, não com suposição.
- [x] **AC4** — Nenhum arquivo de produto tocado.

## Negative Scope

- **Não** restaurar os 7 roadmaps para satisfazer as referências. Eles são governança do upstream e
  a remoção foi correta; o que estava errado era o resíduo do outro lado.
- **Não** mudar `req_dir` para incluir `docs/req/`. Isso adotaria a governança dele.

## Linked ADR
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-residuo-de-docs-req-do-upstream-quebra-integridade-referencial-no-parity.md
