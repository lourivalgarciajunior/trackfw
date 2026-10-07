#!/usr/bin/env bash
# Acende quando o contorno dos shims do npm CADUCAR — nao quando ele existir.
#
# Uso:  check-contorno-dos-shims-caducou.sh
#       check-contorno-dos-shims-caducou.sh --self-test
#
# ─── POR QUE ESTE GATE EXISTE ────────────────────────────────────────────────
#
# Em 2026-10-06 o merge do #527 do upstream deixou a cerca de git INERTE nesta
# maquina: o hook passou a chamar `trackfw guard <nome>`, resolvido no PATH, e o
# PATH tinha a 9.1.0 do npm, sem o subcomando. O contorno foi instalar o binario
# COMPILADO DA ARVORE em %APPDATA%/npm/trackfw.exe e MOVER os tres shims do npm
# para *.pre-guard-bak.
#
# O contorno esta escrito no CLAUDE.md com o roteiro de reversao, e a propria
# nota admitia o furo: "nenhum gate verifica a reversao".
#
# 🔴 E o custo de nao notar aqui e maior que nos contornos anteriores deste
# repositorio, porque este virou GLOBAL: o `trackfw update harness` migrou SETE
# CLIs de agente para `trackfw guard`, e todos dependem do PATH. Um
# `npm i -g trackfw` antes da release recria os shims, o .exe deixa de ser
# resolvido, e todas as cercas de todos os projetos ficam inertes de uma vez.
#
# ─── O QUE ELE AFIRMA, E O QUE ELE NAO AFIRMA ────────────────────────────────
#
# O contorno tem duas metades, e so uma e verificavel de fora:
#
#   os shims estao movidos?            so nesta maquina
#   existe release publicada com guard? em qualquer lugar com rede
#
# 🔴 Este gate afirma a SEGUNDA, de proposito. A primeira e conhecida-verdadeira
# ate alguem reverter, e checa-la num runner de CI daria sempre "contorno
# ausente" — passaria DESCREVENDO O VAZIO, com uma mensagem que soa como boa
# noticia. E a forma exata do defeito que o run-local-gates.sh existe para
# fechar. A segunda e o que muda sem ninguem avisar.
#
# ─── A DERIVACAO ─────────────────────────────────────────────────────────────
#
#   commit do guard   782f5767… "feat(guard): hooks de guard viram trackfw guard"
#   tag que o contem  git tag --contains <commit>
#   publicado         npm view trackfw version
#
#   VERMELHO quando existe tag contendo o commit E a versao publicada e >= ela.
#
# ─── TRES GUARDAS, CADA UMA POR UM MODO DE FALHA MEDIDO NESTE REPOSITORIO ────
#
#   1. COMMIT INALCANCAVEL REPROVA. Sem `git fetch upstream --tags`, o
#      `git tag --contains` devolve vazio — indistinguivel de "nenhuma release
#      tem o guard". Mesma forma do check-inherited-req.sh, que falha dizendo o
#      motivo em vez de derivar zero e passar.
#   2. `npm` INACESSIVEL REPROVA. Rede fora faria a leitura sair vazia e o gate
#      concluir "nao ha release" — verde por cegueira.
#   3. PREMISSA AUSENTE E RELATADA, NAO ASSUMIDA. Se o CLAUDE.md ja nao
#      documentar o contorno, alguem o aposentou: o gate diz isso e passa.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

# O commit que introduziu `trackfw guard`. Chumbado de proposito: e um ponto
# fixo da historia do upstream, nao um valor que envelhece.
GUARD_COMMIT=782f5767ad1a2e1de3939a305206cd74e80c9060
# 🔴 A MARCA MUDOU em 2026-10-07, no dia da reversao, e por um defeito de desenho.
# Ela era 'pre-guard-bak' — a string que o roteiro usa. Mas o REGISTRO historico do
# contorno tambem cita essa string, e registro e para ficar: com a marca antiga o
# alarme continuaria VERMELHO depois de revertido, para sempre. Ruido permanente e
# o que faz aviso deixar de ser lido — e e exatamente o defeito que levamos ao
# upstream na issue #530, cometido aqui.
#
# A premissa passou a ser DECLARACAO EXPLICITA, nao presenca de string em prosa.
MARCA_CONTORNO='<!-- contorno-dos-shims: ATIVO -->'

# contorno_declarado <arquivo> -> imprime sim|nao
contorno_declarado() {
  local f="$1"
  [ -r "$f" ] || { printf 'ilegivel'; return 0; }
  if grep -q "$MARCA_CONTORNO" "$f"; then printf 'sim'; else printf 'nao'; fi
}

