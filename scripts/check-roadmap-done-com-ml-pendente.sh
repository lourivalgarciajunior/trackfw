#!/usr/bin/env bash
# check-roadmap-done-com-ml-pendente.sh — acusa roadmap NOSSO em `done/` com ML que
# nao esta ✅ Concluido e que NAO declara o fechamento retroativo.
#
# REQ-2026-10-08-roadmap-done-com-ml-pendente-nao-tem-gate-e-a-premissa-ingenua-acusaria-17-legitimos
#
# POR QUE ELE EXISTE, e por que a premissa ingenua estava ERRADA
# --------------------------------------------------------------
# Em 2026-10-08 uma varredura achou 17 roadmaps em done/ com ML ⬜ Pendente e isso
# quase virou trabalho de marcar 14 MLs. A medicao recusou:
#
#   HERDADOS do upstream   15   (derivado, nao allowlist)
#   NOSSOS, DECLARADOS      2   ("Fechado retroativamente em 2026-08-16 … os MLs
#                                abaixo permanecem ⬜ Pendente DE PROPOSITO")
#   contradicao real        0
#
# Marcar aqueles MLs ✅ teria afirmado execucao que nao houve — fabricar historico,
# a mesma saida que o check-req-done-com-criterio-aberto.sh recusa. O fechamento
# por INSPECAO DO ENTREGAVEL e legitimo e ja estava escrito desde agosto.
#
# 🔴 A PREMISSA E UM MARCADOR, NUNCA PROSA. A deteccao do fechamento declarado NAO
# procura as palavras "de proposito": procura a marca explicita abaixo. Premissa em
# prosa foi o defeito que levamos ao upstream na #530 — registro historico cita a
# frase, e o gate ficaria vermelho para sempre. Mesma licao do
# check-contorno-dos-shims-caducou.sh, que trocou string por marca.
MARCA='<!-- fechamento-retroativo:'

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

autoteste=0
[ "${1:-}" = "--self-test" ] && autoteste=1

# roadmap_dir sai do trackfw.yaml, nunca chumbado (precedente: check-req-layout.sh)
RD="$(awk '/^roadmap_dir:/{print $2; exit}' trackfw.yaml 2>/dev/null | tr -d '"'"'"'')"
RD="${RD:-docs/roadmaps}"

# ML nao concluido: linha de status que nao e ✅. A forma vem do protocolo do
# CLAUDE.md: "**Status:** ⬜ Pendente" / "🔄 Em andamento" / "✅ Concluido".
ml_nao_concluido() {
	grep -qE '^\*\*Status:\*\* (⬜ Pendente|🔄 Em andamento|❌ Bloqueado)' "$1"
}

# Herdado do upstream: derivado, como no check-inherited-req.sh. Nunca allowlist.
herdado() {
	local b="${1##*/}"
	git cat-file -e "upstream/main:docs/roadmaps/done/$b" 2>/dev/null && return 0
	git cat-file -e "upstream/main:docs/roadmaps/$b" 2>/dev/null && return 0
	return 1
}

declara_fechamento() {
	grep -qF "$MARCA" "$1"
}

if [ "$autoteste" = 1 ]; then
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"' EXIT
	ok=0
	falhas=0
	caso() { # caso <nome> <esperado sim|nao> <conteudo...>
		local nome="$1" esperado="$2"
		shift 2
		printf '%s\n' "$@" > "$tmp/r.md"
		local real=nao
		ml_nao_concluido "$tmp/r.md" && real=sim
		if [ "$real" = "$esperado" ]; then ok=$((ok+1)); else
			falhas=$((falhas+1)); printf '  ✗ %s: esperava %s, deu %s\n' "$nome" "$esperado" "$real"
		fi
	}
	casoM() { # casoM <nome> <esperado sim|nao> <conteudo...>
		local nome="$1" esperado="$2"
		shift 2
		printf '%s\n' "$@" > "$tmp/r.md"
		local real=nao
		declara_fechamento "$tmp/r.md" && real=sim
		if [ "$real" = "$esperado" ]; then ok=$((ok+1)); else
			falhas=$((falhas+1)); printf '  ✗ %s: esperava %s, deu %s\n' "$nome" "$esperado" "$real"
		fi
	}

	caso "ML pendente"            sim '**Status:** ⬜ Pendente'
	caso "ML em andamento"        sim '**Status:** 🔄 Em andamento'
	caso "ML bloqueado"           sim '**Status:** ❌ Bloqueado'
	caso "ML concluido"           nao '**Status:** ✅ Concluído'
	caso "todos concluidos"       nao '**Status:** ✅ Concluído' '**Status:** ✅ Concluído'
	caso "um pendente entre ok"   sim '**Status:** ✅ Concluído' '**Status:** ⬜ Pendente'
	caso "status NAO ancorado"    nao '  **Status:** ⬜ Pendente'
	caso "prosa citando o status" nao 'troque `**Status:** ⬜ Pendente` por concluido'
	caso "roadmap sem ML"         nao '# Roadmap' 'nenhum ML aqui'
	casoM "marca presente"        sim '<!-- fechamento-retroativo: 2026-08-16 — por inspecao -->'
	casoM "marca sem data"        sim '<!-- fechamento-retroativo: -->'
	casoM "PROSA citando a marca" nao 'o fechamento foi retroativo, de propósito, em 2026-08-16'
	casoM "marca so no nome"      nao 'fechamento-retroativo sem a forma de comentario'
	casoM "sem marca nenhuma"     nao '# Roadmap' '**Status:** ⬜ Pendente'

	total=$((ok+falhas))
	echo "self-test: $ok de $total caso(s) passaram"
	[ "$total" -ge 14 ] || { echo "✗ VACUIDADE: menos de 14 casos exercitados ($total)"; exit 1; }
	[ "$falhas" = 0 ] || exit 1
	echo "✓ self-test ok"
	exit 0
