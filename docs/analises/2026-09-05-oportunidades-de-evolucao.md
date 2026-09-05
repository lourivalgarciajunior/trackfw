# trackfw — oportunidades de evolução

> Data: 2026-09-05 · Base: `a958b57` (nossa main) = `87aded6` (upstream) · v7.3.0 + 42 commits
> Autor: análise assistida (Claude), a partir de uma semana de medição contra o upstream.

## 1. O projeto hoje, em números

| | Go | Node | Python |
|---|---|---|---|
| fonte (linhas) | 31.519 | 24.998 | 26.016 |
| testes (linhas) | 39.648 | 23.355 | 27.698 |
| `validator` num único arquivo | 2.759 | 3.654 | 3.809 |
| testes com `skip` | **41** | 1 | 9 |

- **34** regras de `validate` · **50** gates em `scripts/check-*.sh` · **37** subcomandos · 3 locales.
- `docs/cli-parity.md`: **7.151 linhas**, com **65** gaps declarados.
- CI: 9 jobs. `parity` leva **780 s**, dos quais `check-gates-falsify.sh` responde por **610 s** (78%). Dois jobs de Windows rodam com `continue-on-error: true` — marcado como temporário (AC4).
- Windows: **32 testes Go vermelhos** nesta máquina, contra 51 há dois dias. A campanha do upstream: `246 → 217 → 162 → 134 → ?`.
- Último release: `v7.3.0` em 2026-08-28. **42 commits** desde então sem tag, boa parte correção de segurança.

## 2. Diagnóstico: as cinco classes de defeito que esta semana revelou

Todas medidas, nenhuma inferida. Servem de base para as oportunidades da seção 3.

### 2.1 Vacuidade — o sinal que nunca acendeu não é verde

- `✓ No violations found` num fork onde `validate` avaliava **7 de 53** REQs (layout `by_agent`).
- A mensagem exigida pelo roadmap de supressão nomeada tinha **0 ocorrências** sem `go test -v` — a exigência existia e ninguém podia lê-la.
- `pass 0 / fail 1` no `node --test` lê-se como um teste reprovando; é o **arquivo inteiro falhando ao carregar**.
- Três suítes unitárias concordando com um fixture desatualizado, verdes.

### 2.2 Semântica de plataforma escondida em predicado de conveniência

