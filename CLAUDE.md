# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**trackfw** is a governance CLI that enforces a traceable delivery chain — `ADR → REQ → ROADMAP → backlog/wip/blocked/done/abandoned` — using Markdown files and folder position as the only state. No database, no SaaS. See [README.md](README.md) and [docs/visao-projeto/VISION.md](docs/visao-projeto/VISION.md) for the full product rationale.

## Tri-runtime architecture (most important concept)

The same CLI is shipped as **three independent native reimplementations** that must behave identically:

| Runtime | Location | Entry point | Language |
|---|---|---|---|
| **Go** (canonical) | `cmd/trackfw` + `internal/` | `cmd/trackfw/main.go` → `commands.Execute()` | Go (cobra), module `github.com/kgsaran/trackfw` |
| **Node.js** | `npm/` | `npm/bin/trackfw` → `npm/src/commands/index.js` | Node ≥ 18 (commander, @inquirer/prompts) |
| **Python** | `pypi/` | `pypi/trackfw/cli.py:main` | Python ≥ 3.10 (stdlib only) |

The three trees mirror each other deliberately: `internal/commands/*.go` ↔ `npm/src/commands/*.js` ↔ `pypi/trackfw/commands/*.py`, same for `config/`, `validator/`, `generators/`, `serve/`, `i18n/`. **Go is the reference implementation.** When you change shared behavior in one runtime, you almost always need to change all three or you break parity.

Parity is contractually enforced by `scripts/`:
- `scripts/check-cli-parity.sh` — every runtime must expose the same command set and `version`/`--version` output.
- `scripts/check-validate-parity.sh` — `validate` must produce identical violations across runtimes against the same fixture project.
- `scripts/check-static-assets.sh` — the `serve` dashboard's static assets must be **byte-identical** across runtimes. Canonical source is `internal/serve/static/{index.html,app.js,style.css}`; `npm/src/serve/static/` and `pypi/trackfw/serve/static/` are copies. Edit the canonical Go copy, then sync the other two.

Intentional, allowed divergences (Go-binary-only commands like `agents`, `gemini`, `cursor`, `copilot`, `windsurf`, `amazonq`) are documented in `docs/cli-parity.md`. In the npm/pip packages those AI integrations run through `trackfw init` instead.

## Build, test, lint

> Note: this working copy may be missing `go.mod` and `cmd/trackfw/main.go` (and `.github/workflows/`). The Go source under `internal/` is present. If `go build` fails with "no go.mod", you are in a partial snapshot — restore the module file before building.

**Go (canonical):**
```bash
go build -o bin/trackfw ./cmd/trackfw   # what check-cli-parity.sh runs
go test ./...                            # all Go tests
go test ./internal/validator/ -run TestName   # single test
go vet ./...                             # lint
```
(`make build` / `make test` / `make lint` are the documented aliases when a Makefile is present.)

**Node.js:**
```bash
cd npm && npm install
node --test tests/*.test.js              # npm run test
node bin/trackfw --help                  # npm run smoke
```

**Python:**
```bash
cd pypi && pip install -e ".[dev]"       # dev extra = pytest; the package itself is stdlib-only
python3 -m pytest tests/                 # tests live in pypi/tests/
PYTHONPATH=. python3 -m trackfw --help   # run the CLI from source
```

**pytest is required, not optional.** Six test modules are pytest-style — bare `test_*` functions
using the `tmp_path` fixture — which `unittest` cannot collect: `test_context_req_by_agent`,
`test_discover`, `test_req_by_agent`, `test_rules_req_configuraveis`, `test_serve_api`,
`test_traceid`. Without pytest they fail as `ModuleNotFoundError` and 37 tests silently never run.

`python3 -m unittest discover -s tests -t .` still works for the `TestCase`-style modules, but it
skips those six. Note the `-t .`: `pypi/tests/__init__.py` forces UTF-8 output, and without
`-t .` unittest imports the modules top-level and never runs it.

**Parity gates (run after any cross-runtime change):**
```bash
bash scripts/check-cli-parity.sh
bash scripts/check-subcommand-parity.sh
bash scripts/check-validate-parity.sh
bash scripts/check-static-assets.sh
```

`check-cli-parity.sh` only compares **top-level** commands, and only checks presence. That is why
`req move` was missing from all three runtimes and `req list` from Python without any gate noticing —
`req` existed everywhere, so parity passed.

