---
name: roadmap-move-sincroniza-status-2026-08-16
title: "roadmap move sincroniza o status do frontmatter nos três runtimes"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-roadmap-move-sincroniza-status
branch: fix/roadmap-move-sincroniza-status
---

# Roadmap: roadmap move sincroniza status

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-roadmap-move-sincroniza-status.md`

## Diagnóstico / Contexto

`roadmap move` move o arquivo mas não atualiza o `status:` do frontmatter no Go nem no Node.js —
então o comando produz exatamente a incoerência que a regra `folder_status` do validator reclama.
O Python já sincroniza, o que faz disto uma quebra de paridade em que **a implementação de
referência é a errada**. Diagnóstico completo, tabela por runtime e os dois defeitos da versão
Python estão na REQ.

Origem: item 1 da lista de dívida levantada ao fim de `REQ-2026-08-16-consolidar-arvores-governanca`.
O defeito se reproduziu duas vezes ao vivo durante aquele trabalho.

## Critérios de Aceite

- [x] Após `roadmap move X done`, o frontmatter de X declara `status: done` nos três runtimes
- [x] Roadmap sem frontmatter sai byte a byte idêntico
- [x] Frontmatter sem a chave `status:` não ganha a chave
- [x] Linha `status:` no corpo, fora do frontmatter, não é tocada
- [x] Teste novo nos três runtimes, cada um confirmado não-vacuoso
- [x] Gates de paridade passam

---

## Wave 1 — Helper e correção por runtime

> ML-1 define o contrato (Go é a referência). ML-2 e ML-3 espelham. ML-4 alinha o Python, que já
> sincroniza mas com dois defeitos.

### ML-1 — Go: helper de reescrita do frontmatter + uso no `MoveRoadmap`
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/roadmap.go`, `internal/generators/roadmap_move_test.go` (NOVO)
**Ações:**
1. Criar `setFrontmatterStatus(content, state string) string` em `roadmap.go`: localiza o bloco de
   frontmatter (primeira linha `---` na posição 0 e o `---` de fechamento seguinte); dentro dele,
   substitui a primeira linha cuja chave seja `status`; devolve o conteúdo intocado se não houver
   frontmatter ou se a chave não existir.
2. Em `MoveRoadmap`, depois do `os.Rename`, ler o arquivo de destino, aplicar o helper e regravar
   apenas se o conteúdo mudou.
3. Teste novo em `roadmap_move_test.go` cobrindo: com frontmatter, sem frontmatter (byte a byte),
   frontmatter sem `status:`, e `status:` no corpo.
**Critérios de aceite:**
- [x] `go build ./...` sem erros, `gofmt` limpo
- [x] `go test ./internal/generators/ -run TestMoveRoadmap` verde — 8 testes, incluindo os 4
      pré-existentes
- [x] Não-vacuoso: sem o sync, 2 dos 4 testes novos falham
**Comandos de validação:** `go build ./... && go test ./internal/generators/ -run Move`

### ML-2 — Node.js: espelha o helper e o uso
**Status:** ✅ Concluído
**Arquivos afetados:** `npm/src/generators/roadmap.js`, `npm/tests/roadmap_move.test.js` (NOVO)
**Ações:**
1. `setFrontmatterStatus(content, state)` com o mesmo contrato do ML-1.
2. Aplicar depois do `fs.renameSync`.
3. Teste equivalente, mesmos quatro casos.
**Critérios de aceite:**
- [x] `node npm/tests/roadmap_move.test.js` verde — 4 passed, 0 failed
- [x] Não-vacuoso: 2 passed / 2 failed sem o sync
**Comandos de validação:** `node npm/tests/roadmap_move.test.js`

### ML-3 — Python: restringe ao frontmatter e alinha o rótulo
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/generators/roadmap.py`, `pypi/tests/test_roadmap_move.py` (NOVO)
**Ações:**
1. Trocar o `re.sub` global por um helper com o mesmo contrato do ML-1.
2. Trocar o rótulo capitalizado (`WIP`, `Done`) pelo nome minúsculo do estado, alinhando com
   `roadmap new` e com os dois outros runtimes. Remover o dict `state_labels`.
3. Teste equivalente, mesmos quatro casos.
**Critérios de aceite:**
- [x] `python -m unittest tests.test_roadmap_move` verde — 4 testes, OK
- [x] Teste cobre o arquivo sem frontmatter, que a regex global corrompia
- [x] Não-vacuoso: FAILED (failures=4) sem o fix
- [x] Suíte completa volta à baseline exata: 6 errors + 1 failure pré-existentes, nada novo

**Defeito extra encontrado pelo teste (não previsto):** o `move_roadmap` lia com newline universal
e regravava com tradução automática, o que no Windows convertia **o arquivo inteiro de LF para
CRLF** — inclusive quando não havia nada a alterar. Corrigido junto: agora move primeiro com
`os.replace` e só reescreve se o frontmatter mudar, com `newline=""` nos dois lados. É o mesmo
fluxo do Go e do Node.js.

**Efeito colateral assumido:** três testes existentes asseveravam `status: WIP` capitalizado e
foram atualizados para minúsculo, conforme R3. Fica registrado que o template de `roadmap new` do
Python ainda grava `status: Backlog` capitalizado enquanto o do Go grava `backlog` — divergência
pré-existente entre runtimes, no comando `new`, fora do escopo desta REQ. Merece REQ própria.
**Comandos de validação:** `cd pypi && python -m unittest tests.test_roadmap_move`

---

## Wave 2 — Fechamento

### ML-4 — Gates e verificação de ponta a ponta
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `go test ./...` — nenhuma falha nova além das 10 pré-existentes de ambiente Windows em
   `internal/generators` (registradas em `REQ-2026-08-16-consolidar-arvores-governanca`).
2. Os três gates de paridade, com `npm install` feito e `PYTHONIOENCODING=utf-8`.
3. Ponta a ponta: mover um roadmap com cada runtime e conferir que `validate` não gera
   `folder_status` para ele.
**Critérios de aceite:**
- [x] Nenhuma falha de teste nova: Go fecha com as mesmas 10 pré-existentes; pypi volta à
      baseline exata de 6 errors + 1 failure
- [x] Os três gates passam: `check-cli-parity.sh`, `check-validate-parity.sh`,
      `check-static-assets.sh`
- [x] Ponta a ponta nos três runtimes: após `roadmap move r.md done`, o frontmatter declara
      `status: done` e `validate` acusa **zero** `folder_status`
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh && bash scripts/check-validate-parity.sh`
