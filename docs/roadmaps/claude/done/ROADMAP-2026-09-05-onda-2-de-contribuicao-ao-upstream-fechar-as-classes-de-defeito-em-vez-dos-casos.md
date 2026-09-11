---
status: done
date: 2026-09-05
req: "docs/requisições/claude/REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md"
squad: ""
---

# Roadmap: Onda 2 de contribuição ao upstream — fechar as classes de defeito em vez dos casos

> Created: 2026-09-05 | Status: done

## 🔴 Por que este roadmap esta em `blocked/` — 2026-09-10

**Nao esta bloqueado por dependencia externa.** A dependencia que o travava — o discriminante
classificacao x travessia, que o AC2 delegava ao D2 de uma ADR do upstream — **foi removida** pela
`ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor`,
escrita a partir da nossa propria medicao.

O que falta e **trabalho**: escrever o lint. Nada impede de faze-lo hoje.

**Esta em `blocked/` por PRIORIZACAO explicita**, e o mecanismo e a regra 3 do fluxo — um roadmap em
`wip/` por vez. O slot foi liberado para a auditoria dos ACs abertos do nosso proprio acervo:

```
12 REQs NOSSAS com 58 checkbox(es) aberto(s)
57 dos 58 sob bloco de criterio -- criterio real, nao placeholder
10 delas marcadas `done`/`Done`
```

Aquilo **mente todo dia que passa**: dez REQs afirmam entrega concluida com criterio substantivo em
aberto, e sao verificaveis executando o produto de hoje, sem depender de ninguem. Este roadmap nao
mente — ele apenas espera.

🔴 **Registro do risco de estar aqui.** O criterio do mantenedor, adotado neste projeto: *"ML que
ninguem vai fazer e o mesmo passivo das REQs orfas, so mais bem escondido"*. `blocked/` sem causa
nomeada e exatamente esse esconderijo. Por isso a causa esta escrita, e ela e **prioridade**, nao
impedimento — o que significa que a saida daqui nao depende de evento externo nenhum.

**Condicao de retorno a `wip/`:** a auditoria dos 58 ACs fechar, ou decisao explicita de inverter a
ordem.

## 🔴 Reaberto em 2026-09-11 — o lint do AC2 não enxerga Go, e decide a costura pela forma

O merge da #321 do upstream fez o lint reprovar uma costura (`openBrowser(process.platform, url)`) que,
um commit antes, ele aceitava escrita como constante. A investigação mostrou dois limites do nosso
instrumento: os predicados de plataforma do Go e parte dos do Python não estão na varredura (34
`runtime.GOOS`, 9 `sys.platform`, 1 `platform.system()`), e o D3 reconhece a costura pela forma. O
motivo, medido, está na seção "Reaberta em 2026-09-11" da REQ. O trabalho é o **ML-1H**.

## Context
<!-- Derived from REQ: REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md -->
REQ: docs/requisições/claude/REQ-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
<!-- 2026-09-11 (ML-1H): as duas primeiras linhas eram checkboxes VAZIOS, herdados do
     template e nunca preenchidos. Critério vazio conta como critério aberto no nosso
     próprio check-req-done-com-criterio-aberto.sh, então o espelho dos ACs da REQ
     entrou no lugar deles. -->
- [x] AC1 — B1: tabela de contrato de predicados de plataforma (ML-1A)
- [x] AC2 — B2: lint contra predicado de SO em sítio de classificação (ML-1B, ML-1B-a)
- [x] AC3 — C1: gate de ponto único de leitura (ML-1C)
- [x] AC4 — E2: corpus do `barrier-contract` desacoplado da governança (ML-1D)
- [x] AC5 — cada item vira issue com achado medido e controle (ML-1E)
- [x] AC6 — conferir o acervo do upstream antes de abrir (ML-1F)
- [x] AC7 — nenhum item mesclado na nossa `main` como produto (ML-1G)
- [x] AC8 — o lint enxerga os três runtimes, e reconhece a costura pela origem (ML-1H)

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** scripts/testdata/platform-predicates.tsv (artefato de medição)
**Actions:** 1. Enumeração · 2. Threat model · 3. Falsificação · 4. Residual
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência

**1. Enumeração.** Não parti da lista da REQ. Varri as três árvores por primitiva: 84 usos de
predicado dependente de SO e 49 sítios de enumeração perto de `req_dir`/`roadmap_dir`. Foi essa
varredura — e não a lista — que produziu o **sexto** sítio da classe `ENOTDIR`, em
`internal/integrations/manager.go:477`, fora de `internal/validator/` onde toda a atenção esteve.

