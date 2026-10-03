#!/usr/bin/env bash
# Vigia do upstream: commit na main, PR mudando de estado, comentario novo de outro autor.
#
# Daemon de laco infinito. NAO e gate: nada aqui reprova nada, e o agregador
# `run-local-gates.sh` o declara em FORA por isso (executa-lo o penduraria).
#
# ─────────────────────────────────────────────────────────────────────────────
# Reescrita de 2026-09-29: de 40 chamadas de API por ciclo para 2.
# ─────────────────────────────────────────────────────────────────────────────
#
# A versao anterior percorria uma lista fixa de 39 issues com UMA chamada GraphQL
# cada, a cada 90 s — ~1.600 chamadas/hora, disparadas em rajada de 39 seguidas.
#
# 🔴 Nao foi a cota HORARIA que estourou. Medido em 2026-09-29, no momento da
# recusa:
#
#     core     4962/5000      graphql  4888/5000
#     e mesmo assim: "GraphQL: API rate limit already exceeded"
#
# Com quase toda a cota sobrando, o que cortou foi o limite SECUNDARIO — o de
# rajada, que o GitHub aplica a quem dispara muitas chamadas em sequencia curta,
# independente do saldo horario. Ler so o `remaining` faz diagnosticar errado:
# ele fica alto justamente no caso que esta falhando.
#
# Custo por ciclo, e ele e o invariante desta vigia:
#
#   commits  git ls-remote                 0 chamadas  — protocolo git, nao API.
#                                          Ja era assim; fica registrado para
#                                          ninguem "melhorar" trocando por `gh`.
#   PRs      gh api repos/<repo>/pulls     1 chamada
#   comentarios  repos/<repo>/issues/comments?sort=created&direction=desc
#                                          1 chamada — devolve os comentarios
#                                          mais recentes de TODAS as issues do
#                                          repo, abertas e fechadas.
#
# E a cobertura MELHOROU junto com o custo: a lista fixa de 39 nunca veria um
# comentario numa issue nova. Agora nao ha lista.
#
# ─────────────────────────────────────────────────────────────────────────────
# As TRES guardas, cada uma por um modo de falha medido
# ─────────────────────────────────────────────────────────────────────────────
#
#   1. ORDENACAO — `comm` exige entrada ordenada na MESMA colacao. Entrada fora
#      de ordem fez a vigia publicar duas rajadas de 7 eventos que nao existiam
#      (2026-09-11). `LC_ALL=C` dos dois lados.
#
#   2. LEITURA QUE FALHOU NAO E DADO — snapshot vazio nao entra na comparacao e
#      nao move a base. Sem isso, uma falha passageira vira "mudou", e a volta ao
#      normal vira "mudou" de novo.
#
#   3. FORMA DO SNAPSHOT, por braco e sobre o snapshot INTEIRO (2026-10-02).
#      🔴 A guarda 2 cobria VAZIO, nao FORMA — e corpo de erro do GitHub nao e
#      vazio. Medido em 2026-10-01: um 503 no braco de PRs fez o corpo de erro
#      chegar ao comparador, e a vigia publicou
#
#          PR #{"message" -> ...        (e depois saiu 255)
#
#      Dois danos, e o segundo e pior: (a) evento falso; (b) BASELINE
#      ENVENENADO, porque o comparador move a base para o que leu — as
#      transicoes reais daquele ciclo somem, e quando a leitura volta ao normal
#      o acervo inteiro reaparece como novidade.
#
#      🔴 Por que o snapshot INTEIRO e nao linha por linha: filtrar a linha ruim
#      e deixar as boas produz snapshot TRUNCADO, que e exatamente o dano (b),
#      agora escondido atras de um nome que sugere protecao. Uma linha fora da
#      forma invalida o snapshot todo, e o snapshot invalido e tratado como
#      leitura que falhou — a guarda 2 cuida do resto.
#
#      Residuo declarado: a validacao e de FORMA, nao de VERDADE. Um corpo
#      bem-formado e errado (resposta de outro repositorio, por exemplo) passa.
#      Nao ha como distinguir isso de fora sem uma segunda fonte, e a vigia tem
#      uma so.
set -u
REPO=kgsaran/trackfw
ME=lourivalgarciajunior
export LC_ALL=C

# Raiz derivada do proprio caminho do script. No scratchpad isto era um `cd`
# chumbado em /c/dev/...; num script do repositorio seria defeito.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Formas validas, uma por braco.
RE_MAIN='^[0-9a-f]{40}$'
RE_PRS='^[0-9]+:(MERGED|OPEN|CLOSED)$'
RE_COM=$'^[0-9]+\t[0-9]+\t[^\t]+\t(issue|pull)$'

