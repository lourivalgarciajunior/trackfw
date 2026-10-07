#!/usr/bin/env bash
# Reprova quando o diff FECHA CICLO e nao toca o handoff.
#
# Uso:  check-handoff-cobre-o-ciclo.sh
#       check-handoff-cobre-o-ciclo.sh --self-test
#
# ─── POR QUE ESTE GATE EXISTE ────────────────────────────────────────────────
#
# O CLAUDE.md exige atualizar o docs/agents-working-context.md "ao iniciar e ao
# encerrar cada ciclo", em DOIS lugares: nas Regras especificas e no passo 3 do
# Agent Protocol. Nao havia gate, e o passo falhou duas vezes em 24 horas:
#
#   2026-10-03 a 10-06   quatro ciclos fechados sem entrada; o arquivo ficou
#                        tres dias parado
#   2026-10-06 23:04     a entrada escrita as 23:04 nao cobria a frente do
#                        alarme, que fechou as 23:52 — PRs #207 e #208
#
# 🔴 Nas DUAS vezes quem pegou foi o usuario. O validate, o barrier e os catorze
# gates locais ficaram verdes com a lacuna aberta, porque nenhum deles olha para
# isso.
#
# E a segunda falha e ESTRUTURAL, nao descuido: a atualizacao e o ultimo passo do
# ciclo, o ciclo que escreve a entrada nao cobre a si mesmo, e o seguinte depende
# de alguem lembrar. Passo obrigatorio cuja unica salvaguarda e memoria humana
# falha por construcao.
#
# ─── O DISCRIMINANTE ─────────────────────────────────────────────────────────
#
# "Encerrar um ciclo" tem assinatura no diff: um roadmap sai de wip/ e entra em
# done/. E isso que o gate procura — nao "o PR e grande", nao "passou tempo",
# que nao sao verificaveis.
#
# Medido contra as duas PRs reais de 2026-10-06, pela base de merge:
#
#   8415b22e (#207, a entrada)   roadmap->done: 0 · handoff: 1   -> passa
#   2a97172e (#208, o alarme)    roadmap->done: 1 · handoff: 0   -> REPROVA
#
# 🔴 A #208 e o caso que escapou NA VIDA REAL. E ela que da sentido ao gate, e e
# por isso que o self-test a exercita por SHA em vez de usar caso sintetico.
#
# ─── O QUE ELE NAO FAZ, declarado ────────────────────────────────────────────
#
#   - Nao le o CONTEUDO da entrada. Presenca e verificavel; qualidade de texto
#     nao, e fingir que e produziria falso-verde pior que a ausencia.
#   - Nao cobra entrada em PR que nao fecha ciclo. Sync, correcao de gate e
#     documentacao nao movem roadmap para done/ — cobrar todos faria o gate ser
#     desligado na primeira semana.
#   - Nao cobre o "ao iniciar" da mesma exigencia: inicio de ciclo nao tem
#     assinatura no diff, e inventar uma daria gate que reprova por adivinhacao.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

HANDOFF='docs/agents-working-context.md'
BASE_REF=${BASE_REF:-origin/main}

# veredito <n_roadmaps_para_done> <tocou_handoff> -> rc
#   rc=0 ok   ·   rc=1 fecha ciclo sem tocar o handoff
veredito() {
  local mv="$1" aw="$2"
  case "$mv" in ''|*[!0-9]*) echo "  GUARDA: contagem de roadmap invalida: '$mv'" >&2; return 2 ;; esac
  case "$aw" in ''|*[!0-9]*) echo "  GUARDA: contagem de handoff invalida: '$aw'" >&2; return 2 ;; esac
  if [ "$mv" -eq 0 ]; then
    printf '  nenhum roadmap entrando em done/ neste diff -> nada a cobrar\n'
    return 0
  fi
  if [ "$aw" -gt 0 ]; then
    printf '  %s roadmap(s) para done/ e o handoff foi tocado -> ok\n' "$mv"
    return 0
  fi
  printf '  %s roadmap(s) para done/ e o handoff NAO foi tocado\n' "$mv"
  return 1
}

# conta <base> <ponta> -> "<n_done> <n_handoff>"
conta() {
  local base="$1" ponta="$2" d
  d=$(git diff --name-only "$base" "$ponta" 2>/dev/null)
  printf '%s %s' \
    "$(printf '%s\n' "$d" | grep -cE 'docs/roadmaps/.*/done/')" \
    "$(printf '%s\n' "$d" | grep -cF "$HANDOFF")"
}