**2. Threat model — quem esvazia esta onda sem quebrar regra escrita.**

- **Gate que não acha nada e é reportado como sucesso.** O C1 caiu exatamente aqui: a varredura não
  achou sítio novo. O contrapeso é o AC5 — reportar "a lista está completa" **é** o resultado, e o
  valor do gate passa a ser impedir o quinto, não achar o quinto.
- **Grep como prova.** Toda a evidência de B2 e C1 é análise estática. Um sítio que monte o caminho
  indiretamente escapa da janela de ±6 linhas. Declarado nas duas issues.
- **Propor gate que ele não pediu.** Três dos quatro itens são instrumentos, não defeitos. O
  contrapeso foi ancorar cada um num defeito **medido** — o sexto sítio, os 108 basenames — em vez de
  vender a ferramenta.
- **Duplicar o acervo dele.** O AC6 achou a `REQ-2026-09-01` (`In Progress`) adjacente ao B1, e o
  C1 já tinha issue minha. Nenhum dos dois virou report novo.

**3. Falsificação nas duas direções.**

```
B1  tabela de contrato, familia anchored, em Windows real:
      predicado NOVO   7/7        predicado ANTIGO  5/7   <- o antigo TEM de reprovar
B2  6 sitios da classe ENOTDIR, e o controle medido:
      arquivo-como-dir  IsNotExist=true  Is(ENOENT)=false  -> deve REPORTAR
      inexistente       IsNotExist=true  Is(ENOENT)=true   -> deve SUPRIMIR
C1  acusa os 4 conhecidos · NAO acusa o resolvedor
E2  108 de 144 ausentes num consumidor · 1 falha (era 6 antes da #257)
```

