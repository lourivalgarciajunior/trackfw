#!/usr/bin/env bash
# Acusa REQ fora do layout canonico decidido pela ADR-2026-09-03, D1:
#
#   "backlog/analyzing/wip/blocked/done/abandoned sao conceito de ROADMAP.
#    REQ tem status no frontmatter (Open/Done), nao pasta de estado."
#
# O layout canonico em by_agent e req_dir/<agente>/*.md -- um nivel, nunca dois.
#
# REQ-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa
#
# TRES CUIDADOS, cada um por um defeito medido:
#
#   1. GLOB RECURSIVO. A varredura desce a arvore inteira sob req_dir. Um glob de
#      UM NIVEL foi exatamente o que produziu o numero errado da PR #65 -- ele nao
#      via as REQs em <agente>/backlog/, que sao justamente as que este gate
#      existe para achar. O defeito e o mesmo dos dois lados.
#   2. DENOMINADOR IMPRESSO, e falha se for zero. Verde sobre acervo vazio nao
#      conta.
#   3. docs/req/ FICA DE FORA, por decisao escrita. Nao e req_dir deste projeto --
#      e residuo do upstream, e tres daqueles arquivos sao FIXTURE DE TESTE do
#      produto, lidas por caminho literal nos 3 runtimes
#      (REQ-2026-09-05-tres-reqs-de-docs-req). Acusa-las levaria a remove-las, e
#      remove-las quebra go, node e python.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${TRACKFW_CONFIG:-$ROOT_DIR/trackfw.yaml}"

[ -f "$CONFIG" ] || { echo "check-req-layout: config ausente em $CONFIG" >&2; exit 1; }

# req_dir vem da config, nunca chumbado -- um gate que assume o caminho deixa de
# valer no dia em que a config muda, sem avisar.
REQ_DIR=$(sed -n 's/^req_dir:[[:space:]]*//p' "$CONFIG" | head -1 | tr -d '"' | tr -d "'" | tr -d '\r')
REQ_DIR="${REQ_DIR:-docs/req}"
ABS="$ROOT_DIR/$REQ_DIR"

[ -d "$ABS" ] || { echo "check-req-layout: req_dir '$REQ_DIR' nao existe" >&2; exit 1; }

TOTAL=0
FORA=0

# Profundidade 1 = req_dir/<agente>/x.md, que e o canonico em by_agent.
# Profundidade 0 = req_dir/x.md, canonico em layout flat.
# Qualquer coisa mais funda e pasta de estado inventada.
while IFS= read -r f; do
  TOTAL=$((TOTAL+1))
  rel="${f#$ABS/}"
  niveis=$(printf '%s' "$rel" | tr -cd '/' | wc -c | tr -d ' ')
  if [ "$niveis" -gt 1 ]; then
    sobrando=$(printf '%s' "$rel" | cut -d/ -f2)
    echo "FAIL [layout/$rel]: nivel '$sobrando' sobrando -- REQ nao tem dimensao de estado (ADR-2026-09-03 D1)" >&2
    FORA=$((FORA+1))
  fi
done < <(find "$ABS" -name '*.md' -type f | sort)

# Guarda de vacuidade: sem denominador, o verde nao diz nada.
if [ "$TOTAL" -eq 0 ]; then
  echo "check-req-layout: GUARDA DE VACUIDADE -- zero REQs varridas em '$REQ_DIR'" >&2
  exit 1
fi

echo "check-req-layout: $TOTAL REQ(s) varrida(s) em '$REQ_DIR' - $FORA fora do layout canonico"
[ "$FORA" -eq 0 ] || exit 1
