#!/usr/bin/env bash
#
# Falsifica o reconhecimento da forma canônica `Caducou:` no
# `check-req-done-com-criterio-aberto.sh`, borda por borda, nas DUAS direções.
#
# A forma é do PRODUTO, não nossa — `LapsedContinuationRe` em
# `internal/roadmapdoc/roadmapdoc.go`, introduzida pelo #519 do upstream, que
# implementa a nossa #514. Este gate existe para que a paridade entre o nosso
# leitor de texto e o do produto seja verificada SEMPRE, e não uma vez.
#
# 🔴 POR QUE UM GATE, E NÃO UMA MEDIÇÃO AVULSA. O ML-1B da
# `ROADMAP-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou...`
# admitia as duas saídas — medir, ou virar gate "se a medição mostrar que medir
# uma vez não basta". A medição mostrou, duas vezes no mesmo dia:
#
#   1. O `check-vigia-forma.sh` que eu havia escrito era DECORATIVO: testava a
#      função de validação direto, então remover a chamada dela do braço deixou
#      o auto-teste em 15/15 verde. Teste que não passa pelo caminho real não
#      prova nada sobre o caminho real.
#   2. A mensagem de falha do próprio gate alvo dizia *"Duas saídas legítimas, e
#      SÓ estas duas"* — verdade até o #519, FALSA depois dele. Quem pegou foi o
#      caso anti-decorativo abaixo. Prosa de gate caduca igual a código.
#
# 🔴 DUAS LIÇÕES DE CUSTO, que decidiram a forma deste script:
#
#   a. Chamar o gate INTEIRO por caso é inviável: ele faz um `git cat-file` por
#      REQ — 75 por chamada. Criar processo no MSYS é caro, e a primeira versão
#      desta falsificação foi MORTA no limite de 30 min. Os 9 casos de borda
#      chamam só a função `censo`, EXTRAÍDA do gate em tempo de execução: zero
#      git, zero varredura do acervo, UMA fonte de verdade — não uma cópia que
#      divergiria em silêncio.
#   b. Os 2 casos de ponta a ponta plantam REQ no `req_dir` REAL, porque o gate
#      lê o `req_dir` do `trackfw.yaml` e deriva as herdadas contra
#      `upstream/main` — fora do repositório ele falharia pela própria guarda.
#      O `trap EXIT` remove as sondas; um SIGKILL não roda trap e deixa resíduo
#      (aconteceu duas vezes em 2026-10-04). A guarda de resíduo abaixo recusa
#      começar com sonda de corrida anterior no acervo, para "verde" nunca
#      significar "medi sobre lixo da vez passada".
#
# 🔴 CUSTO MEDIDO, E ONDE ELE CAI (2026-10-04). Uma passada do gate alvo custa
# **678 s** nesta máquina — 75 `git cat-file` sobre MSYS —, então os 2 casos de
# ponta a ponta somam ~23 min localmente. Em `ubuntu-latest`, onde o agregador
# `run-local-gates.sh` de fato roda (`.github/workflows/local-gates.yml`), criar
# processo é barato e o mesmo laço custa segundos.
#
# A primeira tentativa de rodar os 11 casos de uma vez foi MORTA no limite de
# 30 min, e o kill deixou uma sonda no `req_dir` real — o episódio que motivou a
# guarda de resíduo abaixo. Os dois casos são FUNÇÕES (`e2e_sucesso`,
# `e2e_falha`) justamente para poderem ser verificados um por vez, por extração,
# sem que ninguém reescreva a asserção numa cópia que divergiria em silêncio.
#
# 🔴 Não há interruptor para pular casos, de propósito: um `FALSIFY_ONLY` faria
# os dois casos anti-decorativos sumirem de um CI verde sem ninguém notar.
set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
export LC_ALL=C

GATE="scripts/check-req-done-com-criterio-aberto.sh"
[ -f "$GATE" ] || { echo "falsify-caducou: FALHA — '$GATE' não existe." >&2; exit 1; }

REQD="docs/requisições/claude"
PREFIX="ZZ-SONDA-CADUCOU"

