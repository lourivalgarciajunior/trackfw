#!/usr/bin/env bash
# Leitura avulsa do upstream: UMA passada, sem laco, para sessao FRIA.
#
# NAO e gate: nada aqui reprova nada. O `run-local-gates.sh` o declara em FORA
# por isso, e tambem porque ele fala com a rede.
#
# ─────────────────────────────────────────────────────────────────────────────
# Por que existe, medido em 2026-11-09
# ─────────────────────────────────────────────────────────────────────────────
#
# O usuario pede "veja se kleber evoluiu" e a varredura era digitada na hora.
# Em 09/11 ela devolveu "nada novo" QUATRO vezes seguidas enquanto havia uma
# resposta do mantenedor esperando desde 08/11 15:43 local — ele comentou a nossa
# #676 quatro minutos depois de eu abri-la.
#
# 🔴 O daemon NAO era o cego: o `snap_com` do `vigia-do-upstream.sh` le
# `repos/<repo>/issues/comments` e o `diff_com` emite `COMENTARIO na issue #N`.
# Cego era o conjunto que eu media a mao — main + lista de PR + tag —, e
# comentario em issue aberta nao estava nele. Zero com sonda errada e cegueira,
# nao ausencia.
#
# ─────────────────────────────────────────────────────────────────────────────
# As quatro propriedades, cada uma por um modo de falha ja medido nesta casa
# ─────────────────────────────────────────────────────────────────────────────
#
#   1. FONTE UNICA. Os reads vem das funcoes do proprio daemon, carregadas por
#      `VIGIA_TEST=1 . vigia-do-upstream.sh` — o mesmo mecanismo que o
#      `check-vigia-forma.sh` usa. Reimplementar um read aqui criaria dois
#      instrumentos que podem discordar sobre o mesmo fato, que e exatamente o
#      defeito que o `check-copia-do-path-esta-atras` pagou quando contava uma
#      verdade diferente do passo irmao.
#
#   2. O BRACO QUE O DAEMON NAO DA A UMA SESSAO FRIA. O daemon relata o que
#      MUDOU desde a base dele; sessao fria nao tem base. O que ela precisa e o
#      ESTADO: quais das NOSSAS issues abertas tem o ultimo comentario de outra
#      pessoa — ou seja, a bola esta com a gente. Isso nao se deriva de diff.
#
#   3. LEITURA QUE FALHOU NUNCA VIRA "NADA NOVO". Cada braco que nao puder ser
#      lido imprime `N/A` NOMEANDO o motivo, e o script sai 2. Silencio com cara
#      de verde foi o que custou o dia que originou este arquivo.
#
#   4. DENOMINADOR IMPRESSO. "Zero issues com a bola do nosso lado" so quer
#      dizer algo ao lado de quantas issues nossas foram varridas.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIGIA="$ROOT/scripts/vigia-do-upstream.sh"

[ -f "$VIGIA" ] || { echo "FALHA: $VIGIA nao existe — a fonte unica dos reads" >&2; exit 2; }
# shellcheck source=/dev/null
VIGIA_TEST=1 . "$VIGIA"   # traz REPO, ME, snap_main, snap_prs, snap_com, snap_issues

cd "$ROOT" || exit 2
problemas=0

na() { echo "  N/A: $1 — nada afirmado aqui. NAO leia isto como 'nada novo'."; problemas=$((problemas+1)); }

# hora local a partir de um instante ISO em UTC. Relato em local e regra desta
# casa; repassar o sufixo Z poe tudo 3 h no futuro.
local_de() { [ -n "${1:-}" ] && date -d "$1" '+%d/%m %H:%M' 2>/dev/null || echo "?"; }

echo "leitura-avulsa-do-upstream  ($REPO)  agora: $(date '+%d/%m %H:%M')"
echo

# ── 1. main ──────────────────────────────────────────────────────────────────
echo "main do upstream:"
M="$(snap_main)"
if [ -z "$M" ]; then
  na "nao consegui ler refs/heads/main (rede, ou forma invalida)"
else
  atras="$(git rev-list --count "HEAD..$M" 2>/dev/null)"
  [ -n "$atras" ] || atras="? (o commit nao esta neste checkout — rode git fetch upstream)"
  echo "  ${M:0:8}   commits a trazer: $atras"
