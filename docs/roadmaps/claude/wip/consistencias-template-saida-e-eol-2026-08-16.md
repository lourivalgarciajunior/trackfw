---
name: consistencias-template-saida-e-eol-2026-08-16
title: "Consistências de template, header, saída e EOL"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-consistencias-template-saida-e-eol
branch: fix/consistencias-6-a-9
---

# Roadmap: consistências de template, header, saída e EOL

> Criado em: 2026-08-16 | Status: 🔄 WIP

REQ: `docs/requisições/claude/REQ-2026-08-16-consistencias-template-saida-e-eol.md`

## Diagnóstico / Contexto

Quatro achados independentes registrados como dívida ao longo desta sessão, nenhum grande o
bastante para REQ própria. Diagnóstico de cada um está na REQ: template do `roadmap new` divergente
no Python, linha humana de status não sincronizada pelo `move`, caminhos de home hardcoded na saída
do instalador Go, e falta de `.gitattributes`.

Ordem de execução: D1 e D2 mexem no mesmo arquivo por runtime, então D1 primeiro para o template já
nascer no formato que D2 vai sincronizar.

## Critérios de Aceite

- [ ] `roadmap new` produz frontmatter e header idênticos nos três runtimes
- [ ] Após `move X done`, a linha `> … | Status:` declara `done` nos três runtimes
- [ ] Nenhum caminho de home hardcoded em `Printf` no Go
- [ ] `gofmt -l internal/ cmd/` devolve zero
- [ ] `go test ./...` verde, pypi na baseline, gates sem prefixo

---

## Wave 1 — Template e header (sequencial por dependência de formato)

### ML-1 — D1: alinhar o template do `roadmap new` no Python
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/generators/roadmap.py`, `pypi/tests/test_generators_roadmap.py`
**Ações:**
1. Em `_roadmap_template`, trocar `status: Backlog` por `status: backlog` e
   `> Criado em: {date} | Status: ⬜ Backlog` por `> Created: {date} | Status: backlog`.
2. Atualizar a asserção `assertIn("status: Backlog", content)` do teste existente.
**Critérios de aceite:**
- [x] `roadmap new` dos três runtimes gera `status: backlog` e
      `> Created: DATE | Status: backlog` — verificado com fixture nos três
- [x] Suíte pypi na baseline: 242 testes, failures=1 errors=6

**Achado de passagem:** o `roadmap new` do Go **exige** uma REQ existente (`Nenhuma REQ encontrada
em docs/req/`), enquanto npm e Python criam o roadmap sem REQ nenhuma. Divergência de contrato
entre runtimes, fora do escopo desta REQ. Candidato a REQ própria.
**Comandos de validação:** `cd pypi && python -m unittest discover -s tests -t .`

### ML-2 — D2: `move` sincroniza a linha humana nos três runtimes
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/roadmap.go` + teste; `npm/src/generators/roadmap.js` +
teste; `pypi/trackfw/generators/roadmap.py` + teste
**Ações:**
1. Helper `setHeaderStatus(content, state)` em cada runtime: acha a primeira linha que comece com
   `> ` **e** contenha `| Status: `, e substitui tudo após esse marcador pelo estado.
2. Encadear com o `setFrontmatterStatus` já existente no fluxo do `move`.
3. Contrato conservador, igual ao do frontmatter: nenhuma linha casando o padrão → conteúdo
   intocado; a linha nunca é criada.
4. Teste em cada runtime cobrindo: linha presente, linha ausente, e header com emoji
   (`Status: 🔄 WIP`), que é o formato herdado neste repositório.
**Critérios de aceite:**
- [x] Após `move X done`, a linha declara `done` nos três runtimes
- [x] Arquivo sem a linha sai byte a byte idêntico — a linha nunca é criada
- [x] Formato herdado com emoji (`| Status: 🔄 WIP`) é substituído por inteiro
- [x] Não-vacuosos nos três: sem o encadeamento, Go 2 falhas, npm 5 passed/2 failed,
      Python `FAILED (failures=2)`
