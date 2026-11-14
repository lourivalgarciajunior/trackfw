#!/usr/bin/env bash
#
# Executa os gates que são SÓ NOSSOS, e reprova se algum reprovar.
#
# Por que existe: derivado em 2026-09-10, **10 scripts em `scripts/` são só
# nossos e NENHUM era invocado por automação nenhuma** — nem `Makefile`, nem CI.
# O `check-upstream-content.sh` ficou VERMELHO por semanas com 7 arquivos de
# governança do upstream em `docs/`, e só apareceu porque alguém o rodou à mão
# numa auditoria de outra REQ.
#
# 🔴 Um gate que ninguém executa é pior que gate nenhum, porque produz a sensação
# de cobertura.
#
# POR QUE NÃO ESTÁ NO `Makefile`: o `Makefile` e os 7 workflows são arquivos
# COMPARTILHADOS com o upstream — derivado por `git ls-tree`, não por
# `git cat-file` (ver nota de conversão do MSYS abaixo). Modificá-los criaria
# divergência de produto que todo merge futuro pagaria, e hoje ela é ZERO.
# Este arquivo e o `Makefile.local` são ADIÇÕES, e adição não é divergência.
#
# Ver REQ-2026-09-10-o-check-upstream-content-nao-roda-em-lugar-nenhum.
set -uo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

# ---------------------------------------------------------------------------
# EXECUTADOS — a lista é explícita, e a GUARDA DE COMPLETUDE abaixo garante que
# um script só-nosso novo não fique de fora em silêncio. Foi assim que o
# `check-upstream-content` sumiu de vista.
#
# 🔴 Os nomes vão COM `.sh`, de propósito (2026-09-11). O `check-orphan-gates.sh`
# do upstream (#323) procura o nome LITERAL do gate numa linha de execução; sem a
# extensão, ele acusava os nossos 9 gates como órfãos, embora rodem a cada push.
# O `FORA` abaixo continua SEM `.sh`: ali nada é executado, e com a extensão o
# gate do upstream contaria um script declarado fora como consumido — a busca
# ingênua por substring que ele mesmo documenta evitar.
# ---------------------------------------------------------------------------
EXECUTAR="
check-upstream-content.sh
check-req-layout.sh
check-referential-integrity.sh
check-inherited-req.sh
check-req-done-com-criterio-aberto.sh
check-os-predicate-classification.sh
check-slug-inventory.sh
check-upstream-sync-falsify.sh
check-gates-uma-linha-por-comando.sh
check-req-marcador-ancorado.sh
measure-os-predicate-sites.sh
check-vigia-forma.sh
check-req-done-caducou-falsify.sh
check-contorno-dos-shims-caducou.sh
check-handoff-cobre-o-ciclo.sh
check-roadmap-done-com-ml-pendente.sh
"

