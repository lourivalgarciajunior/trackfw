#!/usr/bin/env bash
# Ratchet: todo comando de "**Gates da wave:**" nos roadmaps DESTE fork tem de ser
# executavel sozinho, porque e assim que o produto o executa.
#
# ─────────────────────────────────────────────────────────────────────────────
# A regra 5 de docs/cli-parity.md decide:
#
#   "Each non-empty, non-comment line in that block is one gate command,
#    executed from the repository root, in declaration order."
#
# UMA LINHA = UM `sh -c`. Linhas nao compartilham estado: `export`, `cd`, variavel
# e, principalmente, CONSTRUCAO MULTILINHA. Um `for ... do` / `done` legitimo vira
# tres falhas, e a linha do meio EXECUTA com a variavel do laco vazia.
#
# Medido neste acervo em 2026-10-01, antes da correcao (18 blocos, 40 linhas):
#
#   5 blocos afetados · 16 linhas fragmentadas · 3 com contrabarra final
#   4 dos 5 blocos em roadmap `done/` — wave fechada com gate que nunca passou
#
# Reproduzido por efeito com o binario, no `onda-1` wave 0:
#
#   - for n in 273 274 275 268; do:  exit 2
#   - gh issue view "$n" ... :       exit 1   <- EXECUTOU, com $n vazio
#   - done:                          exit 2
#
# Reportado no upstream: https://github.com/kgsaran/trackfw/issues/491
# ─────────────────────────────────────────────────────────────────────────────
#
# 🔴 POR QUE `sh -n` POR STDIN, E NUNCA POR ARGUMENTO
#
# `sh -n -c "$cmd"` MENTE no Windows. Medido em 2026-10-01, em Go e em Python, com
# o MSYS desta maquina: quando o fragmento NAO tem espaco, o argumento sofre escape
# na ida e a aspa chega ao `sh` como contrabarra —
#
#   enviado   esperado="scaffold.go
#   recebido  esperado=\scaffold.go     <- atribuicao VALIDA, `sh -n` sai 0
#
# — e o fragmento passa. Com espaco a ida e volta e fiel (`echo "abre` sai 2), o que
# faz a classe ser estreita e passar desapercebida. Por stdin o argv nao e tocado.
# O discriminante e a presenca de ESPACO, nao a aspa impar.
#
# O mesmo vale para a EXECUCAO: `runGateCommand` (internal/commands/barrier.go)
# chama `exec.Command("sh", "-c", command)`, e no Windows uma linha malformada
# dessa forma sai 0 — gate malformado conta como gate que PASSOU.
#
# ─────────────────────────────────────────────────────────────────────────────
# Como os outros gates so nossos, NAO tem alvo no Makefile: o Makefile e arquivo
# compartilhado com o upstream e mexer nele cria divergencia de produto. Arquivo
# novo em scripts/ nao cria. Mesmo precedente do upstream-sync.sh.

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

YAML="trackfw.yaml"
[ -f "$YAML" ] || { echo "FALHA: $YAML nao encontrado em $ROOT_DIR"; exit 1; }

# roadmap_dir sai do yaml, nunca chumbado — o nosso divergiu do default antes.
ROADMAP_DIR="$(awk -F': *' '/^roadmap_dir:/{gsub(/["'"'"']/,"",$2); print $2; exit}' "$YAML")"
[ -n "$ROADMAP_DIR" ] || ROADMAP_DIR="docs/roadmaps"
[ -d "$ROADMAP_DIR" ] || { echo "FALHA: roadmap_dir '$ROADMAP_DIR' nao existe"; exit 1; }

mapfile -t ROADMAPS < <(find "$ROADMAP_DIR" -type f -name '*.md' | LC_ALL=C sort)

# Guarda de vacuidade 1: varredura que nao acha roadmap nao prova nada.
if [ "${#ROADMAPS[@]}" -eq 0 ]; then
  echo "FALHA (vacuidade): zero roadmaps em '$ROADMAP_DIR' — o padrao de busca quebrou"
  exit 1
fi

