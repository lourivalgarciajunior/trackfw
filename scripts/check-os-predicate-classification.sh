#!/usr/bin/env bash
#
# Lint do AC2 da REQ-2026-09-05-onda-2: predicado de SO em sítio de
# CLASSIFICAÇÃO.
#
# O discriminante é a `ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao`,
# escrita a partir da nossa medição depois que se descobriu que o AC delegava a
# decisão ao D2 de uma ADR do upstream — que não existe neste repositório.
#
#   D1  argumento e ERRO de chamada de sistema  -> travessia, FORA de escopo
#   D2  argumento e STRING AUTORADA             -> classificacao, EM escopo
#   D3  plataforma lida UMA vez para constante  -> a costura, nao a violacao
#   D4  o onus e de quem quer excluir           -> exclusao escrita
#   D5  com teste e sem teste, SEPARADOS        -> misturar falseou 3x
#
# ESTE GATE E UM RATCHET, NAO UMA VARREDURA DE LIMPEZA.
#
# Medido em 2026-09-10: dos 110 sitios sem arquivo de teste, 59 saem por D1 (o
# `os.IsNotExist` recebe `err` em TODOS os sitios de codigo), 12 sao plataforma
# (4 costura + 8 comentario), e ~26 sao classificacao — TODOS em produto do
# upstream.
#
# 🔴 Corrigi-los aqui criaria divergencia de produto, que hoje e ZERO. O escopo
# negativo da REQ decide: achado vira ISSUE, nao correcao local. Entao o gate
# congela os conhecidos, COM MOTIVO, e reprova o proximo.
#
# Ver ADR-2026-09-09 e REQ-2026-09-05-onda-2.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

ESCOPO=(internal npm/src pypi/trackfw cmd)
PREDICADOS='filepath\.IsAbs|os\.path\.isabs|path\.isAbsolute|process\.platform|os\.name|os\.IsNotExist'

# ---------------------------------------------------------------------------
# BASELINE — sitios de classificacao conhecidos em 2026-09-10, COM MOTIVO.
#
# Formato: <arquivo>:<predicado>|<motivo>
# Granularidade de ARQUIVO, nao de linha: numero de linha muda a cada merge do
# upstream e o baseline viraria ruido. O que importa e "este arquivo ja tinha
# sitio de classificacao"; um arquivo NOVO com sitio novo e o que o gate pega.
# ---------------------------------------------------------------------------
BASELINE="
internal/integrations/manager.go|resolucao de caminho de instalacao de integracao; produto do upstream, e o maior sitio unico (10 ocorrencias)
internal/validator/validator.go|validacao de caminho relativo em artefato; produto do upstream
npm/src/integrations/manager.js|espelho Node do manager.go; produto do upstream
npm/src/validator/index.js|espelho Node do validator.go; produto do upstream
pypi/trackfw/validator.py|espelho Python do validator.go; produto do upstream
pypi/trackfw/generators/req.py|resolve req_dir vindo do trackfw.yaml; produto do upstream
pypi/trackfw/generators/adr.py|resolve adr_dir vindo do trackfw.yaml; produto do upstream
pypi/trackfw/commands/status.py|resolve caminho de artefato; produto do upstream
npm/src/commands/serve.js|costura, nao classificacao: le process.platform uma vez e injeta no openBrowser (mesmo desenho do _browser_argv do Python); o D3 deste lint so reconhece atribuicao a constante nomeada, nao a plataforma passada como argumento. Produto do upstream (#321)
"

esta_no_baseline() {
  printf '%s' "$BASELINE" | grep -q "^${1}|"
}

# ---------------------------------------------------------------------------
# Classificadores. Cada um implementa uma decisao da ADR.
# ---------------------------------------------------------------------------
eh_comentario() {  # a linha e comentario?
  case "$(printf '%s' "$1" | sed 's/^[[:space:]]*//')" in
    '//'*|'#'*|'*'*|'/*'*) return 0 ;;
    *) return 1 ;;
  esac
}

eh_d1_travessia() {  # D1: o predicado recebe um valor de ERRO
  printf '%s' "$1" | grep -qE 'IsNotExist\((err|readErr|[a-zA-Z_][a-zA-Z0-9_]*[Ee]rr)\)'
}

eh_d3_costura() {  # D3: leitura UNICA da plataforma para uma constante nomeada
  printf '%s' "$1" | grep -qE '(let|const|var)?[[:space:]]*[_a-zA-Z][_a-zA-Z0-9]*[[:space:]]*=[[:space:]]*(process\.platform|os\.name)'
}

