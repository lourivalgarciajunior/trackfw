---
status: Done
date: 2026-09-05
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md"
---

# REQ: Ondas 3 e 4 — visibilidade do denominador, dívida estrutural e release

> Date: 2026-09-05 | Status: Done

## Motivation

As ondas 1 e 2 reportaram casos e classes. As ondas 3 e 4 do plano
(`docs/analises/2026-09-05-oportunidades-de-evolucao.md`) tratam de **visibilidade** — fazer o gate
dizer sobre quantos artefatos opinou — e de **dívida estrutural**.

O item de visibilidade (A1, `validate --coverage`) nasceu de um fato deste fork: `✓ No violations
found` avaliando **7 de 53** REQs. A proposta era acrescentar o denominador à saída.

**Ao medir para justificar a proposta, o defeito apareceu — e é maior que a proposta.** Não é que o
gate não mostre o denominador: é que o denominador está errado por um motivo que ninguém tinha
medido, e no acervo do próprio mantenedor.

## Restrição assumida: volume de issues

Ao começar esta onda havia **5 issues abertas com ele desde hoje de manhã**, nenhuma respondida.
Abrir mais oito seria transformar contribuição em ruído — e é exatamente a falha que o escopo
negativo da REQ da onda 1 previu: *"REQ que espera decisão de terceiro apodrece em backlog"*.

A decisão foi **entregar só o que produziu achado medido**, e registrar os demais aqui como
não-entregues, com o motivo. Dois dos oito itens saíram.

## Acceptance Criteria

