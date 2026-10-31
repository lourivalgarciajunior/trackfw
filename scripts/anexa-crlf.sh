#!/usr/bin/env bash
# Anexa o conteudo de <fonte> ao fim de <alvo>, convertendo para CRLF, e VERIFICA
# por efeito que os bytes chegaram inteiros. Nao recebe conteudo: recebe CAMINHOS.
#
# Uso:  anexa-crlf.sh <fonte> <alvo>
#       anexa-crlf.sh --self-test
#
# 🔴 POR QUE ESTA FERRAMENTA EXISTE — medido em 2026-10-31, byte a byte:
#
#   O MESMO conteudo, escrito pelos dois caminhos:
#
#     padrao                            Write    por string de comando
#     contrabarra + newline (continuacao)  2        1
#     contrabarra DUPLA  \\                1        0     <- comida
#     contrabarra + t    \t                1        0     <- comida
#     $'\r'                                1        0     <- comida
#     cmp das duas                      DIFEREM
#
#   Conteudo autoral que viaja dentro de uma string de comando PERDE sequencias de
#   contrabarra. Em 2026-10-31 isso publicou no handoff uma continuacao de linha
#   virada em contrabarra-mais-n: um comando que nao roda para quem copia. E pegou
#   DUAS vezes no mesmo minuto — ao escrever, e na busca que tentava consertar.
#   Antes disso, a mesma causa deixou o `check-req-marcador-ancorado.sh` com as
#   duas pernas do CRLF identicas (o caso CRLF nunca foi verificado) e comeu metade
#   das barras de uma sonda do corpus de predicados.
#
#   A ferramenta do Write preserva tudo, porque o conteudo viaja como string de
#   JSON, sem passar por shell. O que faltava era o segundo passo: anexar sem
#   reescrever um arquivo de 32 mil linhas, e sem deixar LF num arquivo CRLF.
#
# 🔴 O PASSO VERIFICA EM VEZ DE PROMETER. Depois de anexar, ele compara os bytes da
# regiao anexada com a fonte normalizada. Se divergir, RESTAURA o alvo e sai 1 —
# alvo meio-escrito e pior que alvo nao escrito.
#
# 🔴 LF-only num arquivo CRLF e o defeito irmao, e tambem e medido: a contagem de
# linhas LF puro no alvo tem de ser a MESMA antes e depois.
set -uo pipefail

# 🔴 `python3` PRIMEIRO, e `python` so como queda. Em `ubuntu-latest` o nome
# `python` NAO existe por padrao — so `python3` —, e o agregador roda la. Chumbar
# `python` reprovaria o passo no CI por motivo de ambiente, nao por defeito.
if [ -n "${PY-}" ]; then :
elif command -v python3 >/dev/null 2>&1; then PY=python3
elif command -v python >/dev/null 2>&1; then PY=python
else echo "anexa-crlf: nem python3 nem python no PATH" >&2; exit 1
fi

norm_e_anexa() {
  fonte="$1"; alvo="$2"
  "$PY" - "$fonte" "$alvo" <<'EOF'
import sys, os
fonte, alvo = sys.argv[1], sys.argv[2]

if not os.path.isfile(fonte):
    print("anexa-crlf: fonte nao existe: %s" % fonte, file=sys.stderr); sys.exit(1)
if not os.path.isfile(alvo):
    print("anexa-crlf: alvo nao existe: %s" % alvo, file=sys.stderr); sys.exit(1)

with open(fonte, "rb") as f:
    src = f.read()
if not src:
    print("anexa-crlf: fonte VAZIA — nada a anexar e erro de quem chama", file=sys.stderr); sys.exit(1)

CR = bytes([13]); LF = bytes([10]); CRLF = CR + LF

# normaliza em dois passos: tudo para LF, LF para CRLF. Idempotente para fonte
# que ja e CRLF, e nao cria CR duplo.
alvo_norm = src.replace(CRLF, LF).replace(CR, LF).replace(LF, CRLF)

with open(alvo, "rb") as f:
    antes = f.read()

def lf_sozinhos(b):
    return b.count(LF) - b.count(CRLF)

lf_antes = lf_sozinhos(antes)

# o alvo tem de terminar em fim de linha, senao a primeira linha anexada cola
cola = b"" if (not antes or antes.endswith(LF)) else CRLF

with open(alvo, "wb") as f:
    f.write(antes + cola + alvo_norm)

with open(alvo, "rb") as f:
    depois = f.read()

falhas = []
if not depois.endswith(alvo_norm):
    falhas.append("a regiao anexada NAO bate byte a byte com a fonte normalizada")
if depois[:len(antes)] != antes:
    falhas.append("o conteudo que ja estava no alvo MUDOU")
lf_depois = lf_sozinhos(depois)
if lf_depois != lf_antes:
    falhas.append("linhas LF puro: %d antes -> %d depois (o anexo deixou LF)" % (lf_antes, lf_depois))

if falhas:
    with open(alvo, "wb") as f:
        f.write(antes)
    print("anexa-crlf: VERIFICACAO FALHOU — alvo RESTAURADO", file=sys.stderr)
    for m in falhas:
        print("  - %s" % m, file=sys.stderr)
    sys.exit(1)

print("anexa-crlf: %d byte(s) anexados e verificados · LF puro %d antes e %d depois"
      % (len(alvo_norm), lf_antes, lf_depois))
EOF
}

