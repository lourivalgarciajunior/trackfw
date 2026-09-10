#!/usr/bin/env bash
#
# Deriva quais REQs do NOSSO req_dir são governança do upstream, e trava o
# conjunto conhecido para que um merge futuro não importe mais nenhuma em
# silêncio.
#
# A ADR-2026-08-29 decide: "A governança do upstream NÃO é importada." Vinte e
# seis REQs entraram aqui em 2026-06-28, quando este repo era cópia por ZIP,
# antes daquela decisão. Elas ficam — a REQ-2026-09-09 trata o destino delas —
# mas o conjunto passa a ser CONGELADO: uma 29ª reprova o gate.
#
# Por que este script existe, e não uma contagem à mão: o número de REQs
# herdadas com critério aberto já foi publicado ERRADO TRÊS VEZES, e as três por
# varredura minha mais estreita que o alvo:
#
#   PR #65               6 REQs ·  54  glob de UM nível, não descia em <agente>/backlog/
#   comentário na #65    8 REQs ·  70  comparação `= "Done"`, perdeu seis `done` minúsculos
#   REQ #76             14 REQs · 109  não reproduzível: nenhuma varredura testada
#                                      em 2026-09-09 chega nesse par
#   este script         (medido)       derivado, com denominador e reconciliação
#
# A quarta armadilha foi encontrada ao conferir a terceira: o heading do bloco
# de critério aparece nas duas grafias — `## Critérios de Aceite` (10 arquivos)
# e `## Critérios de aceite` (13). Um grep case-sensitive perde metade do
# acervo. Por isso o casamento aqui é por tolower(), e por isso o gate RECONCILIA
# o que não soube classificar em vez de absorver no total.
#
# Ver REQ-2026-09-09-governanca-do-upstream-vive-no-nosso-req-dir-28-reqs-contra-a-adr-2026-08-29.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

CONFIG="$ROOT_DIR/trackfw.yaml"
UPSTREAM_REF=${UPSTREAM_REF:-upstream/main}
UPSTREAM_REQ_DIR=${UPSTREAM_REQ_DIR:-docs/req}

# ---------------------------------------------------------------------------
# Baseline congelado — as 28 herdadas conhecidas em 2026-09-09.
#
# Entrada nova aqui exige decisão escrita: é governança do upstream entrando no
# nosso acervo, que é o que a ADR-2026-08-29 recusa. Remover uma entrada é
# legítimo quando a REQ sair daqui — o gate avisa quando uma declaração deixa de
# corresponder a alguma coisa.
# ---------------------------------------------------------------------------
baseline=(
  "REQ-2026-06-12-i18n-wizard-java-scaffold.md"
  "REQ-2026-06-13-discovery-mode-cmdb.md"
  "REQ-2026-06-13-gaps-v2-implementacao.md"
  "REQ-2026-06-13-python-cli-nativo.md"
  "REQ-2026-06-13-traceid-bidirecional.md"
  "REQ-2026-06-13-trackfw-ai-agent-governance-rail.md"
  "REQ-2026-06-13-v2.4-config-evolution.md"
  "REQ-2026-06-13-v2.4.1-baseline-ratchet-warnings.md"
  "REQ-2026-06-13-v2.5.1-json-fields-help-traceid.md"
  "REQ-2026-06-13-validate-json-output.md"
  "REQ-2026-06-13-validator-improvements.md"
  "REQ-2026-06-14-context-req-by-agent.md"
  "REQ-2026-06-14-req-indexing-by-agent.md"
  "REQ-2026-06-14-rules-req-configuraveis.md"
  "REQ-2026-06-14-serve-api-tests-nodejs.md"
  "REQ-2026-06-14-traceid-by-agent-support.md"
  "REQ-2026-06-14-trackfw-serve-ui.md"
  "REQ-2026-06-15-discover-init-hook-autoinstall.md"
  "REQ-2026-06-18-trackfw-update-command.md"
  "REQ-2026-06-19-analyzing-state-ml-status-rules.md"
  "REQ-2026-06-19-architect-command-guidelines.md"
  "REQ-2026-06-20-attention-hooks-agent-clis.md"
  "REQ-adr-wizard-e-list-2026-06-11.md"
  "REQ-multi-ai-support-2026-06-11.md"
  "REQ-req-driven-adr-discovery-2026-06-12.md"
  "REQ-req-wizard-e-list-2026-06-11.md"
  "REQ-roadmap-ai-generation-2026-06-11.md"
  "REQ-testes-unitarios-go-2026-06-11.md"
)

