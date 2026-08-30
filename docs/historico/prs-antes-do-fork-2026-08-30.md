# Histórico dos PRs — arquivado antes de refazer o repositório como fork
> Gerado em 2026-08-30. O GitHub não converte repositório em fork: para
> `lourivalgarciajunior/trackfw` virar fork real do `kgsaran/trackfw` foi preciso apagar e
> re-forkar, o que apaga os PRs e a discussão deles. Os commits sobrevivem no git; **os
> corpos dos PRs, não** — e é neles que está boa parte do raciocínio de cada mudança.
> Este arquivo é a cópia.

---

## PR #1 — Consolidar as três árvores de artefato de governança em uma só
`MERGED` · branch `feat/consolidar-arvores-governanca` · merge `a5cf69a`

Fecha `REQ-2026-08-16-consolidar-arvores-governanca`.

## Problema

O repositório acumulou três convenções concorrentes de organização de artefatos, e **não havia `trackfw.yaml` na raiz** — o CLI rodava nos defaults (`docs/req`, `docs/roadmaps`, `flat`) e enxergava **2 dos 66 artefatos**.

| Árvore | Caminho | Volume | Visível ao CLI |
|---|---|---|---|
| A — flat (default) | `docs/req/` (vazia), `docs/roadmaps/{wip,done}/` | 2 roadmaps | ✅ |
| B — by_agent pt-BR | `docs/requisições/<agente>/`, `docs/roadmaps/claude/` | 27 REQs + 35 roadmaps | ❌ |
| C — `roadmap` singular | `docs/roadmap/artemis/done/` | 2 roadmaps | ❌ |

Consequências: 3 roadmaps presos em `wip/` desde junho sem o gate conseguir acusar, link REQ quebrado, e 20 violações de governança invisíveis.

## O que foi feito

- **ML-1** — `trackfw.yaml` pinando a árvore B como canônica (`req_dir: docs/requisições`, `roadmap_namespacing: by_agent`). Nenhuma mudança de código do produto foi necessária: o schema em `internal/config/config.go` já suportava todas as chaves.
- **ML-2** — 4 roadmaps movidos com `git mv` (R100, `--follow` preserva histórico); `docs/req/`, `docs/roadmap/` e `docs/roadmaps/{wip,done}/` removidos.
- **ML-3** — REQ retroativa `REQ-2026-06-20-attention-hooks-agent-clis` reconstruída a partir do roadmap que a referenciava com link quebrado desde a origem; duplicata byte-idêntica removida; 2 roadmaps herdados fechados com nota explícita de fechamento retroativo.
- **ML-5** — escopo não previsto, revelado pelo ML-1: `status:` alinhado à pasta em 7 roadmaps, frontmatter prependado em 7 REQs legadas, campo `Roadmap:` em 5.
- **ML-4** — `CLAUDE.md` ganha a seção "This repo's own governance (dogfooding)" documentando os dois overrides.

## Resultado

`trackfw validate`: **20 → 5 violações, 10 → 0 avisos**.

## Residual — deliberadamente fora deste PR

- **5 violações `req_has_adr`.** O repositório não tem nenhum ADR. Resolver exige decisão de política (ADR retroativo, `trackfw baseline`, ou rebaixar a regra) — não é migração. Registrado no bloco Residual do roadmap.
- **10 testes Go falhando** em `internal/generators`, pré-existentes e específicos de Windows (HOME resolvido via `USERPROFILE`; bit de execução POSIX em NTFS). Confirmado independente deste trabalho: as mesmas 10 falham com o `trackfw.yaml` removido da raiz.

## Achado no produto

`trackfw roadmap move` move o arquivo mas **não sincroniza o campo `status:` do frontmatter**. Foi o que gerou 7 dos avisos `folder_status` herdados, e voltou a acontecer neste PR. Merece fix nos três runtimes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #2 — Rebaixa req_has_adr de error para warning
`MERGED` · branch `chore/req-has-adr-warning` · merge `dd557d1`

Fecha o residual R1 de `REQ-2026-08-16-consolidar-arvores-governanca`.

O repositório não tem nenhum ADR, em nenhuma pasta. Com `req_has_adr: error`, 5 REQs legadas mantinham o gate vermelho por uma dívida que só se paga escrevendo ADR retroativo — inventar história para satisfazer o linter. Como `warning`, a dívida continua visível a cada `trackfw validate` sem bloquear commit e CI.

`trackfw validate`: **5 violações → 0** (rc=0), 5 avisos.

## Correção — a nota de parity original deste PR estava errada

> A versão original deste corpo afirmava que o parser Go não removia aspas no bloco `rules:`, e que
> `req_has_adr: "warning"` funcionaria no CLI npm mas seria silenciosamente ignorado no binário Go.
> **Isso é falso.** O bloco `rules:` chama `splitKV`, que já faz `strings.Trim(val, "\"'")` em
> `internal/config/config.go:318`. Verificado com o binário compilado deste fonte: com aspas,
> `validate` retorna rc=0 e 5 avisos, idêntico ao npm. O bug descrito em
> `REQ-2026-06-13-v2.4.1-baseline-ratchet-warnings` está corrigido nos dois runtimes.

O valor segue sem aspas no arquivo — funciona dos dois jeitos, e é a forma usada no resto do projeto.

## O gap que existe de verdade fica em outro lugar

Itens de **lista** não têm as aspas removidas, e a inconsistência é interna ao próprio parser: em `acceptance_markers:` e `link_fields:` as aspas são removidas; em `adr_dirs:` e `agents:` não — nos três runtimes igualmente.

Com `agents: - "claude"` em vez de `- claude`, o nome do agente deixa de casar com o diretório `docs/requisições/claude/` e 20 REQs somem da validação **em silêncio**: sem erro, sem aviso, o gate fica verde por não estar olhando. Medido nos dois runtimes: 5 achados caem para 3, idêntico.

Como os três runtimes erram igual, os scripts de parity passam — é bug replicado, não quebra de paridade. Tratado em REQ própria.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #3 — Remove aspas de itens de lista em adr_dirs e agents nos três runtimes
`MERGED` · branch `fix/aspas-itens-de-lista` · merge `2e6788b`

Fecha `REQ-2026-08-16-aspas-em-itens-de-lista`.

## O bug

`adr_dirs:` e `agents:` eram os **dois únicos** blocos do `trackfw.yaml` cujos itens de lista não tinham as aspas envolventes removidas. A inconsistência era interna ao próprio parser, nos três runtimes igualmente:

| Bloco | Aspas removidas antes deste PR? |
|---|---|
| escalares top-level (`req_dir`, `roadmap_dir`, …) | sim |
| `rules:` valores | sim |
| `acceptance_markers:` itens | sim |
| `link_fields:` itens | sim |
| **`adr_dirs:` itens** | **não** |
| **`agents:` itens** | **não** |

YAML trata `- claude` e `- "claude"` como o mesmo valor. O parser do trackfw não.

## Por que importa

Com `roadmap_namespacing: by_agent`, o nome do agente monta o caminho dos artefatos. Um agente escrito `- "claude"` nunca casa com `docs/requisições/claude/` nem `docs/roadmaps/claude/`, então **o namespace inteiro sai da validação em silêncio** — sem erro, sem aviso, o gate fica verde por não estar olhando. Medido neste repositório antes do fix:

```
agents:  - claude     →  validate acha 5
agents:  - "claude"   →  validate acha 3     (as 20 REQs de claude/ somem)
```

É o pior modo de falha possível numa ferramenta cujo propósito é ser gate.

Os scripts de parity não pegavam porque os três runtimes erravam igual — bug replicado, não quebra de paridade. Não existia fixture com aspas.

## O que mudou

| ML | Runtime | Arquivos |
|---|---|---|
| ML-1 | Go (referência) | `internal/config/config.go`, `internal/config/config_test.go` |
| ML-2 | Node.js | `npm/src/config/index.js`, `npm/tests/config.test.js` |
| ML-3 | Python | `pypi/trackfw/config.py`, `pypi/tests/test_config.py` |
| ML-4 | verificação | — |

Mesmo tratamento já aplicado em `acceptance_markers`: `strings.Trim(val, "\"'")`, `.replace(/^["']|["']$/g, '')` e `.strip('"\'')`. Aspas simples e duplas.

## Verificação

Cada teste novo foi confirmado **não-vacuoso** — revertido o fix do seu runtime, o teste falha:

- Go: `ADRDirs[1]: want "docs/decisions", got "'docs/decisions'"` → passa com o fix
- Node.js: 12 passed / 1 failed → 13 passed / 0 failed
- Python: `FAILED (failures=1)` → `OK` (18 testes)

Gates:

- `go test ./...` — fecha com as **mesmas 10 falhas pré-existentes** de `internal/generators` (ambiente Windows, documentadas em `REQ-2026-08-16-consolidar-arvores-governanca`). Nenhuma nova, nenhuma em `internal/config`.
- `check-cli-parity.sh`, `check-validate-parity.sh`, `check-static-assets.sh` — os três passam.
- Ponta a ponta: com e sem aspas, `validate` acha 5 nos dois runtimes disponíveis. Antes era 5 → 3.

## Atrito de ambiente (Windows) — sem relação com o fix

Os gates de paridade precisam de dois preparos nesta máquina, documentados no roadmap:

- `cd npm && npm install` — senão o CLI Node quebra com `MODULE_NOT_FOUND` em commander.
- `PYTHONIOENCODING=utf-8 PYTHONUTF8=1` — senão `python -m trackfw --help` estoura `UnicodeEncodeError` no `→` do help, porque o console usa cp1252.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #4 — roadmap move sincroniza o status do frontmatter nos três runtimes
`MERGED` · branch `fix/roadmap-move-sincroniza-status` · merge `253acc8`

Fecha `REQ-2026-08-16-roadmap-move-sincroniza-status`.

## O bug

`trackfw roadmap move <nome> <estado>` movia o arquivo entre as pastas mas **não atualizava o `status:` do frontmatter** no Go nem no Node.js. O arquivo ia morar em `done/` continuando a declarar `status: wip`.

Quem acusa essa incoerência é a própria ferramenta: a regra `folder_status` do validator lê exatamente esse campo (`internal/validator/validator.go:1322`). Ou seja, **o `move` produzia o defeito que o `validate` reclama** — o usuário roda um comando do trackfw e o gate do trackfw fica sujo por causa dele.

Foi assim que 7 roadmaps deste repositório acumularam `folder_status`, corrigidos à mão em `REQ-2026-08-16-consolidar-arvores-governanca`. Durante aquele trabalho o defeito se reproduziu duas vezes ao vivo.

### Quebra de paridade com a referência do lado errado

| Runtime | Sincronizava? |
|---|---|
| **Go** (referência) | não — `os.Rename` e ia embora |
| **Node.js** | não — `fs.renameSync` e ia embora |
| **Python** | sim, mas com defeitos |

Os gates não pegavam: `check-cli-parity.sh` compara comandos e versão, `check-validate-parity.sh` compara violations sobre um fixture — nenhum executa `roadmap move` e inspeciona o arquivo resultante.

## O contrato adotado

Definido no ML-1 (Go) e espelhado nos outros dois:

- reescreve **só dentro** do bloco `---` do topo do arquivo;
- **só se a chave `status:` já existir** ali — nada de criar frontmatter nem inventar campo, mesmo contrato do validator, que ignora quem não declara;
- rótulo **minúsculo**, igual ao nome do estado e ao que `roadmap new` grava no Go.

## Três defeitos corrigidos no Python

O Python já sincronizava, mas não servia como estava:

1. **`re.sub` global** — casava a primeira linha `status:` de qualquer lugar do arquivo. Num roadmap sem frontmatter, corrompia silenciosamente uma linha do corpo.
2. **Rótulo capitalizado** (`WIP`, `Done`) divergindo de `roadmap new`.
3. **Tradução de newline** — achado pelo teste novo, não estava previsto: lia com newline universal e regravava com tradução automática, convertendo **o arquivo inteiro de LF para CRLF no Windows**, mesmo quando não havia nada a alterar. Agora move com `os.replace` e só reescreve se o frontmatter mudar, com `newline=""` nos dois lados.

## Verificação

Cada teste novo foi confirmado **não-vacuoso** — revertido o fix do seu runtime, o teste falha:

| Runtime | Sem o fix | Com o fix |
|---|---|---|
| Go | 2 dos 4 falham | 8 testes `TestMoveRoadmap` verdes (4 novos + 4 pré-existentes) |
| Node.js | 2 passed / 2 failed | 4 passed / 0 failed |
| Python | `FAILED (failures=4)` | `OK` |

Os quatro casos cobertos em cada runtime: com frontmatter, sem frontmatter (byte a byte), frontmatter sem `status:`, e `status:` no corpo.

**Sem regressão:** `go test ./...` fecha com as mesmas 10 falhas pré-existentes de ambiente Windows em `internal/generators`; a suíte pypi volta à baseline exata de 6 errors + 1 failure. Os três gates de paridade passam.

**Ponta a ponta**, nos três runtimes, com fixture limpo:

```
roadmap move r.md done  →  status: done   |   validate: 0 folder_status
```

## Escopo assumido

- Três testes Python que asseveravam `status: WIP` capitalizado foram atualizados para minúsculo, conforme R3.
- O template de `roadmap new` do Python ainda grava `status: Backlog` capitalizado enquanto o do Go grava `backlog`. Divergência pré-existente, no comando `new`, fora desta REQ.
- A linha humana `> Criado em: … | Status: 🔄 WIP` logo abaixo do título **não** é sincronizada — o R2 restringiu a reescrita ao frontmatter de propósito, por ser o único campo que o validator lê. Candidato a REQ própria.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #5 — Testes de internal/generators param de escrever no home real e a suíte fica verde no Windows
`MERGED` · branch `fix/testes-go-portaveis-windows` · merge `79a2d78`

Fecha `REQ-2026-08-16-testes-go-portaveis-windows`.

## O problema

`go test ./...` fechava com **10 falhas** em `internal/generators` no Windows. Enquanto isso durou, a suíte não serviu de rede de segurança: as três entregas anteriores tiveram que comparar contagem de falhas contra uma baseline em vez de simplesmente exigir verde.

Duas causas independentes.

### Causa A — o override de HOME nunca funcionou no Windows (8 testes)

Os testes faziam `os.Setenv("HOME", tempdir)`. A produção chama `os.UserHomeDir()`, que no Windows lê **`USERPROFILE`**, não `HOME`. O override era ignorado.

E o efeito não era só o assert falhar: **o instalador rodava de verdade contra o home do desenvolvedor**. Saída real de `go test -run TestInstallAgents_CriaArquivosEmHome -v` antes deste PR:

