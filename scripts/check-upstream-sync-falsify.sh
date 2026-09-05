#!/usr/bin/env bash
# check-upstream-sync-falsify.sh — falsifica scripts/upstream-sync.sh contra merges
# HISTÓRICOS reais, nos dois extremos da distribuição produto/governança.
#
# AC4 da REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local.
#
# Por que contra merges históricos, e não fixtures sintéticas
# ----------------------------------------------------------
# O modo de falha que este script existe para pegar é a detecção de renomeação de
# DIRETÓRIO do git casando os roadmaps flat do upstream com os nossos em by_agent. Uma
# fixture sintética não reproduz isso — depende do conteúdo real dos dois acervos e do
# heurístico de similaridade do git. Os dois casos abaixo são merges que de fato
# aconteceram, com o resultado conferido à mão na época.
#
# A propriedade verificada NÃO é "quantos arquivos", e sim a INVARIANTE:
#
#   retido      ⊆  docs/ ∪ vault/         (nunca suprime produto)
#   trazido     =  tudo que não é docs/ nem vault/   (nunca deixa produto para trás)
#
# Contar arquivos foi a primeira formulação do AC4 e estava ERRADA nos dois casos: os
# números vieram de contagem à mão que só olhava docs/{adr,req,roadmaps} e ignorava
# vault/, docs/qualidade e docs/cli-parity.md. A medição corrigiu 32→37 e 0→10. A
# invariante sobrevive à correção; a contagem não sobreviveria.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
SYNC="$ROOT/scripts/upstream-sync.sh"
WT="/c/tfwfalsify"   # curto de proposito: o snapshot do barrier estoura o limite de nome no Windows
FAILED=0

# base<TAB>ref<TAB>rotulo
CASES=$'bfeea12\t4f0ad33\tgovernanca pesada (41 arquivos, 4 de produto)\n01086b5\t6b3ba49\tproduto puro (52 arquivos, 42 de produto)'

cleanup() { git worktree remove --force "$WT" >/dev/null 2>&1 || true; git worktree prune >/dev/null 2>&1 || true; }
trap cleanup EXIT

while IFS=$'\t' read -r BASE REF LABEL; do
	[ -n "${BASE:-}" ] || continue
	echo "── caso: $LABEL"
	cleanup
	git worktree add --detach -q "$WT" "$BASE" 2>/dev/null || { echo "  FAIL: worktree em $BASE"; FAILED=1; continue; }

	( cd "$WT" && bash "$SYNC" --ref "$REF" --skip-verify ) >/dev/null 2>&1 || {
		echo "  FAIL: upstream-sync abortou"; FAILED=1; continue; }

	BROUGHT="$(cd "$WT" && git diff --cached --name-only "$BASE" | sort)"
	ALL="$(cd "$WT" && git diff --name-only "$BASE...$REF" | sort)"
	RETAINED="$(comm -23 <(printf '%s\n' "$ALL") <(printf '%s\n' "$BROUGHT"))"

	# INVARIANTE 1 — nada retido fora de docs/ ou vault/ (nao suprime produto)
	LEAK="$(printf '%s\n' "$RETAINED" | grep -vE '^(docs/|vault/)' | grep -v '^$' || true)"
	if [ -n "$LEAK" ]; then
		echo "  FAIL: PRODUTO suprimido:"; printf '%s\n' "$LEAK" | sed 's/^/      /'; FAILED=1
	else
		echo "  ok  retido ⊆ docs/ ∪ vault/         ($(printf '%s\n' "$RETAINED" | grep -c . || true) arquivos)"
	fi

	# INVARIANTE 2 — nada de produto ficou para tras
	MISSED="$(comm -23 <(printf '%s\n' "$ALL" | grep -vE '^(docs/|vault/)' || true) <(printf '%s\n' "$BROUGHT"))"
	if [ -n "$(printf '%s\n' "$MISSED" | grep -c . || true)" ] && [ -n "$MISSED" ]; then
		echo "  FAIL: produto NAO trazido:"; printf '%s\n' "$MISSED" | sed 's/^/      /'; FAILED=1
	else
		echo "  ok  todo produto trazido            ($(printf '%s\n' "$BROUGHT" | grep -c . || true) arquivos)"
	fi

	# INVARIANTE 3 — docs/ e vault/ identicos a base
	DIFF="$(cd "$WT" && git diff --cached "$BASE" -- docs vault --stat)"
	if [ -n "$DIFF" ]; then
		echo "  FAIL: docs/ ou vault/ divergem da base"; FAILED=1
	else
		echo "  ok  docs/ e vault/ identicos a base"
	fi
done <<< "$CASES"

# ── Controle negativo: o script tem de RECUSAR arvore suja ──────────────────────
echo "── controle: arvore suja tem de ser recusada"
cleanup
git worktree add --detach -q "$WT" bfeea12 2>/dev/null
echo "sujeira" > "$WT/ARQUIVO-NAO-RASTREADO.txt"
if ( cd "$WT" && bash "$SYNC" --ref 4f0ad33 --skip-verify ) >/dev/null 2>&1; then
	echo "  FAIL: aceitou arvore suja"; FAILED=1
else
	echo "  ok  recusou arvore suja"
fi

# ── Controle negativo: ref inexistente ──────────────────────────────────────────
echo "── controle: ref inexistente tem de ser recusada"
cleanup
git worktree add --detach -q "$WT" bfeea12 2>/dev/null
if ( cd "$WT" && bash "$SYNC" --ref nao-existe-esta-ref --skip-verify ) >/dev/null 2>&1; then
	echo "  FAIL: aceitou ref inexistente"; FAILED=1
else
	echo "  ok  recusou ref inexistente"
fi

echo ""
if [ "$FAILED" = "0" ]; then echo "check-upstream-sync-falsify: OK"; exit 0; fi
echo "check-upstream-sync-falsify: FAIL"; exit 1
