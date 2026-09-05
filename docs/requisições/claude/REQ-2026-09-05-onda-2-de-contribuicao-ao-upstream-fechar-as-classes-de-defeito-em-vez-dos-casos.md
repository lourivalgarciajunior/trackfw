---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-onda-2-de-contribuicao-ao-upstream-fechar-as-classes-de-defeito-em-vez-dos-casos.md"
---

# REQ: Onda 2 de contribuição ao upstream — fechar as classes de defeito em vez dos casos

> Date: 2026-09-05 | Status: Done

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

- [ ] **AC1 — B1: tabela de contrato de predicados de plataforma.** Uma tabela declarativa
      (`caso · predicado · esperado`) consumida pelos 3 runtimes, cobrindo os 5 predicados acima.
      Falsificação: rodar contra os predicados **antigos** tem de reprovar; contra os novos, passar.
      Medido em Windows real, não por mutação.
- [ ] **AC2 — B2: lint contra predicado de SO em sítio de classificação.** Gate que reprova
      `filepath.IsAbs`, `os.IsNotExist`, `os.path.isabs`, `path.isAbsolute`, `process.platform`,
      `os.name` em sítios de **classificação**. Sítios de **travessia** de sistema de arquivos ficam
      fora, por decisão do D2 da `ADR-2026-09-04`. A lista de exceções é explícita e cada uma tem
      motivo escrito.
- [ ] **AC3 — C1: gate de ponto único de leitura.** Acusa enumeração de `req_dir`/`roadmap_dir` fora
      do resolvedor canônico. Falsificação: tem de acusar os sítios **já conhecidos**
      (`status.py:57`, `sync.go:43`, `sync.js:237`, `sync.py:197`) e **não** acusar o próprio
      resolvedor.
- [ ] **AC4 — E2: corpus do `barrier-contract` desacoplado da governança.** Medir o custo real para
      um consumidor e propor a separação: fixtures próprias em `scripts/testdata/` para o parser, e
      um segundo gate — só no upstream — conferindo que `docs/roadmaps` ainda parseia.
- [x] **AC5** — Cada item vira issue no `kgsaran/trackfw` com o achado **medido**, o controle na
      direção oposta, e a ressalva do que a medição **não** prova. Item cujo gate não produzir achado
      novo é reportado **como isso mesmo** — gate sem achado é resultado, não fracasso.
- [x] **AC6** — Antes de abrir, conferir o acervo dele. Se já houver registro, o entregável é
      **correção de escopo**. Na onda 1 isso pegou 2 dos 4.
- [x] **AC7** — Nenhum item é mesclado na nossa `main` como produto. Falsificação: a divergência de
      produto continua **vazia** ao fim da onda.

## Negative Scope

- **Não** propor o que o upstream já mediu e descartou: `make -j` no `parity`, matriz de shards,
  forçar o bit de execução, e trocar `IsAbs` nos sítios de **travessia**.
- **Não** aplicar os predicados novos antes de uma syscall. A fronteira da `ADR-2026-09-04` é
  explícita: classificação e emissão sim, travessia não — e violá-la quebra UNC e caminho longo, com
  falha **intermitente**.
- **Não** abrir as ondas 3 e 4 junto.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md

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
