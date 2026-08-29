#!/usr/bin/env bash
# Gate: deteccao de terminal interativo confiavel nos tres runtimes.
#
# sys.stdin.isatty() devolve True para NUL no Windows (character device conta como
# TTY), entao o `init` do Python entrava no wizard de identidade em contexto nao
# interativo e morria com EOF. Go usa GetConsoleMode e Node usa o tipo de handle do
# libuv; so o Python precisava do ajuste.
#
# Ver REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail=0

# ── Por efeito: `init` com stdin nao interativo conclui nos tres ──
# A home tambem e isolada: com identidade ja configurada o wizard nem seria
# alcancado, e o teste passaria sem exercitar nada.
for rt in go node python; do
  d="$WORK/$rt"; mkdir -p "$d" "$WORK/home-$rt"
  rc=0
  case "$rt" in
    go)     (cd "$d" && HOME="$WORK/home-$rt" "$ROOT/bin/trackfw" init </dev/null >/dev/null 2>&1) || rc=$? ;;
    node)   (cd "$d" && HOME="$WORK/home-$rt" node "$ROOT/npm/bin/trackfw" init </dev/null >/dev/null 2>&1) || rc=$? ;;
    python) (cd "$d" && HOME="$WORK/home-$rt" PYTHONPATH="$ROOT/pypi" python -m trackfw init </dev/null >/dev/null 2>&1) || rc=$? ;;
  esac
  if [ "$rc" -ne 0 ]; then
    echo "tty detection: \`$rt init\` saiu $rc com stdin nao interativo (esperado 0)"
    fail=1
  elif [ ! -f "$d/trackfw.yaml" ]; then
    echo "tty detection: \`$rt init\` saiu 0 mas nao escreveu trackfw.yaml"
    fail=1
  fi
done

# ── Estatico: nenhum isatty() cru fora do helper ──
raw=$(grep -rn 'isatty()' "$ROOT/pypi/trackfw" --include='*.py' \
      | grep -v 'trackfw/tty.py' \
      | grep -vE ':\s*#' | grep -v 'never blocks' || true)
if [ -n "$raw" ]; then
  echo "tty detection: python tem isatty() fora do helper:"
  printf '%s\n' "$raw" | sed 's/^/  /'
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo 'Use trackfw.tty.stdin_is_interactive() / stdout_is_interactive().'
  exit 1
fi
echo "Deteccao de TTY: os 3 runtimes concluem \`init\` sem stdin, e nenhum isatty() cru no Python."