# Extrai <arquivo> TAB <linha> TAB <tipo> TAB <comando>.
#   tipo CMD  = linha de comando dentro do bloco de gates
#   tipo F1   = marcador "**Gates da wave:**" DENTRO de cerca (nao e gate, e prosa)
#   tipo SEMF = marcador sem cerca de abertura antes do proximo heading
extrai() {
  awk -v arq="$1" '
    function fence(l,   d) {
      if (l ~ /^[ \t]*```/) return "```"
      if (l ~ /^[ \t]*~~~/) return "~~~"
      return ""
    }
    BEGIN { dentro=0; delim=""; estado=0 }
    {
      f = fence($0)
      if (estado == 2) {
        if (f != "" && f == delim) { estado=0; dentro=0; delim=""; next }
        linha = $0
        sub(/^[ \t]+/, "", linha)
        sub(/[ \t]+$/, "", linha)
        if (linha != "" && substr(linha,1,1) != "#") printf "%s\t%d\tCMD\t%s\n", arq, NR, linha
        next
      }
      if (estado == 1) {
        if ($0 ~ /^#/) { printf "%s\t%d\tSEMF\t%s\n", arq, marcador, "marcador sem cerca"; estado=0; next }
        if (f != "") { estado=2; delim=f; dentro=1; next }
        next
      }
      # estado 0: rastreia cerca comum para nao ler marcador que e prosa
      if (f != "") {
        if (!dentro) { dentro=1; delim=f }
        else if (f == delim) { dentro=0; delim="" }
        next
      }
      if ($0 ~ /^\*\*Gates da wave:\*\*/) {
        if (dentro) { printf "%s\t%d\tF1\t%s\n", arq, NR, "marcador dentro de cerca"; next }
        estado=1; marcador=NR
      }
    }
  ' "$1"
}

n_blocos=0 n_cmds=0 n_f1=0 n_semf=0 n_ruins=0
declare -a RUINS=()

for r in "${ROADMAPS[@]}"; do
  anterior=""
  while IFS=$'\t' read -r arq linha tipo cmd; do
    case "$tipo" in
      F1)   n_f1=$((n_f1 + 1));   RUINS+=("$arq:$linha  F1  marcador dentro de cerca") ;;
      SEMF) n_semf=$((n_semf + 1)); RUINS+=("$arq:$linha  SEMF  marcador sem cerca de abertura") ;;
      CMD)
        n_cmds=$((n_cmds + 1))
        # 🔴 stdin, nunca argv — ver o cabecalho.
        if ! printf '%s' "$cmd" | sh -n 2>/dev/null; then
          n_ruins=$((n_ruins + 1))
          RUINS+=("$arq:$linha  FRAGMENTO  ${cmd:0:72}")
        elif [ "${cmd: -1}" = '\' ]; then
          # `sh -n` nao pega contrabarra final solta (medido pelo mantenedor em
          # bash 3.2 e dash, e reproduzido aqui em bash 5.2): complemento explicito.
          n_ruins=$((n_ruins + 1))
          RUINS+=("$arq:$linha  CONTRABARRA  ${cmd:0:72}")
        fi
        ;;
    esac
  done < <(extrai "$r")
done

# Denominador de arquivos com bloco, para a guarda de vacuidade abaixo poder dizer
# "18 arquivos tem bloco e nenhuma linha saiu" em vez de so "zero".
n_blocos="$(grep -lE '^\*\*Gates da wave:\*\*' "${ROADMAPS[@]}" 2>/dev/null | wc -l)"

echo "roadmaps varridos        $(printf '%d' "${#ROADMAPS[@]}")   (roadmap_dir='$ROADMAP_DIR')"
echo "arquivos com bloco       $n_blocos"
echo "linhas de comando        $n_cmds"
echo "marcador em cerca (F1)   $n_f1"
echo "marcador sem cerca       $n_semf"
echo "linhas que nao rodam so  $n_ruins"

# Guarda de vacuidade 2, e e a que importa: se NENHUMA linha de comando sair da
# extracao, o classificador parou de casar e o gate passaria descrevendo o vazio.
if [ "$n_cmds" -eq 0 ]; then
  echo
  echo "FALHA (vacuidade): zero linhas de comando extraidas de $n_blocos arquivo(s) com bloco."
  echo "A extracao quebrou — o marcador, a cerca ou o roadmap_dir mudaram de forma."
  exit 1
fi

if [ "${#RUINS[@]}" -gt 0 ]; then
  echo
  echo "FALHA: ${#RUINS[@]} achado(s) — todo comando de gate tem de rodar sozinho (regra 5):"
  for l in "${RUINS[@]}"; do echo "  $l"; done
  echo
  echo "Reescreva o comando em UMA linha. Logica maior que uma linha vai para"
  echo "scripts/ e o gate a chama — mesmo precedente dos outros gates so nossos."
  exit 1
fi

echo
echo "OK: os $n_cmds comandos de gate rodam cada um por si."