# ---------------------------------------------------------------------------
# DECLARADOS FORA — cada um COM MOTIVO. Exclusão sem motivo escrito é o mesmo
# que não ter regra.
# ---------------------------------------------------------------------------
# 🔴 HEREDOC CITADO, nunca aspa dupla. Em `FORA="..."` qualquer BACKTICK no
# texto do motivo EXECUTA, e a saida do comando entra na string EM SILENCIO.
# Medido por efeito em 2026-11-09, na propria entrada do leitura-avulsa:
#
#   escrito   "A falsificacao dele e por `gh` falso no PATH"
#   na string "A falsificacao dele e por Work s..."   <- a ajuda do `gh`, costurada
#
# Nao houve erro visivel: o motivo ficou corrompido e o agregador seguiu verde,
# porque a guarda de completude so le o nome antes do `|`. A entrada do
# censo-macos, acrescentada no mesmo dia, levava `gh api` e `<id>` e aí o erro
# APARECEU — "accepts 1 arg(s)" e "id: No such file or directory" —, o que foi
# o que delatou o silencioso. Com <<'FORA_EOF' nada expande, os backticks sao
# TEXTO, e os apostrofos de 'esperado'/'nativo_windows' continuam valendo.
# Mesma familia de backtick-na-mensagem-de-commit-e-executado, agora num script.
#
# ✅ E ate 14/11/2026 isto era CONVENCAO SEM GUARDA — este comentario declarava,
# por escrito, que nenhum instrumento olhava: quem trocasse o heredoc por aspa
# dupla reinstalava a corrupcao silenciosa e o agregador seguia verde. A GUARDA
# DO BACKTICK, logo abaixo das listas, passou a decidir sobre BYTES (conta
# backticks no fonte e na variavel expandida) em vez de sobre forma de atribuicao
# — assim ela pega qualquer forma futura que expanda, nao so a aspa dupla.
FORA=$(cat <<'FORA_EOF'
check-platform-predicates|so diz algo no Windows: 14 das 20 linhas do corpus divergem entre 'esperado' e 'nativo_windows', e a linha do execbit reprovaria em ubuntu-latest por fato de NTFS. Decisao medida, escrita no CLAUDE.md
upstream-sync|nao e gate, e ferramenta: faz merge e MODIFICA a arvore. Rodar num CI de verificacao seria absurdo
anexa-crlf|nao e gate, e ferramenta: anexa o conteudo de uma fonte ao arquivo que recebe como argumento, logo MODIFICA arvore — mesmo precedente do upstream-sync. Invocado sem argumentos ele sai 1 por construcao, entao EXECUTAR o reprovaria por motivo nenhum. O auto-teste dele tem passo proprio no local-gates.yml, com piso no denominador, e trabalha todo em mktemp -d
vigia-do-upstream|nao e gate, e daemon: laco infinito que vigia o upstream e emite evento. Executa-lo aqui penduraria o agregador; e ele nao reprova nada, nao ha veredito para colher
censo-macos|nao e gate, e censo: classifica o par shim-byte-identity por run do quality.yml em VERDE/ABANDONADO/DISPENSADO/INDETERMINADO, e fala com a REDE (um `gh api` por run). Em CI o veredito dependeria da fila de runners do GitHub e da cota da API, nao da arvore — e sem credencial sairia 2 por ambiente. Ele existe porque o laco que o CLAUDE.md publicava lia `actions/runs/<id>/jobs`, que devolve conjunto PARCIAL: um abandono real ficou invisivel em 2026-11-09
leitura-avulsa-do-upstream|nao e gate, e leitura: UMA passada sobre o estado do upstream para sessao fria, e fala com a REDE (git ls-remote + 3 a 4 chamadas da API do GitHub). Num CI de verificacao o veredito dependeria do repositorio alheio e da cota da API, nao da arvore — e sem credencial os bracos sairiam N/A, logo ele sairia 2 por ambiente e nao por defeito. A falsificacao dele e por `gh` falso no PATH, com os quatro cenarios no corpo do script
check-copia-do-path-esta-atras|so diz algo nesta maquina: compara o binario da arvore com a copia que o PATH entrega, e em ubuntu-latest nao existe %APPDATA%/npm nem o contorno dos shims — ZERO cenario seria exercitado. Mesmo precedente do check-platform-predicates. O instrumento que age sozinho e o passo do upstream-sync.sh, no momento em que a defasagem e criada
run-local-gates|e o proprio agregador: executa-lo a partir de si mesmo seria recursao infinita. A guarda de completude o pegou na PRIMEIRA execucao, e esta entrada e a prova de que ela funciona
FORA_EOF
)

# ---------------------------------------------------------------------------
# GUARDA DAS DECLARACOES — os BYTES do que esta escrito tem de chegar inteiros
# na variavel. Ate 14/11/2026 isto era convencao sem instrumento (o comentario
# acima dizia, por escrito, que nada olhava).
#
# A propriedade: cada linha de declaracao do FONTE aparece IDENTICA na variavel.
# Uma expansao — aspa dupla, `$(...)`, qualquer forma futura — altera os bytes, e
# e isso que se compara. O gate nao precisa conhecer a forma da atribuicao.
#
# 🔴 POR QUE NAO CONTAR BACKTICK, que foi a primeira versao desta guarda e esta
# REFUTADA por medicao: em 14/11/2026, com o FORA convertido para aspa dupla, a
# variavel saiu com `fonte=6 var=6` e as 8 entradas reconciliando — e estava
# CORROMPIDA. A ajuda do `gh`, costurada no lugar do texto, trouxe 6 backticks
# PROPRIOS (`gh <command> --help`, `gh help exit-codes`, `gh help accessibility`),
# e a contagem bateu por coincidencia. Contagem de caractere nao e identidade de
# bytes; o que a saida injetada trouxer pode repor exatamente o que ela comeu.
# ---------------------------------------------------------------------------
SELF="${BASH_SOURCE[0]}"