is_baseline() {
  local b="$1" k
  for k in "${baseline[@]}"; do
    [ "$k" = "$b" ] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# Pré-condições — um gate que não pode medir tem de DIZER, não passar.
# ---------------------------------------------------------------------------
if [ ! -f "$CONFIG" ]; then
  echo "check-inherited-req: FALHA — trackfw.yaml não encontrado em $ROOT_DIR" >&2
  exit 1
fi

REQ_DIR=$(sed -n 's/^req_dir:[[:space:]]*//p' "$CONFIG" | head -1 | tr -d '"' | tr -d "'" | tr -d '\r')
if [ -z "$REQ_DIR" ] || [ ! -d "$ROOT_DIR/$REQ_DIR" ]; then
  echo "check-inherited-req: FALHA — req_dir '$REQ_DIR' ausente do trackfw.yaml ou inexistente" >&2
  exit 1
fi

if ! git rev-parse --verify --quiet "$UPSTREAM_REF" >/dev/null; then
  echo "check-inherited-req: FALHA — ref '$UPSTREAM_REF' não existe." >&2
  echo "  A derivação compara com o upstream; sem a ref não há com o que comparar." >&2
  echo "  Rode 'git fetch upstream' — este gate NÃO faz fetch sozinho, porque um" >&2
  echo "  gate que muda o estado que ele mede deixa de ser gate." >&2
  exit 1
fi

if ! git cat-file -t "${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}" >/dev/null 2>&1; then
  echo "check-inherited-req: FALHA — '${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}' não é um diretório." >&2
  echo "  Se o upstream renomeou o req_dir dele, a derivação inteira vira vácuo:" >&2
  echo "  toda REQ pareceria 'só nossa'. Ajuste UPSTREAM_REQ_DIR com a medição escrita." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Censo de critério aberto — com reconciliação.
#
# Devolve: <abertos_sob_criterio> <abertos_total>
# O segundo número existe para o gate poder dizer o que NÃO soube classificar.
# ---------------------------------------------------------------------------
censo_criterio() {  # censo_criterio <arquivo>
  awk '
    # O bloco de critério ABRE num heading e só FECHA num heading de nível igual
    # ou mais raso. `## Critérios de Aceite` seguido de `### Bloco A` continua
    # dentro do bloco -- medido: `REQ-2026-06-13-python-cli-nativo.md` põe os 26
    # checkboxes sob seis subheadings, e uma leitura que zerasse o estado a cada
    # `###` devolveria zero.
    #
    # O casamento evita caractere acentuado de propósito: `[eé]` numa classe de
    # caractere não casa UTF-8 no awk desta máquina, e o resultado é o mesmo
    # zero, agora silencioso. Então casa por pedaço ASCII: `crit`+`aceit`.
    /^#+[ ]/ {
      lvl = index($0, " ") - 1
      h = tolower($0)
      ehcrit = ((h ~ /crit/ && h ~ /aceit/) || (h ~ /acceptance/ && h ~ /criteri/)) ? 1 : 0
      if (ehcrit)                        { dentro = 1; base = lvl }
      else if (dentro && lvl <= base)    { dentro = 0 }
      next
    }
    /^-[ ]\[[ ]\]/ {
      total++
      if (dentro) sob++
    }
    END { printf "%d %d\n", sob+0, total+0 }
  ' "$1"
}

# ---------------------------------------------------------------------------
# Derivação
# ---------------------------------------------------------------------------
varridas=0
herdadas=0
nao_declaradas=0
sem_procedencia=0
sem_heading=0
tot_sob=0
tot_total=0
com_aberto=0
declare -a vistas=()