fi
echo

# ── 2. PRs ───────────────────────────────────────────────────────────────────
echo "PRs do upstream (janela do daemon):"
P="$(snap_prs)"
if [ -z "$P" ]; then
  na "nao consegui ler repos/$REPO/pulls"
else
  abertos="$(printf '%s\n' "$P" | grep -c ':OPEN$')"
  echo "  abertos: $abertos   na janela: $(printf '%s\n' "$P" | grep -c .)"
  printf '%s\n' "$P" | grep ':OPEN$' | while IFS=: read -r n s; do echo "    #$n -> $s"; done
fi
echo

# ── 3. o braco que o daemon nao da a uma sessao fria ─────────────────────────
# As NOSSAS issues abertas, e quem falou por ULTIMO em cada uma.
echo "NOSSAS issues abertas no upstream, e de quem e a bola:"
# 🔴 O `gh` roda SEM cano, e o `sort` vem depois, em dois passos. Com
# `gh ... | sort` o `$?` seria o do SORT — que sai 0 mesmo quando o `gh` falha —,
# e aí uma leitura falha viraria "denominador: 0", indistinguivel de "nenhuma
# issue nossa aberta". Mesma familia do cano-mascara-exit-code, e eu a cometi
# aqui antes de falsificar.
nossas_cru="$(gh api "repos/$REPO/issues?state=open&creator=$ME&per_page=50" \
  --jq '.[] | select(.pull_request == null) | .number' 2>/dev/null)"
rc_nossas=$?
nossas="$(printf '%s\n' "$nossas_cru" | sort -n)"
if [ "$rc_nossas" -ne 0 ]; then
  na "nao consegui listar as nossas issues abertas (gh saiu $rc_nossas)"
else
  total="$(printf '%s\n' "$nossas" | grep -c .)"
  echo "  denominador: $total issue(s) nossa(s) aberta(s)"
  nossa_vez=0
  for n in $nossas; do
    ult="$(gh api "repos/$REPO/issues/$n/comments?per_page=100" \
      --jq 'if length == 0 then "—\t—" else (.[-1] | "\(.user.login)\t\(.created_at)") end' 2>/dev/null)"
    if [ -z "$ult" ]; then
      echo "    #$n   N/A: nao consegui ler os comentarios desta issue"
      problemas=$((problemas+1))
      continue
    fi
    au="${ult%%	*}"; quando="${ult##*	}"
    if [ "$au" = "—" ]; then
      echo "    #$n   sem comentario ainda                       -> aguardando ele"
    elif [ "$au" = "$ME" ]; then
      echo "    #$n   ultimo: $au ($(local_de "$quando"))  -> aguardando ele"
    else
      echo "    #$n   🔴 ultimo: $au ($(local_de "$quando"))  -> A BOLA E NOSSA, leia"
      nossa_vez=$((nossa_vez+1))
    fi
  done
  echo "  com a bola do nosso lado: $nossa_vez de $total"
fi
echo

# ── 4. comentarios recentes de outro autor, em qualquer issue ou PR do repo ──
# Este braco NAO substitui o 3: ele e a janela de 30 mais recentes do repo
# inteiro, entao issue nossa antiga pode estar FORA dela — e foi por isso que o
# braco 3 existe. Serve para ver movimento em coisa que nao e nossa.
echo "comentarios recentes de outro autor (janela de 30 do repo inteiro):"
C="$(snap_com)"
if [ -z "$C" ]; then
  na "nao consegui ler repos/$REPO/issues/comments"
else
  vistos="$(printf '%s\n' "$C" | awk -F'\t' -v me="$ME" '$3 != me {print $4" #"$2" por "$3}' | sort -u)"
  if [ -z "$vistos" ]; then
    echo "  nenhum de outro autor na janela   (janela: $(printf '%s\n' "$C" | grep -c .) comentario(s))"
  else
    printf '%s\n' "$vistos" | sed 's/^/    /'
  fi
fi
echo