eh_teste() {
  case "$1" in *_test.go|*.test.js|*test_*.py|*/tests/*|*/test/*) return 0 ;; *) return 1 ;; esac
}

# ---------------------------------------------------------------------------
# Varredura
# ---------------------------------------------------------------------------
varridos=0; com_teste=0; d1=0; d3=0; coment=0
classificacao=0; nao_declarados=0
declare -a arq_vistos=()

while IFS=: read -r f l pred; do
  [ -n "${f:-}" ] || continue
  varridos=$((varridos + 1))
  if eh_teste "$f"; then com_teste=$((com_teste + 1)); continue; fi

  linha=$(sed -n "${l}p" "$f" 2>/dev/null || true)
  [ -n "$linha" ] || continue

  if eh_comentario "$linha";  then coment=$((coment + 1)); continue; fi
  if eh_d1_travessia "$linha"; then d1=$((d1 + 1)); continue; fi
  if eh_d3_costura "$linha";   then d3=$((d3 + 1)); continue; fi

  classificacao=$((classificacao + 1))
  if ! esta_no_baseline "$f"; then
    echo "  ✗ CLASSIFICACAO NAO DECLARADA: ${f}:${l} — ${pred}" >&2
    echo "      $(printf '%s' "$linha" | sed 's/^[[:space:]]*//' | cut -c1-92)" >&2
    nao_declarados=$((nao_declarados + 1))
  else
    ja=0; for v in "${arq_vistos[@]:-}"; do [ "$v" = "$f" ] && ja=1; done
    [ "$ja" -eq 0 ] && arq_vistos+=("$f")
  fi
done < <({ git grep -a -n -o -E "$PREDICADOS" -- "${ESCOPO[@]}" 2>/dev/null || true; } | sort -u)

# ---------------------------------------------------------------------------
# Guardas de vacuidade
# ---------------------------------------------------------------------------
if [ "$varridos" -eq 0 ]; then
  echo "check-os-predicate-classification: GUARDA — zero sitios varridos em ${ESCOPO[*]}" >&2
  echo "  Seis predicados sumirem de uma vez e a busca ter quebrado, nao limpeza." >&2
  exit 1
fi

if [ "$d1" -eq 0 ]; then
  echo "check-os-predicate-classification: GUARDA — zero sitios classificados como D1." >&2
  echo "  O os.IsNotExist recebe 'err' em TODOS os sitios de codigo medidos; zero aqui" >&2
  echo "  significa que o classificador D1 parou de casar, e tudo viraria classificacao." >&2
  exit 1
fi

if [ "$nao_declarados" -gt 0 ]; then
  echo "" >&2
  echo "${nao_declarados} sitio(s) de CLASSIFICACAO em arquivo nao declarado." >&2
  echo "" >&2
  echo "Pela ADR-2026-09-09, predicado de SO aplicado a string AUTORADA decide" >&2
  echo "significado que tem de ser o mesmo em todo SO. Duas saidas:" >&2
  echo "  1. o sitio passa a usar o resolvedor canonico (internal/pathanchor e espelhos)" >&2
  echo "  2. o arquivo entra no BASELINE deste script COM O MOTIVO ESCRITO" >&2
  echo "" >&2
  echo "🔴 Baseline sem motivo escrito e o mesmo que nao ter regra (D4)." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Denominador. D5: com teste e sem teste, SEPARADOS.
# ---------------------------------------------------------------------------
echo "check-os-predicate-classification: ${varridos} sitio(s) varrido(s) em ${ESCOPO[*]}"
echo "  com arquivo de teste (D5, reportado a parte) : ${com_teste}"
echo "  D1 travessia   (argumento e erro)            : ${d1}"
echo "  D3 costura     (plataforma p/ constante)     : ${d3}"
echo "  comentario                                    : ${coment}"
echo "  D2 CLASSIFICACAO                              : ${classificacao}  em ${#arq_vistos[@]} arquivo(s) declarado(s)"

# Declaracao que nao corresponde mais a nada e lixo: avisa, mas nao reprova --
# some sozinha quando o sitio for corrigido. Mesmo tratamento do
# check-subcommand-parity.
obsoletas=0
printf '%s
' "$BASELINE" | while IFS='|' read -r arq motivo; do
  [ -n "$arq" ] || continue
  achou=0
  for v in "${arq_vistos[@]:-}"; do [ "$v" = "$arq" ] && achou=1; done
  [ "$achou" -eq 0 ] && echo "  ⚠ declaracao obsoleta: '${arq}' nao tem mais sitio de classificacao — remova do BASELINE"
done
echo "Nenhum sitio de classificacao fora do baseline."