**Comandos de validação:** `go test ./internal/generators/ -run Move && node npm/tests/roadmap_move.test.js && cd pypi && python -m unittest tests.test_roadmap_move`

---

## Wave 2 — Saída e repositório (independentes)

### ML-3 — D3: saída do instalador mostra o caminho real
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/generators/home.go`, `agents.go`, `gemini.go`, `scaffold.go`,
`windsurf.go`, `internal/generators/home_test.go`
**Ações:**
1. Em `home.go`, criar `displayPath(abs string) string`: devolve o caminho com o home resolvido
   substituído por `~`, ou o absoluto quando não estiver sob o home.
2. Trocar as 12 `Printf` com `~/…` hardcoded por `displayPath` do caminho que a função já calculou.
3. Teste do helper: caminho sob o home vira `~/…`; fora do home fica absoluto; home irresolúvel não
   quebra.
**Critérios de aceite:**
- [x] Nenhum literal `~/…` em `Printf` nem `Errorf` no pacote — 12 prints e 1 mensagem de erro
      passaram a derivar do caminho resolvido
- [x] Saída no uso normal continua exibindo `~/…`, idêntica à de antes
- [x] Helper coberto por teste: sob o home vira `~`, fora do home fica absoluto, home
      irresolúvel não quebra

**Precisão sobre o efeito.** Durante os testes a saída continua exibindo `~/…`, e isso está
correto: `displayPath` colapsa o home **resolvido**, que no teste é o tempdir. A garantia deixou de
ser cosmética e virou estrutural — a string deriva do caminho real em vez de ser literal. O caso em
que os dois divergem está coberto no teste unitário `fora do home fica absoluto`.
**Comandos de validação:** `go test ./internal/generators/`

### ML-4 — D4: `.gitattributes` e normalização do working copy
**Status:** ✅ Concluído
**Arquivos afetados:** `.gitattributes` (NOVO)
**Ações:**
1. Criar `.gitattributes` com `* text=auto` e `eol=lf` para as extensões de fonte
   (`*.go`, `*.js`, `*.py`, `*.sh`, `*.md`, `*.yaml`, `*.yml`, `*.json`).
2. Normalizar o working copy com `git add --renormalize .` e, se necessário,
   `git checkout-index -a -f` para reescrever os arquivos aplicando o novo filtro.
3. Conferir `gofmt -l internal/ cmd/` em zero.
**Critérios de aceite:**
- [x] `.gitattributes` presente, com `eol=lf` para fontes e `binary` para imagens
- [x] `gofmt -l internal/ cmd/` devolve **zero**
- [x] A renormalização não mudou conteúdo nenhum: `git add -A` deixou só o `.gitattributes`
      staged, e os hashes de working copy e index batem em todos os arquivos tocados

**Correção da minha leitura anterior.** Eu havia afirmado que os 22 arquivos acusados pelo `gofmt`
eram *todos* CRLF. Não eram. Depois de normalizar o EOL, sobraram **9** com desvio real de
formatação em código pré-existente — `:=` alinhados à mão em `config.go`, comentários de lista em
`sync/jira.go`, e afins. Só 59 linhas de diff no total, aplicadas com `gofmt -w`.

Ou seja: 13 arquivos eram CRLF puro, 9 estavam de fato desformatados e agora estão corrigidos.
**Comandos de validação:** `gofmt -l internal/ cmd/ && go build ./...`

---

## Wave 3 — Fechamento

### ML-5 — Suítes e gates
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `go test ./...` com zero falhas e `go vet ./...` limpo.
2. Suíte pypi contra a baseline de 6 errors + 1 failure, sem prefixo de ambiente.
3. Testes npm.
4. Os três gates de paridade, sem prefixo.
**Critérios de aceite:**
- [ ] Go verde, pypi na baseline, npm verde
- [ ] Gates passam sem prefixo
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh && bash scripts/check-validate-parity.sh`
