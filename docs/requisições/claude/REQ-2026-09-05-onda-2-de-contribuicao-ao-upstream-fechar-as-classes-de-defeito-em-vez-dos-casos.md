---
status: done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md"
---

# REQ: Onda 2 de contribuição ao upstream — fechar as classes de defeito em vez dos casos

> Date: 2026-09-05 | Status: Open

## Motivation

A campanha de Windows do upstream corrigiu, em uma semana, **cinco predicados** cuja resposta muda
com o sistema operacional. Cada um foi descoberto **por acidente**, num PR diferente, e corrigido
isoladamente:

| predicado | POSIX | Windows | onde apareceu |
|---|---|---|---|
| `filepath.IsAbs("/opt/x")` | true | **false** | PR #271, achado de segurança |
| `os.IsNotExist(err)` com `ENOTDIR` | false | **true** | reportado por mim na #269, **ainda aberto** |
| `subprocess.run(["bash", …])` | bash real | stub do WSL, ou exceção | PR #267 |
| `os.Stat(...).Mode() & 0111` | bit real | **sempre 0** | PR #269 |
| `sys.stdout.isatty()` para `NUL` | False | **True** | REQ-2026-08-29 |

**Cinco instâncias, cinco descobertas independentes, nenhuma varredura.** O próprio mantenedor
escreveu, ao fechar o parecer da issue #216, que quatro checks do harness *"apareceram uma a uma, por
acidente, e corrigir só elas deixaria o padrão vivo"*.

O mesmo vale para o ponto único de leitura. A `ADR-2026-09-03` estabeleceu `resolve_req_files` como
ponto único (D3/D4), e o AC3 da `REQ-2026-08-30` pede a **varredura** dos consumidores que resolvem
caminho por conta própria. A varredura nunca foi automatizada: o `status` do Python foi achado por
mim, e os três `sync` também — um a um.

**A onda 1 reportou casos. Esta reporta as classes**, com o gate que impede a próxima instância de
nascer.

### Por que este fork é o lugar certo para construir a evidência

Três dos quatro itens só produzem achado quando **executados numa plataforma que o mantenedor não
tem**. Ele falsifica por mutação em macOS; nós medimos em Windows real. Foi o que fez a #273 derrubar
o candidato preferido da REQ dele.

Os gates são construídos aqui como scripts locais, **rodados contra a árvore real**, e o que vai para
o upstream é o **achado medido** mais a proposta. Se ele adotar, o gate volta pelo merge e a cópia
local sai. É o mesmo caminho do `upstream-sync.sh`, que ficou porque é procedimento **nosso**; estes
são do produto.

## Acceptance Criteria

- [x] **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
      (`caso · predicado · esperado`) consumida pelos 3 runtimes, cobrindo os 5 predicados acima.
      Falsificação: rodar contra os predicados **antigos** tem de reprovar; contra os novos, passar.
      Medido em Windows real, não por mutação.

      > **Entregue pela metade, e a outra metade migrou.** A tabela existe —
      > `scripts/testdata/platform-predicates.tsv`, 13 casos em 5 famílias. O que **não** existe é o
      > consumo: medido em 2026-09-08, o arquivo é referenciado por **três documentos e nenhum
      > script**. A parte que falta virou
      > `REQ-2026-09-08-corpus-de-predicados-de-plataforma-nao-e-lido-por-gate-nenhum`, com 7 ACs —
      > inclusive a falsificação que este AC pedia e a guarda de integridade de vetor, que este não
      > previa.
