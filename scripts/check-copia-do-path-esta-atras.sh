#!/usr/bin/env bash
# Acusa quando a copia do trackfw no PATH esta ATRAS do binario da arvore.
#
# Uso:  check-copia-do-path-esta-atras.sh
#       check-copia-do-path-esta-atras.sh --self-test
#
# ─── POR QUE ESTE GATE EXISTE ────────────────────────────────────────────────
#
# Desde o #527 do upstream, os hooks de guard chamam `trackfw guard <nome>`
# RESOLVIDO NO PATH. Nesta maquina o PATH entrega uma COPIA do binario da arvore,
# posta em %APPDATA%/npm/trackfw.exe porque nenhuma release publicada tem `guard`
# (ver o roteiro no CLAUDE.md e o alarme check-contorno-dos-shims-caducou.sh).
#
# O upstream-sync.sh reconstroi bin/trackfw e bin/trackfw.exe depois do merge, mas
# ate 2026-10-07 NAO refazia essa copia. Resultado: a cada sync a cerca passava a
# rodar por um binario atrasado, em silencio, em TODOS os projetos da maquina.
#
# 🔴 Quem pegou a defasagem foi o usuario, nao instrumento. Mesma forma do
# contorno dos shims, que nasceu sem alarme, e do done/.gitkeep, que ficou doze
# dias depois de o upstream consertar a causa.
#
# ─── O DISCRIMINANTE, e por que NAO e a versao ───────────────────────────────
#
# Medido em 2026-10-07, com a copia de 06/10 22:17 e a arvore de 07/10 14:32:
#
#   trackfw --version  (copia velha)   trackfw 9.2.0
#   trackfw --version  (arvore nova)   trackfw 9.2.0     <- MESMA string
#   cmp dos dois binarios              DIFEREM (20439040 vs 20459520 bytes)
#
# O #527 e o #528 entraram DEPOIS da tag v9.2.0, entao a versao nao se move. Quem
# distingue e o CONTEUDO. Um gate que comparasse `--version` sairia verde sobre
# uma copia de qualquer idade.
#
# ─── O QUE ELE NAO FAZ, declarado ────────────────────────────────────────────
#
#   - Nao copia nada. Ele acusa; copiar e do upstream-sync.sh, que e ferramenta.
#     Gate que conserta sozinho esconde a mudanca — mesma decisao do
#     check-contorno-dos-shims-caducou.sh.
#   - Nao roda no CI. Em ubuntu-latest nao existe %APPDATA%/npm, o contorno nao
#     esta em vigor e ZERO cenario seria exercitado. Esta em FORA do
#     run-local-gates.sh COM MOTIVO, pelo mesmo precedente do
#     check-platform-predicates.sh.
#   - Nao afirma que o binario do PATH FUNCIONA. Isso e outra pergunta, e quem a
#     responde e o efeito (o hook bloqueando), nao a comparacao de bytes.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

MARCA_CONTORNO='pre-guard-bak'

# veredito <arvore_existe> <destino_existe> <contorno_em_vigor> <iguais> -> rc
#   rc=0 em dia   ·   rc=1 ATRAS   ·   rc=3 N/A com razao   ·   rc=2 leitura invalida
#
# 🔴 A ordem importa: a premissa e checada ANTES da comparacao. Sem isso, "nao
# iguais" com destino ausente sairia como ATRAS, e o remedio sugerido seria errado.
veredito() {
  local arv="$1" dst="$2" cont="$3" iguais="$4"
  for v in "$arv" "$dst" "$cont" "$iguais"; do
    case "$v" in sim|nao) ;; *) echo "  GUARDA: valor fora da forma: '$v'" >&2; return 2 ;; esac
  done
  if [ "$arv" = "nao" ]; then
    printf '  N/A: o binario da arvore nao existe — rode o build antes de medir\n'
    return 3
  fi
  if [ "$cont" = "nao" ]; then
    printf '  N/A: o contorno dos shims nao esta em vigor aqui — nao ha copia gerida para comparar\n'
    return 3
  fi
  if [ "$dst" = "nao" ]; then
    printf '  N/A: nao ha trackfw resolvido no PATH — nada a comparar\n'
    return 3
  fi
  if [ "$iguais" = "sim" ]; then
    printf '  a copia do PATH e byte a byte o binario da arvore -> em dia\n'
    return 0
  fi
  printf '  a copia do PATH DIFERE do binario da arvore -> ATRAS\n'
  return 1
}