```
  ✓ ~/.claude/agents/trackfw-architect.md (já existe — não sobrescrito)
  ✓ ~/.claude/agents/trackfw-backend.md (já existe — não sobrescrito)
```

Esse `✓ (já existe)` só aparece quando o instalador encontra o home real povoado. Numa máquina limpa, rodar a suíte instalaria 10 arquivos em `~/.claude/agents/`, criaria `~/.gemini/skills/` e anexaria regras em `~/.codeium/windsurf/memories/global_rules.md`. Um dos testes até trazia o comentário `// Use a temp home so we don't touch real ~/.codeium` — a intenção estava certa, o mecanismo é que nunca funcionou.

### Causa B — bit de execução POSIX em NTFS (2 testes)

`TestGenerateCommitMsgHook_Husky` e `_Lefthook` faziam `info.Mode()&0111 == 0`. NTFS não tem bit de execução; o Go reporta `-rw-rw-rw-`. Inverificável por construção.

## A correção

| ML | O quê |
|---|---|
| ML-1 | `home.go` com `var userHomeDir = os.UserHomeDir`; as 4 chamadas passam a usar o seam |
| ML-2 | helper `useTempHome` substitui os 11 blocos de `os.Setenv("HOME")` em 4 arquivos |
| ML-3 | as 2 asserções de bit de execução ganham guard `runtime.GOOS != "windows"` |
| ML-4 | verificação |

**Produção não muda.** `userHomeDir` continua sendo `os.UserHomeDir` em qualquer sistema. Deliberadamente **não** troquei por leitura direta de `HOME`: no Windows sob Git Bash, `HOME` aponta para lugar diferente de `USERPROFILE`, e isso mudaria para onde o `trackfw` instala de verdade — regressão silenciosa para o usuário.

**O guard do ML-3 pula só a asserção do bit**, não o teste: conteúdo do hook, caminho e idempotência continuam verificados no Windows. Fora do Windows a condição original é avaliada exatamente como antes.

**O helper tem teste próprio** (`TestUseTempHome_IsolaOResolvedor`): sem ele, um seam quebrado faria os testes voltarem a escrever no home real em silêncio — que é justamente o modo de falha que este PR corrige.

## Verificação

```
go test ./...   →  ZERO falhas
go vet ./...    →  limpo
```

Os três gates de paridade passam.

**Prova de não-poluição.** Snapshot de caminho + tamanho + mtime de `~/.claude/{agents,skills}`, `~/.gemini/skills` e `~/.codeium/windsurf/memories`, antes e depois da suíte completa: **36 arquivos, idênticos**.

O snapshot sozinho não bastaria — os instaladores são idempotentes, então num home já povoado eles não mudariam mtime de qualquer jeito. O que fecha o caso é a mensagem do instalador durante o teste ter virado `✅ …` (criação em diretório limpo) em vez de `✓ … (já existe — não sobrescrito)` (encontro com o home real).

## Achados de passagem, fora de escopo

- O instalador imprime `~/.claude/agents/` como **literal hardcoded** (`internal/generators/agents.go:39` e `:50`), não o caminho que resolveu — a saída mente sobre o destino quando o home não é o padrão. Cosmético, mas atrapalha exatamente este tipo de diagnóstico.
- `gofmt -l` acusa **17 dos 104** arquivos `.go`, todos por CRLF: `core.autocrlf=true` sem `.gitattributes`. É artefato de working copy — o blob commitado vai como LF, por isso a CI nunca reclamou. Um `.gitattributes` com `*.go text eol=lf` resolveria.

Ambos registrados no roadmap como candidatos a REQ própria.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #6 — CLI Python força UTF-8 na saída e para de quebrar em console Windows
`MERGED` · branch `fix/cli-python-utf8-windows` · merge `11f8a8f`

Fecha `REQ-2026-08-16-cli-python-utf8-windows`.

## O problema era maior que o relatado

O item entrou na lista como "o `--help` do CLI Python estoura nos gates de paridade". A investigação mostrou que isso era a ponta.

Console Windows entrega `sys.stdout.encoding = cp1252`. O CLI escreve `→`, `✓`, `⚠`, `──`, `⚙` e texto acentuado — nada disso existe em cp1252. Medido a partir de `pypi/`, sem variável de ambiente:

| Comando | Go | Node.js | Python |
|---|---|---|---|
| `--help` | rc=0 | rc=0 | **rc=1** |
| `status` | rc=0 | rc=0 | **rc=1** |
| `validate` | rc=0 | rc=0 | **rc=1** |
| `version` | rc=0 | rc=0 | rc=0 |

`status` e `validate` são os dois comandos mais usados da ferramenta. **Na prática o runtime Python era inutilizável num Windows recém-instalado** — só funcionava para quem já sabia exportar `PYTHONIOENCODING=utf-8`.

Go e Node.js não sofrem porque escrevem bytes UTF-8 direto, sem consultar codepage. O comportamento correto já era o deles; o Python é que estava fora de linha.

## A correção

**ML-1** — `_force_utf8_output()` reconfigura `stdout` e `stderr` para `encoding="utf-8", errors="replace"` no topo de `main()`. Condicional e silencioso quando o stream não tem `reconfigure` (testes e pipelines trocam `sys.stdout` por `StringIO`). `errors="replace"` para degradar um glifo em vez de abortar o comando.

**ML-2** — cinco testes: dois de unidade sobre o helper, três por subprocesso com `PYTHONIOENCODING=cp1252` forçado, que **reproduzem o console Windows de forma determinística em qualquer sistema onde a suíte rodar**. Não-vacuosos: removida a chamada do ML-1, `FAILED (failures=3)`.

**ML-4 (escopo acrescentado)** — rodar a suíte sem `PYTHONUTF8` revelou um segundo `UnicodeEncodeError` que **não era de stdout, e sim de escrita de arquivo**: `open(log_path, "w")` sem `encoding`, gravando uma linha com `→`. O default de `open()` no Windows é cp1252.

Auditei todo `open()` do runtime Python. **Produção está limpa** — a única ocorrência sem `encoding` é `serve.py:101` com `"rb"`, binário, onde não se aplica. O defeito era só nos testes: 5 chamadas corrigidas.

Também precisou de `tests/__init__.py`: os testes chamam funções de biblioteca direto (`scaffold`, `generate_claude_commands`), sem passar pelo `main()`, então não herdam o forçamento do entry point.

## Verificação

Os três gates passam **sem nenhum prefixo de ambiente** — que era o objetivo declarado do item:

```
check-cli-parity.sh        →  passed
check-validate-parity.sh   →  passed
check-static-assets.sh     →  synchronized
```

`go test ./...` segue com zero falhas. Suíte pypi bate a baseline exata: 6 errors + 1 failure.

## Correção de leitura sobre a baseline

O "6 errors + 1 failure" que citei nas entregas anteriores foi medido **com `PYTHONUTF8=1`**. Sem o prefixo, o número real era **22 errors** — os 16 extras eram o mesmo `UnicodeEncodeError`, em funções de biblioteca chamadas direto pelos testes. O `tests/__init__.py` deste PR fecha essa diferença.

E os 6 erros restantes agora estão **explicados**, não apenas contados: são 6 módulos que fazem `import pytest`, ausente neste ambiente. Ambiental, não defeito de código.

## Nota de invocação da suíte

Com `tests/__init__.py`, a suíte precisa ser importada como pacote: `python -m unittest discover -s tests -t .` ou `pytest tests/` (o comando documentado no `CLAUDE.md`). A forma `discover -s tests` sem `-t .` insere `tests/` no `sys.path` e importa os módulos como top-level, pulando o `__init__.py`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #7 — Consistências de template, header, saída e EOL (itens 6 a 9)
`MERGED` · branch `fix/consistencias-6-a-9` · merge `e7b2aad`

Fecha `REQ-2026-08-16-consistencias-template-saida-e-eol` — os itens 6 a 9 da dívida acumulada nesta sessão.

Quatro achados independentes, nenhum grande o bastante para REQ própria, todos nascidos do mesmo trabalho.

## D1 — Template de `roadmap new` divergia no Python

| | frontmatter | header humano |
|---|---|---|
| Go, Node.js | `status: backlog` | `> Created: DATE \| Status: backlog` |
| **Python** | **`status: Backlog`** | **`> Criado em: DATE \| Status: ⬜ Backlog`** |

Nasceu como efeito colateral de `REQ-2026-08-16-roadmap-move-sincroniza-status`, que alinhou o `move` dos três em minúsculo e deixou o Python incoerente consigo mesmo: `new` gravava `Backlog`, `move` gravava `wip`. Verificado com fixture: os três agora produzem output idêntico.

## D2 — `move` não sincronizava a linha humana

A REQ anterior restringiu a reescrita ao frontmatter **de propósito**, por ser o único campo que o validator lê. O efeito colateral: o arquivo ia para `done/` declarando `status: done` no frontmatter e `Status: 🔄 WIP` na linha que o humano lê. Aconteceu em **todo** roadmap fechado nesta sessão, cada um exigindo ajuste manual.

`setHeaderStatus` age na primeira linha que comece com `> ` e contenha `| Status: `, substituindo tudo depois do marcador. Contrato conservador igual ao do frontmatter: nenhuma linha casando → conteúdo intocado; a linha nunca é criada. Substituir o trecho inteiro faz o formato herdado com emoji ser normalizado junto.

Três testes por runtime — linha presente, linha com emoji, linha ausente — todos não-vacuosos: sem o encadeamento, Go 2 falhas, npm 5 passed/2 failed, Python `FAILED (failures=2)`.

**O fechamento deste próprio roadmap foi o primeiro em que a linha sincronizou sozinha.**

## D3 — Saída do instalador mentia sobre o destino

12 `Printf` em `agents.go`, `gemini.go`, `scaffold.go` e `windsurf.go` traziam `~/.claude/…`, `~/.gemini/…` e `~/.codeium/…` **hardcoded na string de formato**, sem relação com o caminho resolvido. Isso atrapalhou ativamente o diagnóstico de `REQ-2026-08-16-testes-go-portaveis-windows`, onde o instalador dizia `~/.claude/agents/…` enquanto escrevia num tempdir.

`displayPath` colapsa o home **resolvido** em `~` quando o caminho está sob ele, e devolve o absoluto quando não está. No uso normal a saída fica idêntica à de antes — a garantia deixou de ser cosmética e virou estrutural, porque a string agora deriva do caminho real. Uma mensagem de erro com o mesmo problema foi corrigida junto.

## D4 — `.gitattributes` e `gofmt`

`core.autocrlf=true` sem `.gitattributes` fazia o checkout gravar CRLF nos fontes. O blob commitado sempre foi LF — por isso a CI nunca reclamou — mas `gofmt -l` acusava 22 dos 106 arquivos `.go` localmente.

**Correção de uma leitura minha anterior:** eu havia afirmado que os 22 eram *todos* CRLF. Não eram. Depois de normalizar o EOL sobraram **9** com desvio real de formatação em código pré-existente — `:=` alinhados à mão em `config.go`, comentários de lista em `sync/jira.go`. 13 eram CRLF puro; os 9 foram corrigidos com `gofmt -w`, 59 linhas no total.

A renormalização do working copy não mudou conteúdo nenhum: `git add -A` deixou só o `.gitattributes` staged, e os hashes de working copy e index batem em todos os arquivos tocados.

`gofmt -l internal/ cmd/` devolve **zero**.

## Verificação

- `go test ./...` zero falhas, `go vet ./...` limpo
- npm: `roadmap_move` 7/7, `config` 13/13
- pypi: 245 testes, baseline exata de failures=1 errors=6
- `check-cli-parity.sh`, `check-validate-parity.sh`, `check-static-assets.sh` — os três passam **sem prefixo de ambiente**

## Achados de passagem, fora de escopo

- **`roadmap new` do Go exige uma REQ existente**, npm e Python não. Divergência de contrato entre runtimes.
- **A falha pré-existente do pypi agora está explicada**, não só contada: `test_stale_wip_warning_arquivo_antigo` espera `"10 days"` e recebe `"9 days"` — teste dependente de data, asserção frágil sobre a idade calculada.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #8 — Suíte pypi fecha verde — pytest declarado e asserção de borda corrigida
`MERGED` · branch `fix/suite-pypi-verde` · merge `e0e944f`

Fecha `REQ-2026-08-16-suite-pypi-verde` — itens 10 e 12 da dívida.

A suíte Go fecha verde desde `REQ-2026-08-16-testes-go-portaveis-windows`. A pypi não, e por isso **todas** as entregas desta sessão tiveram que comparar contagem de falhas contra uma baseline em vez de exigir verde. Duas causas independentes.

## D1 — `pytest` é o runner do projeto, mas não estava declarado

Seis módulos são **pytest-style**: funções soltas `test_*` com a fixture `tmp_path`, que o `unittest` não sabe coletar — `test_context_req_by_agent`, `test_discover`, `test_req_by_agent`, `test_rules_req_configuraveis`, `test_serve_api`, `test_traceid`.

Sob `unittest` eles viram `ModuleNotFoundError: No module named 'pytest'` — os 6 "errors" que apareceram em toda medição de baseline desta sessão. Não era defeito de código: era dependência de desenvolvimento ausente. O `CLAUDE.md` já documentava `python3 -m pytest tests/` como o comando da suíte, e o `pyproject.toml` **não declarava pytest em lugar nenhum**.

Converter os seis para `unittest` seria remar contra a convenção do próprio projeto e reescrever muita coisa — os três maiores usam `tmp_path` 18, 35 e 38 vezes.

Adicionado `[project.optional-dependencies] dev = ["pytest>=7"]`. O pacote em si continua sem dependência externa. O `CLAUDE.md` passou a nomear os seis módulos e a registrar o `-t .` que o `unittest discover` precisa para importar `tests/__init__.py`.

## D2 — Asserção sobre uma borda de truncamento

`test_stale_wip_warning_arquivo_antigo` gravava o mtime em **exatamente** `time.time() - 10 dias` e exigia a mensagem `"10 days"`. A produção calcula `int((datetime.now().timestamp() - mtime) / 86400)`.

Os dois lados leem **relógios diferentes**. Medido nesta plataforma, 20 mil amostras:

```
datetime.now().timestamp() - time.time()
  menor:      -0.000001 s
  maior:      +0.001311 s
  negativos:  16889 de 20000   (84%)
```

Quando a leitura da produção cai antes da do teste — 84% das vezes — a idade dá `9.999999` dias e o `int()` trunca para **9**.