# 🔴 UM `mktemp` SO, com UM `trap` so — e o diretorio desta guarda nasce DENTRO
# dele. A primeira versao criava um `mktemp -d` proprio SEM trap, de proposito,
# porque a guarda de completude instala o dela (`trap 'rm -rf "$TMP"' EXIT`) e um
# trap EXIT substitui o anterior; a remocao ficava explicita. O
# `check-mktemp-cleanup.sh` do upstream REPROVOU isso em 14/11/2026 —
# "variable TMP_BT created by mktemp without guaranteed cleanup (ADR D2)" —, e
# com razao: `rm` no caminho normal nao roda se o script morrer antes dele.
# O diagnostico do clobber estava certo e o remedio errado; a LAST-TRAP RULE do
# proprio gate descreve o perigo, e a forma CONTAINED e a saida documentada:
# `V=$(mktemp … "$W/…")` com `W` coberto. Hoje o `TMP` e criado aqui, uma vez,
# e a guarda de completude abaixo o reusa. (O gate nasceu da REQ-2026-11-11, que
# fecha a NOSSA issue #676.)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
TMP_BT=$(mktemp -d "$TMP/declaracoes.XXXXXX")

# As declaracoes se identificam por CONTEUDO, nunca pelos marcadores da
# atribuicao: `<nome>|<motivo>` no FORA, `<nome>.sh` no EXECUTAR, as duas
# ancoradas no inicio da linha — comentario comeca com `#` e `echo` com espaco,
# logo nenhum dos dois casa.
grep -E '^[a-z0-9][a-z0-9.-]*\|'   "$SELF"              | sort > "$TMP_BT/fora-fonte"
printf '%s\n' "$FORA"     | grep -E '^[a-z0-9][a-z0-9.-]*\|' | sort > "$TMP_BT/fora-var"
grep -E '^[a-z0-9][a-z0-9.-]*\.sh$' "$SELF"             | sort > "$TMP_BT/exec-fonte"
printf '%s\n' "$EXECUTAR" | grep -E '^[a-z0-9][a-z0-9.-]*\.sh$' | sort > "$TMP_BT/exec-var"

falhou_bt=0
for lista in fora exec; do
  n=$(wc -l < "$TMP_BT/$lista-fonte" | tr -d ' ')
  # VACUIDADE: sem declaracao no fonte, o `cmp` compara vazio com vazio e passa
  # descrevendo o nada. Zero aqui e extracao quebrada, nunca lista legitima.
  if [ "$n" -lt 1 ]; then
    echo "run-local-gates: FALHA — zero declaracao de '$lista' no fonte." >&2
    echo "  A extracao parou de casar; sem ela a comparacao nao verifica nada." >&2
    falhou_bt=1; continue
  fi
  if ! cmp -s "$TMP_BT/$lista-fonte" "$TMP_BT/$lista-var"; then
    echo "run-local-gates: FALHA — as declaracoes de '$lista' NAO chegaram inteiras." >&2
    echo "  $n no fonte; a variavel difere. Quase sempre e EXPANSAO na atribuicao:" >&2
    echo "  a lista tem de ser heredoc CITADO, <<'EOF', onde nada expande." >&2
    diff "$TMP_BT/$lista-fonte" "$TMP_BT/$lista-var" | head -6 >&2
    falhou_bt=1
  fi
done

# CONTROLE A/B — exercita o discriminante NESTE shell, com texto sintetico, para
# que o verde nunca venha de "nao havia o que medir". A fixture vive em arquivo
# proprio, porque conteudo com backtick nao viaja dentro de string de comando.
CTL="$TMP_BT/ctl.sh"
{
  printf '%s\n' 'A="x|motivo com `echo CORROMPIDO` dentro"'
  printf '%s\n' "B=\$(cat <<'BEOF'"
  printf '%s\n' 'x|motivo com `echo CORROMPIDO` dentro'
  printf '%s\n' 'BEOF'
  printf '%s\n' ')'
  printf '%s\n' 'printf "%s\n%s\n" "$A" "$B"'
} > "$CTL"
_ctl=$(bash "$CTL" 2>/dev/null)
_ctl_a=$(printf '%s\n' "$_ctl" | sed -n 1p)
_ctl_b=$(printf '%s\n' "$_ctl" | sed -n 2p)
if [ "$_ctl_a" = "$_ctl_b" ]; then
  echo "run-local-gates: FALHA — o controle A/B nao reproduz a corrupcao." >&2
  echo "  aspa dupla e heredoc citado deram o MESMO byte: [$_ctl_a]" >&2
  echo "  Sem esse discriminante vivo, o cmp acima nao prova nada." >&2
  falhou_bt=1