# As duas leituras do mundo, injetaveis SO para a sonda. Quando injetadas, o
# gate imprime aviso — execucao de sonda nunca pode passar por veredito real.
: "${SONDA_TAG_GUARD:=}"
: "${SONDA_NPM_LATEST:=}"

# compara_versao <a> <b> -> 0 se a >= b, 1 caso contrario. Semver simples,
# sem pre-release: as tags deste produto sao vX.Y.Z.
compara_versao() {
  local a="${1#v}" b="${2#v}"
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<EOF
$a
EOF
  IFS=. read -r b1 b2 b3 <<EOF
$b
EOF
  a1=${a1:-0}; a2=${a2:-0}; a3=${a3:-0}
  b1=${b1:-0}; b2=${b2:-0}; b3=${b3:-0}
  for p in "$a1" "$a2" "$a3" "$b1" "$b2" "$b3"; do
    case "$p" in ''|*[!0-9]*) return 2 ;; esac
  done
  if [ "$a1" -ne "$b1" ]; then [ "$a1" -gt "$b1" ]; return $?; fi
  if [ "$a2" -ne "$b2" ]; then [ "$a2" -gt "$b2" ]; return $?; fi
  [ "$a3" -ge "$b3" ]
}

# veredito <tag-com-guard> <npm-latest> -> imprime o veredito, devolve rc
#   rc=0 contorno ainda necessario (verde)
#   rc=1 contorno CADUCOU (vermelho)
#   rc=2 nao da para decidir (leitura falhou)
veredito() {
  local tag="$1" pub="$2"
  # 🔴 A FORMA do publicado e validada ANTES de qualquer ramo, e nao so no
  # ramo que compara. Achado pela falsificacao da guarda 2, em 2026-10-06: sem
  # tag, o `pub` nao era conferido em lugar nenhum, entao leitura-lixo (ou so
  # espacos, que o `-z` nao pega) saia VERDE. O veredito estaria certo por
  # acidente — e o denominador impresso, errado. Ver a memoria
  # "verde sem denominador nao e evidencia".
  local limpo
  # A classe POSIX cobre espaco, TAB, CR, NL, FF e VT sem nenhuma contrabarra,
  # e a forma importa. A versao anterior desta linha foi escrita a mao com
  # sequencias de escape; elas foram comidas no transporte e o arquivo ficou com
  # TAB e NEWLINE literais. 🔴 O CR foi entao removido pela NORMALIZACAO DO GIT
  # no commit, em silencio: o blob commitado deixou de tirar justamente o CR que
  # o npm do Windows emite. O self-test passou nas DUAS versoes, porque nenhum
  # caso dele carregava CR — a diferenca so apareceu contando bytes do blob.
  limpo=$(printf '%s' "$pub" | tr -d '[:space:]')
  if [ -z "$limpo" ]; then
    echo "  GUARDA: a versao publicada no npm veio VAZIA (ou so espacos)." >&2
    echo "  Rede fora faria o gate concluir 'nao ha release' — verde por cegueira." >&2
    return 2
  fi
  case "$limpo" in
    v*) limpo=${limpo#v} ;;
  esac
  case "$limpo" in
    ""|*[!0-9.]*|*..*|.*|*.)
      echo "  GUARDA: versao publicada fora da forma X.Y.Z: '$pub'." >&2
      return 2 ;;
  esac
  if [ -z "$tag" ]; then
    printf '  nenhuma tag do upstream contem o commit do guard · publicado: %s\n' "$pub"
    echo "  -> o contorno dos shims CONTINUA necessario."
    return 0
  fi
  # 🔴 O status e capturado ANTES de qualquer `if`. Medido pelo proprio
  # self-test deste gate, em 2026-10-06: a primeira versao fazia
  #
  #     if compara_versao "$pub" "$tag"; then ...; fi
  #     local rc=$?            # <- NAO e o status de compara_versao
  #
  # e `$?` ali e o status do PROPRIO `if` (0 quando a condicao falha e nao ha
  # `else`), nao o da condicao. O caso "versao fora da forma" saia VERDE em vez
  # de recusar o veredito — leitura invalida virando veredito, que e exatamente
  # o que a guarda 2 existe para impedir. E `local rc=$?` piora: o proprio
  # `local` mexe em `$?`.
  local cmp
  # 🔴 A comparacao usa o valor LIMPO, nao o cru. A primeira versao validava
  # `limpo` e comparava `$pub`: com CR de verdade o terceiro componente saia
  # "0" mais CR, nao-numerico, e o gate devolvia "nao da para decidir" em vez
  # do veredito. Quem pegou foi o caso de CR do self-test; o meu teste manual
  # anterior tinha dado certo porque o escape foi comido no transporte e o
  # valor chegou limpo — acerto por acidente.
  compara_versao "$limpo" "${tag#v}"; cmp=$?
  if [ "$cmp" -eq 2 ]; then
    echo "  GUARDA: versao fora da forma vX.Y.Z — tag='$tag' publicado='$pub'." >&2
    return 2
  fi
  if [ "$cmp" -eq 0 ]; then
    printf '  tag com guard: %s · publicado: %s  -> publicado JA CONTEM o guard' "$tag" "$pub"; echo
    return 1
  fi
  printf '  tag com guard: %s · publicado: %s  -> publicado ainda e ANTERIOR a ela\n' "$tag" "$pub"
  echo "  -> o contorno dos shims CONTINUA necessario."
  return 0
}

