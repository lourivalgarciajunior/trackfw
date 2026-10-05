#!/usr/bin/env bash
# Self-test da vigia do upstream: a FORMA do snapshot e a semantica do laco.
#
# Nao faz NENHUMA chamada de rede: carrega `scripts/vigia-do-upstream.sh` com
# `VIGIA_TEST=1`, que devolve so as funcoes, e exercita-as com entradas fixas.
#
# 🔴 Por que este gate existe. Medido em 2026-10-01: um 503 do GitHub no braco de
# PRs fez o corpo de erro chegar ao comparador, e a vigia publicou
#
#     PR #{"message" -> ...
#
# Dois danos, e o segundo e pior: evento falso, e BASELINE ENVENENADO — o
# comparador move a base para o que leu, entao as transicoes reais daquele ciclo
# somem e, quando a leitura volta ao normal, o acervo inteiro reaparece como
# novidade. A guarda que existia cobria VAZIO, e corpo de erro nao e vazio.
#
# O caso 7 e o que da sentido ao gate: snapshot com UMA linha ruim entre linhas
# boas tem de ser invalidado POR INTEIRO. Filtrar a linha ruim produziria
# snapshot truncado, que e o dano 2 escondido atras de um nome que sugere
# protecao.
#
# O caso 13 e o par do 7 do outro lado: snapshot invalido nao move a base, e
# leitura valida continua emitindo.
set -u
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1

VIGIA="scripts/vigia-do-upstream.sh"
[ -f "$VIGIA" ] || { echo "FALHA: $VIGIA nao existe" >&2; exit 1; }

# shellcheck source=/dev/null
VIGIA_TEST=1 . "$VIGIA"

# As funcoes e as formas tem de ter chegado. Sem esta guarda, um `return` que
# parasse antes faria os casos passarem sobre funcoes inexistentes.
for f in valida_forma snap_main snap_prs snap_com snap_issues novas diff_prs diff_com diff_issues; do
  if ! declare -F "$f" >/dev/null; then
    echo "FALHA: funcao '$f' nao foi carregada de $VIGIA" >&2
    exit 1
  fi
done
for v in RE_MAIN RE_PRS RE_COM RE_ISSUES; do
  if [ -z "${!v:-}" ]; then
    echo "FALHA: forma '$v' nao foi carregada de $VIGIA" >&2
    exit 1
  fi
done

N=0
BAD=0
ok()  { N=$((N+1)); printf '  OK   %s\n' "$1"; }
bad() { N=$((N+1)); BAD=$((BAD+1)); printf '  FAIL %s\n       esperado: [%s]\n       obtido:   [%s]\n' "$1" "$2" "$3"; }
cmp_eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

# O corpo de erro REAL do 503, como o `gh` o entrega na saida padrao.
ERRO='{"message":"Server Error","documentation_url":"https://docs.github.com/rest"}'

SHA_OK='3b2eff0912ab34cd56ef78ab90cd12ef34ab56cd'
PRS_OK='507:OPEN
508:MERGED
509:OPEN'
TAB="$(printf '\t')"
COM_OK="111${TAB}507${TAB}kgsaran${TAB}issue
222${TAB}509${TAB}kgsaran${TAB}pull"

echo "== 1-3: corpo de erro do 503 nao passa em nenhum dos tres bracos"
cmp_eq "503 contra RE_MAIN -> snapshot vazio" "" "$(printf '%s\n' "$ERRO" | valida_forma "$RE_MAIN")"
cmp_eq "503 contra RE_PRS  -> snapshot vazio" "" "$(printf '%s\n' "$ERRO" | valida_forma "$RE_PRS")"
cmp_eq "503 contra RE_COM  -> snapshot vazio" "" "$(printf '%s\n' "$ERRO" | valida_forma "$RE_COM")"

echo "== 4-6: leitura valida atravessa intacta (o outro lado da falsificacao)"
cmp_eq "sha de 40 hexa atravessa"          "$SHA_OK" "$(printf '%s\n' "$SHA_OK" | valida_forma "$RE_MAIN")"
cmp_eq "snapshot de PRs atravessa"         "$PRS_OK" "$(printf '%s\n' "$PRS_OK" | valida_forma "$RE_PRS")"
cmp_eq "snapshot de comentarios atravessa" "$COM_OK" "$(printf '%s\n' "$COM_OK" | valida_forma "$RE_COM")"

echo "== 7: UMA linha ruim invalida o snapshot INTEIRO, nao so a linha"
MISTO="507:OPEN
$ERRO
509:OPEN"
cmp_eq "misto (2 boas + 1 ruim) -> vazio" "" "$(printf '%s\n' "$MISTO" | valida_forma "$RE_PRS")"
cmp_eq "sha valido + lixo       -> vazio" "" "$(printf '%s\n%s\n' "$SHA_OK" "nao-e-sha" | valida_forma "$RE_MAIN")"

