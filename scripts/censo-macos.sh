#!/usr/bin/env bash
# Censo do par `shim-byte-identity` por run do quality.yml: VERDE, ABANDONADO,
# DISPENSADO ou INDETERMINADO — com o veredito reconciliado e o denominador.
#
# NAO e gate: nada aqui reprova nada. O `run-local-gates.sh` o declara em FORA
# por isso, e tambem porque ele fala com a rede.
#
# ─────────────────────────────────────────────────────────────────────────────
# Por que ele existe: o laco publicado no CLAUDE.md nao via abandono REAL
# ─────────────────────────────────────────────────────────────────────────────
#
# Aquele laco lia `actions/runs/<id>/jobs` e selecionava por `macos`. Medido em
# 2026-11-09, em dois runs no intervalo de 15 minutos, a API de jobs devolveu
# conjunto PARCIAL — e em direcoes opostas:
#
#   run 42669637625 (main)      18 jobs, total_count=18, TODOS success
#                               e o run e `failure`: o GATE nao esta na lista
#   run 42671272723 (PR #326)   10 jobs, total_count=10, o gate ESTA
#                               e os DOIS bracos da matriz NAO
#
# 🔴 Ela e autoconsistente (`total_count` = devolvidos), entao nao e paginacao:
# ela reporta um conjunto parcial. Para o laco antigo isso virava NENHUMA LINHA,
# indistinguivel de "dispensado" — e um abandono real ficou invisivel.
#
# ─────────────────────────────────────────────────────────────────────────────
# O endpoint que amarra ao run certo, e os quatro casos medidos
# ─────────────────────────────────────────────────────────────────────────────
#
#   check-suites/<check_suite_id>/check-runs
#
# 🔴 NAO e `commits/<sha>/check-runs`: um mesmo sha tem run de `push` E de
# `pull_request` (e a duplicata de `gates-locais`/`gates-windows` que o CLAUDE.md
# explica), entao por sha os dois se misturam. O `check_suite_id` vem do proprio
# run e isola.
#
# Medido em 2026-11-09, quatro runs, quatro formas:
#
#   so `gate failure`                                  -> ABANDONADO (invisivel)
#   `macos cancelled` + `ubuntu success` + gate failure -> ABANDONADO (visivel)
#   `shim-byte-identity skipped` + gate success          -> DISPENSADO (#669)
#   os dois bracos `success`                             -> VERDE
#
# LIMITES DECLARADOS:
#   - o veredito e sobre o PAR do shim, nao sobre o run inteiro: um run pode ser
#     `failure` por outro job e sair VERDE aqui, de proposito.
#   - leitura que falha imprime N/A NOMEANDO o run, nunca vira veredito.
#   - um run cujo gate esta AUSENTE e os bracos presentes e ANOMALIA e sai
#     nomeado: foi medido (o run da main de 09/11), e nao se esconde.
set -u
REPO="${REPO_CENSO:-lourivalgarciajunior/trackfw}"
N="${1:-12}"
case "$N" in ''|*[!0-9]*) echo "uso: censo-macos.sh [quantos runs]" >&2; exit 2 ;; esac

problemas=0
runs="$(gh api "repos/$REPO/actions/workflows/quality.yml/runs?per_page=$N" \
  --jq '.workflow_runs[]|"\(.id)\t\(.created_at)\t\(.event)\t\(.head_sha[0:8])\t\(.conclusion // "EM CURSO")\t\(.check_suite_id)"' 2>/dev/null)"
rc=$?
if [ "$rc" -ne 0 ] || [ -z "$runs" ]; then
  echo "N/A: nao consegui listar os runs de quality.yml em $REPO (gh saiu $rc)" >&2
  echo "-> nada afirmado. NAO leia isto como 'sem abandono'." >&2
  exit 2
fi

tot=0; verde=0; aband=0; disp=0; indet=0
# 🔴 O veredito binario "ABERTA/FECHADA" era funcao do N que quem chama escolhe:
# medido em 14/11/2026, no MESMO acervo, N=7 saia FECHADA e N=8 saia ABERTA,
# porque um abandono velho continua dentro da janela ate rolar para fora dela.
# Quem decide passou a ser DERIVADO e independente do N: o abandono mais recente
# e quantos run(s) limpos vieram depois dele. Os runs chegam do mais novo para o
# mais velho, entao o PRIMEIRO abandono que o laco encontra e o mais recente.
ult_ab=""; desde=0; idx=0
echo "censo do par shim-byte-identity  ($REPO)  agora: $(date '+%d/%m %H:%M')"
echo

while IFS=$'\t' read -r id criado evento head conc suite; do
  [ -n "${id:-}" ] || continue
  tot=$((tot+1))
  local_h="$(date -d "$criado" '+%d/%m %H:%M' 2>/dev/null || echo '?')"
  cr="$(gh api "repos/$REPO/check-suites/$suite/check-runs?per_page=100" \
    --jq '.check_runs[]|select(.name|startswith("shim-byte-identity"))|"\(.name)\t\(.conclusion // "EM CURSO")"' 2>/dev/null)"
  if [ -z "$cr" ]; then
    printf '  %s  %-12s %s  N/A: nenhum check-run do shim legivel (suite %s)\n' \
      "$local_h" "$evento" "$head" "$suite"
    problemas=$((problemas+1)); indet=$((indet+1)); continue
  fi

  mac="$(printf '%s\n' "$cr" | awk -F'\t' '$1 ~ /macos-latest/ {print $2}' | head -1)"
  skp="$(printf '%s\n' "$cr" | awk -F'\t' '$1 == "shim-byte-identity" {print $2}' | head -1)"
  gat="$(printf '%s\n' "$cr" | awk -F'\t' '$1 == "shim-byte-identity-gate" {print $2}' | head -1)"

  idx=$((idx+1))
  if [ -n "$mac" ]; then
    case "$mac" in
      success)   v="VERDE"; verde=$((verde+1)) ;;
      cancelled) v="ABANDONADO (visivel)"; aband=$((aband+1))
                 [ -z "$ult_ab" ] && { ult_ab="$local_h $evento $head"; desde=$((idx-1)); } ;;
      *)         v="INDETERMINADO: macos=$mac"; indet=$((indet+1)) ;;
    esac
    [ -z "$gat" ] && v="$v  🔴 ANOMALIA: gate AUSENTE"
  elif [ "${skp:-}" = "skipped" ]; then
    v="DISPENSADO (#669)"; disp=$((disp+1))
  elif [ "${gat:-}" = "failure" ]; then
    v="🔴 ABANDONADO (invisivel: a API de jobs nao o mostra)"; aband=$((aband+1))
    [ -z "$ult_ab" ] && { ult_ab="$local_h $evento $head"; desde=$((idx-1)); }
  else
    v="INDETERMINADO: sem braco, sem skipped, gate=${gat:-ausente}"; indet=$((indet+1))
  fi
  printf '  %s  %-12s %s  run=%s  %s\n' "$local_h" "$evento" "$head" "$conc" "$v"
