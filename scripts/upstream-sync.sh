#!/usr/bin/env bash
# upstream-sync.sh — merge do upstream com RETENÇÃO da governança local.
#
# REQ-2026-09-05-procedimento-de-merge-do-upstream-com-retencao-da-governanca-local
# Governado por ADR-2026-08-29-adotar-upstream-como-base: produto vem do upstream;
# docs/ e vault/ são locais e NUNCA são importados — com UMA exceção nomeada,
# `docs/cli-parity.md`, que é contrato de produto lido por gate do produto (ver
# PRODUTO_EM_DOCS abaixo).
#
# Por que existe
# -------------
# Com `roadmap_namespacing: by_agent`, o git detecta os roadmaps flat do upstream
# (docs/roadmaps/wip/) como RENOMEAÇÃO dos nossos (docs/roadmaps/claude/done/) e produz
# uma enxurrada de conflitos rename/delete — 23 no merge de 4f0ad33. Resolver um a um é
# caro e erra fácil, e a ADR já decidiu o resultado: não há julgamento a fazer.
#
# O que este script NÃO faz, de propósito
# ---------------------------------------
#   - não faz push
#   - não commita por padrão (o commit carrega a medição, e quem mede é quem escreve)
#   - não resolve conflito de PRODUTO: se sobrar algum, ABORTA e devolve a árvore
#
# Falsificação (AC4): scripts/check-upstream-sync-falsify.sh exercita este script contra
# merges HISTÓRICOS reais, nos dois extremos, mais dois controles negativos (árvore suja e
# ref inexistente). A propriedade verificada é a INVARIANTE — retido ⊆ docs/ ∪ vault/, e
# todo o resto trazido —, não a contagem de arquivos: a contagem à mão errou nos DOIS casos.

# ── Produto que mora em docs/ — TRAZIDO, não retido ─────────────────────────────
# 🔴 Lista literal e curta DE PROPÓSITO. Cada entrada precisa de um gate do upstream que a
# leia; "é documentação de produto" sozinho não basta, senão a lista vira depósito.
#
# docs/cli-parity.md — lido por scripts/check-parity-contract-coverage.sh, que reprova
# seção cuja anotação nomeia gate inexistente. Retido desde o #259, o nosso ficou parado;
# a v8.0.0 (#365) removeu os gates que ele citava, e o gate de cobertura passou a reprovar
# o parity-other-gates em Makefile:35 — antes do barrier —, e o item 4 do
# windows-defect-reproduction travou até o timeout. Medido em 2026-09-16, PR #135.
# Decisão do usuário: trazer e manter trazendo.
# Ver REQ-2026-09-16-gates-so-nossos-depois-da-v8, ML-3A.
PRODUTO_EM_DOCS="docs/cli-parity.md"

# ── Governança que mora FORA de docs/ — RETIDA, não trazida ─────────────────────
# O simétrico da lista acima. trackfw.yaml é a configuração da NOSSA governança
# (req_dir: docs/requisições, by_agent, três agentes, strict) — a ADR-2026-08-29 já
# decide que governança é local. Até 2026-09-18 nenhum merge do upstream tinha tocado
# nele; o #393 acrescentou `lenient_until` ao dele, as linhas colidiram com as nossas,
# e o sync abortou com "conflito de PRODUTO". Decisão do usuário: reter sempre o nosso.
#
# Reter não é ignorar: quando o upstream muda o arquivo, o sync IMPRIME o diff dele,
# para quem sincroniza decidir se há chave nova que nos interesse. A retenção é provada
# por efeito junto com docs/.
# Ver REQ-2026-09-18-upstream-sync-retem-o-trackfw-yaml-do-fork-como-retem-docs.
GOVERNANCA_FORA_DE_DOCS="trackfw.yaml"

set -euo pipefail

REF="upstream/main"
DO_COMMIT=0
SKIP_VERIFY=0

usage() {
	cat <<'USAGE'
uso: scripts/upstream-sync.sh [--ref <git-ref>] [--commit] [--skip-verify]

  --ref <git-ref>   o que mesclar. default: upstream/main
  --commit          além de preparar, commita (mensagem gerada; revise antes do PR)
  --skip-verify     pula a verificação pós-merge (build + paridade de validate)

Prepara o merge com retenção de docs/ e vault/, PROVA a retenção por efeito,
reporta a proporção produto/governança, e verifica que o validate não mexeu.
Aborta se sobrar conflito ou se a retenção não puder ser provada.
USAGE
}

while [ $# -gt 0 ]; do
	case "$1" in
		--ref) REF="${2:?--ref exige um valor}"; shift 2 ;;
		--commit) DO_COMMIT=1; shift ;;
		--skip-verify) SKIP_VERIFY=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "upstream-sync: opção desconhecida: $1" >&2; usage >&2; exit 2 ;;
	esac