# resolve_destino -> imprime o caminho do arquivo REAL que o PATH entrega, ou nada
#
# 🔴 O `command -v` no MSYS devolve o nome SEM extensao para um .exe, e — pior —
# o `[ -f ]` do MSYS responde VERDADE para esse nome sem extensao, embora o
# arquivo nao exista. Medido em 2026-10-07, na pasta do npm:
#
#   ls -1                                 trackfw.exe   (nao ha 'trackfw' pelado)
#   [ -f .../trackfw ]                    VERDADE       <- o MSYS mente
#   Test-Path -LiteralPath .../trackfw    False         <- o Win32 nega
#
# Entao o `.exe` e tentado PRIMEIRO. Testar o nome pelado antes faria o gate
# imprimir um caminho que nao existe — foi o que a primeira versao fez. A
# comparacao de bytes funcionava por acidente, pelo mesmo fallback do MSYS.
resolve_destino() {
  local p
  p=$(bash -lc 'command -v trackfw' 2>/dev/null) || return 0
  [ -n "$p" ] || return 0
  case "$p" in *.exe) [ -f "$p" ] && printf '%s' "$p"; return 0 ;; esac
  if [ -f "${p}.exe" ]; then printf '%s' "${p}.exe"; return 0; fi
  if [ -f "$p" ]; then printf '%s' "$p"; return 0; fi
  return 0
}

# contorno_em_vigor <dir> -> imprime sim|nao
#
# 🔴 A PRIMEIRA VERSAO ESTAVA ERRADA, e o erro apareceu no dia da reversao.
# Ela testava "existe algum *.pre-guard-bak na pasta", e sobra de reversao
# satisfaz isso: o `npm i -g` escreve shims novos e os .pre-guard-bak FICAM.
#
# Medido em 2026-10-07, logo depois de reverter para a 9.3.0 publicada:
#
#   contorno em vigor (detector velho)   sim      <- ERRADO
#   veredito                             ATRAS    <- falso positivo
#   remedio impresso    cp bin/trackfw.exe .../npm/trackfw
#                       ^ isso sobrescreveria o SHIM BASH do npm com um .exe,
#                         reinstalando o contorno sem ninguem pedir
#
# A definicao do contorno e que os shims estao MOVIDOS, nao que existe backup.
# Entao: o bak presente E o shim real AUSENTE. O `.ps1` e o marcador canonico —
# e ele que ganha do `.exe` no PowerShell, e tem extensao, logo o `[ -f ]` do
# MSYS nao mente sobre ele.
contorno_em_vigor() {
  local d="$1"
  [ -f "$d/trackfw.ps1.pre-guard-bak" ] || { printf 'nao'; return 0; }
  [ -f "$d/trackfw.ps1" ] && { printf 'nao'; return 0; }
  printf 'sim'
}