done <<< "$runs"

echo
echo "denominador: $tot run(s) de quality.yml"
echo "  VERDE $verde · ABANDONADO $aband · DISPENSADO $disp · INDETERMINADO $indet"
echo "reconciliacao: $verde + $aband + $disp + $indet = $(( verde + aband + disp + indet ))  (de $tot)"
if [ $(( verde + aband + disp + indet )) -ne "$tot" ]; then
  echo "🔴 os baldes NAO somam o denominador — classificador quebrado." >&2; exit 2
fi
[ "$tot" -gt 0 ] || { echo "🔴 VACUIDADE: zero runs varridos." >&2; exit 2; }
echo
# 🔴 A ORDEM IMPORTA, e a primeira versao a errou: ela imprimia "nenhum abandono
# no conjunto varrido" e SO DEPOIS o "censo INCOMPLETO", entao leitura rasa
# tomava a primeira linha por veredito. Com N/A no conjunto, "zero abandonos" e
# indistinguivel de "nao consegui olhar" — e e exatamente o defeito que este
# script existe para nao cometer. O veredito sai DEPOIS da checagem de N/A, e
# nao sai nenhum quando ela falha.
if [ "$problemas" -gt 0 ]; then
  echo "🔴 $problemas run(s) N/A: censo INCOMPLETO — NENHUM veredito sobre abandono."
  echo "   (os $aband abandono(s) achados valem como PISO, nunca como total.)"
  exit 2
fi
if [ "$aband" -gt 0 ]; then
  echo "ultimo abandono: $ult_ab"
  echo "  $aband abandono(s) no conjunto · $desde run(s) mais novos que ele, 0 com abandono"
  # 🔴 LIMITE DECLARADO: este braco (`desde` = 0) NAO foi exercitado em 14/11/2026.
  # O N sempre ancora no run mais novo, e no acervo daquele dia o mais novo era
  # verde — nao havia como monta-lo sem `gh` falso no PATH, que e a tecnica usada
  # na falsificacao do leitura-avulsa e nao foi construida aqui. Os outros dois
  # bracos foram medidos nas duas direcoes (N=14 e N=7, mesmo acervo).
  if [ "$desde" -eq 0 ]; then
    echo "🔴 o run MAIS NOVO do conjunto e um abandono: a janela esta ABERTA."
  else
    echo "a janela FECHOU naquele run — nenhum abandono depois dele."
    echo "🔴 E $desde run(s) limpos NAO provam resolucao: o precedente medido e de"
    echo "   1 abandono em 76 bracos ao longo de 15 dias, e dois dias de verde ja"
    echo "   foram indistinguiveis do vao entre janelas em 08/11/2026. 'Fechou'"
    echo "   aqui quer dizer 'sem abandono desde entao', e nada mais."
  fi
else
  echo "nenhum abandono nos $tot run(s) varridos."
  echo "🔴 Isto NAO nomeia o ultimo abandono — o conjunto pode ser curto demais"
  echo "   para alcanca-lo. Medido em 14/11/2026: N=7 nao achava nenhum e N=8"
  echo "   achava um, no MESMO acervo. Para datar o fechamento, aumente o N ate"
  echo "   que esta linha troque pelo bloco 'ultimo abandono'."
fi