# ─── AUTO-TESTE ──────────────────────────────────────────────────────────────
if [ "${1:-}" = "--self-test" ]; then
  N=0; BAD=0
  caso() { # <rc esperado> <rotulo> <tag> <publicado>
    local esp="$1" rot="$2" tag="$3" pub="$4" got
    veredito "$tag" "$pub" >/dev/null 2>&1; got=$?
    N=$((N+1))
    if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
    else BAD=$((BAD+1)); printf '  FAIL %s — esperado rc=%s, obtido rc=%s\n' "$rot" "$esp" "$got"; fi
  }

  echo "== VERDE: o contorno ainda e necessario =="
  caso 0 "o mundo de hoje: nenhuma tag contem o commit"        ""        "9.2.0"
  caso 0 "tag existe mas o publicado e anterior a ela"         "v9.3.0"  "9.2.0"
  echo "== VERMELHO: o contorno CADUCOU =="
  caso 1 "publicado igual a tag com guard"                     "v9.3.0"  "9.3.0"
  caso 1 "publicado maior que a tag com guard"                 "v9.3.0"  "9.4.1"
  caso 1 "salto de major"                                      "v9.3.0"  "10.0.0"
  echo "== LEITURA QUE FALHOU nao vira veredito =="
  caso 2 "npm vazio (rede fora)"                               "v9.3.0"  ""
  caso 2 "npm vazio TAMBEM quando nao ha tag"                  ""        ""
  caso 2 "versao fora da forma vX.Y.Z"                         "v9.3.0"  "nove"
  caso 2 "SEM tag e publicado-lixo tambem recusa"              ""        "lixo"
  caso 2 "SEM tag e publicado so com espacos"                  ""        " "
  # 13 e o CR. Construido por awk para nao depender de UMA contrabarra: foi
  # assim que a versao anterior deste bloco se perdeu, com o escape virando CR
  # literal que o git normalizou no commit.
  CR=$(awk 'BEGIN{printf "%c", 13}')
  # GUARDA DE VACUIDADE do proprio caso: se o CR vier vazio, os dois casos
  # abaixo viram duplicata dos de cima e passam sem afirmar nada.
  if [ "${#CR}" -ne 1 ]; then
    echo "GUARDA: o CR da sonda tem ${#CR} byte(s), esperado 1 - caso vacuo" >&2
    exit 1
  fi
  # 🔴 Este caso existe porque o blob COMMITADO deixou de tirar o CR por
  # normalizacao do git, e nenhum caso do self-test o carregava — o verde era
  # cego para a unica sujeira que o npm do Windows realmente emite.
  caso 1 "publicado com CR ainda decide VERMELHO"              "v9.3.0"  "9.3.0$CR"
  caso 0 "publicado com CR e anterior decide VERDE"            "v9.4.0"  "9.3.0$CR"

  echo ""
  echo "== A PREMISSA: declaracao explicita, nao presenca de string em prosa =="
  # 🔴 Estes quatro casos existem por um defeito MEDIDO em 2026-10-07: a marca era
  # 'pre-guard-bak', e o REGISTRO historico do contorno cita essa string. Depois de
  # reverter, o alarme continuaria VERMELHO para sempre — ruido permanente, que e o
  # defeito que levamos ao upstream na #530 e que eu repeti aqui.
  TMPP=$(mktemp -d 2>/dev/null) || TMPP=""
  if [ -n "$TMPP" ]; then
    pcaso() { # <esperado> <rotulo> <conteudo>
      local esp="$1" rot="$2" conteudo="$3"
      local f="$TMPP/p$N.md"
      printf '%s\n' "$conteudo" > "$f"
      local got; got=$(contorno_declarado "$f")
      N=$((N+1))
      if [ "$got" = "$esp" ]; then printf '  ok   %s\n' "$rot"
      else BAD=$((BAD+1)); printf '  FAIL %s — esperado %s, obtido %s\n' "$rot" "$esp" "$got"; fi
    }
    pcaso sim "declarado ATIVO, na forma completa"      "<!-- contorno-dos-shims: ATIVO -->"
    pcaso nao "declarado REVERTIDO"                     "<!-- contorno-dos-shims: REVERTIDO em 2026-10-07 -->"
    pcaso nao "REGISTRO historico citando pre-guard-bak" "renomeie os tres *.pre-guard-bak tirando o sufixo"
    pcaso nao "PROSA citando a marca sem a forma"       "a marca contorno-dos-shims com valor ATIVO"
    pcaso nao "arquivo sem nenhuma marca"               "texto qualquer"
    N=$((N+1))
    if [ "$(contorno_declarado "$TMPP/nao-existe.md")" = "ilegivel" ]; then
      printf '  ok   arquivo ilegivel devolve "ilegivel", nao "nao"\n'
    else
      BAD=$((BAD+1)); printf '  FAIL arquivo ilegivel nao foi distinguido de ausente\n'
    fi
    rm -rf "$TMPP" 2>/dev/null
  else
    printf '  (nao consegui criar diretorio temporario — casos nao exercitados)\n'
  fi

  echo ""
  if [ "$N" -lt 18 ]; then
    echo "GUARDA DE VACUIDADE: $N caso(s), esperado ao menos 18" >&2
    exit 1
  fi
  echo "check-contorno-dos-shims-caducou --self-test: $N caso(s) · $BAD falha(s)"
  [ "$BAD" -eq 0 ] || exit 1
  exit 0