fi
N_FORA_OK=$(wc -l < "$TMP_BT/fora-fonte" | tr -d ' ')
N_EXEC_OK=$(wc -l < "$TMP_BT/exec-fonte" | tr -d ' ')
[ "$falhou_bt" -eq 0 ] || exit 1
echo "run-local-gates: guarda das declaracoes OK — $N_FORA_OK no FORA e $N_EXEC_OK no EXECUTAR, identicas na variavel; controle A/B difere."

# ---------------------------------------------------------------------------
# GUARDA DE COMPLETUDE — o coracao deste script.
#
# Deriva os scripts SO NOSSOS por `git ls-tree` e exige que cada um esteja em
# EXECUTAR ou em FORA. Um script novo que ninguem listar REPROVA aqui.
#
# 🔴 `git ls-tree`, nunca `git cat-file -e "$ref:$path"`. Medido em 2026-09-10:
# o MSYS converte `ref:.caminho` em `ref;\caminho` quando o caminho apos os
# dois-pontos COMECA COM PONTO, e a checagem devolve "so nosso" para arquivo que
# e do upstream. Deu falso em todos os 7 workflows de uma vez. Mesma familia do
# achado que levamos ao upstream na issue #308.
# ---------------------------------------------------------------------------
UPSTREAM_REF=${UPSTREAM_REF:-upstream/main}

if ! git rev-parse --verify --quiet "$UPSTREAM_REF" >/dev/null; then
  echo "run-local-gates: FALHA — ref '$UPSTREAM_REF' nao existe." >&2
  echo "  Sem ela nao da para derivar o que e so nosso, e a guarda de completude" >&2
  echo "  passaria sem verificar nada. Rode 'git fetch upstream'." >&2
  exit 1
fi

# O `TMP` e o `trap` dele sao criados UMA vez, junto da guarda das declaracoes
# acima. 🔴 Reinstalar o trap aqui nao seria redundancia inofensiva: o segundo
# `trap … EXIT` SUBSTITUI o primeiro, e e esse clobber que o `check-mktemp-cleanup.sh`
# chama de LAST-TRAP RULE. Um mktemp, um trap, os dois usuarios no mesmo diretorio.
git ls-tree -r --name-only "$UPSTREAM_REF" -- scripts > "$TMP/upstream.txt" 2>/dev/null || true

if [ ! -s "$TMP/upstream.txt" ]; then
  echo "run-local-gates: GUARDA — 'git ls-tree $UPSTREAM_REF -- scripts' devolveu VAZIO." >&2
  echo "  Isso faria TODO script parecer 'so nosso'. Nao e resultado, e a derivacao quebrada." >&2
  exit 1
fi