# ─── AUTO-TESTE ──────────────────────────────────────────────────────────────
if [ "${1:-}" = "--self-test" ]; then
  N=0; BAD=0
  caso() { # <rc esperado> <rotulo> <mv> <aw>
    local esp="$1" rot="$2"; shift 2
    veredito "$@" >/dev/null 2>&1; local got=$?
    N=$((N+1))
    if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
    else BAD=$((BAD+1)); printf '  FAIL %s — esperado rc=%s, obtido rc=%s\n' "$rot" "$esp" "$got"; fi
  }

  echo "== a decisao, nos quatro quadrantes =="
  caso 1 "fecha ciclo e NAO toca o handoff"        1 0
  caso 0 "fecha ciclo e toca o handoff"            1 1
  caso 0 "nao fecha ciclo e nao toca"              0 0
  caso 0 "nao fecha ciclo e toca de todo jeito"    0 1
  echo "== leitura invalida nao vira veredito =="
  caso 2 "contagem de roadmap vazia"               "" 1
  caso 2 "contagem de handoff nao-numerica"        1 "x"

  echo "== os DOIS CASOS REAIS, por SHA — e a #208 e o que escapou =="
  # 🔴 Caso sintetico nao substitui estes: a #208 e exatamente o diff que passou
  # pelo validate, pelo barrier e pelos catorze gates sem ninguem notar.
  reais=0
  for par in "2a97172e:1:a #208 (alarme) REPROVA" "8415b22e:0:a #207 (entrada) passa"; do
    sha=${par%%:*}; resto=${par#*:}; esp=${resto%%:*}; rot=${resto#*:}
    if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      echo "  GUARDA: o commit $sha nao e alcancavel — o caso real nao pode ser verificado" >&2
      exit 1
    fi
    base=$(git merge-base "$sha" 24938d28 2>/dev/null)
    if [ -z "$base" ]; then
      echo "  GUARDA: sem base de merge para $sha — nao ha o que comparar" >&2
      exit 1
    fi
    read -r mv aw <<EOF
$(conta "$base" "$sha")
EOF
    veredito "$mv" "$aw" >/dev/null 2>&1; got=$?
    N=$((N+1)); reais=$((reais+1))
    if [ "$got" = "$esp" ]; then printf '  ok   %s  (done=%s handoff=%s)\n' "$rot" "$mv" "$aw"
    else BAD=$((BAD+1)); printf '  FAIL %s — esperado rc=%s, obtido rc=%s (done=%s handoff=%s)\n' "$rot" "$esp" "$got" "$mv" "$aw"; fi
  done

  echo ""
  # GUARDA DE VACUIDADE em dois niveis: o total, e os casos REAIS em particular.
  # Sem o segundo, perder os dois SHAs deixaria o gate verde sobre so os
  # sinteticos — que e o caso que nao pegou o defeito na vida real.
  if [ "$reais" -lt 2 ]; then
    echo "GUARDA: $reais caso(s) real(is) exercitado(s), esperado 2" >&2
    exit 1
  fi
  if [ "$N" -lt 8 ]; then
    echo "GUARDA: $N caso(s), esperado ao menos 8" >&2
    exit 1
  fi
  echo "check-handoff-cobre-o-ciclo --self-test: $N caso(s) · $BAD falha(s) · $reais real(is)"
  [ "$BAD" -eq 0 ] || exit 1
  exit 0
fi

# ─── EXECUCAO ────────────────────────────────────────────────────────────────
echo "check-handoff-cobre-o-ciclo:"

if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null 2>&1; then
  echo "  FALHA: a ref de comparacao '$BASE_REF' nao existe." >&2
  echo "  Sem ela o diff sai vazio e o gate passaria descrevendo o nada." >&2
  echo "  Rode 'git fetch origin', ou passe BASE_REF=." >&2
  exit 1
fi

# 🔴 BASE DE MERGE, nunca dois pontos. `main..HEAD` responde "o que ha la e nao
# aqui", que e outra pergunta — e e a terceira vez que o dois-pontos engana
# neste fork; a ultima reprovou o PR #192 com a divergencia real em zero.
BASE=$(git merge-base HEAD "$BASE_REF" 2>/dev/null)
if [ -z "$BASE" ]; then
  echo "  FALHA: nao ha base de merge entre HEAD e '$BASE_REF'." >&2
  exit 1
fi

read -r MV AW <<EOF
$(conta "$BASE" HEAD)
EOF

printf '  base %s · roadmap(s) para done/: %s · handoff tocado: %s\n' "${BASE:0:8}" "$MV" "$AW"

if [ "$MV" -eq 0 ] && [ "$AW" -eq 0 ] && [ "$(git rev-list --count "$BASE"..HEAD)" -eq 0 ]; then
  echo "  diff VAZIO (rodando sobre a propria base) -> passa por vacuidade, nao por verificacao"
  exit 0
fi

veredito "$MV" "$AW"
rc=$?
case "$rc" in
  0) exit 0 ;;
  2) echo "  -> leitura insuficiente: NAO ha veredito. Reprova de proposito." >&2; exit 1 ;;
  *)
    echo "" >&2
    echo "  🔴 ESTE DIFF FECHA CICLO E NAO ATUALIZA O HANDOFF." >&2
    echo "     O CLAUDE.md exige o $HANDOFF ao encerrar cada ciclo," >&2
    echo "     em dois lugares: Regras especificas e passo 3 do Agent Protocol." >&2
    echo "" >&2
    echo "     Acrescente a entrada no TOPO do arquivo, com a medicao do ciclo —" >&2
    echo "     nao o resumo. O que importa no handoff e o numero que a proxima" >&2
    echo "     sessao nao conseguiria derivar sozinha." >&2
    exit 1
    ;;
esac