Isso explica por que o teste passava isolado e falhava no módulo: era cara-ou-coroa viciado em 84% para falhar, e a ordem de execução só mudava o jitter. **Não era fragilidade de data**, como eu havia caracterizado antes de investigar — era asserção exata colocada precisamente sobre a descontinuidade.

A produção está correta: truncar a idade em dias é o comportamento esperado. O defeito era do teste. A folga de 1 hora move o valor para longe da borda sem afrouxar a asserção — 10 execuções seguidas do módulo, zero falhas.

## Resultado

| | antes | depois |
|---|---|---|
| `pytest tests/` | não rodava (pytest ausente) | **283 passed, 0 failed** |
| `unittest discover -s tests -t .` | 245 testes, 1 failure + 6 errors | 245 testes, **0 failures**, 6 errors esperados |

São **37 testes que nunca haviam rodado** nesta máquina.

Validado num venv limpo: `pip install -e ".[dev]"` seguido de `pytest tests/` → 283 passed.

`go test ./...` segue com zero falhas, `gofmt -l` zero, e os três gates de paridade passam.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #9 — Contrato de roadmap new igual nos três runtimes
`MERGED` · branch `fix/roadmap-new-paridade-contrato` · merge `eb0aaf5`

Fecha `REQ-2026-08-16-roadmap-new-paridade-contrato` — item 11 da dívida.

## O item era maior que o enunciado

Entrou na lista como "o `roadmap new` do Go exige uma REQ existente, npm e Python não". A investigação mostrou que a **superfície inteira do comando** diverge:

| | Go | Node.js | Python |
|---|---|---|---|
| título | `-t/--title` | `-t/--title` | **posicional** |
| `--req` | sim | sim | **não existia** |
| `--from-req` | sim | sim | **não existia** |
| sem REQ disponível | mensagem e **exit 0 sem criar nada** | cria, título default `"New Roadmap"` | cria |
| grava `REQ:` no arquivo | sim | sim | **não** |

O Python **não tinha como** linkar uma REQ. A "não exigência" não era permissividade — era ausência do mecanismo.

E o defeito mais grave era do Go: `internal/commands/roadmap.go:73` imprimia a mensagem e fazia `return nil` — **exit 0 sem criar nada**. Script que confie no código de saída seguia adiante achando que o roadmap existia.

Os gates não pegavam porque `check-cli-parity.sh` compara o conjunto de comandos e a saída de `version`, não flags nem comportamento de subcomando.

## Decisão de rota

Sem REQ resolvível, os três **criam com aviso em stderr e saem 0**. Motivos:

1. O validator já trata isso na hora certa — `wip_has_req` é `error`, mas só dispara em `wip/`. Roadmap em `backlog/` sem REQ é estado legítimo do modelo.
2. Recusar quebraria usuários de npm e pypi que hoje criam roadmap sem REQ.
3. A recusa atual do Go não era nem recusa: era no-op silencioso com sucesso, pior que as duas.

O gate é o `validate`, não o `new`. O aviso mantém a governança visível e diz a consequência.

## O que mudou

| ML | Runtime | Mudança |
|---|---|---|
| ML-1 | Go | acaba o no-op silencioso; sem título **e** sem REQ agora falha de verdade em vez de criar roadmap sem nome |
| ML-2 | Node.js | mesmo aviso; sem `--title` e sem REQ, erro claro em vez de criar `"New Roadmap"`; título derivado da REQ quando só `--req` vem |
| ML-3 | Python | ganha `-t/--title`, `-r/--req` e `--from-req`; grava a linha `REQ:`; `--from-req` deriva MLs dos critérios de aceite |
| ML-4 | — | verificação |

O posicional do Python foi **preservado** por retrocompatibilidade — era a única forma antes deste PR. A flag vence quando ambos vêm.

`--agent` continua só no Python: é capacidade extra, não quebra de contrato (Go e npm derivam o agente do `trackfw.yaml`). Registrado como divergência conhecida.

## Verificação

Fixture única nos três runtimes, quatro modos:

```
modo                   go     npm    py
--title (exit)         0      0      0
--req (exit)           0      0      0
--req (link)           com-link com-link com-link
--from-req (exit)      0      0      0
--from-req (link)      com-link com-link com-link
sem nada (exit)        1      1      1
MLs derivados          2      2      2
```

Os testes de npm e Python rodam o CLI **por subprocesso**, cobrindo o contrato e o exit code em vez de só o generator. Não-vacuosos: Go 2/3 falham sem o fix, npm 1 passed/2 failed.

- `go test ./...` zero falhas, `go vet` limpo, `gofmt -l` zero
- npm: 3 + 7 + 13 testes verdes
- pypi: **288 passed** sob pytest
- Os três gates de paridade passam

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #10 — Parser de trackfw.yaml para de descartar listas em silêncio
`MERGED` · branch `fix/config-listas-nao-silenciosas` · merge `b06dea7`

Fecha `REQ-2026-08-16-config-listas-nao-silenciosas` — item 4 da dívida, que era um lead e virou achado com o README junto.

## O problema

O `trackfw.yaml` é lido por um parser caseiro em cada runtime. Ele entende **uma** das três formas de lista que o YAML aceita e descarta as outras duas sem dizer nada.

| forma | YAML válido | Go | npm | Python |
|---|---|---|---|---|
| bloco indentado — `  - claude` | sim | ✅ | ✅ | ✅ |
| bloco não indentado — `- claude` | sim | ❌ | ❌ | ✅ |
| inline — `[claude, gemini]` | sim | ❌ | ❌ | ❌ |

As duas formas de bloco são equivalentes para qualquer parser YAML de verdade — confirmado com PyYAML: `yaml.safe_load` devolve o mesmo objeto para as duas.

### O exemplo do README não funcionava

`README.md:199` documentava, na seção "Multi-agent namespacing":

```yaml
roadmap_namespacing: by_agent
agents: [claude, gemini, copilot]
```

Nos três runtimes isso resultava em `agents = []`. Quem seguia a documentação escrevia uma configuração silenciosamente ignorada.

### Impacto medido, por bloco

**`agents` vazio é benigno** — os três caem no fallback de varrer os subdiretórios de `roadmap_dir` como agentes. Foi por isso que o sintoma original não produzia diferença observável de comportamento.

**`adr_dirs` perdido é perda real.** O diretório declarado nunca era varrido, e toda ADR nele ficava invisível ao `validate` — sem erro e sem aviso. Isolado com uma ADR órfã em `docs/decisions`:

```
adr_dirs         go         npm        py
indentado        VE-a-ADR   VE-a-ADR   VE-a-ADR
NAO indentado    nao-ve     nao-ve     VE-a-ADR
```

### Por que ninguém tropeçou

Os três geradores do `init` emitem bloco indentado. O caminho padrão é seguro — é atingido quem edita à mão, ou quem copia do README.

## Decisão de rota

Duas rotas: cobrir todas as formas de YAML, ou recusar em voz alta o que não se entende. **Escolhida a segunda** — o defeito é o silêncio, não a cobertura. Um parser de poucas centenas de linhas nunca vai cobrir YAML inteiro, e cada forma não coberta reproduz o problema.

**Ressalva registrada.** Aplicar "recusar em voz alta" ao bloco não indentado significaria o Python avisar sobre input que ele já processa corretamente, ou passar a rejeitá-lo — as duas pioram o estado atual. Nesse caso o alinhamento foi **para cima**: Go e npm passam a aceitar a forma que o Python já aceitava. O aviso ficou para a forma inline, que nenhum runtime suporta.

## O que mudou

| ML | Runtime | Mudança |
|---|---|---|
| ML-1 | Go | `- x` conta como item de lista antes do teste de indentação; aviso de inline; emissão uma vez no `sync.Once` |
| ML-2 | Node.js | espelha, mensagem idêntica |
| ML-3 | Python | só o aviso — o bloco não indentado já funcionava |
| ML-4 | — | README + verificação |

O aviso nomeia a chave, diz que a forma inline não é lida e mostra a equivalente que funciona. **Não é um parser disfarçado**: o valor continua não sendo parseado, e há teste garantindo isso.

## Verificação

Fixture única nos três runtimes:

```
forma            go         npm        py
indentado        silencio   silencio   silencio
NAO indentado    silencio   silencio   silencio
inline           AVISA      AVISA      AVISA
```

Não-vacuosidade: removendo só o tratamento de `- ` sem indentação, o teste Go falha com `Agents: want [claude apolo], got []`; sem a mudança de assinatura o pacote nem compila.

- `go test ./...` zero falhas, `go vet` limpo, `gofmt -l` zero
- npm: 16 + 3 + 7 testes verdes
- pypi: **291 passed**
- Os três gates de paridade passam

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #11 — ADRs retroativas das 5 REQs, reconstruídas de evidência
`MERGED` · branch `docs/adrs-retroativas` · merge `fa22988`

Fecha `REQ-2026-08-16-adrs-retroativas` — item 5 da dívida.

O repositório não tinha **nenhuma** ADR. Cinco REQs disparavam `req_has_adr`, que foi rebaixada para `warning` em `REQ-2026-08-16-consistencias-template-saida-e-eol` justamente porque não havia como satisfazê-la. O primeiro elo da cadeia `ADR → REQ → ROADMAP` nunca existiu — as decisões estavam no código, só que sem registro.

## Método: reconstruir de evidência, não do enunciado

ADR retroativa tem um risco óbvio: escrever a decisão que a REQ **pediu** em vez da que o código **tomou**. Cada uma aqui foi reconstruída de três fontes — texto da REQ, roadmap correspondente e código atual — e **o código vence** quando divergem. Todas trazem nota de reconstrução no corpo, dizendo a data real de escrita e o que foi verificado. Nenhuma se apresenta como escrita à época.

## As cinco

| ADR | Decisão registrada |
|---|---|
| `wizard-no-command-layer` | I/O interativo vive só no command layer; generators recebem struct e nunca perguntam — é o que os torna testáveis sem TTY |
| `roadmap-derivado-sem-llm` | roadmap derivado dos critérios de aceite deterministicamente, sem LLM, sem chave, sem dependência |
| `handlers-do-serve-testados-sem-servidor` | handlers são funções sobre um diretório de fixture; teste não sobe porta |
| `subcomando-nativo-por-ferramenta-de-ia` | um subcomando por ferramenta emitindo o formato nativo dela, em vez de um exportador genérico |
| `descoberta-de-adr-guiada-pela-req` | a REQ detecta domínios e emite ADRs `Draft`; `blocked_by_draft_adr` segura o roadmap |

## O método já pagou na segunda

`REQ-roadmap-ai-generation-2026-06-11` está marcada `status: done` e especifica um pacote `internal/ai/` com clientes Anthropic e OpenAI, `anthropic-sdk-go` no `go.mod`, seleção de provider e fallback por chave de API.

**Nada disso existe.** Verificado antes de escrever: não há `internal/ai/`; nenhuma menção a `anthropic` ou `openai` em código Go; `go.mod` sem dependência de IA; nenhum tratamento de chave. O roadmap correspondente está em `done/` com **todos os MLs `⬜ Pendente`**.

O que existe é `roadmap new --from-req`, nos três runtimes, derivando os MLs dos critérios de aceite sem chamar modelo nenhum. A ADR registra essa decisão e explicita a divergência com a REQ — incluindo as três restrições que a justificam: reprodutibilidade, funcionar offline sem credencial, e dependência zero.

Tivesse eu escrito a ADR a partir do enunciado, o repositório passaria a documentar uma arquitetura de IA que ele não tem.

**Achado de governança separado:** uma REQ marcada como entregue para trabalho que não aconteceu. Registrado, fora do escopo desta entrega.

## Fechamento

- Link bidirecional nas cinco: cada REQ ganhou a linha `ADR:`, cada ADR nomeia a REQ.
- `req_has_adr` de volta ao default `error` no `trackfw.yaml` — foi rebaixada por falta de saída, não por discordância.
- `trackfw validate`: **zero violações e zero avisos**, pela primeira vez com a regra em `error`.
- `go test ./...` zero falhas; npm 26 testes verdes; pypi 291 passed; os três gates de paridade passam.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #12 — Abandona a REQ de geração de roadmap por IA
`MERGED` · branch `chore/abandona-req-geracao-ia` · merge `a33ade4`

`REQ-roadmap-ai-generation-2026-06-11` estava marcada `done`, e o roadmap dela em `done/` com **todos os MLs `⬜ Pendente`** — para trabalho que nunca aconteceu.

Verificado antes de mover: não existe `internal/ai/`, não há nenhuma menção a `anthropic` ou `openai` em código Go, o `go.mod` não tem dependência de IA e não há tratamento de chave de API em lugar nenhum.

A solução que venceu está registrada em [`ADR-2026-06-11-roadmap-derivado-sem-llm.md`](docs/adr/ADR-2026-06-11-roadmap-derivado-sem-llm.md): derivação determinística dos critérios de aceite, entregue como `roadmap new --from-req` nos três runtimes.

## O que mudou

| artefato | de | para |
|---|---|---|
| `REQ-roadmap-ai-generation-2026-06-11` | `apolo/done/` | `apolo/abandoned/` |
| `roadmap-roadmap-ai-generation-2026-06-11` | `claude/done/` | `claude/abandoned/` |

**O roadmap foi junto.** Você pediu a REQ, mas deixá-lo em `done/` enquanto a REQ diz `abandoned` só trocaria uma incoerência por outra — é o mesmo registro falso. Se preferir separar, é reverter o segundo `git mv`.

Ambos levam nota explicando o porquê, o que foi verificado e para onde a decisão foi. Vão para `abandoned/` em vez de serem apagados: o pedido existiu, foi avaliado e foi substituído. É história, e o `abandoned/` existe para guardá-la.

## Dois detalhes do próprio tooling

- O roadmap foi movido com `trackfw roadmap move`, e a linha `> … | Status:` **sincronizou sozinha** — o fix de `REQ-2026-08-16-consistencias-template-saida-e-eol` em ação. O arquivo não tem frontmatter, então só a linha humana mudou, exatamente como o contrato prevê.
- A REQ precisou de `git mv` à mão: **não existe `req move` no CLI**, em nenhum dos três runtimes. Só `req new` e `req list`. Achado novo.

`trackfw validate` segue com zero violações e zero avisos.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #13 — Comando req move nos três runtimes
`MERGED` · branch `feat/req-move` · merge `80f690c`

Fecha `REQ-2026-08-17-req-move`.

## O problema

O roadmap tem transição de estado como comando de primeira classe — `trackfw roadmap move <nome> <estado>`. A REQ não tinha nada equivalente, em nenhum dos três runtimes: só `req new` e `req list`.

