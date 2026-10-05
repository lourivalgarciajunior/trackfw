#!/usr/bin/env bash
#
# Acusa REQ NOSSA marcada `done` que ainda tem critério de aceite em aberto.
#
# Medido em 2026-09-10: dez REQs do nosso acervo declaravam entrega concluída com
# 56 critérios substantivos em aberto — 57 dos 58 checkboxes abertos do acervo
# estavam sob bloco de critério, com discriminante escrito e verificável. Duas
# delas escreviam no PRÓPRIO texto do critério que ele "não foi atingido", com a
# REQ em `status: Done`.
#
# É a Regra Dura de Reconciliação deste projeto aplicada ao acervo em vez de ao
# microlote: artefato afirmando o contrário da conclusão do próprio trabalho.
#
# TRÊS DISCRIMINANTES, e cada um existe por um erro medido:
#
#   1. HERDADA fica fora, por construção -- não por allowlist. A exclusão vem do
#      mesmo `git cat-file -e upstream/main:docs/req/<basename>` do
#      check-inherited-req.sh. A ADR-2026-08-29 decide que a governança do
#      upstream não é importada, e a REQ-2026-09-09 decidiu que os 227 ACs
#      abertos dela não são marcados nem desmarcados. Marcá-los aqui seria
#      afirmar autoria sobre entrega dele.
#
#   2. Só `status` = `done` (minúsculo, case-insensitive) entra no alvo. REQ
#      `Open` com critério em aberto NÃO é contradição -- é trabalho em curso.
#      🔴 A primeira derivação deste inventário deu 64 ACs porque não tinha este
#      discriminante, e incluía a própria REQ que o define.
#
#   3. Só checkbox SOB BLOCO DE CRITÉRIO conta. Checkbox em prosa, em escopo
#      negativo ou dentro de template embutido não é critério de aceite.
#
# O leitor de bloco de critério é o mesmo do check-inherited-req.sh, e custou um
# defeito para acertar: `## Critérios de Aceite` seguido de `### Bloco A`
# continua dentro do bloco, e `[eé]` em classe de caractere não casa UTF-8 no awk
# desta máquina.
#
# Ver REQ-2026-09-10-onze-reqs-nossas-afirmam-done-com-58-criterios-de-aceite-em-aberto.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

CONFIG="$ROOT_DIR/trackfw.yaml"
UPSTREAM_REF=${UPSTREAM_REF:-upstream/main}
UPSTREAM_REQ_DIR=${UPSTREAM_REQ_DIR:-docs/req}

if [ ! -f "$CONFIG" ]; then
  echo "check-req-done-com-criterio-aberto: FALHA — trackfw.yaml não encontrado em $ROOT_DIR" >&2
  exit 1
fi

REQ_DIR=$(sed -n 's/^req_dir:[[:space:]]*//p' "$CONFIG" | head -1 | tr -d '"' | tr -d "'" | tr -d '\r')
if [ -z "$REQ_DIR" ] || [ ! -d "$ROOT_DIR/$REQ_DIR" ]; then
  echo "check-req-done-com-criterio-aberto: FALHA — req_dir '$REQ_DIR' ausente ou inexistente" >&2
  exit 1
fi

# A exclusão das herdadas depende da ref do upstream. Sem ela o gate acusaria as
# 28 REQs dele -- 227 ACs que a REQ-2026-09-09 decidiu NÃO tocar. Falhar aqui é
# obrigatório: passar sem a ref transformaria este gate num gerador de ruído.
if ! git rev-parse --verify --quiet "$UPSTREAM_REF" >/dev/null; then
  echo "check-req-done-com-criterio-aberto: FALHA — ref '$UPSTREAM_REF' não existe." >&2
  echo "  Sem ela não dá para excluir as 28 herdadas, e o gate acusaria governança do upstream." >&2
  echo "  Rode 'git fetch upstream' — este gate NÃO faz fetch sozinho." >&2
  exit 1
fi

if ! git cat-file -t "${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}" >/dev/null 2>&1; then
  echo "check-req-done-com-criterio-aberto: FALHA — '${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}' não é diretório." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Conta checkbox aberto SOB bloco de critério, em QUATRO baldes que somam o
