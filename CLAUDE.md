# trackfw — Instruções de Projeto (Claude Code)

> Regras globais de workflow estão em `~/.claude/CLAUDE.md` e se aplicam aqui.

## Visão geral

**trackfw** é um CLI de governança de entrega de software open-source.
Cadeia: `ADR → REQ → ROADMAP → backlog/wip/blocked/done/abandoned`

Leia `docs/visao-projeto/VISION.md` antes de qualquer tarefa.
Leia `docs/agents-working-context.md` para o estado atual de trabalho.

## Stack

- **Linguagem:** Go
- **CLI framework:** cobra (`github.com/spf13/cobra`)
- **Wizard:** huh (`github.com/charmbracelet/huh`)
- **Module:** `github.com/kgsaran/trackfw`

## Estrutura

```
cmd/trackfw/        → entry point
internal/commands/  → comandos CLI
internal/generators/→ geradores de artefatos por stack
internal/validator/ → validate + status
docs/               → visão, contexto de trabalho
scripts/            → install.sh
```

## Comandos

```bash
make build          # compila o binário em bin/trackfw
make test           # go test ./...
make lint           # go vet ./...
make quality        # Go + Node.js + Python + contratos de paridade
make install        # instala em /usr/local/bin
```

## Regra Dura de Paridade — 3 CLIs (INVIOLÁVEL)

Toda feature nova, correção de comportamento ou ajuste de lógica **DEVE ser implementada nos três CLIs**:

| CLI | Localização | Stack |
|-----|------------|-------|
| Go | `internal/` | Go + cobra |
| Node.js | `npm/src/` | Node.js puro (commander) |
| Python | `pypi/trackfw/` | Python puro (argparse/click) |

**Nenhum PR é aceito sem paridade nos 3 CLIs.** O contrato e as exceções
intencionais estão documentados em `docs/cli-parity.md`. Mudanças doc-only,
infra e templates de artefato são exceções explícitas.

## Regras específicas

- **Nunca commitar na `main` sem PR** (mesmo sendo projeto novo)
- **Build obrigatório** após qualquer alteração: `go build ./...`
- **Atualizar `docs/agents-working-context.md`** ao iniciar e encerrar cada ciclo

## Instalação de skills de terceiro (`trackfw <skills|agents> third-party`)

Instala skills externas (via URL) em duas fases obrigatórias, com um ponto de revisão humana entre
elas — **nunca instale sem revisar o conteúdo em quarentena antes de aprovar**:

1. `trackfw <skills|agents> third-party fetch <url>` — baixa o conteúdo e grava um registro de quarentena em
   `.trackfw/thirdparty-quarantine/<checksum>.json`. Nada é instalado ainda.
2. **Revisão humana obrigatória** do conteúdo em quarentena, seguida da aprovação (que grava
   `.trackfw/thirdparty-provenance.json` — nenhum comando do CLI escreve essa aprovação sozinho).
3. `trackfw <skills|agents> third-party install --checksum <sha256> --targets <...>` — só instala se houver
   aprovação de provenance correspondente ao checksum.

O checker de markers usado em `fetch` é uma tripwire para o caso óbvio, não uma defesa contra um
adversário competente (não cobre paráfrase, indireção, fragmentação, homoglifos ou conteúdo
auto-modificável depois de aprovado). Detalhes completos, os 3 schemas JSON e as garantias/limites
da regra `trackfw validate` `thirdparty_artifact_has_provenance` estão em
`docs/cli-parity.md` (seção `trackfw <skills|agents> third-party`).

## Sinalização de Atenção para o Board (`trackfw serve`)

Quando um agente precisar de confirmação ou ação do usuário durante uma implementação,
**escreva o arquivo `.trackfw-attention.json`** na raiz do diretório de roadmaps
(ex: `docs/roadmaps/.trackfw-attention.json`).

O `trackfw serve` monitora esse arquivo a cada 8 s e exibe um banner de alerta no board.

### Formato obrigatório

```json
{
  "roadmap": "nome-exato-do-arquivo.md",
  "ml": "ML-2A — Título do microlote",
  "message": "Descreva objetivamente o que você precisa do usuário.",
  "level": "action_required",
  "timestamp": "2026-06-18T10:30:00Z"
}
```

| Campo | Obrigatório | Valores | Descrição |
|---|---|---|---|
| `message` | ✅ | string | Pergunta ou informação clara para o usuário |
| `level` | ✅ | `"action_required"` \| `"info"` | `action_required` = banner âmbar; `info` = banner azul |
| `timestamp` | ✅ | ISO 8601 UTC | Usado para deduplicar dismissals no browser |
| `roadmap` | recomendado | basename do `.md` | Marca o card correspondente no board |
| `ml` | opcional | string | Microlote em andamento |

### Quando usar

