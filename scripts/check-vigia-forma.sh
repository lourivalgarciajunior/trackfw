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
for f in valida_forma snap_main snap_prs snap_com novas diff_prs diff_com; do
  if ! declare -F "$f" >/dev/null; then
    echo "FALHA: funcao '$f' nao foi carregada de $VIGIA" >&2
    exit 1
  fi
done
for v in RE_MAIN RE_PRS RE_COM; do
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

# Guarda de vacuidade: um `return` precoce no arquivo da vigia, ou um erro aqui,
# faria o resumo sair com poucos casos e exit 0 — verde por nao ter olhado. O
# numero e conferido contra o minimo esperado, nao contra zero.
echo
if [ "$N" -lt 19 ]; then
  echo "FALHA: guarda de vacuidade — $N caso(s) executado(s), esperado ao menos 19" >&2
  exit 1
fi
echo "check-vigia-forma: $N caso(s) · $BAD falha(s)"
[ "$BAD" -eq 0 ] || exit 1