done

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

die() { echo "upstream-sync: $*" >&2; exit 1; }
say() { printf '%s\n' "$*"; }

# ── Pré-condições ────────────────────────────────────────────────────────────────
[ -z "$(git status --porcelain)" ] || die "árvore suja. Commite ou guarde antes de sincronizar."
git rev-parse --verify --quiet "$REF" >/dev/null || die "ref não existe: $REF (fez 'git fetch upstream'?)"

BASE="$(git rev-parse HEAD)"
BASE_SHORT="$(git rev-parse --short HEAD)"
REF_SHORT="$(git rev-parse --short "$REF")"

if [ "$(git rev-list --count "HEAD..$REF")" = "0" ]; then
	say "upstream-sync: nada a trazer — HEAD já contém $REF ($REF_SHORT)."
	exit 0
fi

# ── Baseline do validate, ANTES de mexer na árvore ───────────────────────────────
# Medido com o binário DA ÁRVORE, nunca o do PATH — o do PATH é outra instalação.
BIN="./bin/trackfw"
VAL_BEFORE="n/a"
if [ "$SKIP_VERIFY" = "0" ]; then
	go build -o bin/trackfw ./cmd/trackfw 2>/dev/null || die "não consegui construir o binário da árvore para medir o baseline"
	# No Windows o `-o bin/trackfw` grava exatamente esse nome, e o bin/trackfw.exe -- o que o
	# PowerShell executa -- ficava uma versão atrás a cada sync. A extensão vem do toolchain, não de
	# predicado de SO: GOEXE é ".exe" no Windows e vazio no resto, onde nada muda.
	GOEXE_EXT="$(go env GOEXE 2>/dev/null)"
	[ -z "$GOEXE_EXT" ] || go build -o "bin/trackfw$GOEXE_EXT" ./cmd/trackfw 2>/dev/null || die "não consegui construir bin/trackfw$GOEXE_EXT para medir o baseline"
	VAL_BEFORE="$("$BIN" validate 2>&1 | grep -c '^✗' || true)"
fi

# ── Merge ────────────────────────────────────────────────────────────────────────
say "upstream-sync: mesclando $REF ($REF_SHORT) sobre $BASE_SHORT…"
# 🔴 O merge PODE falhar por motivo que nao e conflito -- historias nao
# relacionadas, identidade ausente, ref irresolvivel, worktree em estado ruim. A
# versao anterior descartava o stderr E ignorava o codigo de saida, e o efeito
# era o pior possivel: o script SEGUIA, `git diff --cached` saia VAZIO, e ele
# reportava "0 arquivos de produto trazidos" como se fosse resultado.
#
# Medido em 2026-09-10: em ubuntu-latest o gate de falsificacao acusou 4 arquivos
# de produto "suprimidos" -- e a supressao era o merge nao ter acontecido. No
# Windows o mesmo caso passa. Silencio no stderr transformou falha de merge em
# medicao plausivel.
#
# Conflito continua sendo esperado e tratado adiante (--diff-filter=U). O que
# esta guarda pega e falha SEM conflito: nao ha o que resolver, e prosseguir
# produziria numero mentiroso.
set +e
MERGE_OUT="$(git merge --no-commit --no-ff "$REF" 2>&1)"
MERGE_RC=$?
set -e

if [ "$MERGE_RC" -ne 0 ] && [ -z "$(git diff --name-only --diff-filter=U)" ]; then
	printf '%s
' "$MERGE_OUT" >&2
	git merge --abort 2>/dev/null || git reset --hard "$BASE" >/dev/null 2>&1
	die "git merge falhou (exit $MERGE_RC) e NAO ha conflito para resolver. Mensagem acima. Arvore devolvida."
fi

# ── Retenção: docs/ e vault/ voltam a ser EXATAMENTE os nossos ───────────────────
# Não se resolve conflito a conflito. A ADR já decidiu o resultado.
git rm -r -q --ignore-unmatch --force docs vault >/dev/null 2>&1 || true
git checkout "$BASE" -- docs >/dev/null 2>&1 || true
# vault/ não existe na nossa árvore: fica deletado, que é o estado correto.

# Governança fora de docs/: volta a ser a da BASE. O checkout a partir de um commit
# também resolve o conflito, se houver — as entradas não mescladas saem do índice.
for g in $GOVERNANCA_FORA_DE_DOCS; do
	git checkout "$BASE" -- "$g" >/dev/null 2>&1 || die "não consegui reter $g da base."
done

# Produto em docs/: volta a ser o do REF. Se o REF não tem o arquivo, ele sai.
EXCLUI_PRODUTO=()
for p in $PRODUTO_EM_DOCS; do
	EXCLUI_PRODUTO+=(":(exclude)$p")
	if git cat-file -e "$REF:$p" 2>/dev/null; then
		git checkout "$REF" -- "$p" >/dev/null 2>&1 || die "não consegui trazer $p de $REF."
	else
		git rm -q --ignore-unmatch --cached -- "$p" >/dev/null 2>&1 || true
		rm -f -- "$p"
	fi