echo "== 8-9: transicao real continua emitindo, e so uma vez"
P_ANTES='507:OPEN
508:OPEN'
P_DEPOIS='507:OPEN
508:MERGED'
cmp_eq "508 OPEN -> MERGED emite 1 evento" "PR #508 -> MERGED" "$(diff_prs "$P_ANTES" "$P_DEPOIS")"
cmp_eq "sem mudanca nao emite nada"        ""                  "$(diff_prs "$P_DEPOIS" "$P_DEPOIS")"

echo "== 10-11: autoria — comentario de outro e evento, o nosso nao"
C_ANTES="111${TAB}507${TAB}kgsaran${TAB}issue"
C_OUTRO="111${TAB}507${TAB}kgsaran${TAB}issue
333${TAB}509${TAB}kgsaran${TAB}pull"
C_NOSSO="111${TAB}507${TAB}kgsaran${TAB}issue
444${TAB}509${TAB}lourivalgarciajunior${TAB}pull"
cmp_eq "comentario de kgsaran em PR emite" "COMENTARIO no PR #509 por kgsaran" "$(diff_com "$C_ANTES" "$C_OUTRO")"
cmp_eq "comentario nosso nao emite"        ""                                  "$(diff_com "$C_ANTES" "$C_NOSSO")"

echo "== 12: ordenacao — entrada invertida da o mesmo resultado (guarda 1)"
P_INVERT='508:MERGED
507:OPEN'
cmp_eq "entrada fora de ordem nao inventa evento" "PR #508 -> MERGED" "$(diff_prs "$P_ANTES" "$P_INVERT")"

echo "== 13: semantica do laco — snapshot invalido nao move a base e nao emite"
# Reproduz as linhas do laco onde a guarda 2 age.
ciclo() { # $1 = base, $2 = leitura nova; imprime "<evento>|<base depois>"
  local base="$1" novo="$2" ev=""
  if [ -n "$novo" ] && [ "$novo" != "$base" ]; then
    ev="$(diff_prs "$base" "$novo")"
    base="$novo"
  fi
  printf '%s|%s' "$ev" "$base"
}
cmp_eq "leitura invalida: 0 evento, base intacta" "|$P_ANTES" "$(ciclo "$P_ANTES" "$(printf '%s\n' "$ERRO" | valida_forma "$RE_PRS")")"
cmp_eq "leitura valida: 1 evento, base avanca"    "PR #508 -> MERGED|$P_DEPOIS" "$(ciclo "$P_ANTES" "$(printf '%s\n' "$P_DEPOIS" | valida_forma "$RE_PRS")")"

echo "== 14-17: os BRACOS, exercitados de ponta a ponta sem rede"
# 🔴 Este bloco existe porque a primeira versao deste gate NAO pegava a
# sabotagem: ela exercitava `valida_forma` direto e nunca os bracos, entao tirar
# `| valida_forma` de `snap_prs` deixava o gate verde — teste decorativo, no
# sentido exato da Regra Dura de Reconciliacao. Medido em 2026-10-02.
#
# `gh` e `git` sao substituidos por FUNCAO, que tem precedencia sobre o PATH.
# Nao se cria stub em arquivo de proposito: precisaria de bit de execucao, e
# forcar o bit e vetado neste repo desde 2026-08-29.
gh()  { printf '%s\n' "$ERRO"; }
git() { printf '%s\n' "$ERRO"; }
cmp_eq "snap_prs  com corpo de erro -> vazio" "" "$(snap_prs)"
cmp_eq "snap_com  com corpo de erro -> vazio" "" "$(snap_com)"
cmp_eq "snap_main com corpo de erro -> vazio" "" "$(snap_main)"
unset -f gh git

# O outro lado: braco com leitura valida devolve a leitura. Sem este caso, a
# "correcao" segura seria um braco que rejeita tudo.
gh() { printf '%s\n' "$PRS_OK"; }
cmp_eq "snap_prs  com leitura valida atravessa" "$PRS_OK" "$(snap_prs)"
unset -f gh

echo "== 18-20: o braco de issues passa pelas MESMAS tres guardas"
ISS_OK='526:OPEN:lourivalgarciajunior
527:CLOSED:kgsaran'
cmp_eq "503 contra RE_ISSUES -> snapshot vazio" "" "$(printf '%s
' "$ERRO" | valida_forma "$RE_ISSUES")"
cmp_eq "snapshot de issues atravessa"      "$ISS_OK" "$(printf '%s
' "$ISS_OK" | valida_forma "$RE_ISSUES")"
MISTO_ISS="526:OPEN:kgsaran
$ERRO"
cmp_eq "misto (1 boa + 1 ruim) -> vazio"   ""        "$(printf '%s
' "$MISTO_ISS" | valida_forma "$RE_ISSUES")"

