---
id: REQ-2026-08-16-roadmap-move-sincroniza-status
title: roadmap move deve sincronizar o campo status do frontmatter nos três runtimes
status: done
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: `roadmap move` e o `status:` do frontmatter

Roadmap: docs/roadmaps/claude/done/roadmap-move-sincroniza-status-2026-08-16.md

## Problema

`trackfw roadmap move <nome> <estado>` move o arquivo entre as pastas de estado, mas **o Go e o
Node.js não atualizam o campo `status:` do frontmatter**. O arquivo passa a morar em `done/`
declarando `status: wip`.

Quem acusa essa incoerência é a própria ferramenta: a regra `folder_status` do validator lê
exatamente esse campo (`internal/validator/validator.go:1322`, via `extractFrontmatterField`).
Ou seja, **o `move` produz o defeito que o `validate` reclama** — o usuário roda um comando do
trackfw e o gate do trackfw fica sujo por causa dele.

Foi assim que 7 roadmaps deste repositório acumularam `folder_status`, corrigidos à mão em
`REQ-2026-08-16-consolidar-arvores-governanca`. Durante aquele mesmo trabalho o defeito se
reproduziu duas vezes ao vivo, nos dois roadmaps fechados com o CLI.

### Quebra de paridade — e a referência é a errada

| Runtime | Sincroniza `status:`? | Como |
|---|---|---|
| **Go** (referência) | **não** | `MoveRoadmap` faz `os.Rename` e vai embora (`internal/generators/roadmap.go:283`) |
| **Node.js** | **não** | `moveRoadmap` faz `fs.renameSync` e vai embora (`npm/src/generators/roadmap.js:173`) |
| **Python** | **sim** | reescreve antes de gravar no destino (`pypi/trackfw/generators/roadmap.py:216`) |

Os scripts de paridade não pegam porque `check-cli-parity.sh` compara o conjunto de comandos e a
versão, e `check-validate-parity.sh` compara violations sobre um fixture — nenhum dos dois executa
`roadmap move` e inspeciona o arquivo resultante.

### Dois defeitos na implementação Python

Ela é a que mais se aproxima do certo, mas não serve como está:

1. **A regex não se restringe ao frontmatter.** `re.sub(r"^(status:\s*).*$", ..., count=1,
   flags=MULTILINE)` casa a primeira linha do arquivo que comece com `status:`. Num roadmap **sem**
   bloco de frontmatter, isso reescreve silenciosamente uma linha do corpo.
2. **O rótulo diverge do resto da ferramenta.** Escreve `WIP`, `Done`, `Backlog` capitalizados,
   enquanto `roadmap new` grava `status: backlog` minúsculo e todos os roadmaps do repositório usam
   minúsculo. O gate não se importa (`strings.EqualFold`), mas a ferramenta fica incoerente consigo
   mesma.

## Requisitos

### R1 — Sincronizar `status:` ao mover, nos três runtimes
Depois de mover, o `status:` do frontmatter passa a valer o estado de destino.

### R2 — Só dentro do bloco de frontmatter, e só se o campo já existir
A reescrita acontece exclusivamente entre os delimitadores `---` de abertura e fechamento no topo
do arquivo. Arquivo sem frontmatter, ou com frontmatter sem a chave `status:`, fica **intocado** —
nada de criar frontmatter nem de inventar campo. É o mesmo contrato do validator, que ignora quem
não declara (`declared == "" → continue`).

### R3 — Rótulo minúsculo, igual ao nome do estado
`backlog`, `analyzing`, `wip`, `blocked`, `done`, `abandoned` — igual ao que `roadmap new` grava e
igual ao nome da pasta. Muda o comportamento atual do Python, de propósito.

### R4 — Teste em cada runtime
Cada teste move um roadmap e assevera o `status:` no destino. Precisa cobrir também o caso do
arquivo sem frontmatter, que deve sair byte a byte idêntico.

## Critérios de Aceite

- [x] Após `roadmap move X done`, o frontmatter de X declara `status: done` nos três runtimes
- [x] Roadmap sem frontmatter não é modificado — conteúdo byte a byte idêntico após o move
- [x] Roadmap com frontmatter sem a chave `status:` não ganha a chave
- [x] Uma linha `status:` no corpo, fora do frontmatter, não é tocada
- [x] Teste novo nos três runtimes, cada um confirmado não-vacuoso
- [x] `go build ./...` verde; nenhuma falha de teste nova além das 10 pré-existentes de ambiente
- [x] `check-cli-parity.sh`, `check-validate-parity.sh` e `check-static-assets.sh` passam
- [x] Verificação de ponta a ponta: mover um roadmap e rodar `validate` não gera `folder_status`