fi

# ─── EXECUCAO ────────────────────────────────────────────────────────────────
echo "check-contorno-dos-shims-caducou:"

# GUARDA 3 — premissa: o contorno ainda esta DECLARADO ativo?
case "$(contorno_declarado CLAUDE.md)" in
  ilegivel)
    echo "  FALHA: CLAUDE.md ilegivel — nao da para saber se o contorno esta declarado." >&2
    exit 1
    ;;
  nao)
    echo "  o CLAUDE.md nao declara mais o contorno ativo ('$MARCA_CONTORNO' ausente)."
    echo "  -> ele foi revertido ou aposentado. Nada a vigiar."
    exit 0
    ;;
esac

# GUARDA 1 — o commit do guard tem de ser alcancavel, senao `--contains` mente.
if ! git cat-file -e "${GUARD_COMMIT}^{commit}" 2>/dev/null; then
  echo "  FALHA: o commit do guard ${GUARD_COMMIT:0:12} nao e alcancavel nesta arvore." >&2
  echo "  Sem ele, 'git tag --contains' devolve VAZIO — indistinguivel de 'nenhuma" >&2
  echo "  release tem o guard'. Rode 'git fetch upstream --tags'." >&2
  exit 1
fi

if [ -n "$SONDA_TAG_GUARD" ] || [ -n "$SONDA_NPM_LATEST" ]; then
  echo "  🔴 AVISO: leitura(s) INJETADA(S) por SONDA_* — este NAO e um veredito real."
fi

if [ -n "$SONDA_TAG_GUARD" ]; then
  TAG="$SONDA_TAG_GUARD"
else
  # A menor tag que contem o commit: e a primeira release que o carrega.
  TAG=$(git tag --contains "$GUARD_COMMIT" 2>/dev/null | sort -V | head -1)
fi

if [ -n "$SONDA_NPM_LATEST" ]; then
  PUB="$SONDA_NPM_LATEST"
else
  PUB=$(npm view trackfw version 2>/dev/null | tr -d '\r' | tail -1)
fi

veredito "$TAG" "$PUB"
rc=$?

case "$rc" in
  0) exit 0 ;;
  2) echo "  -> leitura insuficiente: NAO ha veredito. Isto reprova de proposito." >&2; exit 1 ;;
  *)
    echo "" >&2
    echo "  🔴 O CONTORNO DOS SHIMS CADUCOU — reverta." >&2
    echo "     1. renomeie os tres *.pre-guard-bak em %APPDATA%/npm tirando o sufixo" >&2
    echo "     2. apague o %APPDATA%/npm/trackfw.exe copiado da arvore" >&2
    echo "     3. npm i -g trackfw@${PUB}" >&2
    echo "     4. confira por efeito: 'trackfw guard git-branch' com payload de" >&2
    echo "        'git push origin main' tem de sair rc=2, e 'git status' rc=0" >&2
    echo "     5. tire a secao do contorno do CLAUDE.md, com a medicao do passo 4" >&2
    echo "" >&2
    echo "  🔴 Nao reverta sem o passo 4. O contorno existe porque a cerca ficou" >&2
    echo "     inerte em silencio uma vez; reverter sem medir repete o episodio." >&2
    exit 1
    ;;
esac