# total. Devolve: <sob> <lapsed> <fora> <total>
#
# `sob`    aberto sob bloco de critério, SEM continuação `Caducou:`  -> acusa
# `lapsed` aberto sob bloco de critério, COM `Caducou:` válido       -> não acusa
# `fora`   aberto fora de bloco de critério                          -> nomeado, não acusa
# `total`  todos os `- [ ]` fora de cerca — e sob+lapsed+fora TEM de dar total
#
# 🔴 A forma `Caducou:` é do PRODUTO, não nossa. O #519 do upstream — que
# implementa a nossa #514 — a definiu, e a fonte da verdade das bordas é
# `internal/roadmapdoc/roadmapdoc.go`:
#
#     LapsedContinuationRe = regexp.MustCompile(`^ {2,}Caducou:\s*\S`)
#
# As quatro bordas, lidas de lá e espelhadas aqui:
#   1. >= 2 espaços de indentação, e **não** tabulação;
#   2. a continuação vem IMEDIATAMENTE após o `- [ ]`, sem linha em branco;
#   3. justificativa obrigatória — `  Caducou:` pelo e `  Caducou:` falham,
#      porque `` é espaço e o `\S` exige caractere real depois;
#   4. dentro de cerca de código, é ignorado.
#
# 🔴 Por que paridade e não "uma heurística que funcione": divergir numa borda
# faria este gate e o `validate` discordarem sobre o mesmo arquivo — e aí o
# acervo passa a depender de qual instrumento foi rodado.
#
# E por que reconhecer em vez de endurecer: sem isto, o gate seria o ÚNICO
# instrumento a recusar a saída que o produto passou a oferecer, e a forma
# canônica — que é o nosso próprio precedente, "fica aberto de propósito" —
# viraria inútil aqui.
# ---------------------------------------------------------------------------
censo() {
  awk '
    function fecha() {
      if (pend) { if (pend_dentro) sob++; else fora++; pend = 0 }
    }
    # CERCA DE CODIGO: `- [ ]` dentro de ``` e CITACAO, nao criterio. Medido em
    # 2026-09-10: sao 3 no acervo -- um trecho de outra REQ citado como prova, e
    # dois de um template de roadmap embutido. Conta-los inventa criterio que
    # ninguem escreveu, e foi o que fez este inventario acusar um caso que nao
    # existe.
    /^```/ { fecha(); cerca = !cerca; next }
    /^#+[ ]/ {
      fecha()
      lvl = index($0, " ") - 1
      h = tolower($0)
      ehcrit = ((h ~ /crit/ && h ~ /aceit/) || (h ~ /acceptance/ && h ~ /criteri/)) ? 1 : 0
      if (ehcrit)                     { dentro = 1; base = lvl }
      else if (dentro && lvl <= base) { dentro = 0 }
      next
    }
    /^-[ ]\[[ ]\]/ {
      fecha()
      if (cerca) next
      total++
      pend = 1; pend_dentro = dentro
      next
    }
    {
      # Continuacao `Caducou:` — paridade com LapsedContinuationRe do produto.
      # `^   *` e DOIS espacos literais mais zero-ou-mais: >= 2, e tabulacao nao
      # casa. O `[^[:space:]]` no fim e o `\S` do produto, e e ele que recusa a
      # justificativa vazia, inclusive com CRLF.
      if (pend && !cerca && $0 ~ /^   *Caducou:[[:space:]]*[^[:space:]]/) {
        if (pend_dentro) lapsed++; else fora++
        pend = 0
        next
      }
      fecha()
    }
    END {
      fecha()
      print sob+0, lapsed+0, fora+0, total+0
    }
  ' "$1"
}

varridas=0
herdadas=0
abertas_legitimas=0
acusadas=0
acs_acusados=0
acs_caducados=0
fora_de_bloco=0

while IFS= read -r f; do
  varridas=$((varridas + 1))
  b=$(basename "$f")

  if git cat-file -e "${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}/${b}" 2>/dev/null; then
    herdadas=$((herdadas + 1)); continue
  fi

  st=$(sed -n 's/^status:[[:space:]]*//p' "$f" | head -1 | tr -d '"' | tr -d "'" | tr -d '\r')
  lst=$(printf '%s' "$st" | tr 'A-Z' 'a-z')

  read -r sob lapsed fora total < <(censo "$f")

  # RECONCILIACAO DO DENOMINADOR: os tres baldes TEM de somar o total. Se nao
  # somarem, o classificador parou de casar e o gate passaria descrevendo outra
  # coisa -- falha nomeando, em vez de seguir.
  if [ "$((sob + lapsed + fora))" -ne "$total" ]; then
    echo "check-req-done-com-criterio-aberto: FALHA — denominador nao reconcilia em ${b}: sob=${sob} + lapsed=${lapsed} + fora=${fora} != total=${total}" >&2
    exit 1
  fi
  [ "$lapsed" -gt 0 ] && acs_caducados=$((acs_caducados + lapsed))

  # RECONCILIAÇÃO: checkbox aberto que o gate não soube atribuir a bloco de
  # critério. Não acusa -- mas também não some. Medido: existe exatamente um
  # caso hoje (REQ-2026-09-05-reqs-que-passam-so-por-prosa), e ele foi tratado
  # como ML próprio justamente por não caber no lote.
  if [ "$fora" -gt 0 ]; then
    echo "  ⚠ reconciliação: ${b} — ${fora} checkbox(es) aberto(s) FORA de bloco de critério" >&2
    fora_de_bloco=$((fora_de_bloco + 1))
  fi

  if [ "$lst" != "done" ]; then
    [ "$sob" -gt 0 ] && abertas_legitimas=$((abertas_legitimas + 1))
    continue
  fi

  if [ "$sob" -gt 0 ]; then
    echo "  ✗ ${b}: status '${st}' com ${sob} critério(s) de aceite EM ABERTO" >&2
    acusadas=$((acusadas + 1))
    acs_acusados=$((acs_acusados + sob))
  fi
done < <(find "$ROOT_DIR/$REQ_DIR" -type f -name '*.md' | sort)

# ---------------------------------------------------------------------------
# Guardas de vacuidade
# ---------------------------------------------------------------------------
if [ "$varridas" -eq 0 ]; then
  echo "check-req-done-com-criterio-aberto: GUARDA — zero REQs varridas em '$REQ_DIR'" >&2
  exit 1
fi

# Se NENHUMA herdada foi excluída, a exclusão quebrou -- e o gate estaria prestes
# a acusar governança do upstream, ou já acusou. Medido: são 28 em 2026-09-10.
if [ "$herdadas" -eq 0 ]; then
  echo "check-req-done-com-criterio-aberto: GUARDA — zero REQs herdadas detectadas." >&2
  echo "  A exclusão das 28 do upstream quebrou. Sem ela este gate acusa governança dele." >&2
  exit 1
fi

if [ "$acusadas" -gt 0 ]; then
  echo "" >&2
  echo "${acusadas} REQ(s) marcada(s) 'done' com ${acs_acusados} critério(s) de aceite em aberto." >&2
  echo "  (${acs_caducados} outro(s) critério(s) com \`Caducou:\` justificado NÃO estão nesta conta)" >&2
  echo "" >&2
  echo "TRÊS saídas legítimas, e só estas três:" >&2
  echo "  1. o critério foi atendido  -> marque [x], NOMEANDO o sítio no produto que comprova" >&2
  echo "  2. o critério não foi atendido -> a REQ deixa de ser 'done'" >&2
  echo "  3. o critério CADUCOU -> a caixa fica '- [ ]' e ganha a continuação canônica:" >&2
  echo "" >&2
  echo "       - [ ] <critério>" >&2
  echo "         Caducou: <justificativa obrigatória>" >&2
  echo "" >&2
  echo "     >= 2 espaços (não tabulação), linha imediatamente seguinte, sem linha em" >&2
  echo "     branco, e justificativa não vazia. A forma é do PRODUTO (#519 do upstream," >&2
  echo "     que implementa a nossa #514); a fonte da verdade é" >&2
  echo "     internal/roadmapdoc/roadmapdoc.go, LapsedContinuationRe." >&2
  echo "" >&2
  echo "🔴 Reescrever o critério para que o estado atual o satisfaça NÃO é saída: é" >&2
  echo "   fabricar histórico, e é o defeito que este gate existe para fechar. A saída 3" >&2
  echo "   NÃO é essa: ela mantém o critério não atendido e exige dizer POR QUE caducou." >&2
  exit 1
fi

echo "check-req-done-com-criterio-aberto: ${varridas} REQ(s) varrida(s) em '${REQ_DIR}' · ${herdadas} herdada(s) excluída(s) · ${abertas_legitimas} não-'done' com critério aberto (legítimo) · ${acs_caducados} critério(s) com \`Caducou:\` justificado (não acusam)"
if [ "$fora_de_bloco" -gt 0 ]; then
  echo "  ⚠ ${fora_de_bloco} REQ(s) com checkbox fora de bloco de critério (ver acima) — não acusadas, mas nomeadas"
fi
echo "Nenhuma REQ 'done' com critério de aceite em aberto."