A assimetria não é cosmética: o validator **já conhece** o ciclo de estados da REQ — `resolveREQFiles` varre `backlog`, `wip`, `blocked`, `done` e `abandoned` sob cada agente. O modelo previa que a REQ transitasse; a ferramenta não oferecia o comando. Mover uma REQ era `git mv` à mão mais edição do frontmatter — foi exatamente o que precisei fazer no PR anterior para abandonar `REQ-roadmap-ai-generation-2026-06-11`.

## O que a implementação esbarrou

Escrever `req move` exige resolver "onde está a REQ", e essa camada está quebrada de duas formas diferentes. Medido neste repositório:

| resolvedor | o que varre | vê das 36 REQs |
|---|---|---|
| `req list` (`ListREQs`) | `reqDir/*.md` | **0** — ignora `by_agent` inteiro |
| `validate` (`resolveREQFiles`) | `reqDir/<agente>/<estado>/*.md` | **5** — ignora `reqDir/<agente>/*.md` |

Idêntico nos três runtimes, então nenhum gate pega — é bug replicado, não quebra de paridade. Confirmado com fixture: uma REQ em `claude/backlog/` é validada, a mesma em `claude/` não é.

**Reportado, não corrigido aqui.** Tornar as 31 invisíveis visíveis levaria o `validate` deste repo de 0 para **53 violações** (31 `req_has_adr` + 22 `req_has_roadmap`). Isso é decisão de governança de quem mantém o projeto, não efeito colateral de um comando novo. Registrado na REQ e na ADR.

## A decisão de desenho

Registrada em [`ADR-2026-08-17-req-move-resolve-as-tres-formas.md`](docs/adr/ADR-2026-08-17-req-move-resolve-as-tres-formas.md), com duas partes:

**O resolvedor cobre as três formas** — `<agente>/<estado>/`, `<agente>/` e a raiz do `req_dir`. Reusar `resolveREQFiles` seria zero código novo, mas o comando falharia em 31 das 36 REQs deste repositório, incluindo todas as criadas nesta sessão. Um comando que não acha o arquivo que o usuário está vendo não é o comando.

Isso significa que `req move` enxerga mais que o `validate`. É assimetria assumida, e o lado certo dela.

**O log vai para `<req_dir>/.trackfw-log`**, separado do de roadmaps. `trackfw log` e `trackfw metrics` tratam cada linha de `<roadmap_dir>/.trackfw-log` como transição de roadmap — misturar REQs ali distorceria lead time e throughput em silêncio. Um número errado que ninguém percebe é pior que um número que não existe.

O agente de origem é preservado no destino: uma REQ em `apolo/done/` vai para `apolo/abandoned/`, não para o primeiro agente da lista. Mover não pode trocar o dono.

## Verificação

Fixture única, três runtimes, três formas de origem:

```
forma de origem                    go                 npm                py
agente/estado                      ok-sincronizado    ok-sincronizado    ok-sincronizado
agente, sem estado                 ok-sincronizado    ok-sincronizado    ok-sincronizado
raiz do req_dir (flat)             ok-sincronizado    ok-sincronizado    ok-sincronizado
estado invalido (exit)              1 1 1
nao encontrada (exit)               1 1 1
```

**Não-vacuosidade das duas decisões centrais**, verificada quebrando cada uma isoladamente no Go: removendo o pattern `<agente>/*.md`, `TestMoveREQ_DeDentroDoAgenteSemEstado` falha; usando o primeiro agente em vez do de origem, `TestMoveREQ_PreservaOAgente` falha.

Os testes de npm e Python rodam o CLI **por subprocesso**, cobrindo contrato e exit code em vez de só o generator.

- Go: 9 testes novos, `go test ./...` zero falhas, `vet` limpo, `gofmt -l` zero
- npm: 8 testes novos; 34 no total, todos verdes
- pypi: 8 testes novos; **299 passed**
- `check-cli-parity.sh` passa com o comando novo nos três; os outros dois gates também
- `trackfw validate` rc=0

## Pendências registradas

- Nenhum comando lê `<req_dir>/.trackfw-log` ainda — `trackfw log` continua só nos roadmaps. Dívida deliberada: preservar a história custa uma linha, reconstruí-la depois é impossível.
- Os dois resolvedores de REQ com alcances diferentes convivem no código até o ponto cego ser atacado.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #14 — Unifica os três resolvedores de REQ e congela a dívida revelada
`MERGED` · branch `feat/resolvedor-req-unificado` · merge `3805d5e`

Fecha `REQ-2026-08-17-resolvedor-req-unificado`.

## O problema

Três resolvedores de REQ no mesmo código, com alcances diferentes. Medido neste repositório:

| resolvedor | o que varria | via |
|---|---|---|
| `ListREQs` | `reqDir/*.md` | **0** das 36 |
| `resolveREQFiles` | `reqDir/<agente>/<estado>/*.md` | **5** |
| `findREQ` | as três formas | **36** |

O terceiro foi escrito em `REQ-2026-08-17-req-move` justamente porque os dois existentes não serviam. `req list` respondia "No REQs found" num repositório com 36 REQs, e **o `validate` não olhava 31 delas** — incluindo todas as criadas nesta sessão.

Idêntico nos três runtimes: bug replicado, invisível aos gates.

## A unificação

Um resolvedor por runtime: `internal/reqs` (Go), `npm/src/reqs.js`, `pypi/trackfw/reqs.py`. Os consumidores viraram casca fina.

No Go precisou de pacote próprio: `generators` já importa `validator`, então um resolvedor compartilhado não cabia em nenhum dos dois sem criar ciclo.

`req list` saiu de "No REQs found" para listar as 40, agrupadas por agente e estado.

## A medição

```
44 violações, 0 avisos     (27 REQs distintas, de 40)

25  req_has_adr
18  req_has_roadmap
 1  req_frontmatter
```

Os três runtimes concordam nas 44.

**Corrijo minha estimativa anterior de 53.** Aquele número veio de contar por grep as linhas `ADR:` e `Roadmap:` ausentes, o que não reproduz as condições das regras. O real é 44 — medido, não estimado.

## Dois defeitos que a unificação revelou

**`parseREQMeta` (Go) e `parseREQStatus` (npm)** varriam o arquivo inteiro atrás de `| Status: `, deixando qualquer tabela ou trecho de corpo sobrescrever o status. Estava escondido atrás do resolvedor quebrado — só apareceu quando o `req list` passou a listar algo, e a coluna veio como lixo. Corrigidos para preferir o frontmatter e parar no primeiro `## `.

**`SaveBaseline` do Go gravava `"warnings": null`**, e o Python estourava com `TypeError: 'NoneType' object is not iterable` ao ler. O `.trackfw-baseline.json` é artefato compartilhado entre os três runtimes e nenhum gate cobre isso. Corrigido dos dois lados: o Go grava `[]`, o Python tolera `null` para baselines já existentes.

## Baseline aplicado

Por decisão do usuário, `trackfw baseline` congelou as 44. Gate volta a rc=0 nos três, e o ratchet foi verificado: criando uma REQ sem ADR nem roadmap, **os três a acusam**.

## Verificação

- Go: 7 testes novos no pacote `reqs`, `go test ./...` zero falhas, `vet` limpo, `gofmt -l` zero
- npm: 34 testes verdes
- pypi: **299 passed**
- Os três gates de paridade passam

## Lacuna registrada

**`req list` não existe no runtime Python** — só `new` e `move`. Não havia o que unificar ali. Fora do escopo desta REQ.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #15 — Comando req list no runtime Python
`MERGED` · branch `feat/req-list-python` · merge `da601e8`

Fecha `REQ-2026-08-17-req-list-python` — lacuna registrada em `REQ-2026-08-17-resolvedor-req-unificado`.

## O problema

O runtime Python tinha só `req new` e `req move`. Go e Node.js têm `req list` desde sempre, e desde a unificação do resolvedor os dois listam as 40 REQs agrupadas por agente e estado, com saída idêntica entre si.

Quem usa `pip install trackfw` não conseguia listar as REQs do próprio projeto pela ferramenta.

**Por que os gates não pegaram:** `check-cli-parity.sh` compara o conjunto de comandos de *primeiro nível* e a saída de `version`. Não desce em subcomando. `req` existe nos três, então a paridade passa mesmo com `list` faltando em um — do mesmo jeito que passava com `move` faltando nos três antes do PR #13.

## O que foi feito

`parse_req_status` **nasce com o comportamento correto**: frontmatter primeiro, e a busca pela linha de cabeçalho para no primeiro `## `. Go e npm tiveram o defeito de varrer o arquivo inteiro — deixando qualquer tabela do corpo sobrescrever o status — e foram corrigidos no PR #14. Esta versão não reproduz o defeito, e há quatro testes garantindo isso, incluindo uma tabela com `| Status: ` depois do primeiro `## `.

`list_reqs` usa `trackfw.reqs.all_reqs`, o mesmo resolvedor que o `validate` e o `move` do Python já usavam. Nenhuma lógica de caminho nova.

## Escopo acrescentado: newline de todo o CLI Python

O `diff` entre os runtimes acusou as 51 linhas como diferentes — com o conteúdo idêntico. O Python emitia **CRLF** no Windows enquanto Go e Node.js emitem **LF**.