# ── 5. as branches do upstream ───────────────────────────────────────────────
# 🔴 LIDAS DO REMOTO, por `git ls-remote`, NUNCA de refs/remotes locais.
# `git fetch` nao poda sem configuracao, e a leitura local ja mediu CEMITERIO
# aqui: 135 refs locais contra 4 branches reais, com as 4 MAIS NOVAS dando 404.
# Ver a secao "git fetch nao poda" do CLAUDE.md.
#
# Custo: ZERO chamadas de API — e protocolo git, como o `snap_main` do daemon.
#
# 🔴 Este braco NAO vem do daemon, e a razao fica escrita: o daemon nao tem read
# de branches: ele vigia main, PRs, comentarios e issues. Nao e duplicacao — e o
# primeiro sitio. Se o daemon ganhar esse braco um dia, este passa a reusa-lo,
# como os outros tres.
#
# Por que ele existe: em 09/11, com a `main` parada e zero PR, a UNICA coisa que
# respondia "ele andou?" era a branch de trabalho dele — e eu tive de conferi-la
# a mao, que e exatamente o defeito que este script existe para fechar.
echo "branches do upstream (lidas do REMOTO, nao de refs locais):"
# 🔴 O nome da branch padrao e DERIVADO do symref do remoto, nunca `main`
# chumbado: o `snap_main` do daemon pede refs/heads/main de proposito, mas aqui
# o conjunto e todas as branches, e chumbar o nome quebraria num repo cuja
# padrao seja outra. Sem symref legivel, cai em `main` e DIZ que caiu.
DEFAULT_BR="$(git ls-remote --symref "https://github.com/$REPO.git" HEAD 2>/dev/null \
  | sed -n 's|^ref: refs/heads/\([^ \t]*\).*|\1|p' | head -1)"
if [ -z "$DEFAULT_BR" ]; then
  DEFAULT_BR=main
  echo "  (symref ilegivel — assumindo '$DEFAULT_BR' como padrao; a contagem de commits pode mentir)"
fi
# a base das contagens e o tip da branch padrao lido no braco 1, nao um ref local
sha_main="${M:-}"
B="$(git ls-remote --heads "https://github.com/$REPO.git" 2>/dev/null)"
if [ -z "$B" ]; then
  na "nao consegui ler as branches de $REPO (git ls-remote)"
else
  nb="$(printf '%s\n' "$B" | grep -c .)"
  echo "  denominador: $nb branch(es) no remoto"
  printf '%s\n' "$B" | while read -r sha ref; do
    nome="${ref#refs/heads/}"
    if git cat-file -e "$sha" 2>/dev/null; then
      quando="$(git log -1 --format=%ad --date=format-local:'%d/%m %H:%M' "$sha")"
      if [ "$nome" = "$DEFAULT_BR" ]; then extra=""
      else
        n="$(git rev-list --count "$sha" "^$sha_main" 2>/dev/null)"
        extra="  ${n:-?} commit(s) sobre $DEFAULT_BR"
      fi
      echo "    ${sha:0:8}  $nome   tip de $quando$extra"
    else
      echo "    ${sha:0:8}  $nome   🔴 tip NAO esta neste checkout — ha commit novo. rode: git fetch upstream --prune"
    fi
  done
  # cemiterio: ref local de rastreamento que o remoto nao tem mais
  mortas="$(comm -23 \
    <(git for-each-ref --format='%(refname:short)' "refs/remotes/upstream" | sed 's|^upstream/||' | sort) \
    <(printf '%s\n' "$B" | awk '{sub(/^refs\/heads\//,"",$2); print $2}' | sort))"
  nm="$(printf '%s\n' "$mortas" | grep -c .)"
  if [ "$nm" -eq 0 ]; then
    echo "  refs locais que o remoto nao tem (cemiterio): 0"
  else
    echo "  🔴 refs locais que o remoto NAO tem (cemiterio): $nm — rode: git fetch upstream --prune"
    printf '%s\n' "$mortas" | sed 's/^/      /'
  fi
fi
echo

if [ "$problemas" -gt 0 ]; then
  echo "🔴 $problemas braco(s) N/A: esta leitura esta INCOMPLETA."
  exit 2
fi
echo "leitura completa: os cinco bracos responderam."
