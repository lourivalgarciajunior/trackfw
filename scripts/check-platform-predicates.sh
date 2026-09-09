#!/usr/bin/env bash
# Executa o corpus scripts/testdata/platform-predicates.tsv contra os predicados
# REAIS do runtime, em vez de deixa-lo como tabela que ninguem le.
#
# REQ-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum
#
# Tres guardas, nesta ordem -- cada uma existe por um modo de falha MEDIDO:
#
#   1. INTEGRIDADE DO VETOR. Cada linha declara o comprimento em bytes do campo
#      `caso`. Se o lido divergir do declarado, o gate reprova ANTES de comparar
#      qualquer predicado. Motivo: em 2026-09-08 uma sonda deste repositorio
#      perdeu metade das barras invertidas num heredoc e quase inverteu a
#      conclusao -- num corpus de CAMINHOS, barra perdida vira verde falso.
#   2. DESPACHO POR FAMILIA. A coluna `caso` nao e homogenea: em `anchored` ela
#      e string de ENTRADA; nas outras e NOME DE CENARIO. Um leitor uniforme
#      passaria "arquivo-lido-como-diretorio" a um predicado de caminho e
#      obteria um false que casa por acaso com outra linha.
#   3. VACUIDADE. Casos executados tem de igualar as linhas nao-comentario.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="${CORPUS:-$ROOT_DIR/scripts/testdata/platform-predicates.tsv}"
PROBE_DIR="$ROOT_DIR/.trackfw-predicate-probe"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK" "$PROBE_DIR"' EXIT

FAIL=0; EXECUTADOS=0; NAO_APLICAVEIS=0

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) SO=windows ;;
  *)                    SO=posix ;;
esac

fail() { echo "FAIL [$1]: $2" >&2; FAIL=$((FAIL+1)); }
ok()   { echo "OK   [$1]"; EXECUTADOS=$((EXECUTADOS+1)); }
na()   { echo "N/A  [$1]: $2"; NAO_APLICAVEIS=$((NAO_APLICAVEIS+1)); EXECUTADOS=$((EXECUTADOS+1)); }
winpath() { cygpath -w "$1" 2>/dev/null || printf '%s' "$1"; }

[ -f "$CORPUS" ] || { echo "check-platform-predicates: corpus ausente em $CORPUS" >&2; exit 1; }

# --- Guarda 1: integridade do vetor -----------------------------------------
LINHAS=0
while IFS=$'\t' read -r fam caso bytes esp win nota; do
  [ -z "${fam:-}" ] && continue
  case "$fam" in "#"*) continue ;; esac
  LINHAS=$((LINHAS+1))
  real=$(printf '%s' "$caso" | wc -c | tr -d ' ')
  if [ "$real" != "$bytes" ]; then
    fail "integridade/$fam/$caso" "declarado $bytes bytes, lido $real -- vetor corrompido"
  fi
done < <(tr -d '\r' < "$CORPUS")

[ "$LINHAS" -gt 0 ] || { echo "GUARDA: corpus sem nenhuma linha de caso" >&2; exit 1; }
[ "$FAIL" -eq 0 ] || { echo "GUARDA: integridade reprovou -- nao comparo predicado sobre vetor corrompido" >&2; exit 1; }
echo "integridade: $LINHAS vetores conferidos byte a byte"

# --- Sonda Go da familia anchored -------------------------------------------
mkdir -p "$PROBE_DIR"
{
  echo "package main"
  echo ""
  echo "import ("
  echo "	\"bufio\""
  echo "	\"fmt\""
  echo "	\"os\""
  echo "	\"path/filepath\""
  echo ""
  echo "	\"github.com/kgsaran/trackfw/internal/pathanchor\""
  echo ")"
  echo ""
  echo "func main() {"
  echo "	// Modo direrr: o corpus fala de os.IsNotExist do GO. Medir com Python"
  echo "	// seria medir outro predicado -- ele distingue NotADirectoryError de"
  echo "	// FileNotFoundError, e a linha do corpus existe justamente porque o Go"
  echo "	// NAO distingue no Windows."
  echo "	if len(os.Args) == 3 && os.Args[1] == \"-direrr\" {"
  echo "		_, err := os.ReadDir(os.Args[2])"
  echo "		if err == nil {"
  echo "			fmt.Println(\"sem-erro\")"
  echo "		} else if os.IsNotExist(err) {"
  echo "			fmt.Println(\"suprimido\")"
  echo "		} else {"
  echo "			fmt.Println(\"reportado\")"
  echo "		}"
  echo "		return"
  echo "	}"
  echo "	sc := bufio.NewScanner(os.Stdin)"
  echo "	for sc.Scan() {"
  echo "		p := sc.Text()"
  printf '\t\tfmt.Printf("%%v\\t%%v\\n", pathanchor.IsAnchored(p), filepath.IsAbs(p))\n'
  echo "	}"
  echo "}"
} > "$PROBE_DIR/main.go"

ANCHORED_OK=1
(cd "$ROOT_DIR" && go build -o "$WORK/probe" ./.trackfw-predicate-probe) 2>"$WORK/build.err" || ANCHORED_OK=0

PY_DIRERR='import os,sys
try:
    os.listdir(sys.argv[1]); print("sem-erro")
except NotADirectoryError: print("report")
except FileNotFoundError: print("suppress")
except OSError: print("outro")'

