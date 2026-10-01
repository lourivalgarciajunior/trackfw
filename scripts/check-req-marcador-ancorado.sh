#!/usr/bin/env bash
# Acusa REQ nossa que TEM marcador `ADR:` ou `Roadmap:` no texto mas nao o tem
# ANCORADO em inicio de linha e com valor — o defeito da
# `REQ-2026-09-05-reqs-que-passam-so-por-prosa-tres-do-acervo-sem-link-real-de-adr`.
#
# ─────────────────────────────────────────────────────────────────────────────
# POR QUE ISTO E UM SCRIPT, E NAO O GATE DA WAVE 0 DAQUELE ROADMAP
#
# A logica morava dentro de `python -c "` com DEZ linhas, no bloco de gates. Pela
# regra 5 de docs/cli-parity.md cada linha do bloco e UM comando, executado num
# `sh -c` proprio: aquelas dez linhas nunca rodaram como um programa. Nove das doze
# linhas do bloco reprovam `sh -n` sozinhas.
#
# 🔴 E o gate carregava um defeito a mais, de autoria: as duas pernas do `or` eram
#
#     empty = (m+' \n') in c or (m+' \r\n') in c
#
# e as contrabarras foram COMIDAS por heredoc na hora de escrever. O que ficou no
# arquivo tem newline literal nas duas pernas — ou seja, as duas ficaram IDENTICAS,
# e o caso CRLF deixou de ser verificado. Medido em 2026-10-01 com `cat -A`.
#
# Aqui o CRLF nao e remendado com uma segunda perna: ele e removido na entrada
# (`tr -d '\r'`), o que cobre os dois fins de linha com um caminho so. Os roadmaps
# e REQs deste repo estao em CRLF (156 de 156 linhas no arquivo medido), entao sem
# isso o `$` do grep nunca casa.
# ─────────────────────────────────────────────────────────────────────────────
#
# Como os outros gates so nossos, NAO tem alvo no Makefile — arquivo compartilhado
# com o upstream. Arquivo novo em scripts/ nao cria divergencia.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

YAML="trackfw.yaml"
[ -f "$YAML" ] || { echo "FALHA: $YAML nao encontrado em $ROOT_DIR"; exit 1; }

# req_dir sai do yaml, nunca chumbado: o nosso e `docs/requisições`, nao o default.
REQ_DIR="$(awk -F': *' '/^req_dir:/{gsub(/["'"'"']/,"",$2); print $2; exit}' "$YAML")"
[ -n "$REQ_DIR" ] || REQ_DIR="docs/req"
[ -d "$REQ_DIR" ] || { echo "FALHA: req_dir '$REQ_DIR' nao existe"; exit 1; }

mapfile -t REQS < <(find "$REQ_DIR" -type f -name '*.md' | LC_ALL=C sort)

if [ "${#REQS[@]}" -eq 0 ]; then
  echo "FALHA (vacuidade): zero REQs em '$REQ_DIR' — o padrao de busca quebrou"
  exit 1
fi

# 🔴 UMA passada de awk sobre todos os arquivos, de proposito. A primeira versao
# fazia `grep` por REQ e por marcador — 3 spawns x 2 marcadores x 73 REQs — e nao
# terminou em 120 s nesta maquina: criar processo no MSYS e caro. Um gate que nao
# termina nao e gate.
RELATORIO="$(awk '
  function decide(arq) {
    if (arq == "") return
    for (i = 1; i <= nm; i++) {
      m = marc[i]
      if (!tem[m]) continue
      n_tem++
      if (vazio[m])      { n_vazio++;    continue }
      if (ancorado[m])   { n_ancorado++; continue }
      printf "RUIM\t%s\t%s\n", arq, m
    }
  }
  BEGIN { nm = 2; marc[1] = "ADR:"; marc[2] = "Roadmap:" }
  FNR == 1 { decide(anterior); anterior = FILENAME; for (i=1;i<=nm;i++) { m=marc[i]; tem[m]=0; vazio[m]=0; ancorado[m]=0 } }
  {
    linha = $0
    sub(/\r$/, "", linha)
    for (i = 1; i <= nm; i++) {
      m = marc[i]
      if (index(linha, m) == 0) continue
      tem[m] = 1
      # "marcador + um espaco + fim de linha": valor vazio. E o que o template
      # emite; nao e prosa, e nao conta como violacao (decisao do ML original).
      if (linha ~ (m " $")) vazio[m] = 1
      # Ancorado em inicio de linha E com ao menos um caractere nao-branco de valor.
      if (linha ~ ("^" m "[ \t]*[^ \t]")) ancorado[m] = 1
    }
  }
  END {
    decide(anterior)
    printf "CONTA\t%d\t%d\t%d\n", n_tem, n_ancorado, n_vazio
  }
' "${REQS[@]}")"

n_tem="$(printf '%s\n'  "$RELATORIO" | awk -F'\t' '$1=="CONTA"{print $2}')"
n_ancorado="$(printf '%s\n' "$RELATORIO" | awk -F'\t' '$1=="CONTA"{print $3}')"
n_vazio="$(printf '%s\n'    "$RELATORIO" | awk -F'\t' '$1=="CONTA"{print $4}')"
mapfile -t RUINS < <(printf '%s\n' "$RELATORIO" | awk -F'\t' '$1=="RUIM"{printf "%s  marcador %s aparece no texto, mas nunca ancorado com valor\n", $2, $3}')

echo "REQs varridas            ${#REQS[@]}   (req_dir='$REQ_DIR')"
echo "marcadores encontrados   $n_tem"
echo "  com valor ancorado     $n_ancorado"
echo "  vazios (template)      $n_vazio"
echo "  so em prosa            ${#RUINS[@]}"

# Guarda de vacuidade: zero marcador encontrado em dezenas de REQs significa que o
# predicado parou de casar, nao que o acervo esta limpo.
if [ "$n_tem" -eq 0 ]; then
  echo
  echo "FALHA (vacuidade): zero marcadores em ${#REQS[@]} REQs — o predicado quebrou."
  exit 1
fi

if [ "${#RUINS[@]}" -gt 0 ]; then
  echo
  echo "FALHA: ${#RUINS[@]} REQ(s) com marcador so em prosa:"
  for l in "${RUINS[@]}"; do echo "  $l"; done
  exit 1
fi

echo
echo "OK: todo marcador presente esta ancorado com valor, ou vazio pelo template."