done

# ── AC2: PROVAR a retenção por efeito, não afirmá-la ─────────────────────────────
RETENTION_DIFF="$(git diff --cached "$BASE" --stat -- docs vault $GOVERNANCA_FORA_DE_DOCS "${EXCLUI_PRODUTO[@]}")"
if [ -n "$RETENTION_DIFF" ]; then
	echo "$RETENTION_DIFF" >&2
	git merge --abort 2>/dev/null || git reset --hard "$BASE" >/dev/null 2>&1
	die "RETENÇÃO NÃO PROVADA: docs/, vault/ ou $GOVERNANCA_FORA_DE_DOCS diferem da base. Árvore devolvida."
fi
# ...e a exceção prova o lado oposto: o produto em docs/ ficou IGUAL ao do REF.
TRAZIDO_DIFF="$(git diff --cached "$REF" --stat -- $PRODUTO_EM_DOCS)"
if [ -n "$TRAZIDO_DIFF" ]; then
	echo "$TRAZIDO_DIFF" >&2
	git merge --abort 2>/dev/null || git reset --hard "$BASE" >/dev/null 2>&1
	die "PRODUTO EM docs/ NÃO TRAZIDO: difere de $REF. Árvore devolvida."
fi

# ── Conflito remanescente é de PRODUTO: aborta ───────────────────────────────────
LEFT="$(git diff --name-only --diff-filter=U)"
if [ -n "$LEFT" ]; then
	echo "$LEFT" >&2
	git merge --abort 2>/dev/null || git reset --hard "$BASE" >/dev/null 2>&1
	die "conflito de PRODUTO remanescente (acima). Resolva à mão. Árvore devolvida."
fi

# ── AC3: a proporção é o discriminante ───────────────────────────────────────────
PRODUCT_N="$(git diff --cached --name-only "$BASE" | wc -l | tr -d ' ')"
TOTAL_N="$(git diff --name-only "$BASE...$REF" | wc -l | tr -d ' ')"
GOV_N=$(( TOTAL_N - PRODUCT_N ))
[ "$GOV_N" -lt 0 ] && GOV_N=0

# O upstream mudou governança que retemos? Mostra o que ficou para trás.
MUDOU_GOV="$(git diff --name-only "$BASE...$REF" -- $GOVERNANCA_FORA_DE_DOCS)"
if [ -n "$MUDOU_GOV" ]; then
	say ""
	say "  ⚠ o upstream mudou governança que este fork RETÉM ($MUDOU_GOV). O diff dele:"
	git diff "$BASE...$REF" -- $GOVERNANCA_FORA_DE_DOCS | sed 's/^/      /'
	say "    Retido o nosso. Se houver chave nova que nos interesse, aplique à mão, em commit próprio."
fi

say ""
say "  arquivos de PRODUTO trazidos : $PRODUCT_N"
say "  de governança RETIDOS        : $GOV_N   (de $TOTAL_N no merge)"
say ""
git diff --cached --name-only "$BASE" | sed 's/^/    /'
say ""