fi

git rev-parse --verify --quiet upstream/main >/dev/null || {
	echo "✗ upstream/main nao resolve — rode 'git fetch upstream --prune'."
	echo "  O gate NAO faz fetch de proposito: gate que muda o estado que mede deixa de ser gate."
	exit 1
}

total=0; herdados=0; declarados=0; limpos=0; acusados=0
lista_acusados=""
while IFS= read -r f; do
	[ -n "$f" ] || continue
	total=$((total+1))
	ml_nao_concluido "$f" || { limpos=$((limpos+1)); continue; }
	if herdado "$f"; then herdados=$((herdados+1)); continue; fi
	if declara_fechamento "$f"; then declarados=$((declarados+1)); continue; fi
	acusados=$((acusados+1)); lista_acusados="$lista_acusados${f##*/}
"
done <<EOF
$(find "$RD" -type d -name done -print0 2>/dev/null | xargs -0 -I{} find {} -name '*.md' -type f 2>/dev/null)
EOF

echo "roadmap-done-com-ml-pendente:"
echo "  varridos em done/        $total"
echo "  sem ML pendente          $limpos"
echo "  herdados do upstream     $herdados   (derivado por git cat-file, nao allowlist)"
echo "  fechamento DECLARADO     $declarados   (marca $MARCA …)"
echo "  ACUSADOS                 $acusados"

# Reconciliacao: os quatro baldes somam o total, ou o classificador parou de casar.
soma=$((limpos+herdados+declarados+acusados))
[ "$soma" = "$total" ] || { echo "✗ RECONCILIACAO: $limpos+$herdados+$declarados+$acusados = $soma != $total"; exit 1; }

# Vacuidade 1: varrer zero e derivacao quebrada, nao acervo limpo.
[ "$total" -gt 0 ] || { echo "✗ VACUIDADE: zero roadmaps varridos em $RD/**/done — a varredura quebrou."; exit 1; }

# Vacuidade 2: o acervo tem herdadas conhecidas; zero significa que o cat-file
# parou de resolver (ref ausente ja foi tratada acima, mas caminho pode mudar).
if [ "$herdados" = 0 ]; then
	echo "✗ VACUIDADE: zero herdados detectados. Em 2026-10-08 eram 15; zero aqui e"
	echo "  derivacao quebrada, nao acervo limpo. Confira o caminho em upstream/main."
	exit 1
fi

if [ "$acusados" != 0 ]; then
	echo
	echo "✗ roadmap NOSSO em done/ com ML nao concluido e SEM fechamento declarado:"
	printf '%s' "$lista_acusados" | sed 's/^/    /'
	echo
	echo "  Duas saidas, e a terceira esta RECUSADA:"
	echo "    (a) os MLs foram executados -> marque ✅ Concluido, um a um"
	echo "    (b) o roadmap fechou por INSPECAO DO ENTREGAVEL -> declare, nomeando o sitio:"
	echo "        $MARCA <data> — <por que, e onde esta o entregavel> -->"
	echo "    (c) marcar ✅ sem execucao NAO e saida: e afirmar entrega que nao houve."
	exit 1
fi

echo "✓ nenhum roadmap nosso em done/ com ML pendente nao declarado."