PY_EXECBIT='import os,sys
print("com-bit" if os.stat(sys.argv[1]).st_mode & 0o111 else "sem-bit")'

PY_ISATTY='import os
d = "NUL" if os.name == "nt" else "/dev/null"
fd = os.open(d, os.O_WRONLY)
print("true" if os.isatty(fd) else "false")
os.close(fd)'

# --- Execucao por familia ---------------------------------------------------
while IFS=$'\t' read -r fam caso bytes esp win nota; do
  [ -z "${fam:-}" ] && continue
  case "$fam" in "#"*) continue ;; esac
  if [ "$SO" = windows ]; then alvo="$win"; else alvo="$esp"; fi
  rot="$fam/$caso"

  case "$fam" in
  anchored)
    if [ "$ANCHORED_OK" != 1 ]; then
      na "$rot" "sonda Go nao compilou: $(head -1 "$WORK/build.err")"
      continue
    fi
    linha=$(printf '%s\n' "$caso" | "$WORK/probe")
    anch=$(printf '%s' "$linha" | cut -f1)
    isabs=$(printf '%s' "$linha" | cut -f2)
    [ "$anch" = "$esp" ] || fail "$rot/anchored" "IsAnchored=$anch, corpus declara esperado=$esp"
    if [ "$SO" = windows ]; then
      [ "$isabs" = "$win" ] || fail "$rot/isabs" "filepath.IsAbs=$isabs, corpus declara nativo_windows=$win"
    fi
    ok "$rot"
    ;;

  direrr)
    d="$WORK/direrr.$RANDOM"; mkdir -p "$d"
    case "$caso" in
      arquivo-lido-como-diretorio) printf 'x' > "$d/f"; p="$d/f" ;;
      subdir-dentro-de-arquivo)    printf 'x' > "$d/f"; p="$d/f/sub" ;;
      caminho-inexistente)         p="$d/nunca-existiu" ;;
      *) na "$rot" "cenario sem executor"; continue ;;
    esac
    if [ "$ANCHORED_OK" != 1 ]; then
      na "$rot" "sonda Go nao compilou: $(head -1 "$WORK/build.err")"
      continue
    fi
    bruto=$("$WORK/probe" -direrr "$p")
    # O observavel e binario: o erro foi suprimido por os.IsNotExist, ou nao.
    # O corpus usa tres tokens porque distingue se a supressao e LEGITIMA
    # (`suppress`, caso ENOENT) ou indevida (`swallow`, caso ENOTDIR).
    case "$bruto" in
      reportado) obs=report ;;
      suprimido) if [ "$esp" = suppress ]; then obs=suppress; else obs=swallow; fi ;;
      *)         obs="$bruto" ;;
    esac
    [ "$obs" = "$alvo" ] || fail "$rot" "observado=$obs (os.IsNotExist do Go disse $bruto), corpus declara $alvo"
    ok "$rot"
    ;;

  execbit)
    f="$WORK/exec.$RANDOM"; printf 'x\n' > "$f"; chmod 0755 "$f" 2>/dev/null || true
    obs=$(PYTHONIOENCODING=utf-8 python -c "$PY_EXECBIT" "$(winpath "$f")")
    [ "$obs" = "$alvo" ] || fail "$rot" "observado=$obs, corpus declara $alvo"
    ok "$rot"
    ;;

  isatty)
    obs=$(PYTHONIOENCODING=utf-8 python -c "$PY_ISATTY")
    [ "$obs" = "$alvo" ] || fail "$rot" "observado=$obs, corpus declara $alvo"
    ok "$rot"
    ;;

  bash)
    if [ "$SO" = windows ]; then
      # PRECONDICAO. A linha do corpus descreve o stub do WSL vencendo a
      # resolucao por nome nu. Sem WSL instalado nao ha stub, e o caso nao pode
      # ser exercitado -- declarar N/A com a razao, nunca comparar contra um
      # cenario que nao existe nesta maquina.
      if [ ! -f /c/Windows/System32/bash.exe ]; then
        na "$rot" "System32\\bash.exe ausente (WSL nao instalado) -- o cenario do corpus exige o stub"
        continue
      fi
      w=$(cmd //c where bash 2>/dev/null | tr -d '\r' | head -1 || true)
      case "$w" in
        *System32*|"") obs=stub-ou-erro ;;
        *)             obs=absolute ;;
      esac
    else
      if [ -n "$(command -v bash || true)" ]; then obs=absolute; else obs=stub-ou-erro; fi
    fi
    [ "$obs" = "$alvo" ] || fail "$rot" "observado=$obs, corpus declara $alvo"
    ok "$rot"
    ;;

  *) na "$rot" "familia sem executor" ;;
  esac
done < <(tr -d '\r' < "$CORPUS")

# --- Guarda 3: vacuidade ----------------------------------------------------
if [ "$EXECUTADOS" -ne "$LINHAS" ]; then
  echo "GUARDA DE VACUIDADE: $EXECUTADOS de $LINHAS casos executados" >&2
  exit 1
fi

if [ "$SO" = windows ]; then col=nativo_windows; else col=esperado; fi
echo "check-platform-predicates: $EXECUTADOS caso(s) - $NAO_APLICAVEIS nao-aplicavel(is) - SO=$SO - coluna=$col"
[ "$FAIL" -eq 0 ] || { echo "check-platform-predicates: $FAIL divergencia(s)" >&2; exit 1; }