so_nossos=""
for f in scripts/*.sh; do
  grep -qx "$f" "$TMP/upstream.txt" || so_nossos="$so_nossos $(basename "$f" .sh)"
done

n_so_nossos=$(printf '%s' "$so_nossos" | wc -w | tr -d ' ')
if [ "$n_so_nossos" -eq 0 ]; then
  echo "run-local-gates: GUARDA — zero scripts so nossos derivados." >&2
  echo "  Este fork tem gates proprios; zero significa que a derivacao quebrou." >&2
  exit 1
fi

nao_listados=0
# 🔴 `produtor | grep PADRAO >/dev/null`, nunca a opcao `-q`: sob `set -o pipefail` o
# grep silencioso sai no PRIMEIRO casamento, o produtor recebe SIGPIPE e o cano
# devolve 141 de forma intermitente. Medido pelo upstream em 2026-11-06 (D5 da
# ADR-2026-11-06) e vigiado pelo `check-no-grep-q-under-pipefail.sh` dele, que o sync
# vai trazer. Ver o comentario longo no `check-os-predicate-classification.sh`.
for s in $so_nossos; do
  if printf '%s' "$EXECUTAR" | grep -x "${s}.sh" >/dev/null; then continue; fi
  if printf '%s' "$FORA" | grep "^${s}|" >/dev/null; then continue; fi
  echo "  ✗ COMPLETUDE: 'scripts/${s}.sh' e so nosso e nao esta nem em EXECUTAR nem em FORA" >&2
  nao_listados=$((nao_listados + 1))
done

if [ "$nao_listados" -gt 0 ]; then
  echo "" >&2
  echo "${nao_listados} script(s) so nosso(s) fora da lista." >&2
  echo "Acrescente a EXECUTAR, ou a FORA COM O MOTIVO ESCRITO." >&2
  echo "🔴 Ficar de fora em silencio e exatamente o defeito que este script existe para fechar." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# PRE-CONDICAO DO BINARIO — converte morte silenciosa em falha NOMEADA.
#
# Medido na primeira corrida em CI (2026-09-10): sem `npm ci`, o
# check-subcommand-parity saiu exit 1 com ZERO linhas de saida. Ele invocava
# `node npm/bin/trackfw --help 2>/dev/null`; sem os modulos o node falhava, o
# stderr era descartado, e `set -euo pipefail` matava o script sem dizer nada.
#
# Um gate que morre calado e indistinguivel de um gate que reprovou. Esta guarda
# faz a diferenca aparecer ANTES, com o nome do que falta.
#
# 🔴 Ate 2026-09-16 ela exigia tambem `node npm/bin/trackfw` e
# `python3 -m trackfw`. A v8.0.0 do upstream (#365) removeu as duas
# reimplementacoes, e com elas o unico gate nosso que as invocava
# (check-subcommand-parity, retirado). Exigir runtime que nenhum gate usa
# reprovaria o agregador inteiro por motivo nenhum -- foi o que o sync mediu.
# Ver REQ-2026-09-16-gates-so-nossos-depois-da-v8.
# ---------------------------------------------------------------------------
faltando=""
[ -x "$ROOT_DIR/bin/trackfw" ] || faltando="$faltando bin/trackfw"

if [ -n "$faltando" ]; then
  echo "run-local-gates: FALHA — pre-requisito(s) indisponivel(is):$faltando" >&2
  echo "  Gates que chamam o binario da arvore descartam o stderr dele. Sem ele," >&2
  echo "  eles morrem com exit 1 e nenhuma mensagem -- indistinguivel de reprovacao." >&2
  echo "  Rode 'go build -o bin/trackfw ./cmd/trackfw'." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Execucao
# ---------------------------------------------------------------------------
echo "run-local-gates: ${n_so_nossos} script(s) so nosso(s) derivado(s) de $(ls scripts/*.sh | wc -l | tr -d ' ') em scripts/"
echo ""

falhas=0
executados=0
for s in $EXECUTAR; do
  [ -f "scripts/${s}" ] || { echo "  ✗ ${s%.sh}: LISTADO em EXECUTAR mas o arquivo nao existe" >&2; falhas=$((falhas+1)); continue; }
  saida=$(bash "scripts/${s}" 2>&1); rc=$?
  executados=$((executados + 1))
  if [ "$rc" -eq 0 ]; then
    printf '  ok   %-38s\n' "${s%.sh}"
  else
    printf '  FAIL %-38s exit=%s\n' "${s%.sh}" "$rc"
    printf '%s\n' "$saida" | sed 's/^/         /' >&2
    falhas=$((falhas + 1))
  fi
done

# GUARDA DE VACUIDADE: zero executados com exit 0 seria verde por nao ter feito nada.
if [ "$executados" -eq 0 ]; then
  echo "run-local-gates: GUARDA — zero gates executados." >&2
  exit 1
fi

echo ""
echo "  declarados FORA, com motivo:"
printf '%s\n' "$FORA" | while IFS='|' read -r nome motivo; do
  [ -n "$nome" ] || continue
  printf '    %-28s %s\n' "$nome" "$motivo"
done

echo ""
if [ "$falhas" -gt 0 ]; then
  echo "run-local-gates: ${executados} executado(s) · ${falhas} REPROVOU(RAM)" >&2
  exit 1
fi
echo "run-local-gates: ${executados} executado(s) · 0 falha(s)"
