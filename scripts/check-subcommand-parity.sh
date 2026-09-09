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

# ---------------------------------------------------------------------------
# Comandos que têm subcomando — DERIVADOS POR EXECUÇÃO, nunca chumbados.
#
# A lista era `commands=(adr req roadmap)`. Medido em 2026-09-09: são OITO, e o
# gate comparava TRÊS. `branch`, `note`, `release`, `agents` e `skills` ficavam
# sem verificação de paridade nenhuma.
#
# O critério é a linha `Usage:` do próprio CLI: ela NOMEIA o comando e contém
# `[command]`. Duas outras derivações foram tentadas e descartadas, e ficam
# registradas para não serem re-tentadas (ver ML-0A do roadmap):
#
#   1. `--help` da raiz por indentação. FALHA: a descrição de `ship` e `commit`
#      continua no recuo 2, indistinguível de comando. Devolvia `already`, `the`,
#      `for`, `has`, `happens`, `skeleton`, `without` como se fossem comandos.
#   2. Fonte, por padrão de registro. FALHA: três padrões diferentes por runtime
#      (`.command(`, `AddCommand(`, `add_subparsers(`) e dois falsos positivos —
#      `integrations` e `thirdparty`, onde nome de ARQUIVO != nome de comando.
#      Trocar uma lista literal de 3 por três padrões literais não é derivar.
#
# A validação por execução filtra prosa por construção: `already --help` cai no
# help da raiz, cuja `Usage:` não contém `already`.
# ---------------------------------------------------------------------------
has_subcommands() {  # has_subcommands <candidato>
  local u
  u=$(node "$ROOT_DIR/npm/bin/trackfw" "$1" --help 2>/dev/null | grep -m1 -iE '^usage:' || true)
  [ -n "$u" ] || return 1
  case "$u" in
    *"trackfw $1 "*) : ;;   # a Usage tem de NOMEAR o candidato
    *) return 1 ;;
  esac
  case "$u" in
    *"[command]"*) return 0 ;;
    *) return 1 ;;
  esac
}

candidates=$(node "$ROOT_DIR/npm/bin/trackfw" --help 2>/dev/null \
  | sed -n '/^Commands:/,$p' | tail -n +2 \
  | awk '$1 ~ /^[a-z][a-z0-9-]*$/ { print $1 }' | sort -u)

commands=()
for c in $candidates; do
  has_subcommands "$c" && commands+=("$c")
done

# Guarda de vacuidade: derivar zero e sair 0 seria o defeito que este gate
# existe para fechar, cometido pelo próprio gate.
if [ "${#commands[@]}" -eq 0 ]; then
  echo "check-subcommand-parity: GUARDA — zero comandos com subcomando derivados" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Divergências conhecidas
#
# Formato: "<comando>:<runtime>:<subcomando>:<faltando|sobrando>"
#
# Cada entrada precisa de motivo. Divergência NOVA falha o gate; declarada passa.
# Mesmo princípio do trackfw baseline: congela o conhecido sem esconder.
# ---------------------------------------------------------------------------
known_divergences=(
  # Vazio desde a migracao para a 7.3.0: o subsistema de plugins foi removido
  # pelo upstream (ADR-2026-08-15) e com ele as quatro divergencias que
  # estavam registradas aqui. Ver REQ-2026-08-29-migrar-para-upstream-7.3.0.
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

# Extrai nomes de subcomando por COLUNA, não por primeira palavra.
#
# A versão anterior pegava a primeira palavra de qualquer linha, e funcionava só
# porque o gate cobria `adr`, `req` e `roadmap`, cujas descrições são curtas. Ao
# derivar a lista (2026-09-09) e incluir `branch`, `release` e `skills`, ela
# passou a devolver PROSA como subcomando: `executed`, `slug`, `and`, `never`,
# `only`, `two-phase`, `gated`, `integrated`. Onze falsos positivos.
#
# O discriminante é a coluna: um subcomando real é `nome [args]` seguido de DOIS
# OU MAIS espaços e então a descrição, tudo na mesma linha. Prosa é espaçada
# simples. O cabeçalho aceita qualquer sequência de grupos `[...]` ou `<...>` —
# `new [options] [title]` tem DOIS grupos em colchetes, e um padrão que só
# admitisse `[options]` seguido de `<arg>` perderia `roadmap new` (falso
# negativo, que é pior que a prosa).
#
# `help` é excluído porque é injetado pelo framework, não registrado por nós —
# exigir paridade dele seria exigir paridade do commander/cobra/argparse.
only_names() {
  awk '
    /^[ ]+[a-z][a-z0-9-]*/ {
      line = $0
      sub(/^[ ]+/, "", line)   # o recuo difere por runtime: 2 no commander e no
                               # cobra, 4 no argparse (aninhado sob SUBCOMMAND)
      idx = match(line, /[ ][ ]+/)
      if (idx > 0) {
        head = substr(line, 1, idx - 1)
      } else {
        # Sem corrida de 2+ espaços, dois casos MEDIDOS que não podem ser
        # confundidos:
        #   `list [options]`            subcomando SEM descrição (Node)
        #   `third-party Fetch and ...` subcomando cujo nome é o MAIS LONGO do
        #                               bloco, e o cobra alinha deixando 1 espaço
        #   `two-phase quarantine gate` PROSA, continuação de descrição
        # O discriminante é a segunda palavra: descrição começa em MAIÚSCULA ou
        # é um grupo `[...]`/`<...>`; prosa continua em minúscula.
        n = split(line, w, " ")
        if (n == 1)                                   head = line
        else if (w[2] ~ /^[A-Z]/ || w[2] ~ /^[[<]/)   head = w[1]
        else                                          next
      }
      sub(/[ ]+$/, "", head)
      if (head ~ /^[a-z][a-z0-9-]*([ ](\[[^]]*\]|<[^>]*>))*$/) {
        split(head, p, " ")
        if (p[1] != "help") print p[1]
      }
    }' | sort -u
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

contabilizados=0
subcomandos_comparados=0

for cmd in "${commands[@]}"; do
  go_set=$(subcommands_go "$cmd")
  # GUARDA DE RECONCILIACAO: o comando foi DERIVADO como tendo subcomando, entao
  # o extrator do Go tem de encontrá-los. Set vazio aqui significa que o gate
  # deixaria de comparar um comando que ele mesmo derivou -- e o `continue`
  # silencioso que existia neste ponto tornava isso invisível.
  if [ -z "$go_set" ]; then
    echo "  ✗ RECONCILIACAO: '${cmd}' foi derivado como tendo subcomando, mas o extrator do Go devolveu conjunto VAZIO" >&2
    failures=$((failures + 1))
    continue
  fi
  contabilizados=$((contabilizados + 1))
  subcomandos_comparados=$((subcomandos_comparados + $(echo "$go_set" | grep -c .)))

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

# Denominador escrito. Verde sem denominador não é evidência.
if [ "$contabilizados" -ne "${#commands[@]}" ]; then
  echo "check-subcommand-parity: GUARDA DE RECONCILIACAO — ${contabilizados} de ${#commands[@]} comandos derivados foram contabilizados" >&2
  exit 1
fi

echo "check-subcommand-parity: ${#commands[@]} comando(s) derivado(s) [${commands[*]}] · ${subcomandos_comparados} subcomando(s) comparado(s)"
if [ "$declared_but_absent" -gt 0 ]; then
  echo "Subcommand parity checks passed (${declared_but_absent} declaração(ões) obsoleta(s))"
else
  echo "Subcommand parity checks passed"
fi
