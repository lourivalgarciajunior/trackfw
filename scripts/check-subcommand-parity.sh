#!/usr/bin/env bash
#
# Compara o conjunto de SUBCOMANDOS de cada comando entre os três runtimes.
#
# O check-cli-parity.sh compara só comandos de primeiro nível, e só presença —
# por isso `req move` faltou nos três e `req list` faltou no Python sem nenhum
# gate avisar. Este desce um nível e compara conjuntos nos dois sentidos:
# subcomando faltando E subcomando sobrando.
#
# Ver REQ-2026-08-17-gate-paridade-subcomando.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GO_BIN=${GO_BIN:-"$ROOT_DIR/bin/trackfw"}

mkdir -p "$(dirname "$GO_BIN")"
GOCACHE=${GOCACHE:-/tmp/trackfw-go-cache} go build -o "$GO_BIN" ./cmd/trackfw

# Comandos que têm subcomando em pelo menos um runtime.
commands=(adr req roadmap plugins)

# ---------------------------------------------------------------------------
# Divergências conhecidas
#
# Formato: "<comando>:<runtime>:<subcomando>:<faltando|sobrando>"
#
# Cada entrada precisa de motivo. Divergência NOVA falha o gate; declarada passa.
# Mesmo princípio do trackfw baseline: congela o conhecido sem esconder.
# ---------------------------------------------------------------------------
known_divergences=(
  # `adr list` existe em Go e Node.js desde REQ-adr-wizard-e-list-2026-06-11,
  # mas nunca foi portado para o Python. Lacuna real, ainda não priorizada.
  "adr:python:list:faltando"

  # O `plugins` do Python foi escrito com outra superfície: tem `run`, que os
  # outros dois não têm, e não tem add/remove/search. Pode ser decisão
  # deliberada — o pacote pip não gerencia instalação de plugin da mesma forma.
  # Precisa de decisão antes de virar trabalho.
  "plugins:python:add:faltando"
  "plugins:python:remove:faltando"
  "plugins:python:search:faltando"
  "plugins:python:run:sobrando"
)

is_known() {
  local entry="$1" k
  for k in "${known_divergences[@]}"; do
    [ "$k" = "$entry" ] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Extratores — cada runtime formata o help de um jeito.
# ---------------------------------------------------------------------------

# Filtra a primeira palavra de cada linha, mantendo só nomes de subcomando.
# Descarta linha de continuação de descrição longa (que não começa com palavra)
# e o `help` que o commander injeta sozinho.
only_names() {
  awk '$1 ~ /^[a-z][a-z0-9-]+$/ && $1 != "help" { print $1 }' | sort -u
}

subcommands_go() {  # cobra: bloco "Available Commands:" até linha em branco
  "$GO_BIN" "$1" --help 2>/dev/null \
    | sed -n '/^Available Commands:/,/^[[:space:]]*$/p' | tail -n +2 | only_names
}

subcommands_node() {  # commander: bloco "Commands:" até o fim
  node "$ROOT_DIR/npm/bin/trackfw" "$1" --help 2>/dev/null \
    | sed -n '/^Commands:/,$p' | tail -n +2 | only_names
}

subcommands_python() {  # argparse: bloco "positional arguments:" até linha em branco
  # O metavar varia entre COMMAND e SUBCOMMAND conforme o comando.
  PYTHONPATH="$ROOT_DIR/pypi" PYTHONIOENCODING=utf-8 PYTHONUTF8=1 \
    python3 -m trackfw "$1" --help 2>/dev/null \
    | sed -n '/^positional arguments:/,/^[[:space:]]*$/p' | tail -n +2 | only_names
}

# ---------------------------------------------------------------------------
# Comparação — o Go é a referência.
# ---------------------------------------------------------------------------
failures=0
declared_but_absent=0

report() {  # report <comando> <runtime> <subcomando> <direcao>
  local entry="$1:$2:$3:$4"
  if is_known "$entry"; then
    return 0
  fi
  echo "  ✗ ${1}: '${3}' ${4} no runtime ${2}" >&2
  failures=$((failures + 1))
}

for cmd in "${commands[@]}"; do
  go_set=$(subcommands_go "$cmd")
  [ -z "$go_set" ] && continue

  for runtime in node python; do
    case "$runtime" in
      node)   other_set=$(subcommands_node "$cmd") ;;
      python) other_set=$(subcommands_python "$cmd") ;;
    esac

    # O nome usado nas declarações é "python"/"node"; mantém consistente.
    while read -r sub; do
      [ -z "$sub" ] && continue
      report "$cmd" "$runtime" "$sub" "faltando"
    done < <(comm -23 <(echo "$go_set") <(echo "$other_set"))

    while read -r sub; do
      [ -z "$sub" ] && continue
      report "$cmd" "$runtime" "$sub" "sobrando"
    done < <(comm -13 <(echo "$go_set") <(echo "$other_set"))
  done
done

# Uma declaração que não corresponde mais a nada é lixo — avisa, mas não falha,
# porque some sozinha quando a divergência é corrigida.
for k in "${known_divergences[@]}"; do
  IFS=':' read -r kcmd kruntime ksub kdir <<<"$k"
  case "$kruntime" in
    node)   other_set=$(subcommands_node "$kcmd") ;;
    python) other_set=$(subcommands_python "$kcmd") ;;
    *)      continue ;;
  esac
  go_set=$(subcommands_go "$kcmd")
  still=1
  if [ "$kdir" = "faltando" ]; then
    comm -23 <(echo "$go_set") <(echo "$other_set") | grep -qx "$ksub" || still=0
  else
    comm -13 <(echo "$go_set") <(echo "$other_set") | grep -qx "$ksub" || still=0
  fi
  if [ "$still" -eq 0 ]; then
    echo "  ⚠ divergência declarada já não existe: ${k} — remova do allowlist" >&2
    declared_but_absent=$((declared_but_absent + 1))
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "" >&2
  echo "${failures} divergência(s) de subcomando não declarada(s)." >&2
  echo "Corrija o runtime, ou declare em known_divergences com o motivo." >&2
  exit 1
fi

if [ "$declared_but_absent" -gt 0 ]; then
  echo "Subcommand parity checks passed (${declared_but_absent} declaração(ões) obsoleta(s))"
else
  echo "Subcommand parity checks passed"
fi