- [x] 🔴 **AC2 — B2: lint contra predicado de SO em sítio de classificação.** — ~~**O ÚNICO EM ABERTO.**~~ **ENTREGUE em 2026-09-10:** `scripts/check-os-predicate-classification.sh`. Gate que reprova
      `filepath.IsAbs`, `os.IsNotExist`, `os.path.isabs`, `path.isAbsolute`, `process.platform`,
      `os.name` em sítios de **classificação**. Sítios de **travessia** de sistema de arquivos ficam
      fora, por decisão do D2 da `ADR-2026-09-04`. A lista de exceções é explícita e cada uma tem
      motivo escrito.

      > **Não entregue, e não abandonado — porque a superfície é grande e viva.** Medida em
      > 2026-09-08 na árvore atual:
      >
      > | predicado | sítios |
      > |---|---|
      > | `os.IsNotExist` | 61 |
      > | `filepath.IsAbs` | 19 |
      > | `os.path.isabs` | 10 |
      > | `process.platform` | 7 |
      > | `path.isAbsolute` | 5 |
      > | `os.name` | 3 |
      > | **total** | **105** |
      >
      > Considerei abandonar com motivo medido, pelo critério do mantenedor — *"ML que ninguém vai
      > fazer é o mesmo passivo das REQs órfãs, só mais bem escondido"*. **A medição desautoriza o
      > abandono:** 105 sítios não é dívida morta. E o `internal/pathanchor`, criado por ele em
      > 2026-09-08, cobre só a família de ancoragem — é consumido por 3 arquivos, não pelos 105.

      > ### Atualização de 2026-09-09 — o número não era reproduzível, e agora é
      >
      > Ao remedir para decidir este AC, as **quatro** leituras plausíveis deram valores diferentes,
      > e **nenhuma reproduz 105**:
      >
      > ```
      > ocorrencias, com teste   196
      > ocorrencias, SEM teste   110   <- a mais proxima de 105
      > arquivos,    com teste    45
      > arquivos,    SEM teste    30
      > ```
      >
      > O método de 08/09 não ficou escrito, então não dá para dizer se a superfície cresceu ou se eu
      > apenas contei diferente. O que **é** medido: os PRs #304 e #305 do upstream tocaram **0
      > arquivos** de `internal/npm/pypi/cmd`, então não foram eles.
      >
      > **Entregue no lugar do número: `scripts/measure-os-predicate-sites.sh`.** Ele nomeia as
      > quatro leituras, emite o inventário como `arquivo:linha:predicado` e compara com baseline
      > **por nome, nos dois sentidos** — porque saldo zero não é conjunto igual. Falsificado em
      > quatro direções, e duas delas só valeram na segunda tentativa (`git grep` sai 1 sem casar
      > nada e, sob `pipefail`, matava o script antes da guarda falar).
      >
      > ### 🔴 E apareceu o que de fato trava este AC
      >
      > O critério de exclusão acima diz que travessia fica fora *"por decisão do D2 da
      > `ADR-2026-09-04`"*. **Essa ADR não existe no nosso acervo.** Há **três** arquivos com aquela
      > data em `upstream/main:docs/adr/`, e a `ADR-2026-08-29` decide que a governança dele não é
      > importada.
      >
      > Ou seja: este AC, como está escrito, **não é executável aqui** — separar classificação de
      > travessia depende de uma decisão que não mora neste repositório. Não é falta de esforço nem
      > de medição; é uma dependência de governança que o AC não declarou. **A decisão é do
      > usuário**, e as opções são escrever ADR nossa com o discriminante, ou reescrever o AC sem
      > depender da dele.
      >
      > **O roadmap dizia o contrário disto.** O ML-1B estava marcado ✅ Concluído com o corpo em
      > branco do template. Corrigido para ⬜ Pendente no mesmo PR, com o motivo escrito.
      >
      > ### Atualização — a dependência foi removida, não esperada
      >
      > **`ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor`**
      >
      > O discriminante passa a ser a **origem do argumento**, não a intenção do autor:
      >
      > | | regra | efeito |
      > |---|---|---|
      > | **D1** | argumento é **erro de chamada de sistema** → travessia, fora de escopo | os 57 sítios de código de `os.IsNotExist` saem de uma vez |
      > | **D2** | argumento é **string autorada** (config, frontmatter, argv, template) → classificação, em escopo | `filepath.IsAbs(destination)` entra |
      > | **D3** | predicado de plataforma lido **uma vez** para constante nomeada é a costura, não a violação | `_platform`, `isWindows` — com allowlist e motivo |
      > | **D4** | o ônus é de quem quer excluir, e a exclusão é escrita | sem julgamento silencioso |
      > | **D5** | com teste (196) e sem teste (110) são reportados **separados** | misturá-los falseou este denominador três vezes |
      >
      > **Medido:** classificados linha a linha, os 61 sítios de `os.IsNotExist` são **57 código +
      > 4 comentários + 0 outros**, e os 57 recebem todos um valor de erro. **Zero recebe outra
      > coisa** — é regra sem exceção, não regra com maioria.
      >
      > 🔴 A primeira redação da ADR dizia "59 de 61" porque contei ocorrências do padrão **dentro
      > das linhas** em vez de classificar **linha a linha**. Corrigido, e o erro fica escrito.
      >
      > **O AC2 volta a ser executável aqui.** O que falta agora é o lint em si — trabalho, não
      > dependência.