while IFS= read -r f; do
  varridas=$((varridas + 1))
  b=$(basename "$f")
  git cat-file -e "${UPSTREAM_REF}:${UPSTREAM_REQ_DIR}/${b}" 2>/dev/null || continue

  herdadas=$((herdadas + 1))
  vistas+=("$b")

  if ! is_baseline "$b"; then
    echo "  ✗ NÃO DECLARADA: '${b}' é governança do upstream e entrou depois do baseline" >&2
    nao_declaradas=$((nao_declaradas + 1))
  fi

  # PROCEDÊNCIA NO PRÓPRIO ARQUIVO (ML-2A).
  #
  # A decisão da Wave 2 foi UMA, aplicada às 28: elas ficam onde estão e a
  # procedência é declarada no frontmatter. O AC2 mediu que remover é impossível
  # (26 vetadas pelo snapshot congelado do barrier, 2 por ADR nossa) e o escopo
  # negativo já proibia mover.
  #
  # A declaração vive só no FRONTMATTER, de propósito: medido em 2026-09-09, o
  # `req list` dos três runtimes lê o status de uma linha do CORPO
  # (`> Date: … | Status: <status>`), não do frontmatter. Uma nota em blockquote
  # logo abaixo do H1 poderia ser capturada por aquele extrator. Falsificado por
  # efeito: `req list` antes e depois das 28 edições é byte a byte idêntico.
  #
  # Sem esta checagem, a decisão seria decorativa -- alguém apaga a linha e nada
  # acusa.
  esperado="kgsaran/trackfw:${UPSTREAM_REQ_DIR}/${b}"
  declarado=$(sed -n 's/^upstream_origin:[[:space:]]*//p' "$f" | head -1 | tr -d '"' | tr -d "'" | tr -d '\r')
  if [ -z "$declarado" ]; then
    echo "  ✗ SEM PROCEDÊNCIA: '${b}' é herdada e não declara 'upstream_origin' no frontmatter" >&2
    sem_procedencia=$((sem_procedencia + 1))
  elif [ "$declarado" != "$esperado" ]; then
    echo "  ✗ PROCEDÊNCIA ERRADA: '${b}' declara '${declarado}', esperado '${esperado}'" >&2
    sem_procedencia=$((sem_procedencia + 1))
  fi

  read -r sob total < <(censo_criterio "$f")
  tot_sob=$((tot_sob + sob))
  tot_total=$((tot_total + total))
  [ "$total" -gt 0 ] && com_aberto=$((com_aberto + 1))

  # RECONCILIAÇÃO: checkbox aberto que o gate não conseguiu atribuir a um bloco
  # de critério. Absorver isso no total daria um número maior sem dizer de onde
  # veio; descartar daria um número menor pelo mesmo silêncio. Os dois já
  # aconteceram neste acervo. Então: nomeia.
  if [ "$total" -gt "$sob" ]; then
    echo "  ⚠ reconciliação: ${b} — $((total - sob)) de ${total} checkbox(es) aberto(s) FORA de bloco de critério reconhecido" >&2
    sem_heading=$((sem_heading + 1))
  fi
done < <(find "$ROOT_DIR/$REQ_DIR" -type f -name '*.md' | sort)

# ---------------------------------------------------------------------------
# Guardas de vacuidade — verde sobre zero não é evidência.
# ---------------------------------------------------------------------------
if [ "$varridas" -eq 0 ]; then
  echo "check-inherited-req: GUARDA — zero REQs varridas em '$REQ_DIR'" >&2
  exit 1
fi

if [ "$herdadas" -eq 0 ] && [ "${#baseline[@]}" -gt 0 ]; then
  echo "check-inherited-req: GUARDA — zero herdadas derivadas, mas o baseline declara ${#baseline[@]}." >&2
  echo "  Isso não é 'limpamos tudo': é a derivação tendo quebrado. Meça antes de esvaziar o baseline." >&2
  exit 1
fi

# Declaração obsoleta: some sozinha quando a REQ sair daqui. Avisa, não falha.
obsoletas=0
for k in "${baseline[@]}"; do
  achou=0
  for v in "${vistas[@]}"; do
    [ "$v" = "$k" ] && { achou=1; break; }
  done
  if [ "$achou" -eq 0 ]; then
    echo "  ⚠ declaração obsoleta: '${k}' não está mais no acervo — remova do baseline" >&2
    obsoletas=$((obsoletas + 1))
  fi
done

if [ "$sem_procedencia" -gt 0 ]; then
  echo "" >&2
  echo "${sem_procedencia} REQ(s) herdada(s) sem a declaracao de procedencia correta." >&2
  echo "A decisao do ML-2A e que as 28 ficam onde estao COM a procedencia escrita no" >&2
  echo "frontmatter. Apagar a linha nao 'limpa' nada -- so torna a heranca invisivel." >&2
  exit 1
fi

if [ "$nao_declaradas" -gt 0 ]; then
  echo "" >&2
  echo "${nao_declaradas} REQ(s) do upstream entrou(ram) no nosso req_dir sem declaração." >&2
  echo "A ADR-2026-08-29 decide que a governança do upstream não é importada." >&2
  echo "Se a entrada for deliberada, declare no baseline com o motivo escrito." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Denominador. Verde sem denominador não é evidência.
# ---------------------------------------------------------------------------
echo "check-inherited-req: ${varridas} REQ(s) varrida(s) em '${REQ_DIR}' · ${herdadas} herdada(s) do upstream · ${#baseline[@]} declarada(s)"
echo "  critério aberto: ${com_aberto} REQ(s) herdada(s) · ${tot_sob} sob bloco de critério · ${tot_total} checkbox(es) aberto(s) no total"
if [ "$sem_heading" -gt 0 ]; then
  echo "  ⚠ ${sem_heading} REQ(s) com checkbox fora de bloco de critério reconhecido (ver acima)"
fi
if [ "$obsoletas" -gt 0 ]; then
  echo "Inherited REQ check passed (${obsoletas} declaração(ões) obsoleta(s))"
else
  echo "Inherited REQ check passed"
fi