# ─── AUTO-TESTE ──────────────────────────────────────────────────────────────
if [ "${1:-}" = "--self-test" ]; then
  N=0; BAD=0
  caso() { # <rc esperado> <rotulo> <arv> <dst> <cont> <iguais>
    local esp="$1" rot="$2"; shift 2
    veredito "$@" >/dev/null 2>&1; local got=$?
    N=$((N+1))
    if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
    else BAD=$((BAD+1)); printf '  FAIL %s — esperado rc=%s, obtido rc=%s\n' "$rot" "$esp" "$got"; fi
  }

  echo "== a decisao =="
  caso 0 "tudo presente e iguais -> em dia"              sim sim sim sim
  caso 1 "tudo presente e DIFEREM -> ATRAS"              sim sim sim nao
  echo "== premissa ausente e N/A, nunca ATRAS =="
  caso 3 "arvore sem binario"                            nao sim sim nao
  caso 3 "contorno fora de vigor"                        sim sim nao nao
  caso 3 "nada resolvido no PATH"                        sim nao sim nao
  echo "== a PRECEDENCIA da premissa sobre a comparacao =="
  # 🔴 Sem a ordem certa, estas tres sairiam rc=1 e mandariam recopiar sobre um
  # destino que nao existe, ou sobre maquina que nao usa copia gerida.
  caso 3 "arvore ausente ganha de 'iguais'"              nao sim sim sim
  caso 3 "contorno fora de vigor ganha de 'iguais'"      sim sim nao sim
  echo "== leitura invalida nao vira veredito =="
  caso 2 "valor vazio"                                   sim sim sim ""
  caso 2 "valor fora do dominio"                         sim sim sim talvez

  echo ""
  echo "== o DETECTOR DO CONTORNO, contra pastas reais =="
  # 🔴 Estes quatro casos existem por um falso positivo MEDIDO: no dia da
  # reversao, a sobra dos *.pre-guard-bak fez o detector velho dizer "em vigor",
  # o gate gritou ATRAS e o remedio impresso sobrescreveria o shim do npm.
  # Caso sintetico aqui e legitimo porque o que se afirma e a LEITURA DA PASTA,
  # e a pasta e construtivel.
  TMPD=$(mktemp -d 2>/dev/null) || TMPD=""
  if [ -n "$TMPD" ]; then
    cdcaso() { # <esperado> <rotulo> <arquivos...>
      local esp="$1" rot="$2"; shift 2
      local d="$TMPD/c$N"
      mkdir -p "$d"
      for f in "$@"; do : > "$d/$f"; done
      local got; got=$(contorno_em_vigor "$d")
      N=$((N+1))
      if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
      else BAD=$((BAD+1)); printf '  FAIL %s — esperado %s, obtido %s\n' "$rot" "$esp" "$got"; fi
    }
    cdcaso sim "shims movidos: so o bak"                 trackfw.ps1.pre-guard-bak trackfw.exe
    cdcaso nao "APOS REVERSAO: bak E shim real juntos"   trackfw.ps1.pre-guard-bak trackfw.ps1 trackfw.cmd
    cdcaso nao "instalacao limpa do npm: so os shims"    trackfw.ps1 trackfw.cmd trackfw
    cdcaso nao "pasta vazia"
    rm -rf "$TMPD" 2>/dev/null
  else
    printf '  (nao consegui criar diretorio temporario — casos nao exercitados)\n'
  fi

  echo ""
  echo "== o resolvedor de destino, contra o ambiente REAL =="
  # Guarda de vacuidade do proprio resolvedor: se ele devolver caminho, o arquivo
  # tem de existir. Devolver caminho inexistente seria pior que devolver nada.
  D=$(resolve_destino)
  if [ -n "$D" ]; then
    N=$((N+1))
    if [ -f "$D" ]; then printf '  ok   resolveu para arquivo existente: %s\n' "$D"
    else BAD=$((BAD+1)); printf '  FAIL resolveu para caminho inexistente: %s\n' "$D"; fi
  else
    printf '  (o PATH nao resolve trackfw aqui — caso nao exercitado)\n'
  fi

  echo ""
  if [ "$N" -lt 13 ]; then
    echo "GUARDA: $N caso(s), esperado ao menos 13" >&2
    exit 1
  fi
  echo "check-copia-do-path-esta-atras --self-test: $N caso(s) · $BAD falha(s)"
  [ "$BAD" -eq 0 ] || exit 1
  exit 0
fi

# ─── EXECUCAO ────────────────────────────────────────────────────────────────
echo "check-copia-do-path-esta-atras:"

GOEXE=$(go env GOEXE 2>/dev/null)
ARV="bin/trackfw${GOEXE}"
[ -f "$ARV" ] || ARV="bin/trackfw"

DST=$(resolve_destino)

ARV_EX=nao; [ -f "$ARV" ] && ARV_EX=sim
DST_EX=nao; [ -n "$DST" ] && DST_EX=sim

# O contorno esta em vigor quando os shims estao MOVIDOS — nao quando ha sobra.
CONT=nao
if [ -n "$DST" ]; then
  CONT=$(contorno_em_vigor "$(dirname "$DST")")
fi

IGUAIS=nao
if [ "$ARV_EX" = sim ] && [ "$DST_EX" = sim ]; then
  cmp -s "$ARV" "$DST" && IGUAIS=sim
fi

printf '  arvore : %s  (existe: %s)\n' "$ARV" "$ARV_EX"
printf '  PATH   : %s  (existe: %s · contorno em vigor: %s)\n' "${DST:-<nenhum>}" "$DST_EX" "$CONT"

veredito "$ARV_EX" "$DST_EX" "$CONT" "$IGUAIS"
rc=$?
case "$rc" in
  0) exit 0 ;;
  3) echo "  -> N/A: nada afirmado aqui. NAO leia isto como 'em dia'." ; exit 0 ;;
  2) echo "  -> leitura insuficiente: NAO ha veredito. Reprova de proposito." >&2; exit 1 ;;
  *)
    echo "" >&2
    echo "  🔴 A COPIA DO PATH ESTA ATRAS DO BINARIO DA ARVORE." >&2
    echo "     Os hooks de guard de TODOS os projetos desta maquina executam essa" >&2
    echo "     copia, nao o binario da arvore. Enquanto ela estiver atras, a cerca" >&2
    echo "     roda por codigo velho." >&2
    echo "" >&2
    echo "     🔴 E o 'trackfw --version' NAO acusa isto: as duas versoes dizem a" >&2
    echo "     mesma coisa, porque o guard entrou depois da tag publicada." >&2
    echo "" >&2
    echo "     Remedio:  cp $ARV $DST" >&2
    echo "     E confira por EFEITO depois: o hook tem de bloquear 'git commit'" >&2
    echo "     pelas DUAS ferramentas, Bash e PowerShell." >&2
    exit 1
    ;;
esac