# ── A cópia que o PATH entrega ───────────────────────────────────────────────────
#
# Desde o #527 do upstream, os hooks de guard chamam `trackfw guard <nome>`
# RESOLVIDO NO PATH. Nesta máquina o PATH entrega uma CÓPIA do binário da árvore,
# posta em %APPDATA%/npm/trackfw.exe porque nenhuma release publicada tem `guard`
# (roteiro no CLAUDE.md; o alarme é o check-contorno-dos-shims-caducou.sh).
#
# Este passo existe porque o rebuild acima refazia o bin/ e deixava a cópia atrás,
# em silêncio, a cada sync — e a cerca de TODOS os projetos da máquina passava a
# rodar por código velho. Em 2026-10-07 quem pegou a defasagem foi o usuário.
#
# 🔴 `trackfw --version` NÃO detecta isto: as duas versões dizem `9.2.0`, porque o
# guard entrou depois daquela tag. O discriminante é o CONTEÚDO.
#
# Três propriedades, cada uma por uma falha medida:
#
#   1. Só age quando o contorno está em vigor (há shim renomeado ao lado). Em
#      máquina sem o contorno não há cópia gerida, e copiar seria invadir o PATH
#      de alguém.
#   2. `cp` pode falhar com "Device or resource busy" — medido em 2026-10-07, o
#      .exe estava em uso por uma chamada de guard que acabara de rodar. O
#      remédio é renomear o ocupado e copiar no lugar, que o Windows permite.
#   3. Verifica POR EFEITO depois de copiar e RESTAURA se a verificação falhar.
#      Cópia quebrada deixa todas as cercas inertes, e falha aberta: é pior que
#      cópia velha.
refaz_copia_do_path() {
	local p dst dir stamp
	p=$(bash -lc 'command -v trackfw' 2>/dev/null) || return 0
	[ -n "$p" ] || return 0
	# O `[ -f ]` do MSYS responde VERDADE para o nome sem extensão de um .exe que
	# não existe, então o .exe é tentado PRIMEIRO.
	case "$p" in
		*.exe) dst="$p" ;;
		*) if [ -f "${p}.exe" ]; then dst="${p}.exe"; else dst="$p"; fi ;;
	esac
	[ -f "$dst" ] || return 0

	local arv="bin/trackfw${GOEXE_EXT:-}"
	[ -f "$arv" ] || arv="bin/trackfw"
	[ -f "$arv" ] || return 0

	dir=$(dirname "$dst")
	# shellcheck disable=SC2012
	ls "$dir" 2>/dev/null | grep -q 'pre-guard-bak' || return 0

	if cmp -s "$arv" "$dst"; then
		say "  copia do PATH    ja em dia ($dst)"
		return 0
	fi

	stamp=$(date '+%Y%m%d-%H%M%S')
	cp "$dst" "$dir/trackfw.exe.pre-sync-bak" 2>/dev/null \
		|| die "não consegui guardar a cópia anterior de $dst — não troco binário de cerca sem poder voltar."

	if ! cp "$arv" "$dst" 2>/dev/null; then
		mv "$dst" "$dir/trackfw.exe.ocupado-$stamp" 2>/dev/null \
			|| die "a cópia do PATH está ocupada e não pude renomeá-la. O PATH ficou ATRÁS — refaça à mão: cp $arv $dst"
		cp "$arv" "$dst" 2>/dev/null \
			|| die "renomeei o ocupado mas não consegui copiar. O PATH está SEM trackfw — restaure: mv $dir/trackfw.exe.ocupado-$stamp $dst"
	fi

	# Verificação POR EFEITO, não por versão.
	if ! cmp -s "$arv" "$dst" || ! "$dst" guard --help >/dev/null 2>&1; then
		cp "$dir/trackfw.exe.pre-sync-bak" "$dst" 2>/dev/null
		die "a cópia nova não passou na verificação (conteúdo ou \`guard --help\`). RESTAUREI a anterior. Investigue antes de mexer no PATH."
	fi

	say "  copia do PATH    refeita e verificada ($dst · guard --help rc=0)"
}

# ── AC5: verificação pós-merge ───────────────────────────────────────────────────
if [ "$SKIP_VERIFY" = "0" ]; then
	say "upstream-sync: verificando…"
	go build ./... >/dev/null 2>&1 || die "go build ./... reprovou depois do merge."
	go build -o bin/trackfw ./cmd/trackfw >/dev/null 2>&1 || die "não consegui reconstruir o binário da árvore."
	[ -z "${GOEXE_EXT:-}" ] || go build -o "bin/trackfw$GOEXE_EXT" ./cmd/trackfw >/dev/null 2>&1 || die "não consegui reconstruir bin/trackfw$GOEXE_EXT."
	VAL_AFTER="$("$BIN" validate 2>&1 | grep -c '^✗' || true)"
	say "  go build ./...   exit 0"
	say "  validate         $VAL_BEFORE antes · $VAL_AFTER depois"
	if [ "$VAL_BEFORE" != "$VAL_AFTER" ]; then
		die "o validate MUDOU ($VAL_BEFORE -> $VAL_AFTER). O merge não deveria tocar governança — investigue antes de commitar."
	fi
	refaz_copia_do_path
fi

# ── Commit (opcional) ────────────────────────────────────────────────────────────
if [ "$DO_COMMIT" = "1" ]; then
	git commit --no-edit -q -F - <<EOF
merge: $REF ($REF_SHORT) — $PRODUCT_N arquivos de produto

Preparado por scripts/upstream-sync.sh, com retenção de docs/ e vault/ pela
ADR-2026-08-29: a governança do upstream não é importada.

  produto trazido      $PRODUCT_N
  governança retida    $GOV_N  (de $TOTAL_N no merge)
  validate             $VAL_BEFORE antes · ${VAL_AFTER:-n/a} depois

Retenção PROVADA por efeito: git diff --cached $BASE_SHORT -- docs vault $GOVERNANCA_FORA_DE_DOCS saiu vazio,
exceto o produto em docs/ ($PRODUTO_EM_DOCS), provado igual ao de $REF_SHORT.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
	say "upstream-sync: commitado. Revise a mensagem antes de abrir o PR."
else
	say "upstream-sync: preparado e NÃO commitado."
	say "  revise com: git diff --cached $BASE_SHORT --stat"
fi