TMP=$(mktemp -d)
limpa() { rm -f "$REQD/$PREFIX"*.md; rm -rf "$TMP"; }
trap limpa EXIT

# GUARDA DE RESÍDUO — sonda de corrida anterior invalida a medição inteira.
resto=$(ls "$REQD/$PREFIX"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$resto" != "0" ]; then
  echo "falsify-caducou: GUARDA — ${resto} sonda(s) de corrida anterior em '$REQD'." >&2
  echo "  Uma corrida morta por SIGKILL não roda o trap. Remova-as e rode de novo:" >&2
  echo "    rm -f '$REQD/$PREFIX'*.md" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# A função `censo` sai do GATE, não de uma cópia. Se o gate deixar de tê-la,
# este script falha nomeando — nunca passa por não ter achado o que medir.
# ---------------------------------------------------------------------------
eval "$(sed -n '/^censo() {/,/^}$/p' "$GATE")"
if ! declare -F censo >/dev/null; then
  echo "falsify-caducou: FALHA — não extraí a função 'censo()' de $GATE." >&2
  echo "  O gate foi reescrito e esta falsificação perdeu o alvo. Reaponte-a," >&2
  echo "  🔴 nunca a faça copiar a lógica: a cópia divergiria em silêncio." >&2
  exit 1
fi

N=0; BAD=0
ok()  { N=$((N+1)); printf '  ok   %s\n' "$1"; }
bad() { N=$((N+1)); BAD=$((BAD+1)); printf '  FAIL %s\n       esperado [%s] obtido [%s]\n' "$1" "$2" "$3" >&2; }

TAB=$(printf '\t')

# caso <rótulo> <esperado "sob lapsed fora total"> <linhas após o critério...>
caso() {
  local rot="$1" esp="$2"; shift 2
  local f="$TMP/c.md"
  { printf '%s\n' '## Acceptance Criteria' ''
    printf '%s\n' '- [ ] criterio inverificavel'
    for l in "$@"; do printf '%s\n' "$l"; done
  } > "$f"
  local got; got=$(censo "$f")
  if [ "$got" = "$esp" ]; then ok "$rot"; else bad "$rot" "$esp" "$got"; fi
}

echo "== direção A — a forma VÁLIDA conta como 'lapsed', e não como aberto"
echo "   (afirma: o gate reconhece a forma do produto, logo não acusa caducado justificado)"
caso "2 espaços + justificativa"       "0 1 0 1" "  Caducou: a v8 removeu o produto"
caso "4 espaços + justificativa"       "0 1 0 1" "    Caducou: quatro espacos tambem valem"
caso "sem espaço após os dois-pontos"  "0 1 0 1" "  Caducou:texto colado"

echo "== direção B — cada borda violada volta a contar como ABERTO"
echo "   (afirma: o reconhecimento é ESTRITO, logo a palavra não é porta para fechar critério)"
caso "sem justificativa"               "1 0 0 1" "  Caducou:"
caso "coluna 0"                        "1 0 0 1" "Caducou: sem indentacao"
caso "um espaço só"                    "1 0 0 1" " Caducou: um espaco"
caso "tabulação em vez de espaço"      "1 0 0 1" "${TAB}Caducou: tab nao vale"
caso "linha VAZIA no meio"             "1 0 0 1" "" "  Caducou: justificativa"

echo "== cerca de código — nada é contado, nem aberto nem caducado"
echo "   (afirma: exemplo em documentação não fecha e não infla critério real)"
{ printf '%s\n' '## Acceptance Criteria' '' '```' '- [ ] exemplo em doc' '  Caducou: exemplo' '```'
} > "$TMP/cerca.md"
got=$(censo "$TMP/cerca.md")
if [ "$got" = "0 0 0 0" ]; then ok "cerca: 0 0 0 0"; else bad "cerca" "0 0 0 0" "$got"; fi

# ---------------------------------------------------------------------------
# ANTI-DECORATIVO — duas passadas pelo GATE DE VERDADE, uma por caminho.
#
# 🔴 Sem isto, "a função reconhece a forma" não diz nada sobre o VEREDITO do
# gate: foi exatamente o erro que eu cometi no `check-vigia-forma.sh`. E os dois
# caminhos são necessários porque, quando o gate acusa, ele sai ANTES do resumo
# — esperar "acusa E conta o caducado" na MESMA passada é insatisfazível.
# ---------------------------------------------------------------------------
echo "== anti-decorativo — o gate inteiro, nos DOIS caminhos"

cabeca() { printf '%s\n' '---' 'status: Done' 'date: 2026-10-04' 'adr: ""' 'roadmap: ""' '---' '' '## Acceptance Criteria' ''; }

e2e_sucesso() {
  # caminho de SUCESSO: só caducado -> passa, e CONTA o caducado no resumo
  { cabeca; printf '%s\n' '- [ ] criterio inverificavel' '  Caducou: a v8 removeu o produto'; } > "$REQD/$PREFIX-ok.md"
  out=$(bash "$GATE" 2>&1); rc=$?
  cad=$(printf '%s' "$out" | grep -ao '[0-9][0-9]* critério(s) com' | tail -1 | grep -o '^[0-9]*')
  acu=$(printf '%s' "$out" | grep -c "$PREFIX-ok")
  printf '       rc=%s · acusa=%s · caducados=%s\n' "$rc" "$acu" "${cad:-0}"
  if [ "$rc" = "0" ] && [ "$acu" = "0" ] && [ "${cad:-0}" -ge 1 ]; then
    ok "só caducado: o gate passa e CONTA o caducado no resumo"
  else
    bad "só caducado" "rc=0 acusa=0 caducados>=1" "rc=$rc acusa=$acu caducados=${cad:-0}"
  fi
  rm -f "$REQD/$PREFIX"*.md
}

e2e_falha() {
  # caminho de FALHA: caducado + aberto -> acusa SÓ o aberto, e a falha nomeia as 3 saídas
  { cabeca; printf '%s\n' '- [ ] criterio inverificavel' '  Caducou: justificado' '- [ ] criterio sem justificativa'; } > "$REQD/$PREFIX-mix.md"
  out=$(bash "$GATE" 2>&1); rc=$?
  acu=$(printf '%s' "$out" | grep -c "$PREFIX-mix")
  men=$(printf '%s' "$out" | grep -c 'NÃO estão nesta conta')
  tres=$(printf '%s' "$out" | grep -c 'TRÊS saídas')
  printf '       rc=%s · acusa=%s · menciona-caducado=%s · três-saídas=%s\n' "$rc" "$acu" "$men" "$tres"
  if [ "$rc" != "0" ] && [ "$acu" = "1" ] && [ "$men" = "1" ] && [ "$tres" = "1" ]; then
    ok "caducado + aberto: acusa só o aberto, e a falha nomeia o caducado e as TRÊS saídas"
  else
    bad "caducado + aberto" "rc!=0 acusa=1 menciona=1 três=1" "rc=$rc acusa=$acu men=$men tres=$tres"
  fi
  rm -f "$REQD/$PREFIX"*.md
}

e2e_sucesso
e2e_falha

sobrou=$(ls "$REQD/$PREFIX"*.md 2>/dev/null | wc -l | tr -d ' ')
printf '       sondas remanescentes no acervo: %s\n' "$sobrou"
[ "$sobrou" = "0" ] || { echo "falsify-caducou: FALHA — a limpeza das sondas não fechou." >&2; BAD=$((BAD+1)); }

# GUARDA DE VACUIDADE: menos casos que o esperado significa extração quebrada,
# não acervo limpo — e sairia VERDE por não ter medido nada.
echo ""
if [ "$N" -lt 11 ]; then
  echo "falsify-caducou: GUARDA — ${N} caso(s) executado(s), esperado ao menos 11." >&2
  echo "  Menos casos que o declarado é instrumento quebrado, não ausência de defeito." >&2
  exit 1
fi

echo "check-req-done-caducou-falsify: ${N} caso(s) · ${BAD} falha(s)"
[ "$BAD" -eq 0 ] || exit 1