- Agente encontrou ambiguidade bloqueante que não pode resolver com o contexto disponível.
- Agente precisa escolher entre duas abordagens e o impacto é significativo.
- Agente gerou artefato que requer revisão antes de continuar.

### Quando NÃO usar

- Dúvidas que podem ser resolvidas lendo o roadmap, CLAUDE.md ou o código existente.
- Decisões de baixo risco (nomenclatura, formatação, ordem de campos).

### Limpeza após resolução

**Apague o arquivo** assim que a atenção não for mais necessária — o banner desaparece automaticamente.

```bash
rm docs/roadmaps/.trackfw-attention.json
```

---

## Protocolo de Release (tag)

Ao gerar uma nova tag, o fluxo obrigatório é:

1. **Determinar a próxima versão** com base no SemVer e nos commits desde a última tag:
   - `git tag --sort=-version:refname | head -1` — última tag
   - `git log <última-tag>..HEAD --oneline --no-merges` — commits incluídos

2. **Gerar o changelog** a partir dos commits desde a última tag, agrupando por tipo:
   - `feat` → What's New / `### Added`
   - `fix` → Fixes / `### Fixed`
   - `refactor/perf` → `### Changed`
   - `docs/chore/test/style/build/ci` → omitir ou agrupar em "Internal"
   - Indicar Breaking Changes explicitamente (ou "Nenhum" se retrocompatível)

3. **Atualizar `CHANGELOG.md`** (raiz do projeto, formato [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)):
   inserir uma nova seção `## [x.y.z] - YYYY-MM-DD` **no topo** do arquivo,
   com o mesmo agrupamento do passo 2. Este é o mesmo PR do bump de versão
   (`chore(release): bump version files to x.y.z`) — nunca um commit separado.
   `CHANGELOG.md` é arquivo único na raiz; não duplicar em `npm/` ou `pypi/`.

4. **Criar a tag anotada** com o changelog no corpo da mensagem:
   ```bash
   git tag -a v<x.y.z> -m "<changelog>"
   git push origin v<x.y.z>
   ```

5. **Nunca criar tag diretamente na main sem PRs merged** — a tag representa o estado pós-merge.

> Critério de versão: feat breaking → major; feat não-breaking → minor; fix/patch → patch.

<!-- trackfw:rules:start -->
## trackfw — Governance Rules

This project uses **trackfw** for AI-native delivery governance.
Chain: `ADR → REQ → ROADMAP` · States: `backlog / analyzing / wip / blocked / done / abandoned`

### Agent Protocol
1. **Before any implementation (mandatory):** create governance artifacts FIRST, then branch:
   `trackfw req new "title"` → `trackfw roadmap new "title"` → `trackfw roadmap move <name> wip` → `git checkout -b feat/<branch>`
   ❌ Never create a branch before REQ + ROADMAP are in wip/
   ❌ Never defer REQ/ROADMAP creation to a future task — they are prerequisites, not deliverables
   ✓ `trackfw validate` enforces this via `branch_has_wip_roadmap` rule (v2.7.0+)
2. **Before starting:** run `trackfw context` · read `docs/agents-working-context.md`
3. **After finishing:** update `docs/agents-working-context.md` with what changed
4. **Before PR:** `trackfw validate` must pass
5. **ML lifecycle — mandatory:**
   - Starting a ML: edit roadmap `**Status:** ⬜ Pendente` → `**Status:** 🔄 Em andamento` + commit.
   - Completing a ML: edit roadmap → `**Status:** ✅ Concluído` + include in ML commit.
   - Analyzing a roadmap: move from `backlog/` to `analyzing/`; to `wip/` only when coding starts.
6. **Obrigatório: Inspecione e respeite todos os ADRs globais nos diretórios listados em adr_dirs (inclusive caminhos ~/...) antes de propor alterações de arquitetura.**

### Attention Signal (when you need user input during a task)
Write `docs/roadmaps/.trackfw-attention.json`:
```json
{"roadmap":"file.md","ml":"ML-1A","message":"what you need","level":"action_required","timestamp":"ISO8601Z"}
```
Delete the file when resolved. Visible as a live banner in `trackfw serve`.

> **Windsurf users:** before asking the user a question or requesting approval, write
> `<roadmap_dir>/.trackfw-attention.json` manually — there is no automatic hook for this.
> Delete the file after the user responds.

### Architecture Directives (mandatory)
- **3-layer separation:** frontend / backend / database — never mix concerns
- **No in-memory data:** always database + ORM (never arrays/globals for persistence)
- **Auth from day 1:** never defer — refactoring auth later is very costly
- **Docker + .env from day 1:** containerize early; all config via env vars
- **2-layer validation:** frontend (UX) + backend (security) — never only one
- **API-first:** define OpenAPI contract before coding frontend/backend integration
- **Security wave:** include a red-team review wave in every feature roadmap
- **Test coverage:** TDD for critical logic; min 60% (prototype) / 80% (production)
- Use `/trackfw:architect` to define stack before the first REQ