- [x] **AC1 — A1 (visibilidade do denominador).** Entregue como **defeito medido**, não como proposta
      de flag: a detecção de marcador vazio compara com uma literal, e 5 de 7 grafias de vazio passam.
      Executado contra o acervo dele: o gate acusa **11** REQs sem ADR; são **69**. → [#278](https://github.com/kgsaran/trackfw/issues/278)
- [x] **AC2 — G2 (os `t.Skip`).** Entregue: **9 skips de classe plataforma sobraram do ML-4A**, em 4
      arquivos que a #269 não tocou, mais o inventário das duas classes (plataforma × dependência
      ausente). → [#279](https://github.com/kgsaran/trackfw/issues/279)
- [x] **AC3 — os demais itens ficam registrados como NÃO entregues, com o motivo.** Ver a seção
      abaixo. Item não entregue por decisão é desfecho; item não entregue por esquecimento é dívida.
- [x] **AC4** — Cada issue traz o achado medido, o controle na direção oposta, e a ressalva do que a
      medição **não** prova.
- [x] **AC5** — Nada mesclado na nossa `main` como produto. Divergência de produto continua **zero**.

## Itens NÃO entregues, e por quê

| item | por quê |
|---|---|
| **F3** `doctor --governance` | proposta de ferramenta sem defeito medido por trás. O `validate` já reporta as mesmas condições; a diferença seria de forma. Sem achado, não vale uma issue. |
| **G3** release `v7.4.0` | 42+ commits desde a v7.3.0, incluindo correção de segurança (#271). É observação factual, não achado — e a cadência de release é decisão dele, num repositório onde ele é o único mantenedor. Registrado aqui, não reportado. |
| **D1** cache por gate no `falsify` | exigiria medir o custo por gate no CI **dele** para dizer quanto o cache pouparia. Não tenho acesso ao runner, e um número de máquina local não transfere — foi a lição da #273, onde eu quase reportei 62% em vez de 9%. |
| **G1** quebrar os três `validator` | refatoração pura, sem defeito medido. O diff seria enorme e o risco é dele, não meu. Fica no plano. |
| **F1** vocabulário canônico de ML | o nosso acervo já está normalizado e o `validate` está limpo; medir o dele exigiria rodar o `barrier`, que leva ~16 min e depende do corpus acoplado — que é justamente o [#277](https://github.com/kgsaran/trackfw/issues/277). Bloqueado por outro item aberto. |
| **D2** Windows local para o mantenedor | não é issue: é o arranjo que já existe de fato. Este fork **é** o Windows dele há três dias, e sete achados saíram disso. Propor a formalização é conversa, não report. |

## Re-medição de 2026-09-12 — cinco caducaram, um segue recusado, e o F1 foi REFUTADO

Pedido: "vamos para a onda 3", depois "mede a onda 4". A REQ estava `Done` com 2 de 8 entregues, e
**seis recusas justificadas**. Sete dias depois, os motivos foram confrontados com o mundo.

### Onda 3 — A1, F3, G3

| item | motivo em 05/09 | medido em 12/09 | veredito |
|---|---|---|---|
| **A1** | — | entregue: virou a [#278](https://github.com/kgsaran/trackfw/issues/278), fechada por ele | entregue |
| **F3** `doctor --governance` | "11 de 13 roadmaps em `wip/` parados no upstream" | **2** em `wip/`, **0** parados · **0 de 208** REQs `Open` com roadmap em `done/` | **caducou** |
| **G3** release | "42 commits desde a v7.3.0, `CHANGELOG` sem seção" | **v7.4.0** (06/09), **v7.5.0** e **v7.5.1** (09/09); 14 commits desde a última tag | **caducou** |

### Onda 4 — D1, D2, E1, F1, G1, G2

| item | motivo em 05/09 | medido em 12/09 | veredito |
|---|---|---|---|
| **G2** os 41 `t.Skip` | — | entregue: virou a [#279](https://github.com/kgsaran/trackfw/issues/279) | entregue |
| **D1** cache por gate | "exigiria medir o custo no CI dele; não tenho acesso" | ele **implementou sharding**, que havia descartado por escrito em 05/09 (`strategy.matrix.shard: [0,1,2,3]`); run inteiro em **526 s** | **caducou** |
| **D2** Windows local | "não é issue, é o arranjo que já existe" | `scripts/windows-repro/run.ps1` **existe**, com sondas nos 3 runtimes; 5 jobs `windows-*` no CI dele | **caducou** |
| **E1** `upstream sync` | "cada merge me custa 23 conflitos" | ele não tem o subcomando nem `merge=ours`, mas **nós** resolvemos com o `scripts/upstream-sync.sh`, com falsificação. A dor não existe mais aqui | **caducou** |
| **G1** quebrar os `validator` | "refatoração pura, sem defeito medido" | cresceram de 2794/3684/3844 para **2988/4042/4325** linhas — crescimento não é defeito | **segue recusado** |
| **F1** vocabulário de status de ML | "medir o dele exigiria o `barrier` (~16 min) e o corpus acoplado do #277" | **REFUTADO por medição** — ver abaixo | **refutado** |

### 🔴 O F1: o motivo da recusa era falso, e a proposta também

**O bloqueio nunca existiu.** A medição saiu por `git grep` sobre as refs dele, em segundos, sem
tocar no `barrier` nem no corpus do #277.

**E o que ela mostrou refuta a proposta.** O acervo dele tem **25 tokens distintos** de status em 1088
ocorrências (o nosso: 8 em 427). Mas o F1 propunha "vocabulário canônico porque gerador e verificador
discordam" — e **eles não discordam**. Reimplementei o predicado real (`internal/commands/barrier.go`,
`statusIsComplete`) e confrontei os 25:

- `✅ Concluído` (730), `done` (91), `✅ concluído` (50), `CONCLUIDO` (5), `✅ Concluido` (1) → **completo**,
  porque `normalizeStatusToken` dobra diacríticos e minúscula de propósito;
- `⬜ Pendente` (163), `🔄 Em andamento` (11), `pending` (9), `❌ Cancelado`, `PENDENTE`, `ABANDONADO`,
  `🚫 **Abandonado**` → **não-completo**, corretamente;
- `⬜ Pendente ✅` (2) → **não-completo**, e o código comenta que um `Contains(marker, "✅")` classificaria
  errado — o predicado olha só `Fields[0]` justamente por isso;
- `d<U+1DC0>one` → **não-completo**: é o ataque de combining mark que ele fecha com `hasDisallowedCombiningMark`.

Paridade preservada: os três runtimes aceitam `✅`, `done`, `concluido`, `feito`, `finalizado`, `ok`,
`complete`. **Não há divergência entre gerador e verificador.** As 25 formas são variação cosmética
que um normalizador endurecido absorve.

🔴 **Quatro medições, três erradas — e isso fica escrito.** "12 grafias" veio de um regex de duas
palavras que truncava `🔄 Em andamento` e capturava crases; "246 formas" contava prosa anexada
(`· **Agente:** …`) como vocabulário; "9 tokens" mutilava sequências UTF-8 e perdia 90% do corpus.
Só a quarta, com extrator que opera em caracteres, deu o número estável. É o mesmo padrão que o
`check-inherited-req.sh` existe para impedir, e desta vez ele apareceu **antes** de virar issue.

### Efeito colateral achado no nosso próprio acervo

`ROADMAP-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink.md:159` escreve
`**Status:** done, com um criterio **nao cumprido** e declarado`. O primeiro campo é `done,` **com
vírgula**, que não está no vocabulário: o produto lê aquele ML como **não concluído**.

O formato com emoji tolera ressalva (`✅ Concluído — commit …` continua completo, porque `Fields[0]`
é `✅`); o formato `done` não. Registrado aqui; não é defeito do produto, é uso nosso.

### Conclusão

**Nada a reportar ao upstream.** Cinco itens caducaram porque ele resolveu, um segue sem defeito
medido, e o único que parecia achado foi refutado pelo próprio código dele. A REQ permanece `Done`.

## Negative Scope

- **Não** abrir issue para item sem achado medido.
- **Não** propor o que ele já mediu e descartou.
- **Não** aplicar nada de produto na nossa `main`.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-05-ondas-3-e-4-visibilidade-do-denominador-divida-estrutural-e-release.md