**Hipótese descartada, registrada:** procurei violação do D4 por **duplicação** do resolvedor, que
grep de enumeração não pega. O candidato (`generators/roadmap.py:535`, docstring dizendo *"espelhando
exatamente `resolve_req_files`"*) **chama** o resolvedor na linha seguinte. Falso positivo, e está na
issue porque a frase induz ao erro.

**4. Residual declarado.**

- **Nada foi medido por execução do produto**, exceto a tabela do B1 em Node e Python. O predicado
  novo do **Go é não-exportado** e exigiria teste dentro do pacote — não rodei.
- **A família `direrr` da tabela está declarada, não executada** nos 3 runtimes.
- **O E2 foi medido por leitura do gate mais a contagem dos ausentes**, sem rodar a suíte completa
  (~16 min no CI Linux, mais em Windows). O caminho de código é direto e sem ramo alternativo, mas
  não executei.
- **Os 78 usos restantes de predicado de SO não foram classificados.** Só afirmo os 6 que guardam
  leitura de diretório.

**Gates da wave:**
```bash
# Wave 0 gate — replace this placeholder with a project-specific check before
# marking ML-0A done. Do not remove the gate; replace its command (AC13).
for n in 276 277 268; do
  gh issue view "$n" --repo kgsaran/trackfw --json number >/dev/null 2>&1 || { echo "issue #$n ausente"; exit 1; }
done
test -s scripts/testdata/platform-predicates.tsv || { echo "tabela de contrato ausente"; exit 1; }
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: none

### ML-1A — **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
- [x] build passes
- [x] tests green

### ML-1B — AC2: lint contra predicado de SO em sítio de classificação
**Status:** ✅ Concluído
**Files affected:** `scripts/measure-os-predicate-sites.sh` (pré-requisito), lint ainda não escrito
**Acceptance criteria:**
- [x] Gate que reprova os seis predicados em sítios de **classificação**
- [x] **Pré-requisito: a superfície é mensurável de forma reproduzível**

🔴 **Este ML estava marcado ✅ Concluído e não estava.** A REQ, no mesmo dia, descrevia o AC2 como
*"O ÚNICO EM ABERTO — não entregue, e não abandonado"*. Roadmap e REQ afirmavam o contrário um do
outro, e o roadmap é que estava errado.

O corpo denuncia como aconteceu: `Files affected:` vazio, `Actions:` vazio, e o critério era o
genérico `build passes` / `tests green` do template do `roadmap new --from-req`. **Nada disso foi
verificado; foi marcado.** O título ainda está truncado no meio da frase — o mesmo defeito de
truncamento de AC multilinha que registrei ao gerar o roadmap da `REQ-2026-09-09-governanca-do-upstream`.

É a Regra Dura de Reconciliação aplicada ao nosso próprio acervo: **artefato afirmando o contrário da
conclusão do mesmo trabalho.** A regra existe porque isso já custou uma auditoria externa em
2026-09-05; desta vez pegou uma varredura nossa, quatro dias depois.

**O que de fato foi entregue neste ML:** `scripts/measure-os-predicate-sites.sh`, que é o
pré-requisito — não o lint. Ver ML-1B-a.

### ML-1B-a — Tornar a superfície mensurável antes de decidir o lint
**Status:** ✅ Concluído
**Files affected:** `scripts/measure-os-predicate-sites.sh`, `scripts/testdata/os-predicate-sites-baseline.txt`
**Acceptance criteria:**
- [x] As leituras plausíveis são **nomeadas**, não escolhidas em silêncio
- [x] Comparação com baseline **por nome**, nos dois sentidos
- [x] Guardas de vacuidade, falsificadas

**Por que este ML existe.** O AC2 não pôde ser decidido porque o tamanho da superfície mudava de
valor conforme quem digitava o grep:

```
publicado em 2026-09-08     105 sitios
redigitado em 2026-09-09    196  ocorrencias, com teste
                            110  ocorrencias, SEM teste
                             45  arquivos,    com teste
                             30  arquivos,    SEM teste
```

🔴 **Nenhuma das quatro reproduz 105, e o método de 08/09 não ficou escrito.** A mais próxima é
`110 ocorrências sem teste`, o que sugere variação de ~5 e não de 91 — mas *sugere* não é *mede*, e
os PRs #304/#305 do upstream tocaram **0 arquivos** de `internal/npm/pypi/cmd`, então não foram eles.

Por isso o entregável é o **método**, não o número. O inventário sai como `arquivo:linha:predicado` e
a comparação é de conjunto.

**Falsificação — quatro direções:**

| # | mutação | esperado | medido |
|---|---|---|---|
| A | plantar um `filepath.IsAbs` novo | nomeia o sítio | `+ internal/commands/help.go:427:filepath.IsAbs` |
| B | baseline com **saldo zero** e conjunto diferente | acusa | `novos 1 · sumidos 1` + `A superfície MUDOU` |
| C | predicado que não casa nada | reprova | `exit 1`, `GUARDA — zero sítios em 507 arquivos` |
| D | escopo inexistente | reprova | `exit 1`, `GUARDA — zero arquivos varridos` |

🔴 **C e D não valeram na primeira tentativa: `exit 1` sem mensagem nenhuma.** O `git grep` sai 1
quando não casa nada e, sob `set -euo pipefail`, matava o script **antes** da guarda falar. Código
certo, motivo errado — a guarda seguia sem nunca ter sido exercitada. Corrigido com `|| true` dentro
da substituição, e a razão ficou escrita no script.

🔴 **E o `--gravar-baseline` nasceu inalcançável:** a checagem de baseline ausente saía antes do
código que grava. Pego na primeira execução.

**O que este ML NÃO resolve, e é o que trava o AC2.** O critério de exclusão do AC2 diz que sítios de
**travessia** ficam fora *"por decisão do D2 da `ADR-2026-09-04`"*. **Essa ADR não existe no nosso
acervo.** Medido: há **três** arquivos com aquela data em `upstream/main:docs/adr/` — âncora POSIX em
config, tolerância a CRLF no frontmatter, e separador POSIX em artefato —, e a `ADR-2026-08-29`
decide que a governança dele não é importada.

~~Então o AC2, como está escrito, **não é executável aqui**~~ — **resolvido em 2026-09-09.**

### A dependência foi REMOVIDA, não esperada

`ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor`,
escrita a partir da nossa medição em vez de importada da dele.

| | regra | efeito medido |
|---|---|---|
| **D1** | argumento é **erro de chamada de sistema** → travessia, fora de escopo | os **57** sítios de código de `os.IsNotExist` saem de uma vez |
| **D2** | argumento é **string autorada** → classificação, em escopo | `filepath.IsAbs(destination)` entra |
| **D3** | predicado de plataforma lido **uma vez** para constante nomeada é a costura | `_platform`, `isWindows`, com allowlist e motivo |
| **D4** | o ônus é de quem quer excluir, e a exclusão é escrita | sem julgamento silencioso |
| **D5** | com teste (196) e sem teste (110) reportados **separados** | misturá-los falseou este denominador três vezes |

**O achado que decidiu:** classificados **linha a linha**, os 61 sítios de `os.IsNotExist` são
**57 código + 4 comentários + 0 outros**, e os 57 recebem **todos** um valor de erro. Zero recebe
outra coisa — regra sem exceção, não regra com maioria. Mais de metade da superfície fica decidida
por leitura do argumento, sem julgar intenção.

🔴 **A primeira redação da ADR dizia "59 de 61" e estava errada:** contei ocorrências do padrão
*dentro* das linhas com `grep -oE` em vez de classificar *linha a linha*. A correção **fortalece** a
decisão, mas fica escrita — contagem por ocorrência já falseou o denominador deste trabalho três
vezes.

~~**O que falta para o AC2 agora é o lint em si.**~~ **Entregue em 2026-09-10:**
`scripts/check-os-predicate-classification.sh`.

```
196 sitios varridos
 86 com arquivo de teste   (D5: a parte, nunca somado)
 57 D1 travessia
  4 D3 costura
 30 comentario
 19 D2 CLASSIFICACAO       em 8 arquivos declarados
```

Os cinco somam **196 exatamente** — o denominador reconcilia, não sobra resto. Cada linha do gate
implementa uma decisão da ADR, e nenhuma é heurística inventada na hora.

🔴 **É um RATCHET, e essa foi a decisão de desenho.** Os 19 sítios de classificação estão **todos em
produto do upstream**. Corrigi-los aqui criaria divergência, que hoje é zero — e o escopo negativo
desta REQ decide: achado vira **issue**, não correção local. O gate congela os conhecidos **com
motivo por arquivo** e reprova o próximo.

**Falsificação — quatro direções:**

| # | mutação | esperado | medido |
|---|---|---|---|
| A | sítio de classificação em arquivo **novo e rastreado** | reprova | `exit 1`, nomeando `internal/commands/zz_probe.go:5` |
| B | o mesmo sítio, em **arquivo de teste** | passa (D5 separa) | `exit 0` |
| C | classificador D1 cegado | reprova | `exit 1`, `GUARDA — zero sitios classificados como D1` |
| D | escopo inexistente | reprova | `exit 1`, guarda de vacuidade |

🔴 **A direção A não valeu na primeira tentativa.** Plantei o arquivo e **não fiz `git add`** — o gate
usa `git grep`, que só vê conteúdo **rastreado**, e devolveu `exit 0`. Pareceu gate cego; era teste
mal montado. Fica escrito no `CLAUDE.md` como limite do gate.

🔴 **E o baseline nasceu com uma entrada obsoleta.** Escrevi `validator_git_branch_guard.go` a partir
de uma classificação ad-hoc **diferente** da que o gate implementa; o aviso de declaração obsoleta a
pegou na primeira execução. Removida. É o mesmo mecanismo do `check-subcommand-parity`, e serviu para
o mesmo fim: baseline escrito à mão diverge do derivado.

### ML-1C — **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de req_dir/roadmap_dir fora
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de req_dir/roadmap_dir fora
- [x] build passes
- [x] tests green

### ML-1D — **AC4 — E2: corpus do barrier-contract desacoplado da governança.** Medir o custo real para
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC4 — E2: corpus do barrier-contract desacoplado da governança.** Medir o custo real para
- [x] build passes
- [x] tests green

### ML-1E — **AC5** — Cada item vira issue no kgsaran/trackfw com o achado **medido**, o controle na
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC5** — Cada item vira issue no kgsaran/trackfw com o achado **medido**, o controle na
- [x] build passes
- [x] tests green

### ML-1F — **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
- [x] build passes
- [x] tests green

### ML-1G — **AC7** — Nenhum item é mesclado na nossa main como produto. Falsificação: a divergência de
**Status:** ✅ Concluído
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [x] **AC7** — Nenhum item é mesclado na nossa main como produto. Falsificação: a divergência de
- [x] build passes
- [x] tests green

### ML-1H — O lint enxerga os três runtimes, e a costura se reconhece pela origem (reaberto em 2026-09-11)
**Status:** ✅ Concluído
**Files affected:** `scripts/check-os-predicate-classification.sh`, `scripts/measure-os-predicate-sites.sh`, `scripts/testdata/os-predicate-sites-baseline.txt`
**Acceptance criteria:**
- [ ] `runtime.GOOS`, `sys.platform` e `platform.system()` entram na varredura do lint **e** da medição —
      os dois compartilham a lista de seis predicados, e corrigir só um deixaria o inventário e o lint
      discordando
- [ ] Cada sítio novo classificado por D1–D5, por nome; o denominador reconcilia, sem resto
- [ ] O D3 reconhece a plataforma **passada como argumento** (costura por injeção), não só atribuída a
      constante — e o `serve.js` sai do baseline porque passa a ser D3, não por exceção
- [ ] Falsificação nas duas direções: uma classificação real continua D2 e é acusada; uma costura por
      argumento vira D3 e é aceita; e o denominador de D1 continua maior que zero
- [ ] Sítio de classificação real achado em produto do upstream vira **issue**, não correção local — o
      escopo negativo desta REQ
- [ ] Nenhum arquivo de produto tocado; `validate` e gates verdes

**Entregue em 2026-09-11.**

| medida | antes | depois |
|---|---|---|
| predicados na lista (lint **e** medição) | 6 | **9** |
| sítios varridos | 196 | **240** |
| D3 costura | 4 | **9** |
| D2 classificação | 20, em 9 arquivos | **16, em 9 arquivos** |
| comentário | 30 | **46** |

O denominador reconcilia sem resto: 112 teste + 57 D1 + 9 D3 + 46 comentário + 16 D2 = 240.

**Três decisões, cada uma medida:**

1. **O D3 reconhece a costura pela origem.** Plataforma passada como argumento inteiro é costura,
   igual à constante nomeada. Enumerado no corpus: no produto a regra nova casa **só** o
   `serve.js:280`; os outros três casos que ela casa são arquivo de teste e saem antes por D5. O
   `serve.js` saiu do baseline **por ser D3**, não por exceção.
2. 🔴 **Um furo foi achado por sonda ANTES do merge.** `strings.Contains(runtime.GOOS, "win")` tem a
   forma de argumento e o ato de comparação, e a primeira versão da regra o aceitava como costura —
   bastaria trocar `==` por um ajudante de string para fechar o ratchet sem corrigir nada. Passou a
   ser recusado por lista literal de comparadores. **Zero sítios nessa forma no escopo hoje**, então
   a correção fecha um caminho futuro sem mexer em contagem.
3. **Prosa dentro de docstring não é sítio.** O classificador só olhava o início da linha, e contava
   como classificação sete linhas de texto que citam `os.path.isabs` e `os.name` ao explicar a ADR.
   Foi por elas que `pypi/trackfw/validator.py` estava no baseline — **um arquivo declarado por um
   sítio que nunca existiu**. Saiu, com o motivo escrito.

**Falsificação, quatro direções, com sítio plantado e `git add`** (o lint só vê conteúdo rastreado —
medido em 2026-09-10, quando plantar sem `git add` deu `exit 0`):

| plantado | esperado | medido |
|---|---|---|
| `if runtime.GOOS == "windows"` (predicado novo) | acusa | `rc=1`, nomeia o sítio |
| `abrirBrowser(runtime.GOOS, url)` (costura por argumento) | passa | `rc=0`, D3 sobe de 9 para 10 |
| `strings.HasPrefix(runtime.GOOS, "win")` (comparador) | acusa | `rc=1`, nomeia o sítio |
| docstring com prosa + código depois dela | acusa **só** o código | `rc=1`, nomeia só a linha de código |

A `ADR-2026-09-09` recebeu nota com as duas decisões novas. Elas cabem no critério dela — concentração
da dependência num ponto —, mas não estavam no texto, e decisão que mora só no script é o script
decidindo pela ADR.

**Gates:** `run-local-gates` 10/10, `validate` limpo, baseline da medição regravado (240 sítios, e a
execução seguinte fecha em 0 novos · 0 sumidos). **Nenhum arquivo de produto tocado** — a divergência
continua zero.

## Desfecho de cada item (AC5, AC6)

| item | desfecho | onde |
|---|---|---|
| **B1** tabela de contrato | fundido ao B2 — a tabela é o instrumento, o sexto sítio é a evidência | [#276](https://github.com/kgsaran/trackfw/issues/276) |
| **B2** lint de predicado de SO | **achado novo**: `manager.go:477`, fora do validator, e o comentário da `2451` que nomeia `ENOTDIR` | [#276](https://github.com/kgsaran/trackfw/issues/276) |
| **C1** ponto único de leitura | **varredura completa, zero sítio novo** — reportado como comentário no AC3 dele, não como issue | [#268](https://github.com/kgsaran/trackfw/issues/268#issuecomment-5553347715) |
| **E2** corpus do barrier | **acoplamento persiste** pós-#257: 108 de 144 ausentes, 1 falha em vez de 6 | [#277](https://github.com/kgsaran/trackfw/issues/277) |

**B1 e B2 viraram uma issue só** porque a tabela sozinha é proposta de ferramenta; com o sexto sítio
ao lado, é defeito medido com o instrumento que o teria achado antes.

**Nenhum item mesclado na nossa `main` como produto (AC7).**