# valida_forma <regex> — le o snapshot do stdin e devolve-o INTEIRO se TODA linha
# casar; nada se alguma nao casar. "Nada" = leitura que falhou (guarda 2).
valida_forma() {
  local re="$1" buf
  buf="$(cat)"
  [ -n "$buf" ] || return 0
  if printf '%s\n' "$buf" | grep -qvE "$re"; then
    return 0
  fi
  printf '%s\n' "$buf"
}

snap_main() {
  git ls-remote "https://github.com/$REPO.git" refs/heads/main 2>/dev/null \
    | awk '{print $1}' | valida_forma "$RE_MAIN"
}

# REST, nao `gh pr list` — e a diferenca importa.
#
# `gh pr list` fala GraphQL, e foi justamente o balde do GraphQL que o limite
# SECUNDARIO cortou. Medido em 2026-09-29, no mesmo minuto:
#     gh pr list ...            -> "API rate limit already exceeded"  (vazio)
#     gh api repos/.../pulls    -> 478:CLOSED 477:CLOSED ...          (ok)
# Sao baldes distintos; com REST a vigia nao depende do que estourou.
#
# 🔴 E o motivo de o estado ser DERIVADO e nao lido: o REST devolve `closed` para
# PR mesclado — `merged` nao existe como estado ali. Copiar o `.state` cru faria
# todo merge aparecer como CLOSED, e a vigia deixaria de distinguir "o mantenedor
# mesclou" de "o mantenedor fechou sem mesclar", que e a diferenca que interessa.
snap_prs() {
  gh api "repos/$REPO/pulls?state=all&per_page=15" \
    --jq '.[] | "\(.number):\(if .merged_at then "MERGED" elif .state == "open" then "OPEN" else "CLOSED" end)"' \
    2>/dev/null | sort | valida_forma "$RE_PRS"
}

# Uma linha por comentario recente: <id>\t<numero>\t<autor>\t<issue|pull>
# O tipo sai do html_url (.../issues/123#... ou .../pull/123#...), que e o unico
# discriminante barato: o payload de issues/comments nao marca PR de outra forma.
snap_com() {
  gh api "repos/$REPO/issues/comments?sort=created&direction=desc&per_page=30" \
    --jq '.[] | [(.id|tostring), (.issue_url|split("/")|last), .user.login, (if (.html_url|test("/pull/")) then "pull" else "issue" end)] | join("\t")' \
    2>/dev/null | sort | valida_forma "$RE_COM"
}

# linhas de $2 que nao estao em $1 — as duas ORDENADAS pela mesma colacao
novas() { comm -13 <(printf '%s\n' "$1" | sort) <(printf '%s\n' "$2" | sort); }

# Um evento por comentario novo de OUTRO autor. Comentario nosso nao e evento.
diff_com() {
  novas "$1" "$2" | while IFS="$(printf '\t')" read -r _id n au tipo; do
    [ -n "$n" ] || continue
    [ "$au" = "$ME" ] && continue
    case "$tipo" in
      pull) echo "COMENTARIO no PR #$n por $au" ;;
      *)    echo "COMENTARIO na issue #$n por $au" ;;
    esac
  done
}

diff_prs() { novas "$1" "$2" | while IFS=: read -r n s; do [ -n "$n" ] && echo "PR #$n -> $s"; done; }

# sourced pelo teste: so as funcoes, sem o laco
[ "${VIGIA_TEST:-0}" = 1 ] && return 0 2>/dev/null

cd "$ROOT" || exit 1

M0=$(snap_main || true)
P0=$(snap_prs || true)
C0=$(snap_com || true)
# A base nao pode nascer de leitura falha: senao a primeira comparacao valida
# publica o acervo inteiro como se fosse novidade.
while [ -z "$C0" ]; do sleep 30; C0=$(snap_com || true); done

while true; do
  sleep 90

  M1=$(snap_main || true)
  [ -z "$M0" ] && M0="$M1"
  if [ -n "$M1" ] && [ "$M1" != "$M0" ]; then
    echo "MAIN do upstream mudou: ${M0:0:8} -> ${M1:0:8} — ha commit para trazer"
    M0="$M1"
  fi

  P1=$(snap_prs || true)
  [ -z "$P0" ] && P0="$P1"
  if [ -n "$P1" ] && [ "$P1" != "$P0" ]; then
    diff_prs "$P0" "$P1"
    P0="$P1"
  fi

  C1=$(snap_com || true)
  # vazio = leitura falhou, ou forma invalida (guarda 3): nao comparo e nao movo
  # a base.
  if [ -n "$C1" ] && [ "$C1" != "$C0" ]; then
    diff_com "$C0" "$C1"
    C0="$C1"
  fi
done