`check-subcommand-parity.sh` goes one level down and compares **sets** in both directions: missing
*and* extra. Known divergences are declared inline in the script with a reason each; a new one fails
the gate. It also warns when a declaration no longer matches reality, so the list does not rot.

## The governance domain model

Understanding these layers is required to work on `validate`, `context`, or any generator:

- **ADR** (`docs/adr/`) — the *why*. A REQ is "blocked" until every ADR it links reaches `Status: Accepted`.
- **REQ** (`docs/req/` by default) — the *what*, links to an ADR.
- **ROADMAP** (`docs/roadmaps/{backlog,analyzing,wip,blocked,done,abandoned}/`) — the *when*. **Folder position IS the state** — moving a file is the state transition.
- `validate` is the heart of the tool: a configurable gate (15+ rules, each `off`/`warning`/`error`, plus `governance_mode: strict|lenient`) meant to run as a pre-commit hook and CI gate.

Two config features pervade the validator and must be handled in every code path that walks artifacts:
- **`roadmap_namespacing: by_agent`** — artifacts nest under an agent name (`docs/roadmaps/claude/wip/`). All walking/validation must be by_agent-aware to avoid false positives.
- **`trace_id_field`** — bidirectional REQ↔ROADMAP linking with 5 dedicated checks (see `internal/validator/validator_traceid.go`).

Config is loaded from `trackfw.yaml`; the schema/loader lives in `internal/config/` (and the Node/Python mirrors).

### This repo's own governance (dogfooding)

trackfw governs itself, and its `trackfw.yaml` overrides two defaults — read it before assuming any path:

- `req_dir: docs/requisições` (not `docs/req`) — the Portuguese name is historical.
- `roadmap_namespacing: by_agent` with `agents: [apolo, artemis, claude]`, so artifacts live in
  `docs/requisições/<agent>/` and `docs/roadmaps/<agent>/{backlog,wip,done}/`.

Until 2026-08-16 there was no `trackfw.yaml` at all: the CLI ran on the flat defaults and saw 2 of
the repo's 66 artifacts, which hid 3 roadmaps stuck in `wip/` and 20 validate violations. If you
find artifacts outside the two paths above, that is drift — see
`docs/requisições/claude/REQ-2026-08-16-consolidar-arvores-governanca.md`.

## Key internal packages (Go)

- `internal/commands/` — one file per CLI command; `root.go` registers them all on the cobra root.
- `internal/config/` — `trackfw.yaml` parsing, path resolution, namespacing, config evolution.
- `internal/validator/` — all governance rules + traceid checks. Heavily test-covered; mirror new rules into npm/pypi.
- `internal/generators/` — stack- and AI-tool-specific file emitters used by `init`/`update`. Add a new stack here without touching core logic. Templates in `internal/generators/templates/{agents,amazonq,copilot,cursor,gemini,windsurf}/`. Each installer is idempotent — never overwrite user customizations.
- `internal/serve/` + `internal/server/` — local governance dashboard HTTP API + the byte-identical static frontend.
- `internal/discover/` — discovery/CMDB mode that infers governance state from an existing repo.
- `internal/sync/` — Jira / Linear integrations.
- `internal/metrics/`, `internal/plugins/`, `internal/i18n/` (locales: `en-US`, `es-ES`, `pt-BR`).

## AI assistant integrations

`init`/`update` install governance context for 6+ AI CLIs and auto-inject **attention hooks** (`PreToolUse`/`PostToolUse`) so the `serve` board shows a live banner when an agent needs user action. The 10 specialist roles installed for each tool are: **architect, backend, frontend, qa, infra, security, code-quality, dba, ux, data** — templates under `internal/generators/templates/`.

## Conventions

- Go code uses `github.com/spf13/cobra` for command wiring and `github.com/kgsaran/trackfw` as the module path.
- Every command/feature change should add tests in all three runtimes (`*_test.go`, `npm/tests/*.test.js`, `pypi/tests/`).
- Project planning artifacts live under `docs/requisições/<agent>/` and `docs/roadmaps/<agent>/`, organized by lifecycle (`backlog/wip/done`). This repo dogfoods trackfw on itself — see "This repo's own governance" above. `docs/req/` and `docs/roadmap/` (singular) were drift and no longer exist.