Não era do `req list`: era de **toda** saída do CLI Python, desde sempre. `_force_utf8_output` (do PR #6) reconfigurava a codificação mas não o newline. Corrigido no `reconfigure`, com teste próprio que assevera ausência de CRLF na saída do subprocesso.

Isso quebrava `diff`, pipe e qualquer script que comparasse a saída dos três.

## Verificação

```
diff go vs py    →  IDENTICOS byte a byte
diff npm vs py   →  IDENTICOS byte a byte
req_dir vazio    →  "No REQs found in docs/req" nos três
```

- Go: zero falhas
- npm: 31 testes verdes
- pypi: **307 passed**
- Os três gates passam; `trackfw validate` rc=0

## Nota de método

Meu primeiro check de não-vacuosidade do teste de CRLF **passou indevidamente**: o script que removia o fix não casou o padrão por causa de escape, e o teste rodou duas vezes com o fix ainda presente. Só percebi ao conferir o arquivo com `grep` em vez de confiar na saída do script.

Refeito com edição direta e `__pycache__` limpo — sem o fix, `FAILED (failures=1)`. Um teste de não-vacuosidade que não falha quando deveria é pior que nenhum, porque dá confiança falsa.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #16 — Gate de paridade de subcomando
`MERGED` · branch `feat/gate-paridade-subcomando` · merge `99e38a2`

Fecha `REQ-2026-08-17-gate-paridade-subcomando`.

## O buraco

`check-cli-parity.sh` compara o conjunto de comandos de **primeiro nível**, e só verifica presença contra uma lista fixa.

Foi por isso que duas lacunas passaram nesta sessão: `req move` faltava nos três runtimes (PR #13) e `req list` faltava no Python (PR #15). Em ambos os casos `req` existia em todos, então a paridade passava. As lacunas só apareceram porque alguém tropeçou nelas.

## O gate

Desce um nível e compara **conjuntos nos dois sentidos** — subcomando faltando *e* sobrando.

Extrai dos três formatos de help: `Available Commands:` (cobra), `Commands:` (commander, descartando o `help` que ele injeta sozinho) e o bloco `positional arguments:` (argparse). O metavar do argparse varia entre `COMMAND` e `SUBCOMMAND` conforme o comando — ancorar nele faria o `roadmap` do Python sair vazio, então o extrator ancora no cabeçalho do bloco.

## Cinco divergências que ninguém conhecia

```
✗ adr:     'list'   faltando no runtime python
✗ plugins: 'add'    faltando no runtime python
✗ plugins: 'remove' faltando no runtime python
✗ plugins: 'search' faltando no runtime python
✗ plugins: 'run'    sobrando no runtime python
```

`adr list` existe em Go e Node.js desde `REQ-adr-wizard-e-list-2026-06-11` e nunca foi portado. O `plugins` do Python foi escrito com outra superfície inteira.

## Como o gate nasce verde sem esconder

As cinco ficam declaradas **no próprio script**, cada uma com o motivo em comentário. Mesmo princípio do `trackfw baseline`: congela o conhecido, e qualquer divergência **nova** falha.

O script também avisa quando uma declaração não corresponde mais à realidade, para a lista não apodrecer depois que alguém corrigir a divergência.

**Corrigir as cinco não é escopo desta REQ.** `plugins run` pode ser capacidade deliberada do Python — o pacote pip não gerencia instalação de plugin da mesma forma. Precisa de decisão antes de virar trabalho.

## Verificação

| cenário | resultado |
|---|---|
| allowlist vazio | acusa **exatamente** as 5 medidas à mão |
| removendo só `adr:python:list` | acusa **exatamente** ela — 1, não 5 |
| declaração obsoleta (`req:python:move`) | `⚠ divergência declarada já não existe … — remova do allowlist`, rc=0 |
| estado atual | passa |

Os quatro gates passam, `go test ./...` zero falhas, `trackfw validate` rc=0.

`CLAUDE.md` documenta os quatro, com um parágrafo explicando o que este cobre que o `check-cli-parity.sh` não cobre — citando os dois casos que passaram batido.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #17 — Porta adr list para o Python e alinha o parser de status nos três
`MERGED` · branch `feat/adr-list-python` · merge `eca06fd`

Fecha `REQ-2026-08-17-adr-list-python` — uma das cinco divergências que o gate de subcomando revelou ao nascer (PR #16).

## O port destampou uma divergência maior

`adr list` existe em Go e Node.js desde junho e nunca foi portado. Portar exige decidir **de onde vem o status** — e aí se descobre que os dois runtimes existentes **já discordavam entre si**.

Com uma ADR cujo corpo tem uma tabela mencionando `| Status: `:

```
ADR-x.md    quebrado     ← Go:  varria o arquivo inteiro, a ULTIMA ocorrencia vencia
ADR-x.md    Accepted     ← npm: varria o arquivo inteiro, a PRIMEIRA vencia
```

Nenhum dos dois lia o `status:` do frontmatter — o campo canônico, que o `adr new` grava e o validator usa.

É a mesma família de defeito que `parseREQMeta` e `parseREQStatus` tinham, corrigida nos PRs #14 e #15. Aqui estava **latente**: nenhuma ADR deste repositório tem tabela com esse texto, então as duas saídas coincidiam por acidente.

Portar sem resolver acrescentaria uma **terceira** resposta possível para a mesma pergunta.

## O contrato

Único nos três, o mesmo já adotado para REQ: o `status:` do frontmatter é a fonte preferida; na ausência dele, a linha de cabeçalho `> … | Status: …`, parando no primeiro `## `. **O corpo nunca decide.**

Python nasce correto; Go e Node.js foram corrigidos.

## Verificação

| cenário | go | npm | py |
|---|---|---|---|
| ADR com tabela no corpo | `Accepted` | `Accepted` | `Accepted` |
| diretório vazio | `No ADRs found in docs/adr` | idem | idem |
| listagem completa | `diff` vazio entre os três | | |

- 4 testes novos no Go, 8 no Python — frontmatter, cabeçalho, tabela no corpo, ausência
- Go zero falhas; npm 24 testes; pypi **315 passed**
- Os **quatro** gates passam

`adr:python:list:faltando` saiu do allowlist do gate de subcomando — de 5 divergências declaradas para 4. O gate não emitiu aviso de declaração obsoleta, confirmando que as outras quatro continuam reais.

## Limitação herdada, registrada e não corrigida

`adr list` lista apenas o **primeiro** `adr_dirs`, com glob plano e sem recursão — nos três runtimes. O validator, por outro lado, usa `walkADRFiles`, que percorre todos os `adr_dirs` recursivamente.

É a mesma classe de problema que existia para REQ antes do PR #14: o comando mostra menos do que o gate enxerga. Mantive o comportamento dos outros dois porque paridade é o objetivo desta REQ; unificar o resolvedor de ADR é trabalho próprio. Neste repositório não há diferença observável — `adr_dirs` tem uma entrada só e as ADRs são planas.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #18 — Unifica a geração de slug e saneia caracteres de caminho nos três runtimes
`CLOSED` · branch `fix/slug-unificado`

Fecha `REQ-2026-08-28-slug-unificado`.

## O problema

Sete funções de slug no projeto — uma no Go, três no Node.js, três no Python — com **quatro** comportamentos diferentes.

**Caractere de caminho derrubava o comando.** Medido com `adr new "React + shadcn/ui as frontend"`:

```
Go   → Error: ... The system cannot find the path specified   (falha, não cria nada)
npm  → node:fs:2413  binding.writeFileUtf8(...)               (stack trace cru)
py   → funcionava
```

**Acento produzia nomes diferentes — e mutilados.** Este é o caso comum aqui, porque o repositório é em português. Mesma REQ, `roadmap new --from-req` nos três:

```
go   ROADMAP-2026-08-28-consolidação-das-três-árvores.md
npm  ROADMAP-2026-08-28-consolida-o-das-tr-s-rvores.md
py   ROADMAP-2026-08-28-consolida-o-das-tr-s-rvores.md
```

O `[^a-z0-9]+` sem dobra NFKD engole a letra acentuada inteira: `consolidação` vira `consolida-o`. É pior que preservar o acento.

Isso quebrava a premissa tri-runtime — o mesmo artefato gerado por runtimes diferentes recebia nomes diferentes, então `--from-req` e qualquer fluxo que atravesse runtime produzia arquivos divergentes.

## O que mudou

Um módulo por runtime: `internal/slug`, `npm/src/slug.js`, `pypi/trackfw/slug.py`. As sete cópias delegam — **nenhuma definição sobrou fora dos módulos**. Mesmo desenho de `internal/reqs`.

Algoritmo único: dobra NFKD, minúsculas, colapso de `[^a-z0-9]+` em hífen, trim das pontas.

## Sobre o commit órfão

Existe `83e3e07` na branch `claude/jovial-morse-3a90d1` (2026-06-28) que atacou exatamente isto e nunca entrou na `main` — ficou 88 commits para trás.

**Não foi cherry-pick.** Aproveitei o algoritmo e os casos de teste, mas reimplementei, porque aquele commit corrige as funções onde elas estão, sem eliminar a duplicação — que é a causa de a divergência voltar. Além disso ele toca o `adr.go` justamente onde o `parseADRMeta` foi reescrito no PR #17, e é anterior à disciplina de verificação byte a byte que adotamos.

**Custo de dependência: zero.** `golang.org/x/text` já estava no `go.mod` como indireta; só foi promovida a direta. O `go.sum` não mudou.

## Verificação

Título `React + Consolidação/ui das três árvores`, nos três:

```
go   ROADMAP-2026-08-28-react-consolidacao-ui-das-tres-arvores.md
npm  ROADMAP-2026-08-28-react-consolidacao-ui-das-tres-arvores.md
py   ROADMAP-2026-08-28-react-consolidacao-ui-das-tres-arvores.md
```

Idênticos. Além dos casos da tabela, cada runtime tem um teste que garante que a saída **nunca** contém `/ \ : * ? " < > |` — inclusive para `../../etc/passwd`.

- Go: 13 subtestes + o de separador; zero falhas, `vet` limpo, `gofmt -l` zero
- npm: 47 testes verdes
- pypi: **317 passed**
- Os quatro gates passam; `trackfw validate` rc=0

## Achado novo, fora de escopo

O prefixo da ADR ainda diverge, por dois motivos anteriores a esta REQ. Um já era conhecido — o Python usa numeração sequencial (`ADR-001-`) e os outros usam data.

O outro é **novo**: o Go usa `time.Now().Format(...)` (data **local**) e o Node.js usa `new Date().toISOString()` (data **UTC**). A medição foi feita às 23:44 no fuso −03:00, quando em UTC já era dia 29 — e os dois geraram artefatos com datas diferentes.

A janela é de 21:00 a 00:00 no horário de Brasília. Três horas por dia, o que explica por que nunca apareceu. O Python usa `date.today()`, alinhado ao Go. Merece REQ própria.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #19 — chore(migracao): adota o upstream 7.3.0 como base
`MERGED` · branch `chore/migrar-upstream-7.3.0` · merge `ad5ce96`

Migra este repositório de uma cópia por ZIP da **v2.12.2** para a base do **upstream v7.3.0**, estabelecendo ancestralidade com `kgsaran/trackfw`.

## O problema

Não havia ancestral comum. `git merge` se recusava a rodar, e por isso o repo ficou **cinco majors atrás** sem ninguém perceber. Sete correções feitas aqui nas últimas semanas já existiam upstream.

Depois desta PR:

```bash
git fetch upstream
git merge upstream/v7.4.0
```

`git merge-base HEAD v7.3.0` devolve `89928b1` — o próprio commit da 7.3.0.

## Política

Produto vem do upstream. `docs/`, `trackfw.yaml` e `.gitattributes` são locais. A governança do upstream (52 ADRs, 140 REQs, 142 roadmaps) **não** é importada — cairia dentro de `docs/adr/` e `docs/roadmaps/`, que é onde vive a governança daqui. `docs/` final: 7 ADRs, 44 REQs, 54 roadmaps.

## O que a rota escolhida revelou

Merge de históricos não-relacionados **adiciona, mas nunca apaga**. Todo arquivo que o upstream deletou entre a 2.12.2 e a 7.3.0 sobreviveu em silêncio. Quem denunciou foi o compilador:

```
internal/generators/codex.go:142:12: undefined: injectCodexHooks
```

Podados **110 arquivos**: os 6 geradores legados (`amazonq/codex/copilot/cursor/gemini/windsurf` — o upstream tem REQ de remoção em `done/`), o subsistema de plugins nos 3 runtimes (ADR-2026-08-15), os 80 templates de agente e `internal/server/` (virou `internal/serve/`).

Também removidos 8 testes locais escritos contra as portas antigas de `req move`, `req list`, `adr list` e `roadmap new` — o upstream implementou as mesmas features com contratos diferentes.

## Divergências locais deliberadas

| O quê | Por quê |
|---|---|
| `_force_utf8_output` em `pypi/trackfw/cli.py` | Sem ele, `UnicodeEncodeError` no `→` em console cp1252. Verificado por não-vacuidade. |
| `internal/homedir` (novo) | Os testes isolam `HOME` em 97 call sites, mas no Windows `os.UserHomeDir()` lê `%USERPROFILE%`. Uma rodada de `go test ./...` escreveu ADR, manifesto e scripts de guard **dentro da home real**. 19 call sites de produção custam menos que 97 de teste, que conflitariam em todo merge futuro. |
| `scripts/check-subcommand-parity.sh` | Gate local. `known_divergences` esvaziado — as 4 entradas eram de `plugins`. |

Superfície local fora de `docs/`: **5 arquivos**.

## Verificação

- `go build ./...` verde · `go vet ./...` limpo · `gofmt -l` vazio
- `trackfw version` = 7.3.0 nos três runtimes
- `check-subcommand-parity.sh` passa, e **falha** com defeito injetado (não-vacuidade confirmada)
- 11 violações de link de REQ → 0 (o `referenceExists` da 7.3.0 faz `os.Stat` relativo ao cwd; as REQs legadas escreviam só o basename)

### As suítes de teste: a 7.3.0 é vermelha no Windows

Medido contra worktree pristina em `v7.3.0`, mesma máquina:

| runtime | 7.3.0 pristina | esta PR |
|---|---|---|
| Go | 6 pacotes FAIL / 8 ok | 6 pacotes FAIL / 8 ok |
| npm | 329 falhas / 614 passes | 297 falhas / 631 passes |
| pypi | 223 falhas / 1264 passes | 213 falhas / 1307 passes |

A migração não introduziu regressão — em npm e pypi ficou melhor que o upstream puro.

## Passivo aberto

**`trackfw validate` sai 1 nesta máquina e não há como evitar.** A regra `credential_guard_hook_resolvable` testa `info.Mode()&0111 == 0`, e o `os.Stat` do Go no Windows devolve `-rw-rw-rw-` para todo arquivo — verificado empiricamente, inclusive depois de `chmod +x`. O baseline não resolve: `filterBaselineTagged` isenta `credentialGuardAnchoredRules` da supressão por decisão de segurança do upstream (`validator.go:577`). 9 das 15 violações de bit de execução foram congeladas; as 6 de credential-guard nunca podem ser.

É a terceira barreira estrutural de Windows na 7.3.0, junto com o UTF-8 e o `homedir`.

## Decisão pendente

`vault/` (85 notas de conhecimento do upstream) entrou no merge. Mesma categoria da governança que ficou de fora, mas não colide com nada e nenhum teste depende dele.

---

Refs: `REQ-2026-08-29-migrar-para-upstream-7.3.0` · `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #20 — docs(governanca): REQ e roadmap para o slug de artefato divergente no Python
`MERGED` · branch `docs/slug-python-diverge-de-go-e-node` · merge `5fdc444`

Governança para o resíduo que sobrou depois de fechar a #18. Nenhuma linha de implementação — o roadmap fica em `backlog/`.

## O defeito

Os três runtimes geram nomes de arquivo diferentes para o mesmo título quando ele contém caractere não-alfanumérico que não seja espaço. Medido em diretório limpo por runtime, com `adr new "Ação C/C++ & Café"`:

```
Go      ADR-2026-08-29-acao-c-c-cafe.md
Node    ADR-2026-08-29-acao-c-c-cafe.md
Python  ADR-2026-08-29-acao-cc-cafe.md
```

A regra difere: o Python **deleta** os não-alfanuméricos (`re.sub(r'[^a-z0-9-]', '', slug)` em `pypi/trackfw/generators/adr.py:22`); Go e Node os **substituem por hífen**. Acento, `/`, `+` e `&` já são tratados nos três — não é sanitização ausente, é regra de colapso divergente.

Consequência: uma REQ criada pelo Python e outra criada pelo Go a partir do mesmo título viram arquivos distintos, e a cadeia ADR → REQ → ROADMAP quebra por referência que não resolve.

## Por que o gate não pegou

`scripts/check-artifact-parity.sh` usa `TITLE="Autenticação e Sessão"` (linha 43) — só acento, nenhum dos caracteres onde os runtimes discordam. O gate passa e o defeito sobrevive.

## Como isso apareceu

Ao verificar se as duas branches de slug ainda faziam sentido depois da migração para a base 7.3.0 (#19). As duas foram fechadas — `fix/slug-unificado` (#18) e `claude/jovial-morse-3a90d1` (commit `83e3e07`, preservado aqui para recuperação) — porque o `slugify` da 7.3.0 já cobre o que elas consertavam. Este é o que ficou.

## Fora de escopo

`internal/identity/slug.go` (slug de identidade de agente) tem contrato próprio e fixture de vetores. Não é o mesmo slug.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #21 — docs(governanca): ML-0A do slug — threat model e inventário fechado
`MERGED` · branch `docs/ml-0a-threat-model-slug` · merge `f3f0788`

Wave 0 do roadmap do slug. **Nenhuma linha de implementação** — o roadmap sai de `backlog/` para `analyzing/`.

## O que a enumeração devolveu

A REQ nomeava três arquivos. São **dez implementações de slug em cinco superfícies**:

| Runtime | Implementações | Observação |
|---|---|---|
| Go | 1 — `internal/generators/adr.go:151` | compartilhada por adr, req, roadmap, note **e `java.go`** |
| Node | 5 — `toSlug` em adr/note/req/roadmap + inline no `init.js:336` | as quatro `toSlug` são byte a byte idênticas |
| Python | 4 — `slugify` em adr/note/req/roadmap | **só `adr.py` diverge** |

Quatro tipos de artefato, não três — a REQ omitia `note`.

## O defeito é mais estreito num eixo e mais largo noutro

**Mais estreito.** Medido com `new "Ação C/C++ & Café"`, diretório limpo por runtime:

```
adr new       go acao-c-c-cafe   node acao-c-c-cafe   py acao-cc-cafe    <- diverge
req new       go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
roadmap new   go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
note new      go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
```

Não é "o Python". É `pypi/trackfw/generators/adr.py:slugify` sozinho — ele deleta os não-alfanuméricos, enquanto `note.py`, `req.py` e `roadmap.py` colapsam por hífen igual a Go e Node. O critério da REQ que dizia "vale para adr, req e roadmap" estava errado.

**Mais largo.** Uma segunda divergência, independente, no `artifactId` do `pom.xml`. O Go usa `toSlug` com NFKD; o Node usa expressão inline sem NFKD e **perde a letra**:

```
"Café App"   ->   Go: cafe-app     Node: caf-app
```

## A linha que muda o critério

Na falsificação em duas direções, uma entrada importa mais que as outras: se o `pom.xml` do Go regredir para *também* não dobrar acento, os dois runtimes passam a concordar **no valor errado** — paridade verde, comportamento pior.

Por isso o critério deixou de ser "os três iguais" e passou a exigir a regra documentada em `docs/cli-parity.md` com o motivo.

## Gate da Wave 0

`scripts/check-slug-inventory.sh` substitui o placeholder `exit 1`. Lista as dez implementações e compara com o inventário declarado. Passa hoje, e **falha** com uma décima primeira — verificado, não assumido:

```
Wave 0: inventario de slug mudou.
6a7
> pypi/trackfw/generators/_naovacuidade.py:slugify
rc=1
```

## Residual declarado

Fora de escopo por contrato próprio: `internal/identity/slug.go` (slug de identidade, com fixture de vetores), `deriveSlug` (URL, não título) e `normalizeBranchSlug` (nome de branch, não gera arquivo).

Aceito sem virar trabalho: o `note new` do Python imprime `vault/notes\arquivo.md`, com separador misto no Windows. O arquivo criado é o mesmo.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #22 — docs(governanca): ML-1A — a regra de slug de artefato é colapso por hífen
`MERGED` · branch `docs/ml-1a-regra-de-slug` · merge `4693671`

Wave 1, ML-1A do roadmap do slug. Ainda **nenhuma linha de implementação** — só a decisão e o contrato escrito.

## A decisão

**Colapso por hífen:** `[^a-z0-9]+` → um hífen, nunca deleção.

1. **Deleção junta tokens que o título separava.** `C/C++ & Café` vira `cc-cafe` em vez de `c-c-cafe`; `AWS+GCP` vira `awsgcp` em vez de `aws-gcp`. O nome de arquivo existe para ser lido por gente, e a fronteira de palavra é o que o torna legível.
2. **9 das 10 implementações já colapsam.** Alinhar a décima é a mudança menor.

Documentado em `docs/cli-parity.md` como `## Artifact slug contract`.

## O que apareceu ao escrever a seção

O `cli-parity.md` já tinha um contrato de slug — o de **identidade de agente**. E ele manda **descartar** o caractere fora de `[a-z0-9-]`, o oposto do de artefato. Medido:

| Entrada | Identidade | Artefato |
|---|---|---|
| `C/C++` | `cc` | `c-c` |
| `AWS+GCP` | `awsgcp` | `aws-gcp` |
| `Meu Agente` | `meu-agente` | `meu-agente` |

São dois contratos separados de propósito: identidade é identificador curto, validado e sujeito a colisão; artefato é nome de arquivo legível.

**A terceira linha é a armadilha.** Eles coincidem no caso comum, que é como alguém conclui que são a mesma coisa.

E isso explica a origem do defeito: `pypi/trackfw/generators/adr.py:slugify` não tem um erro aleatório — ele **implementa a regra de identidade onde vai a de artefato**. As duas seções agora se referenciam mutuamente, com a instrução explícita de não unificar.

## Gates

- `check-parity-contract-coverage.sh` verde. Minha inserção tinha deslocado a anotação da seção de identidade do lugar que o gate exige; devolvida.
- `check-slug-inventory.sh` verde, 10 implementações.

## Fora de escopo, registrado

`scripts/check-parity-contract-coverage.sh` morre com `UnicodeEncodeError` no `→` em console cp1252 — pré-existente, verificado rodando o gate na `main` sem esta mudança (o doc tem 65 ocorrências do caractere). Só roda com `PYTHONIOENCODING=utf-8`.

É o **quarto bloqueio de Windows** da 7.3.0, junto com o UTF-8 do CLI, o `homedir` e o `credential_guard_hook_resolvable`.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #23 — fix(eol): geradores Python passam a escrever LF, não CRLF
`MERGED` · branch `fix/geradores-python-escrevem-crlf-no-windows` · merge `199dea4`

O CLI Python gravava **todo** arquivo com CRLF no Windows; Go e Node gravam LF. Isso viola a Regra Dura de Paridade — os três CLIs produziam artefato diferente byte a byte para a mesma entrada.

## Não era cosmético

Entre os 23 arquivos afetados estão os cinco `scripts/*.sh` que o `trackfw init` gera:

```
py     b'#!/usr/bin/env bash\r'
go     b'#!/usr/bin/env sh'
node   b'#!/usr/bin/env sh'
```

Um `.sh` com CR no shebang falha em qualquer sistema POSIX com `bad interpreter: bash^M`. Quem rodasse `init` pelo CLI Python no Windows e commitasse entregaria hooks de guard quebrados para todo mundo que desse checkout em Linux, macOS ou WSL.

## A correção

`newline="\n"` explícito em toda escrita de texto — **68 sites em 15 arquivos**, cobrindo `open(w|a)` e `write_text`. Aplicado com parser de parênteses balanceados, não regex, porque há chamadas multilinha. Modo binário intocado.

Medido **por efeito**, não por contagem de call site — rodando `init` e os quatro `new` num diretório limpo e varrendo os bytes de tudo:

```
antes    py  CRLF=23 arquivos  LF=0
depois   py  CRLF=0            LF=23
```

**Efeito no `check-artifact-parity.sh`: 8 drifts `go vs python` → 0.** Era tudo isso.

## Regressão

Medida por **lista nomeada**, não por contagem, com as duas corridas na mesma árvore de trabalho — revertendo os 15 arquivos ao `HEAD` e restaurando depois:

```
antes    200 failed / 1292 passed
depois   199 failed / 1293 passed

novas falhas:     nenhuma
falha que sumiu:  test_stale_wip_warning_arquivo_antigo
```

O teste que oscila é o de skew de relógio já caracterizado — `time.time()` no teste contra `datetime.now().timestamp()` na produção. Explica as três contagens diferentes (198, 199, 200) para o mesmo código.

Uma primeira tentativa comparou contra uma cópia isolada do `pypi/` em tempdir e deu 205 falhas — 6 a mais, todas por a cópia estar fora do repo. Baseline contaminada, descartada.

## Uma ML abandonada porque eu estava errado

O roadmap tinha um **ML-1B** para alinhar o shebang. Medi os cinco scripts e só o `trackfw-validate.sh` diverge — e essa divergência é **deliberada e arquitetada**: decisão de arquiteto de 2026-08-27, documentada em `docs/cli-parity.md` sob "validate.sh — pertencimento a conjunto", com um check de set-membership construído no `scaffold_doctor` dos três runtimes só para acomodá-la.

Eu tinha medido a divergência sem ter lido a decisão. ML abandonada, não adiada.

## Gate

`scripts/check-python-writes-lf.sh` — estático de propósito: a CI do upstream é Linux e nunca verá esse defeito, então todo arquivo novo que vier de lá chega sem `newline`. O gate pega no merge, que é onde a regressão vai nascer.

Não-vacuidade verificada: com um site regredido, ele acusa `pypi/trackfw/generators/note.py:65` e sai 1.

> A primeira tentativa desse teste passou verde e era **vacuosa** — o escape do heredoc virou quebra de linha real e a injeção nunca aconteceu. Só peguei porque conferi se o padrão tinha sido encontrado antes de olhar o resultado.

## Passivo aberto

O `check-artifact-parity.sh` ainda sai 1, agora por outro motivo: o `validate` do **Node** devolve não-zero citando a home **real** do usuário, apesar do gate exportar `HOME` para um tempdir. É o mesmo problema de isolamento de home que a migração corrigiu no Go com `internal/homedir`, não corrigido em Node nem em Python.

Com isso o **ML-2A do roadmap do slug segue bloqueado** — agora por esta parede, não mais pelo CRLF. Precisa de REQ própria.

---

Refs: `REQ-2026-08-29-geradores-python-escrevem-crlf-no-windows`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #24 — fix(homedir): Node e Python passam a honrar $HOME, como o Go
`MERGED` · branch `fix/node-e-python-ignoram-home-no-windows` · merge `b4df197`

`os.homedir()` no Node e `os.path.expanduser` no Python leem `%USERPROFILE%` no Windows e **ignoram `$HOME`**. O Go já tinha sido corrigido na migração para a 7.3.0 com `internal/homedir.Dir()`; estes dois ficaram para trás.

```
node   os.homedir()      com HOME=/c/tmp/fake  ->  C:/Users/louri
py     expanduser("~")   com HOME=/c/tmp/fake  ->  C:/Users/louri
```

Consequência: **nenhum teste conseguia isolar a home**. Foi assim que rodadas de teste nesta máquina criaram ADRs dentro de `~/.trackfw`, instalaram scripts de guard e tocaram os seis arquivos de config global de agente.

## A correção

`npm/src/homedir.js` e `pypi/trackfw/homedir.py` espelham o helper do Go. No Python são **duas famílias**, como o ML-0A exigia:

- `home_dir()` — "me dê a home"
- `expand_path(p)` — "expanda o `~` deste caminho", porque `adr_dirs: ~/algo` no `trackfw.yaml` também resolvia pelo `USERPROFILE`

25 sites em 13 arquivos no Node, 28 em 11 no Python. Verificado **por efeito**: `HOME=<tempdir> adr new --scope global` escreve no tempdir nos três runtimes, com a mesma mensagem e o mesmo caminho.

## Três bugs meus, encontrados e corrigidos

Todos da mesma família — substituição mecânica sem olhar escopo:

| Onde | O quê |
|---|---|
| `integrations/manager.py:33` | o `home_dir` importado colidia com o **parâmetro** `home_dir` do `__init__`; com o parâmetro `None`, virava `None()` |
| `integrations/doctor.py:165` | a mesma colisão em `run_doctor` |
| `config.py:283` | a troca atingiu uma **docstring** que descrevia a origem do valor |

Os dois primeiros eram `TypeError` em runtime, não erro de sintaxe — `ast.parse` não pegaria. Só a suíte pegou. Derrubaram as falhas novas de 12 para 2.

## Regressão

**Python — completo.** Duas corridas na mesma árvore, revertendo os 24 arquivos e restaurando:

```
antes    194 failed / 1298 passed
depois   105 failed / 1387 passed
resolvidas: 91      novas: 2
```

As 2 novas **não são regressão**:

1. `test_claude_tolerates_double_slash_in_stored_command` — o teste setava `HOME` e era ignorado; a produção lia a home real, **que tem o hook do guard instalado**. O dedup achava a entrada global na home errada e pulava a injeção, então o `assertFalse` passava. Com isolamento de verdade ele expõe o defeito que o próprio nome descreve — e o **Go falha o teste equivalente**, com a mesma mensagem, já tendo o fix de `homedir`. Defeito de produto, estava mascarado.
2. `test_init_scaffolds_project` — `UnicodeDecodeError` em cp1252, consequência do `isatty` no passivo abaixo.

**Node — incompleto, e digo isso.** Nenhuma das duas corridas npm terminou nesta máquina: a com o fix cobriu 36 dos 70 arquivos, a linha de base parou antes, nas duas tentativas. **Não há total de npm defensável.** No escopo dos 318 testes que as duas executaram: **0 falhas novas, 12 resolvidas** — entre elas `adr new --scope global writes into $HOME/.trackfw/adr` e `agents install sem TTY grava em ~/.claude`, exatamente a família que o fix ataca.

> Tentei isolar o travamento rodando `generators.test.js` sozinho e concluí cedo demais que ele travava só antes do fix. Repetindo com `stdin=/dev/null`, para igualar a condição da suíte, ele trava **nos dois** estados. A conclusão anterior estava errada e não entra como evidência.

## Gate

`scripts/check-homedir-parity.sh`, duas metades — por efeito e estática. Cobre os **três** runtimes, não só os dois corrigidos: o ML-0A apontou o Go regredir como a direção menos vigiada, porque "já está certo".

Não-vacuidade verificada nas duas metades. Com um site do Node restaurado, a metade de efeito mostra ele listando a home **real**.

> A primeira versão do gate reprovava os três **com o comportamento correto**: comparava o caminho inteiro, e o `mktemp` do Git Bash devolve `/tmp/tmp.XXXX` enquanto os runtimes reportam `C:/Users/.../Temp/tmp.XXXX`.

## Passivo — o sétimo bloqueio de Windows

O `check-artifact-parity.sh` ainda não passa, agora por um defeito que o isolamento revelou: o `init` do Python entra no wizard de identidade mesmo com stdin não interativo.

```
sys.stdin.isatty()   com </dev/null  ->  True       (Python)
process.stdin.isTTY  com </dev/null  ->  undefined  (Node)
```

`NUL` no Windows é character device, e o Windows reporta character device como TTY. O Go usa `GetConsoleMode` de verdade, o Node usa o tipo de handle do libuv. O `init.py:117` **tem** a guarda `sys.stdin.isatty()` — ela só não funciona nesta plataforma. Estava mascarado enquanto o Python lia a home real, que já tem identidade configurada.

O **ML-2A do roadmap do slug segue bloqueado**, pela terceira parede diferente: primeiro o CRLF, depois a home, agora o `isatty`.

---

Refs: `REQ-2026-08-29-node-e-python-ignoram-home-no-windows`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #25 — fix(tty): detecção de terminal confiável no Python — e o gate de artefato passa
`MERGED` · branch `fix/isatty-do-python-devolve-true-para-nul-no-windows` · merge `33a083c`

`sys.stdin.isatty()` devolve `True` para `NUL` no Windows — character device conta como TTY. O `init` do Python entrava no wizard de identidade em contexto não interativo e morria com `EOF when reading a line`. A guarda existia em `init.py:117`; ela só não funcionava nesta plataforma.

```
                     stdin de /dev/null
python  sys.stdin.isatty()      True
node    process.stdin.isTTY     undefined
```

## A correção

`pypi/trackfw/tty.py` usa `isatty()` como base e, **só no Windows**, estreita com `GetConsoleMode` via `msvcrt.get_osfhandle`. É o **mesmo syscall** que o `charmbracelet/x/term` do Go usa:

```go
func isTerminal(fd uintptr) bool {
	var st uint32
	err := windows.GetConsoleMode(windows.Handle(fd), &st)
	return err == nil
}
```

Casa com o Go **por construção**, não por heurística paralela. POSIX inalterado.

8 sites em 4 arquivos — incluindo o `sys.stdout.isatty()` de `validate.py:24`, que emitiria cor ANSI para dentro de arquivo redirecionado. Essa é a família que some numa varredura que só pensa em wizard.

## O risco previsto, materializado

Dois testes de `test_scope_resolution.py` fingiam TTY com `monkeypatch.setattr("sys.stdin.isatty", lambda: True)` e passaram a falhar.

Foi **exatamente o over-correct que o ML-0A registrou como o modo de falha perigoso** — previsto como silencioso, apareceu como teste vermelho, que é o desfecho bom. E a causa não era o helper: fingir `isatty` sobre um fd que não é console não basta mais; num console real o `GetConsoleMode` teria sucesso. Os dois testes passaram a injetar `stdin_is_interactive`, que é o seam correto.

## ML-1B — um defeito distinto, corrigido aqui por proporcionalidade

Depois do `isatty` o gate avançou e parou noutro ponto:

```
go    zeus/ROADMAP-cycle-analyzing.md   backlog → analyzing
node  zeus/ROADMAP-cycle-analyzing.md   backlog → analyzing
py    zeus\ROADMAP-cycle-analyzing.md   backlog → analyzing
```

`roadmap.py:609` usava `os.path.join(agent, basename)`. O nome no `.trackfw-log` é artefato portável, não caminho de sistema. É **uma linha** — mandar para REQ própria seria cerimônia. O CRLF, com 38 sites e alcance sobre todo arquivo gravado, foi para REQ própria com razão; a regra aplicada é proporcionalidade e está escrita no roadmap para não virar precedente solto.

## `check-artifact-parity.sh` passa pela primeira vez

```
Artifact parity checks passed (8 artifact types × 3 runtimes; roadmap flags,
quoted status, analyzing cycle flat/by_agent; CLAUDE.md ## Architect responses)
rc=0
```

Ele estava bloqueado por **quatro** coisas em sequência, cada uma escondendo a próxima: o CRLF dos geradores Python, o isolamento de home em Node e Python, o `isatty`, e o separador do log.

Com ele verde, o **ML-2A do roadmap do slug está desbloqueado** — era o propósito da cadeia inteira.

## Gate

`scripts/check-tty-detection.sh`, duas metades. Por efeito, `init` com `stdin=/dev/null` **e home isolada** conclui nos três — a home isolada importa, porque com identidade já configurada o wizard nem seria alcançado e o gate passaria sem exercitar nada.

Não-vacuidade verificada:

```
tty detection: `python init` saiu 1 com stdin nao interativo (esperado 0)
tty detection: python tem isatty() fora do helper:
  pypi/trackfw/commands/init.py:118:    if not skip_identity_wizard and sys.stdin.isatty():
rc=1
```

> A primeira versão do gate **falhava sem imprimir diagnóstico**: com `set -euo pipefail` o subshell abortava antes do `rc=$?`. Um gate que reprova sem dizer por quê é quase tão ruim quanto um que não reprova.

## Regressão

```
antes    105 failed / 1387 passed
depois    95 failed / 1397 passed
resolvidas: 11    novas: 1
```

A única "nova" é `test_stale_wip_warning_arquivo_antigo`, o instável de skew de relógio já caracterizado.

## Pendência declarada

**O caso positivo continua sem verificação nesta máquina** — não há console anexado, então não provo que um terminal de verdade continua promptando. A mitigação é o mesmo syscall do Go: o que um console real fizer para o Go, fará para o Python. Um teste manual num terminal real fecha o buraco e segue em aberto.

---

Refs: `REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #26 — fix(slug): fecha o roadmap do slug — adr.py, pom.xml e o gate que os guarda
`MERGED` · branch `fix/slug-de-artefato-no-python-diverge-de-go-e-node` · merge `2e50ebe`

Fecha o roadmap do slug de artefato: os três MLs de implementação e a wave do gate.

## ML-1B — `adr.py` colapsa em vez de deletar

`pypi/trackfw/generators/adr.py:slugify` **implementava a regra do slug de identidade de agente onde vai a de artefato** — deletava os não-alfanuméricos, enquanto Go, Node e os outros três geradores do próprio Python colapsam em hífen. Não era erro aleatório: são dois contratos separados de propósito e eles coincidem no caso comum, que é a armadilha.

```
adr new       antes  go acao-c-c-cafe  node acao-c-c-cafe  py acao-cc-cafe
              agora  go acao-c-c-cafe  node acao-c-c-cafe  py acao-c-c-cafe
```

`req`, `roadmap` e `note` já concordavam — o enunciado original da REQ, que dizia "vale para adr, req e roadmap", estava errado e foi corrigido no ML-0A.

## ML-1C — `pom.xml` do Node perdia a letra acentuada

A expressão inline em `generatePomXml` não fazia NFKD:

```
"Café App"     antes  node caf-app    go cafe-app
               agora  node cafe-app   go cafe-app
```

Passou a usar o `toSlug` compartilhado que `adr.js` já exporta — não uma quinta variante, como o ML-0A pedia. O `check-slug-inventory.sh` caiu de **10 para 9** implementações.

## ML-2A — a fixture do gate

`TITLE` passou de `"Autenticação e Sessão"` para `"Autenticação e Sessão C/C++ & OAuth+"`, com as **duas classes de caractere na mesma entrada**: acento pega quem não dobra NFKD, `/ + &` pega quem deleta em vez de colapsar. Com só acento — como era — o gate passava enquanto o `adr.py` divergia.

```
Artifact parity checks passed (8 artifact types × 3 runtimes; roadmap flags,
quoted status, analyzing cycle flat/by_agent; CLAUDE.md ## Architect responses)
rc=0
```

**Não-vacuidade**, com a divergência do `adr.py` reintroduzida sozinha:

```
artifact parity drift: adr (python) — arquivo ausente:
  docs/adr/ADR-2026-08-29-autenticacao-e-sessao-c-c-oauth.md
rc=1
```

Para a divergência do `pom.xml` o guarda é outro — o `check-slug-inventory.sh`, que reprova se alguém reintroduzir resolução própria em `init.js`. O `check-artifact-parity.sh` não cobre `pom.xml` porque a fixture dele não usa stack Java. **Limite declarado, não esquecido.**

## O que bloqueava este ML

Quatro paredes em sequência, cada uma escondendo a próxima, todas de Windows — e **nenhuma delas era sobre slug**:

1. **CRLF** nos geradores Python — 8 drifts `go vs python` ([#23](https://github.com/lourivalgarciajunior/trackfw/pull/23))
2. **Home** não isolada em Node e Python — `validate` lia a home real ([#24](https://github.com/lourivalgarciajunior/trackfw/pull/24))
3. **`isatty`** devolvendo `True` para `NUL` — `init` do Python travava no wizard ([#25](https://github.com/lourivalgarciajunior/trackfw/pull/25))
4. **Separador do log** — `zeus\ARQUIVO.md` contra `zeus/ARQUIVO.md` (ML-1B da #25)

O gate que existia para guardar o contrato de slug só pôde guardar alguma coisa depois que as quatro caíram.

## Gates

Os seis verdes:

```
check-slug-inventory      OK        check-tty-detection      OK
check-python-writes-lf    OK        check-artifact-parity    OK
check-homedir-parity      OK        check-subcommand-parity  OK
```

## Limite de verificação

`tests/generators.test.js` do npm estoura o tempo limite nesta máquina — **nos dois estados**, com e sem esta mudança, então não é sinal sobre ela. `tests/init.test.js`, que cobre o arquivo alterado, passa.

---

Refs: `REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #27 — docs(governanca): registra o fechamento da cadeia de defeitos de Windows
`MERGED` · branch `docs/fechamento-da-cadeia-windows` · merge `9c1e92d`

Handoff da sessão. Só `docs/agents-working-context.md`.

## O que registra

Oito defeitos de Windows encontrados a partir da migração para a 7.3.0 — e **quatro deles bloqueavam em fila o mesmo gate**, o `check-artifact-parity.sh`, que existe para guardar o contrato de slug. Nenhum dos quatro era sobre slug. Cada correção revelava o próximo.

| # | Onde | Estado |
|---|---|---|
| 1 | `cli.py` em cp1252 | corrigido (#19) |
| 2 | `os.UserHomeDir` no Go | corrigido (#19) |
| 3 | `Mode()&0111` no validator | **em aberto** |
| 4 | `check-parity-contract-coverage.sh` | registrado |
| 5 | CRLF nos geradores Python | corrigido (#23) |
| 6 | home em Node e Python | corrigido (#24) |
| 7 | `isatty` para `NUL` | corrigido (#25) |
| 8 | separador no `.trackfw-log` | corrigido (#25) |

Tudo consolidado em [kgsaran/trackfw#216](https://github.com/kgsaran/trackfw/issues/216), com referências verificadas contra a tag `v7.3.0`.

## As três pendências, escritas em vez de esquecidas

- **O #3 não tem saída deste lado.** É a origem das 6 violações que `trackfw validate` reporta hoje. Aguarda o upstream.
- **O caso positivo do `isatty` não foi verificado.** Esta máquina não tem console anexado, então não há prova de que um terminal de verdade continua promptando. A mitigação é usar o mesmo `GetConsoleMode` do Go; um teste manual em terminal real fecha o buraco.
- **A suíte npm não completa nesta máquina**, em nenhum estado. Não há total de npm defensável.

## As duas lições

**Teste pode passar pelo motivo errado.** O `TestGBGDedup_...ToleratesDoubleSlash` passava porque a produção lia a home real, que já tinha o hook instalado pelas próprias rodadas de teste. A fixture do gate de artefato era só acento, e por isso nunca pegou a divergência de slug do `adr.py`.

**Medir por lista nomeada, nunca por contagem.** A suíte pypi tem um teste instável de skew de relógio: três corridas do mesmo código deram 198, 199 e 200. Sem a lista nomeada eu teria reportado regressão onde não havia — e teria perdido as três colisões de escopo que eu mesmo introduzi no fix de `homedir`, que eram `TypeError` em runtime e passavam pelo `ast.parse`.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #28 — chore(upstream): merge da upstream main com o fix de symlink
`MERGED` · branch `chore/atualizar-para-a-upstream-main-com-o-fix-de-symlink` · merge `bede8b1`

Primeiro `git merge upstream/main` real depois da ancestralidade estabelecida na [#19](https://github.com/lourivalgarciajunior/trackfw/pull/19). Dois commits depois da `v7.3.0`, sem tag nova.

## Por que agora

Correção de **escrita arbitrária por symlink**, classificada HIGH pelo revisor do upstream e reproduzida nos três CLIs. Da nota deles:

> As checagens de presença e as escritas seguem symlink por padrão, sem nenhuma guarda de `lstat` em `update.go`, `update.js`, `update.py`, nem nos irmãos `discover.*`.

Symlink vivo em `.github/workflows/trackfw-validate.yml` apontando para fora do projeto, mais um `trackfw update` — **mesmo com `ci: none`** — sobrescreve o alvo. Symlink pendurado mais `discover --init` **cria** arquivo no caminho escolhido, fora do projeto.

Importa aqui concretamente: este repo faz dogfooding e roda `update` e `discover`. Vem junto o pin de versão do gate de CI e o `install.sh` honrando `TRACKFW_VERSION`.

## O que este merge provou

Era o primeiro teste real dos quatro gates locais — os que existem porque a CI do upstream é Linux e nunca verá esses defeitos.

**O `check-python-writes-lf` pegou quatro escritas que o merge derrubou:**

| O que caiu | Qual gate pegou |
|---|---|
| `pypi/trackfw/commands/discover.py:491` | `check-python-writes-lf` |
| `pypi/trackfw/commands/update.py:230` | `check-python-writes-lf` |
| `pypi/trackfw/generators/init_gen.py:631` | `check-python-writes-lf` |
| `pypi/trackfw/generators/init_gen.py:636` | `check-python-writes-lf` |

**Nenhuma das quatro gerou conflito.** O upstream reescreveu as funções e o `newline="\n"` sumiu em silêncio — exatamente o cenário que o ML-0A marcou como "o achado mais importante possível aqui, e o mais fácil de não notar".

Os outros cinco gates passaram de primeira. **Nenhum buraco de cobertura**: cada perda teve gate que a acusou, que era a pergunta central do threat model.

## Resolução dos conflitos

| O que | Resolução |
|---|---|
| 3 REQs + 1 roadmap do upstream aterrissando na nossa governança | **removidos** — a detecção de rename casou os `docs/req/` deles contra nomes parecidos nossos; governança do upstream fica fora, pela ADR |
| `vault/notes/index.md` | mantido removido, mesma política |
| `docs/roadmaps/.trackfw-log` | 23 transições nossas mantidas, 206 do upstream descartadas |
| `pypi/trackfw/commands/discover.py` | versão do upstream (com a guarda) **mais** o `newline` local reaplicado |

O conflito do `discover.py` foi didático: ele reescreveu `_write_ci_workflow` inteira para adicionar a guarda, e a versão dele fecha com `open(dest, "w", encoding="utf-8")` — sem o `newline`. Tomar a dele e reaplicar o nosso é a política da ADR posta em prática.

## Regressão: zero

```
antes    95 failed / 1397 passed
depois  100 failed / 1430 passed
novas: 5    resolvidas: 0
```

As 5 novas são **todas do arquivo de teste que o próprio upstream trouxe** para o fix, `test_update_discover_symlink_guard.py`. Morrem em `os.symlink`:

```
OSError: [WinError 1314] O cliente nao tem o privilegio necessario
```

Windows exige Developer Mode ou admin para criar symlink. Não é regressão — e a suíte cresceu de 1397 para 1430 passes.

## Um critério que NÃO foi cumprido

> "A vulnerabilidade de symlink verificada como corrigida em execução real, nos três runtimes"

**Não foi**, e o checkbox no roadmap está desmarcado, não maquiado.

Meu primeiro teste saiu **vacuoso**: o `ln -s` do Git Bash criou uma cópia, não um symlink — o `ls` mostrou arquivo regular de 44 bytes. Tentei com `MSYS=winsymlinks:nativestrict` e recebi `Operation not permitted`, o mesmo `WinError 1314`.

O que verifiquei é mais fraco, e digo qual é: a guarda **está presente** nos três runtimes, nos dois comandos.

```
go      update.go: 7   discover.go: 2
node    update.js: 6   discover.js: 5
python  update.py: 4   discover.py: 2
```

Presença de guarda não é prova de comportamento. **A verificação por efeito fica pendente e precisa de uma máquina com Developer Mode ligado** — vale para este repo e para qualquer um que rode a suíte do trackfw em Windows sem esse privilégio.

---

Refs: `REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink` · `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #29 — chore(upstream): remove as notas de vault que voltaram no merge
`MERGED` · branch `chore/remove-vault-que-voltou-no-merge` · merge `9393106`

Duas notas de conhecimento do upstream entraram como arquivo novo na [#28](https://github.com/lourivalgarciajunior/trackfw/pull/28):

```
vault/notes/barrier-so-casa-cabecalho-de-aceite-em-portugues-2026-08-28.md
vault/notes/update-segue-symlink-e-escreve-fora-do-projeto-2026-08-28.md
```

Saem pela mesma política da ADR que já tinha deixado as outras 85 de fora — conteúdo do upstream não é importado neste repo.

## O padrão que isso revela

**Não houve conflito para avisar.** O `vault/` tinha sido removido na #19, e caminho novo não colide com diretório ausente — o git simplesmente adiciona.

É a mesma classe do que o `check-python-writes-lf` pegou na #28: o merge derruba ou traz coisa **sem gerar conflito**, e a política só vale se algo a verificar. A diferença é que ali havia gate, e aqui não.

A política "governança e conteúdo do upstream ficam fora" **não é auto-aplicável**. Um gate para ela — nenhum arquivo versionado fora dos diretórios que este repo declara como seus — seria o próximo passo natural, e pegaria isso no próximo `git merge upstream/<tag>` em vez de depender de alguém reparar.

Não abri REQ para o gate ainda; fica como sugestão registrada aqui.

## Verificação

`go build ./...` verde, `check-artifact-parity.sh` rc=0. Nenhum teste lê o vault real — verificado na #19, quando as 85 primeiras saíram.

---

Refs: `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #30 — docs(governanca): fecha o roadmap do merge upstream
`MERGED` · branch `docs/fecha-roadmap-do-merge-upstream` · merge `7cd5fb0`

Move o roadmap do merge para `done/`. Todos os MLs concluídos.

**O critério de verificação por efeito do symlink fica com o checkbox desmarcado, de propósito.** Não foi cumprido — symlink nativo exige Developer Mode nesta máquina — e a razão está escrita no ML-2A.

Roadmap em `done` não significa todo critério verde. Significa que o trabalho acabou e que o que ficou de fora está declarado, com o motivo, em vez de sumir num checkbox marcado por conveniência.

---

Refs: `REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #31 — chore(upstream): remove a ADR do upstream que entrou no merge
`MERGED` · branch `chore/remove-adr-do-upstream-que-entrou-no-merge` · merge `2f1586f`

A `ADR-2026-08-28-gate-de-ci-gerado-nasce-pinado-na-versao-que-o-gerou...` é do upstream. Verificado por referência:

```
upstream/main  existe
v7.3.0         não existe
HEAD~5         não existe
```

Entrou na [#28](https://github.com/lourivalgarciajunior/trackfw/pull/28) pelo mesmo mecanismo das notas de vault: **caminho novo não colide com nada, então não há conflito para avisar.**

Naquele merge eu removi as 3 REQs e o roadmap do upstream e deixei a ADR passar. O resultado era uma ADR sem REQ que a referenciasse — e o `validate` acusava exatamente isso.

## Terceira vez do mesmo padrão

| PR | O que entrou sem conflito |
|---|---|
| #28 | `vault/notes/index.md` (peguei durante o merge) |
| #29 | 2 notas de `vault/` |
| esta | 1 ADR |

A política **"governança e conteúdo do upstream ficam fora" não é auto-aplicável.** O gate sugerido na #29 — nenhum arquivo versionado fora dos diretórios que este repo declara como seus — cobriria as três de uma vez, no próximo `git merge upstream/<tag>` em vez de depender de alguém reparar.

## Depois disso

`trackfw validate` reporta 15 violações e **todas são de bit de execução** — o bloqueio de Windows que aguarda o upstream na [issue #216](https://github.com/kgsaran/trackfw/issues/216). Nenhuma de governança.

> A contagem difere entre binários: o `bin/trackfw` do repo diz 9 e o CLI global diz 15, porque o `bin` é da `main` já mesclada, à frente da tag `v7.3.0` que o npm publica.

---

Refs: `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #32 — fix(governanca): gate para a política de conteúdo do upstream
`MERGED` · branch `fix/politica-de-conteudo-do-upstream-sem-gate` · merge `d5aa5e4`

A `ADR-2026-08-29-adotar-upstream-como-base` diz que produto vem do upstream e que a governança e o conteúdo dele **não são importados**. A política estava escrita e **não era auto-aplicável**.

Conteúdo do upstream entrou **três vezes nesta sessão**, sempre sem gerar conflito:

| PR | O que entrou | Como foi notado |
|---|---|---|
| [#28](https://github.com/lourivalgarciajunior/trackfw/pull/28) | `vault/notes/index.md` | por acaso, durante a resolução |
| [#29](https://github.com/lourivalgarciajunior/trackfw/pull/29) | 2 notas de `vault/` | reparei depois do merge |
| [#31](https://github.com/lourivalgarciajunior/trackfw/pull/31) | 1 ADR do upstream | o `validate` acusou ADR sem REQ |

O mecanismo é sempre o mesmo: **caminho novo não colide com nada.** Removemos o `vault/` na #19, então um arquivo novo em `vault/notes/` não gera conflito — o git só adiciona. Não há o que resolver, e a política só vale se alguém reparar.

A terceira só apareceu porque produziu efeito colateral visível. Não há razão para supor que a quarta produza.

## O desenho: proveniência, não lista de caminhos

Lista de caminhos proibidos envelhece a cada release do upstream. A interseção não:

> **Arquivo sob `docs/` ou `vault/` que exista também em `upstream/main` é conteúdo do upstream** — a menos que esteja declarado como mantido, **com o motivo**.

Hoje 10 coincidem, e os 10 são legítimos: docs de produto, schemas, o `VISION.md`, o handoff, e o `docs/seguranca/2026-08-15-...` que o `internal/thirdparty` lê num teste.

**Escopo é só `docs/` e `vault/`.** Em `internal/`, `npm/src/` e `pypi/trackfw/` coincidir com o upstream é o comportamento **desejado** — um gate que reclamasse disso estaria invertido. Está comentado no script.

## Falsificação — um a um, não em bloco

Cada vazamento histórico reintroduzido sozinho, testado, e removido antes do próximo:

```
#28  vault/notes/index.md    rc=1  acusa vault/notes/index.md
#29  nota de vault           rc=1  acusa update-segue-symlink-...-2026-08-28.md
#31  ADR do upstream         rc=1  acusa ADR-2026-08-28-gate-de-ci-...

sem upstream/main            rc=1  "não consigo checar — rode git fetch upstream"
estado atual                 rc=0  "nada indevido em docs/ nem em vault/"
```

**O quarto é o que separa este gate de teatro.** Verde por não conseguir checar seria pior que vermelho, porque pareceria cobertura — a lição que atravessou a sessão inteira.

## O que este gate NÃO resolve

A lista de mantidos pode virar depósito. Nada impede que a próxima reprovação no meio de um merge seja "resolvida" acrescentando uma linha ao `KEEP`. O motivo escrito por entrada torna isso visível a quem lê, **e nada mais que isso** — é por isso que o motivo é critério de aceite, não gosto pessoal.

Também não cobre conteúdo do upstream que chegue com **outro nome**: se alguém copiar uma nota do vault para `docs/notas/`, o caminho não coincide e o gate não vê. O sinal é proveniência por caminho, não por conteúdo.

## Gates

São **sete** agora, todos verdes:

```
check-slug-inventory      check-artifact-parity
check-python-writes-lf    check-subcommand-parity
check-homedir-parity      check-upstream-content   ← novo
check-tty-detection
```

---

Refs: `REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate` · `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #33 — docs(governanca): registra a segunda metade da sessão no contexto
`MERGED` · branch `docs/contexto-da-segunda-metade` · merge `313dd6d`

Handoff. Só `docs/agents-working-context.md`.

## O que registra

**Upstream em dia.** `git merge-base HEAD upstream/main` devolve `e0f8543` — o HEAD deles.

**O primeiro merge real provou os gates locais.** O `check-python-writes-lf` nomeou quatro escritas que o merge derrubou, e **nenhuma gerou conflito** — o upstream reescreveu as funções e o `newline` sumiu em silêncio. Os outros cinco passaram de primeira.

**Sétimo gate**, desenhado por proveniência em vez de lista de caminhos, porque conteúdo do upstream entrou três vezes sem conflito.

**A skill foi para 1.4.0**, e o repositório mudou de caminho — o que quebrou a publicação de um jeito silencioso: o marketplace apontava para pasta morta e o `plugin update` responderia sem erro.

## Duas correções ao que eu mesmo havia registrado

- **O `roadmap move` sincroniza** a referência da REQ. Eu tinha registrado o contrário: meu teste setava a linha do corpo, que o CLI ignora. Medi a coisa errada.
- **O baseline npm não foi corrompido por mim** — travou, no mesmo ponto exato das duas tentativas.

## Três achados novos na issue do upstream

O que mais importa: **os testes do próprio fix de symlink não rodam em Windows sem privilégio elevado** — 5 Python, 5 Node, 2 Go. O Windows não valida a correção de segurança do upstream.

Mais o `ref_targets_exist` vacuoso em `by_agent`, e o sync do `move` escrevendo separador do sistema.

## O fio da sessão

**Verde que não significa nada**, com roupas diferentes: teste que passa por ler a home real; fixture com só acento; regra que não roda num layout suportado; três testes meus de não-vacuidade que passaram vacuosos; `validate` limpo num CLI cinco majors atrasado; e um gate que passaria por não conseguir checar.

O `check-upstream-content.sh` é o único que trata isso explicitamente — reprova quando não consegue verificar.

## Pendências, escritas em vez de esquecidas

- As 15 violações de bit de execução, aguardando o upstream.
- Verificação por efeito do symlink — precisa de Developer Mode.
- O `KEEP` do gate novo pode virar depósito; o motivo escrito torna isso visível a quem lê, e nada mais.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #34 — chore(upstream): traz d4e286e, o dialeto canônico do barrier
`MERGED` · branch `chore/trazer-barrier-do-upstream` · merge `09cbae7`

Segundo `git merge upstream/main`. Um commit: `d4e286e` (`fix(barrier)` — dialeto canônico do roadmap, status por token, consciência de cerca). Sem tag ainda.

**Governança enxuta de propósito.** O primeiro merge levou threat model completo porque o processo era inédito e derrubou quatro fixes locais sem conflito. Agora os sete gates existem e dizem o que se perde. Cerimônia acompanha risco, não hábito.

## O gate novo se pagou na estreia

Resolvi tudo o que o git apontou — `vault/notes/index.md` em conflito, duas REQs e um roadmap do upstream — e **achei que estava limpo**.

O `check-upstream-content.sh` acusou **sete arquivos que eu não tinha visto**, todos entrados sem conflito:

```
docs/adr/ADR-2026-08-29-dialeto-canonico-...      ← ADR do upstream
vault/notes/ambiente-do-dev-e-mais-rico-...
vault/notes/barrier-crlf-divergencia-node-regex-...
vault/notes/barrier-fence-closing-trailing-content-...
vault/notes/barrier-trust-check-fail-open-em-tmpdir-...
vault/notes/gates-da-wave-sao-um-comando-por-linha-...
vault/notes/paridade-cross-runtime-dentro-do-go-test-...
```

Sem ele, seriam a quarta e a quinta vez que conteúdo do upstream entra sem ninguém ver.

## Regressão: zero

```
antes (pós 1º merge)  100 failed / 1445 passed
depois                105 failed / 1451 passed
novas: 5    resolvidas: 0
```

As **5 são testes que o próprio commit trouxe** — `git show e0f8543:pypi/tests/test_barrier.py` não tem nenhum deles. Falham pela parede de encoding do Windows: o commit introduziu `⬜` no vocabulário de status do barrier.

Contra a `upstream/main` **pura**, nos mesmos dois arquivos: **17 falhas lá, 7 aqui.**

## Duas medições minhas que estavam erradas

1. **Baseline errado** — comparei contra as 95 de antes do *primeiro* merge, misturando dois.
2. **Medição contaminada** — havia **13 `__pycache__`** apontando para `C:\Indieexpert\GitHub\`, o caminho de antes de o repositório mudar de pasta. Um teste falhava só por isso. O número 106 que reportei primeiro **não valia**; o que vale é 105, com bytecode limpo.

## Uma regressão que é minha

`test_wave_argumento_invalido_mensagem_pinada_literalmente` falha **só aqui**:

```
- ... "2-BIS" ? not a valid wave label     (nossa)
+ ... "2-BIS" — not a valid wave label     (esperado)
```

Consequência do `_force_utf8_output`: o CLI emite UTF-8 e o harness lê com o padrão da plataforma. **Antes, `--help` e `validate` morriam com `UnicodeEncodeError`; agora funcionam, e um teste que captura saída vê mojibake.** Troca de uma classe de falha por outra menor. A correção certa é o harness decodificar UTF-8 explicitamente — vai para a issue #216.

## Registrado sem investigar

O `check-artifact-parity` **oscila**: reprovou na primeira medição e passou nas duas seguintes, com a mesma árvore. Gate que oscila é gate em que não se confia. Não investiguei a causa.

## Verificação

`go build ./...` verde · sete gates verdes · meu fix do separador sobreviveu (`log_basename = agent + "/"`) · 7 ADRs, só as nossas · 25 transições nossas no log, 210 do upstream descartadas.

---

Refs: `REQ-2026-08-29-trazer-o-barrier-dialeto-canonico-do-upstream` · `ADR-2026-08-29-adotar-upstream-como-base`

🤖 Generated with [Claude Code](https://claude.com/claude-code)

---

## PR #35 — docs(governanca): registra o segundo merge do upstream no contexto
`MERGED` · branch `docs/contexto-do-segundo-merge` · merge `9b036eb`

Handoff. Só `docs/agents-working-context.md`.

## O que registra

**Em dia com o upstream** — `merge-base` = `d4e286e`.

**O gate viu o que eu não vi.** Resolvi tudo o que o git apontou e dei a resolução por encerrada; o `check-upstream-content.sh` acusou **sete arquivos** entrados sem conflito. Nas três vezes anteriores o vazamento foi notado por acaso, por releitura, ou por efeito colateral no `validate`. Nesta, o gate viu antes de mim.

**Regressão zero** — as 5 novas falhas são testes que o próprio commit trouxe. Contra a `upstream/main` pura: 17 falhas lá, 7 aqui.

## Três correções em medições minhas

1. **Baseline errado** — misturei dois merges.
2. **Bytecode obsoleto contaminou a suíte.** 13 `__pycache__` apontando para `C:\Indieexpert\GitHub\`, o caminho de antes de os repos mudarem de pasta. Um teste falhava só por isso. O número 106 que reportei **não valia**; vale 105.
   Ficou a regra prática: **depois de mover um repositório Python, limpe `__pycache__` antes de medir.**
3. **Uma regressão que é minha** — o `_force_utf8_output` troca `UnicodeEncodeError` por mojibake num teste que captura saída. Uma classe de falha por outra menor, escrita em vez de silenciada.

## Ordem permanente registrada

**Não forçar o bit de execução.** As 15 ficam vermelhas; a correção vem do upstream. E o `trackfw update harness`, que a própria mensagem de erro sugere, **não resolve** — medido: `updated=0 skipped=33`.

O patch está levantado e **segurado por decisão sua**: 6 sites, dois por runtime, com o precedente do `CurrentGOOS` a espelhar. Fica pronto para quando liberar.

## Registrado sem investigar

O `check-artifact-parity` **oscila** — reprovou uma vez e passou duas, mesma árvore.

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