- [x] **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de `req_dir`/`roadmap_dir` fora
      do resolvedor canônico. Falsificação: tem de acusar os sítios **já conhecidos**
      (`status.py:57`, `sync.go:43`, `sync.js:237`, `sync.py:197`) e **não** acusar o próprio
      resolvedor.

      > **Alcançado por outra via: o achado saiu, o instrumento não.** O
      > [#268](https://github.com/kgsaran/trackfw/issues/268) cita os **quatro** sítios nominais
      > deste AC — `status.py:57`, `status.py:58`, `sync.go:43`, `sync.js:237`, `sync.py:197` —,
      > medidos e reportados. Ele está na fila de execução do mantenedor, posição 7.
      >
      > O gate local que este AC descrevia como método **não foi construído**: os sítios foram
      > achados por varredura direta. Fica declarado assim, e não como se o instrumento existisse.
- [x] **AC4 — E2: corpus do `barrier-contract` desacoplado da governança.** Medir o custo real para
      um consumidor e propor a separação: fixtures próprias em `scripts/testdata/` para o parser, e
      um segundo gate — só no upstream — conferindo que `docs/roadmaps` ainda parseia.

      > **Cumprido.** Virou o [#277](https://github.com/kgsaran/trackfw/issues/277) — *108 de 144
      > basenames ausentes num consumidor* —, com o custo real medido depois (`918 OK · 1 FAIL`,
      > `18m12s`). O mantenedor aceitou a proposta de interruptor (`TRACKFW_SELF_GOVERNED=1`) em vez
      > da separação por fixtures, e disse por quê: *"sem a sua medição eu teria proposto sintetizar
      > 144 arquivos — trabalho grande para o problema errado."* Está na fila dele, posição 10.
- [x] **AC5** — Cada item vira issue no `kgsaran/trackfw` com o achado **medido**, o controle na
      direção oposta, e a ressalva do que a medição **não** prova. Item cujo gate não produzir achado
      novo é reportado **como isso mesmo** — gate sem achado é resultado, não fracasso.
- [x] **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
      **correção de escopo**. Na onda 1 isso pegou 2 dos 4.
- [x] **AC7** — Nenhum item é mesclado na nossa `main` como produto. Falsificação: a divergência de
      produto continua **vazia** ao fim da onda.

- [x] **AC8 — o lint enxerga os três runtimes, e reconhece a costura pela origem, não pela forma.**
      *(Acrescentado em 2026-09-11, na reabertura — ver "Reaberta em 2026-09-11".)* O lint do AC2
      procura seis predicados e reconhece a costura só como atribuição a constante nomeada. Os dois
      limites têm medida: `runtime.GOOS` (34 no produto), `sys.platform` (9) e `platform.system()` (1)
      ficam invisíveis; e a mesma costura do `serve.js`, reescrita de constante para argumento na #321
      do upstream, passou de D3 para D2. Critério: os predicados de plataforma dos três runtimes entram
      na varredura, cada sítio novo classificado por D1–D5; o D3 reconhece a plataforma passada como
      argumento; o `serve.js` sai do baseline por ser D3, não por exceção; falsificação nas duas
      direções.
## Negative Scope

- **Não** propor o que o upstream já mediu e descartou: `make -j` no `parity`, matriz de shards,
  forçar o bit de execução, e trocar `IsAbs` nos sítios de **travessia**.
- **Não** aplicar os predicados novos antes de uma syscall. A fronteira da `ADR-2026-09-04` é
  explícita: classificação e emissão sim, travessia não — e violá-la quebra UNC e caminho longo, com
  falha **intermitente**.
- **Não** abrir as ondas 3 e 4 junto.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md
ADR: docs/adr/ADR-2026-09-09-predicado-de-so-em-sitio-de-classificacao-o-discriminante-e-a-origem-do-argumento-nao-a-intencao-do-autor.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md

## Desfecho (2026-09-05)

| item | desfecho | onde |
|---|---|---|
| B1 + B2 predicados de plataforma | **achado novo** — o sexto sítio, fora do validator | [#276](https://github.com/kgsaran/trackfw/issues/276) |
| C1 ponto único de leitura | **varredura completa, zero sítio novo** | [comentário no #268](https://github.com/kgsaran/trackfw/issues/268#issuecomment-5553347715) |
| E2 corpus do barrier | acoplamento persiste pós-#257 | [#277](https://github.com/kgsaran/trackfw/issues/277) |

**O AC5 foi exercitado de verdade:** o C1 não achou sítio novo, e isso foi reportado **como
resultado** — a lista está completa, e o valor do gate passa a ser impedir o quinto em vez de achar o
quinto. Gate sem achado não é fracasso.

**O AC6 achou dois adjacentes:** a `REQ-2026-09-01` dele (`In Progress`) para o B1, e a minha própria
issue #268 para o C1. Nenhum dos dois virou report novo.

## Reaberta em 2026-09-11

Pela Regra Dura de Causa Raiz: sítio de mesma causa entra na REQ vigente, e o roadmap volta para
`wip/`.

**O que reabriu.** O merge da #321 do upstream (nossa #105) fez o lint do AC2 reprovar o
`npm/src/commands/serve.js:280` como classificação. Não era: `openBrowser(process.platform, url)` lê a
plataforma uma vez e a injeta na função que escolhe o comando que abre o browser — costura. Antes da
#321, a mesma costura era `const platform = process.platform`, e o lint a aceitava como D3. **Mesma
costura, outra forma — e o lint decide pela forma.** O `serve.js` entrou no baseline com o motivo
escrito, como remédio de passagem.

**O que isso expôs.** O lint procura `filepath.IsAbs`, `os.path.isabs`, `path.isAbsolute`,
`process.platform`, `os.name` e `os.IsNotExist`. Os predicados de plataforma do Go e parte dos do Python
ficam de fora — medido na árvore em 2026-09-11:

| predicado | ocorrências no produto |
|---|---|
| `runtime.GOOS` | 34 |
| `sys.platform` | 9 |
| `platform.system()` | 1 |

A mesma costura do browser, no Python (`_browser_argv(system, url)`), passa sem ser vista, enquanto a do
Node é barrada.

**Por que o escopo original não previa — medido, não suposto.** A lista de seis predicados do lint é a
mesma do `measure-os-predicate-sites.sh` (linha 42), que o ML-1B-a criou para tornar mensurável a
superfície que esta REQ já nomeava; `runtime.GOOS`, `sys.platform` e `platform.system()` não aparecem
nenhuma vez nesta REQ. E o D3 foi definido no ML-1B-a pela forma que existia no corpus — plataforma
"lida uma vez para constante nomeada" (`_platform`, `isWindows`) —, sem uma segunda forma para
falsificar o reconhecedor. A ADR-2026-09-09 decide pela origem do argumento; a implementação tomou a
constante como critério.

**O que não é.** Não é defeito no produto do upstream: nenhum sítio novo de classificação foi achado.
É o nosso instrumento que ficou mais estreito que a ADR que ele implementa.