### Key Commands
- `trackfw context` — current governance state (always run first)
- `trackfw status` — all artifacts and states
- `trackfw validate` — governance consistency check
- `trackfw roadmap move <name> <state>` — transition roadmap state
- `trackfw serve` — live Kanban board at http://localhost:4080
<!-- trackfw:rules:end -->

---

## Este repositório é uma cópia consumidora, não o upstream

O produto vem de `kgsaran/trackfw`, adicionado como remote `upstream`. Este repo **consome** o
trackfw e o usa para governar a si mesmo; ele não é a linha principal do produto.

**Atualizar — use o script, não o `git merge` cru:**

```bash
git fetch upstream
./bin/trackfw branch new chore/<slug>
scripts/upstream-sync.sh
```

O `upstream-sync.sh` mescla, **retém `docs/` e `vault/`**, prova a retenção por efeito, reporta a
proporção produto/governança e verifica que o `validate` não mexeu. Não commita nem faz push por
padrão: o commit carrega a medição, e quem mede é quem escreve. Aborta e devolve a árvore se sobrar
conflito de produto ou se a retenção não puder ser provada.

**Por que não `git merge` direto.** Com `roadmap_namespacing: by_agent`, o git detecta os roadmaps
flat do upstream (`docs/roadmaps/wip/`) como **renomeação** dos nossos (`docs/roadmaps/claude/done/`)
e produz uma enxurrada de `rename/delete` — **23 conflitos** no merge de `4f0ad33`. Resolver um a um
é caro e erra fácil, e a `ADR-2026-08-29` já decidiu o resultado: não há julgamento a fazer.

A ancestralidade que torna o merge possível veio daquela ADR, com um merge de históricos. Antes
disso o repo era cópia por ZIP, sem ancestral comum, e `git merge` se recusava a rodar — o que
deixou este repo cinco majors atrás sem ninguém perceber.

**A proporção é o discriminante.** Um merge que fecha com muito mais que uma mão-cheia de arquivos
de produto indica que algo de `docs/` passou. Medido nos merges reais: `4f0ad33` trouxe 4 de produto
e reteve 37; `6b3ba49` trouxe 42 e reteve 10.

**Falsificação:** `scripts/check-upstream-sync-falsify.sh` exercita o script contra esses dois
merges históricos mais dois controles negativos. A propriedade verificada é a **invariante** —
retido ⊆ `docs/` ∪ `vault/`, e todo o resto trazido —, não a contagem: a contagem à mão errou nos
dois casos.

**Não há alvo no `Makefile` de propósito.** O `Makefile` é arquivo compartilhado com o upstream, e
modificá-lo criaria divergência de produto que todo merge futuro pagaria. Acrescentar arquivo novo
em `scripts/` não cria divergência — é o mesmo precedente dos outros três scripts só nossos.

**Governança local** (o `trackfw.yaml` daqui sobrescreve dois defaults do produto):

- `req_dir: docs/requisições` — não `docs/req`. O nome em português é histórico.
- `roadmap_namespacing: by_agent`, agentes `[apolo, artemis, claude]`, então os artefatos ficam em
  `docs/requisições/<agente>/` e `docs/roadmaps/<agente>/{backlog,wip,done}/`.

A governança do upstream **não** é importada: as 52 ADRs, 140 REQs e 142 roadmaps dele cairiam
dentro de `docs/adr/` e `docs/roadmaps/`, que é onde vive a governança daqui.

**Divergência local de produto: NENHUMA.** Medido em 2026-09-05:

```bash
git diff --name-only main upstream/main -- internal npm/src pypi/trackfw cmd .github Makefile
# (vazio)
```

Os únicos arquivos só nossos são adições que o upstream não tem — `scripts/check-slug-inventory.sh`,
`scripts/check-subcommand-parity.sh`, `scripts/check-upstream-content.sh`, `scripts/upstream-sync.sh`
e `scripts/check-upstream-sync-falsify.sh`. Adição não é divergência: nenhum arquivo compartilhado
difere.

> **Correção de 2026-09-05.** Esta seção afirmava que `_force_utf8_output` em `pypi/trackfw/cli.py`
> era divergência local deliberada. **Não é mais** — o upstream absorveu (2 ocorrências em
> `upstream/main:pypi/trackfw/cli.py`). A `REQ-2026-08-16-cli-python-utf8-windows` continua válida
> como registro do defeito e da correção; o que caducou foi a afirmação de que ela só existe aqui.
> Documentação que descreve divergência inexistente faz o próximo merge procurar conflito onde não
> há.