echo "== 21-23: issue nova, issue que fechou, e nada quando nada muda"
I_ANTES='500:OPEN:kgsaran'
I_NOVA='500:OPEN:kgsaran
526:OPEN:kgsaran'
I_FECHOU='500:CLOSED:kgsaran'
cmp_eq "issue nova emite com o autor" "ISSUE #526 aberta por kgsaran" "$(diff_issues "$I_ANTES" "$I_NOVA")"
cmp_eq "issue que fechou emite estado" "ISSUE #500 -> CLOSED"          "$(diff_issues "$I_ANTES" "$I_FECHOU")"
cmp_eq "sem mudanca nao emite nada"    ""                              "$(diff_issues "$I_ANTES" "$I_ANTES")"

echo "== 24: issue NOSSA tambem emite — a assimetria deliberada com o diff_com"
# 🔴 Este e o caso que da sentido ao braco. A #526 foi aberta pela nossa propria
# conta, de outro repositorio consumidor e de outra sessao, e a vigia nao a viu.
# Se alguem "corrigir" o diff_issues para filtrar $ME por simetria com o
# diff_com, este caso reprova — que e exatamente o ponto.
I_NOSSA='500:OPEN:kgsaran
526:OPEN:lourivalgarciajunior'
cmp_eq "issue nossa emite igual" "ISSUE #526 aberta por lourivalgarciajunior" "$(diff_issues "$I_ANTES" "$I_NOSSA")"

echo "== 25-29: snap_issues de ponta a ponta, com jq de verdade"
# 🔴 Os casos acima exercitam a comparacao; estes exercitam o BRACO, que e onde
# vive o filtro de pull request. Sem jq nao ha como aplicar a expressao real do
# script, e o gate FALHA dizendo isso em vez de pular em silencio.
if ! command -v jq >/dev/null 2>&1; then
  echo "FALHA: os casos 25-29 exigem jq para aplicar a expressao --jq real de snap_issues" >&2
  exit 1
fi
# O stub le o --jq dos PROPRIOS argumentos e o aplica com jq real: assim a
# expressao sob teste e a do script, nao uma copia que pode divergir dele.
gh() {
  local jqexp=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --jq) jqexp="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  printf '%s' "$CARGA" | jq -r "$jqexp"
}
CARGA='[{"number":526,"state":"open","user":{"login":"lourivalgarciajunior"}},
        {"number":527,"state":"open","user":{"login":"kgsaran"},"pull_request":{"url":"x"}},
        {"number":500,"state":"closed","user":{"login":"kgsaran"}}]'
# 🔴 A comparacao e por LINHA UNICA de proposito. A primeira versao deste caso
# comparava o snapshot inteiro contra um literal de duas linhas, e reprovou com
# esperado e obtido IDENTICOS na tela: este arquivo e CRLF, entao o literal
# carregava um CR que a saida do jq (LF) nao tem. Mesma familia do CR invisivel
# que so o `od -c` revela.
SAI_ISS="$(snap_issues)"
cmp_eq "o PR 527 da carga NAO aparece" "0" "$(printf %s "$SAI_ISS" | grep -c '^527:')"
cmp_eq "as duas issues de verdade aparecem" "2" "$(printf %s "$SAI_ISS" | grep -cE '^(500|526):')"
cmp_eq "o autor vem na linha da 526" "1" "$(printf %s "$SAI_ISS" | grep -c '^526:OPEN:lourivalgarciajunior$')"
CARGA='[{"number":527,"state":"open","user":{"login":"kgsaran"},"pull_request":{"url":"x"}}]'
cmp_eq "carga SO de PR -> snapshot vazio" "" "$(snap_issues)"
unset -f gh
unset CARGA
gh() { printf '%s
' "$ERRO"; }
cmp_eq "snap_issues com corpo de erro -> vazio" "" "$(snap_issues)"
unset -f gh

# Guarda de vacuidade: um `return` precoce no arquivo da vigia, ou um erro aqui,
# faria o resumo sair com poucos casos e exit 0 — verde por nao ter olhado. O
# numero e conferido contra o minimo esperado, nao contra zero.
echo
if [ "$N" -lt 31 ]; then
  echo "FALHA: guarda de vacuidade — $N caso(s) executado(s), esperado ao menos 31" >&2
  exit 1
fi
echo "check-vigia-forma: $N caso(s) · $BAD falha(s)"
[ "$BAD" -eq 0 ] || exit 1