if [ "${1-}" = "--self-test" ]; then
  T=$(mktemp -d) || exit 1
  BS=$(printf '\134')
  N=0; BAD=0
  caso() {
    esp="$1"; rot="$2"; shift 2
    "$@" >"$T/out" 2>&1; got=$?
    N=$((N+1))
    if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
    else BAD=$((BAD+1)); printf '  FAIL %s — esperado rc=%s, obtido rc=%s\n' "$rot" "$esp" "$got"
         sed 's/^/        /' "$T/out"; fi
  }

  # fonte com as sequencias que a string de comando come
  printf 'cmd --flag %s\n  | segundo\nduplo %s%s\ntab %st\n' "$BS" "$BS" "$BS" "$BS" > "$T/f-lf.txt"
  printf 'linha um\r\nancora\r\n' > "$T/a.md"
  caso 0 "fonte LF em alvo CRLF" norm_e_anexa "$T/f-lf.txt" "$T/a.md"

  "$PY" - "$T/a.md" "$T/f-lf.txt" <<'EOF'
import sys
alvo = open(sys.argv[1], "rb").read(); fonte = open(sys.argv[2], "rb").read()
CR=bytes([13]); LF=bytes([10]); BS=bytes([92])
norm = fonte.replace(CR+LF, LF).replace(CR, LF).replace(LF, CR+LF)
lf_sozinho = alvo.count(LF) - alvo.count(CR+LF)
bate = alvo.endswith(norm)
duplo = alvo.count(BS+BS); tab = alvo.count(BS+b"t")
ok = bate and lf_sozinho == 0 and duplo == 1 and tab == 1
print("VERIF conteudo: %s · bate=%s lf_sozinho=%d duplo=%d tab=%d"
      % ("ok" if ok else "FALHOU", bate, lf_sozinho, duplo, tab))
sys.exit(0 if ok else 1)
EOF
  rc=$?; N=$((N+1))
  if [ "$rc" = 0 ]; then echo "  ok   as contrabarras sobreviveram e nao sobrou LF"
  else BAD=$((BAD+1)); echo "  FAIL as contrabarras ou o fim de linha nao sobreviveram"; fi

  printf 'ja em crlf\r\n' > "$T/f-crlf.txt"
  printf 'base\r\n' > "$T/b.md"
  caso 0 "fonte JA CRLF (idempotente)" norm_e_anexa "$T/f-crlf.txt" "$T/b.md"
  "$PY" - "$T/b.md" <<'EOF'
import sys
b = open(sys.argv[1], "rb").read()
CR = bytes([13])
sys.exit(0 if (CR+CR) not in b else 1)
EOF
  rc=$?; N=$((N+1))
  if [ "$rc" = 0 ]; then echo "  ok   nao criou CR duplo"
  else BAD=$((BAD+1)); echo "  FAIL criou CR duplo"; fi

  printf 'sem fim de linha' > "$T/c.md"
  caso 0 "alvo SEM fim de linha final" norm_e_anexa "$T/f-crlf.txt" "$T/c.md"

  : > "$T/vazia.txt"
  printf 'base\r\n' > "$T/d.md"
  caso 1 "fonte VAZIA recusa" norm_e_anexa "$T/vazia.txt" "$T/d.md"
  caso 1 "fonte inexistente recusa" norm_e_anexa "$T/naoexiste" "$T/d.md"
  caso 1 "alvo inexistente recusa" norm_e_anexa "$T/f-crlf.txt" "$T/naoexiste.md"

  "$PY" - "$T/d.md" <<'EOF'
import sys
b = open(sys.argv[1], "rb").read()
sys.exit(0 if b == b"base\r\n" else 1)
EOF
  rc=$?; N=$((N+1))
  if [ "$rc" = 0 ]; then echo "  ok   recusa NAO tocou o alvo"
  else BAD=$((BAD+1)); echo "  FAIL a recusa mexeu no alvo"; fi

  rm -rf "$T"
  echo ""
  [ "$N" -ge 9 ] || { echo "GUARDA: $N caso(s), esperado >= 9" >&2; exit 1; }
  echo "anexa-crlf --self-test: $N caso(s) · $BAD falha(s)"
  [ "$BAD" -eq 0 ] || exit 1
  exit 0
fi

FONTE="${1:?uso: anexa-crlf.sh <fonte> <alvo>}"
ALVO="${2:?uso: anexa-crlf.sh <fonte> <alvo>}"
norm_e_anexa "$FONTE" "$ALVO"