| predicado | POSIX | Windows | consequência |
|---|---|---|---|
| `filepath.IsAbs("/opt/x")` | true | **false** | guard de segurança pulado (#271) |
| `os.IsNotExist(ENOTDIR)` | false | **true** | diagnóstico engolido em 4 sítios (#269) |
| `subprocess.run(["bash", …])` | bash real | **stub do WSL** ou `FileNotFoundError` | ~50 testes sem executar o guard (#267) |
| `os.Stat(...).Mode() & 0111` | bit real | **sempre 0** em NTFS | bit de execução falsamente vermelho |

Nos quatro casos, o nome do predicado prometia uma pergunta e o sistema operacional respondia outra.

### 2.3 Paridade aparente

- O controle POSIX da #271 existe nos três runtimes; **só o Go reprova** no Windows, porque `path.isAbsolute` e `ntpath.isabs` já tratam `/x` como absoluto e `filepath.IsAbs` não. Três testes iguais, três premissas diferentes.
- O bucket `Other` do `status`: Python tinha, Go e Node não (#263). O contador de REQ do `status`: Go e Node usam o resolvedor, Python enumera flat (#268).

### 2.4 Gerador e verificador que discordam

Cabeçalho de aceite em pt vs en; vocabulário de status de ML com **três formas** coexistindo (`⬜ Pendente` / `✅ Concluído` / `done`) mais 12 variantes de sufixo livre; layout de REQ; palavra-chave de fechamento em português que nenhuma issue reconhecia.

### 2.5 Acoplamento entre o gate do produto e a governança de quem o consome

- `check-roadmap-barrier-contract.sh` congela um corpus dos roadmaps do **próprio repositório** — falha em qualquer fork que não os tenha.
- `sync` chumba `docs/req` nos três runtimes e ignora `req_dir` — num fork com `docs/requisições`, sincroniza **0** REQs reais e abriria issue para resíduo de merge.
- `branch_has_wip_roadmap` casa por `strings.Contains` (`validator.go:2571`) num `wip/` que só cresce — o próprio mantenedor mediu 11 de 13 roadmaps parados lá.

## 3. Oportunidades

Ordenadas por **impacto sobre a confiabilidade do sinal** dividido pelo custo. Cada uma traz evidência, proposta e como falsificar.

### A. Confiabilidade do sinal (a mais barata e a mais rentável)

**A1 — `validate --coverage`: quantos artefatos cada regra avaliou.**
Evidência: 2.1. Hoje nenhuma regra expõe o denominador; `grep` por `evaluated|coverage` no `validator.go` dá zero.
Proposta: cada regra devolve `{violations, evaluated}`; a saída textual ganha uma linha por regra com `n avaliados`, e `--json` expõe o campo. Regra com `evaluated: 0` num repositório que tem artefatos daquele tipo vira **aviso**.
Falsificação: fixture `by_agent` com 4 REQs; antes `evaluated` inexiste, depois toda regra de REQ reporta 4. Controle: fixture vazio reporta 0 e o aviso dispara.
Custo: médio (toca as 34 regras nos 3 runtimes, mas é mecânico).

**A2 — Distinguir "arquivo de teste não carregou" de "teste reprovou" no CI.**
Evidência: `pass 0 / fail 1` no Node; a falha atual do `validator.test.js` com `YAML malformado` é de nível de arquivo e aparece igual antes e depois de qualquer merge.
Proposta: no `quality.yml`, após cada suíte, um passo que falha se `pass == 0 && fail >= 1` com mensagem própria ("suíte não carregou"). Mesmo tratamento para `pytest` com `errors` e para pacotes Go com `[build failed]`.
Falsificação: introduzir `require('inexistente')` num teste; o CI tem de dizer "não carregou", não "1 falhou".
Custo: baixo.

**A3 — Ratchet de vermelhos no Windows em vez de `continue-on-error`.**
Evidência: os dois jobs de Windows não bloqueiam nada hoje; 32 vermelhos aqui, e o mantenedor não tem Windows local.
Proposta: gravar a lista de testes vermelhos conhecidos (por nome) em `scripts/testdata/windows-known-red.txt`; o job falha se aparecer **nome novo** e avisa quando algum sai da lista (para ser removido). É o que fiz manualmente três vezes esta semana comparando `comm -13`.
Falsificação: o `TestPathIsAnchoredForHookConfig_ControlePOSIX` da #271 teria sido bloqueado no PR, não descoberto num fork.
Custo: baixo. Remove a única razão para `continue-on-error`.

### B. Semântica de plataforma

**B1 — Tabela de contrato de predicados de plataforma, executada nos 3 runtimes × 3 SOs.**
Evidência: 2.2 — quatro predicados, quatro correções separadas, cada uma descoberta por acidente.
Proposta: um único `scripts/testdata/platform-predicates.tsv` (`caso · esperado · runtime · so`) consumido por um teste em cada runtime. Entram: ancoragem de caminho, classificação de erro de diretório (`ENOENT` vs `ENOTDIR`), resolução de `bash`, bit de execução, separador na emissão.
Falsificação: rodar a tabela contra `filepath.IsAbs`/`os.IsNotExist` tem de reprovar; contra os predicados novos, passar — nos três SOs do CI.
Custo: médio. Fecha a classe, não o caso.

**B2 — Lint que proíbe predicado dependente de SO em sítio de classificação.**
Evidência: a ADR da #271 já exige "zero chamada dependente de SO, verificável por grep" para o predicado — mas o **controle** que o valida chama `filepath.IsAbs` e reprova no Windows.
Proposta: gate `check-os-predicates-in-classifiers.sh` com lista dos sítios de classificação (config de hook, mensagens, chaves) e a lista negra (`filepath.IsAbs`, `os.IsNotExist`, `os.path.isabs`, `path.isAbsolute`, `process.platform`, `os.name`). Sítios de **travessia** de sistema de arquivos ficam fora, por decisão da mesma ADR.
Custo: baixo.

**B3 — Trocar `os.IsNotExist` por `errors.Is(err, syscall.ENOENT)` nos 4 sítios de leitura de diretório.**
Evidência: #269, medido: `L67 listDirForRule` (4 regras), `L1700`, `L2504`, `L2522`; dois testes do próprio repositório (`*_DiretorioNaoLegivel_P2`) já reprovam por isso no Windows.
Já reportado ao upstream; entra aqui como item de acompanhamento.

### C. Ponto único de leitura (D4 da ADR-2026-09-03)

**C1 — Gate que acusa enumeração de `req_dir`/`roadmap_dir` fora do resolvedor.**
Evidência: AC3 da `REQ-2026-08-30` pede a varredura; `status.py:57` e os três `sync` são os sítios conhecidos.
Proposta: `check-single-read-point.sh` — grep por `listdir|readdirSync|Glob|ReadDir` seguido de `req_dir|roadmap_dir|docs/req` fora dos arquivos do resolvedor. Lista de exceções explícita com motivo.
Custo: baixo, e converte a AC3 de tarefa manual em invariante.

**C2 — `sync` passa a usar o resolvedor, honrar `req_dir` e ganhar `--dry-run`.**
Evidência: 2.5 — hoje é o único comando que **escreve em serviço externo** e o faz sobre a lista errada. Não pude medi-lo por execução justamente por não ter `--dry-run`.
Falsificação: `--dry-run` num fork com `req_dir: docs/requisições` lista 53, não 0.
Custo: baixo por runtime.

### D. CI e tempo de parede

**D1 — Cache por gate no `check-gates-falsify.sh`, chaveado pelo hash do script + do binário.**
Evidência: 610 s de 780 s; o mantenedor mediu e descartou `make -j` (paraleliza targets, não linhas) e sharding (~19%, e renomearia o check obrigatório).
Proposta: não paralelizar — **pular** o que não mudou. Cada gate grava `sha256(script ∥ trackfw-bin ∥ fixtures)` → veredito em `~/.cache/trackfw-gates/`; o CI restaura o cache por chave de commit-base. Um PR que toca 2 gates reexecuta 2, não 46.
Falsificação: PR que muda só docs tem de rodar `parity` em < 60 s; PR que muda `validator.go` tem de reexecutar todos os gates que o exercitam (o binário mudou).
Custo: médio. É a única alavanca que sobra depois das que ele mediu.

**D2 — Um Windows local reproduzível para o mantenedor.**
Evidência: cinco PRs esta semana terminaram com "só o CI de Windows fecha"; eu fechei três delas em minutos porque tenho a plataforma.
Proposta: documentar (e testar) o caminho `scripts/windows-repro/run.ps1` num VM/`act` ou num runner self-hosted; ou, mais barato, um `Makefile` target `windows-probe` que roda a sonda via `gh workflow run` e traz o artefato.
Custo: baixo a médio; alto retorno de ciclo.

### E. Experiência de fork/consumidor

**E1 — `trackfw upstream sync`: merge com retenção de governança.**
Evidência: cada merge do upstream me custa `git rm -r docs vault && git checkout main -- docs` e 23 conflitos de renomeação por causa do `by_agent`. Escrevi o procedimento na memória porque vai se repetir.
Proposta: `.gitattributes` com `docs/** merge=ours` e `vault/** merge=ours` no template do consumidor, ou um subcomando que faz o merge e o restore num movimento e reporta "N arquivos de produto, M de governança retidos".
Custo: baixo.

**E2 — Desacoplar o corpus do `barrier-contract` da governança do repositório.**
Evidência: achado 16 do #216 — 108 basenames ausentes em qualquer fork.
Proposta: o corpus congelado passa a viver em `scripts/testdata/` **como fixtures próprias**, não como espelho de `docs/roadmaps/`. O gate testa o parser contra as fixtures; um segundo gate (só no upstream) confere que `docs/roadmaps` ainda parseia.
Custo: baixo; já parcialmente atacado na #257.

### F. Governança: vocabulário e higiene

**F1 — Vocabulário canônico de status de ML, com `trackfw roadmap normalize`.**
Evidência: 2.4 — três formas + 12 variantes. Medi 45/25/19 no nosso acervo antes de converter à mão.
Proposta: um único vocabulário no gerador **e** no verificador (a discordância entre os dois é a classe 2.4); regra `ml_status_vocabulary` no `validate`; comando de migração idempotente.
Custo: médio.

**F2 — `branch_has_wip_roadmap` casa por igualdade de slug, não `Contains`.**
Evidência: `validator.go:2571`; o mantenedor mediu o efeito (`wip/` inchado enfraquece o portão).
Proposta: casar `slug(branch) == slug(roadmap)` ou prefixo ancorado; erro lista os candidatos por distância de edição.
Falsificação: branch `feat/status` não pode casar com `ROADMAP-…-bucket-other-no-status-…`.
Custo: baixo.

**F3 — `trackfw doctor --governance`: roadmap em `wip/` com zero ML pendente, REQ `Open` com roadmap em `done/`, REQ sem ADR.**
Evidência: 11 de 13 em `wip/` parados no upstream; 42 violações no nosso acervo, 32 delas REQ sem ADR de 06/2026.
Proposta: relatório acionável com o comando de correção ao lado de cada linha (`trackfw roadmap move X done`).
Custo: baixo; a maioria das regras já existe, falta a face.

### G. Dívida estrutural

**G1 — Quebrar os três `validator` monolíticos por regra.**
Evidência: 2.759 / 3.654 / 3.809 linhas; o Go já começou (`validator_credential_guard.go`, `validator_git_branch_guard.go`). O `grep -a` é obrigatório no `index.js` porque o arquivo é classificado como binário.
Proposta: um arquivo por família de regra, com o mesmo nome nos 3 runtimes — o que também simplifica o gate de paridade por regra.
Custo: alto em diff, baixo em risco se feito sem mudar comportamento (gate de paridade byte a byte como rede).

**G2 — Os 41 `t.Skip` do Go.**
Evidência: 41 contra 1 no Node e 9 no Python. A política do mantenedor é "nenhum skip; um teste pulado não mede mais que um que não executa".
Proposta: classificar os 41 — quantos são supressão de plataforma (devem virar supressão **nomeada**, como na #269), quantos são dependência ausente (devem falhar nomeando), quantos são obsoletos.
Custo: médio; retorno em honestidade da suíte.

**G3 — Release.**
Evidência: 42 commits desde `v7.3.0`, incluindo a correção de segurança da #271. `CHANGELOG.md` sem seção nova.
Proposta: `v7.4.0` agora, com o protocolo do `CLAUDE.md`; e cadência declarada (por exemplo, toda correção de segurança dispara patch).
Custo: baixo.

## 4. Sequência sugerida

| onda | itens | por quê primeiro |
|---|---|---|
| **1 — sinal honesto** | A2, A3, F2, C2 | baixo custo, e cada um remove uma forma de verde falso. A3 em particular habilita tudo que vem depois no Windows. |
| **2 — fechar as classes** | B1, B2, C1, E2 | converte os quatro acidentes desta semana em invariantes verificáveis por gate. |
| **3 — visibilidade** | A1, F3, G3 | o denominador das regras e o relatório acionável; release do que já está pronto. |
| **4 — estrutura** | D1, F1, G1, G2, E1, D2 | os mais caros; cada um com rede de paridade byte a byte já existente. |

## 5. O que **não** fazer

Decisões que o upstream já mediu e que este plano respeita:

- **Não** paralelizar o `parity` com `make -j` (2,2–3,4× mais lento, medido) nem com matriz (renomeia o check obrigatório com `enforce_admins`).
- **Não** forçar o bit de execução em NTFS — supressão nomeada, como na #269.
- **Não** trocar `IsAbs`/`isabs` nos sítios de **travessia** de sistema de arquivos — só nos de classificação (D2 da ADR de 2026-09-04).
- **Não** importar a governança do upstream para o fork (ADR-2026-08-29).
- **Não** usar `skip` para esconder o que não pode ser medido — falhar nomeando a garantia não exercitada.

## 6. Como este plano vira trabalho

Cada item de A a G é um candidato a `trackfw req new` + `trackfw roadmap new`, com o critério de falsificação da seção 3 virando AC. Os de onda 1 cabem num único roadmap de 4 MLs. Os que tocam produto vão como issue/PR ao upstream, pela mesma trilha desta semana; os de experiência de fork (E1) podem viver aqui.
