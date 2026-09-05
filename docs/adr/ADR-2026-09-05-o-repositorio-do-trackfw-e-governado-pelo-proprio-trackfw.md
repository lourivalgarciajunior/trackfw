---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: O repositório do trackfw é governado pelo próprio trackfw

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra decisão aplicada entre 2026-06-15 e 2026-08-16. Escrita em 2026-09-05
> para dar lastro às 5 REQs abaixo.

## Context

O trackfw governa entrega de software por uma cadeia `ADR → REQ → ROADMAP → kanban`. A pergunta que
essa proposta convida é imediata: **o próprio trackfw segue a cadeia?**

A decisão de que sim tem uma consequência que não é retórica. Um produto que usa a si mesmo descobre
por uso o que nenhuma suíte de teste alcança — porque o autor passa a ser usuário e sente o atrito
antes do cliente. Os casos deste acervo:

- o estado `analyzing` e as regras de marcação de ML foram propostos **porque faltavam** ao usar;
- os attention hooks nasceram da necessidade de um agente pedir confirmação no meio de um roadmap;
- o `/trackfw:architect` veio da constatação de que definir stack antes da primeira REQ não tinha rito;
- o `discover --init` veio de instalar hook à mão repetidas vezes;
- a **consolidação das três árvores de artefato** veio de um sintoma que só um usuário vê: o
  repositório tinha três convenções de organização sobrepostas no tempo, e o `trackfw` enxergava
  apenas a menor delas, porque não existia `trackfw.yaml` na raiz e tudo rodava no default.

O último é o mais eloquente: **a ferramenta de governança não governava o próprio acervo, e ninguém
percebeu** — porque o comando não reprovava. Ele reportava sobre a fatia que enxergava.

Esse é o padrão que justifica a decisão e, ao mesmo tempo, o seu maior risco: **um gate que avalia um
denominador reduzido devolve verde e o verde é lido como saúde.** Aconteceu de novo em 2026-09-03,
por outra causa (layout `by_agent` não resolvido), com `✓ No violations found` sobre 7 de 53 REQs.

## Decision

**O repositório do trackfw é governado pelo trackfw, em modo estrito, e a auto-governança é fonte
legítima de requisito.**

1. `governance_mode: strict` no `trackfw.yaml` da raiz. O gate é bloqueante, não informativo.
2. **Atrito sentido ao usar é motivo suficiente para abrir REQ.** Não é preciso pedido externo.
3. O acervo de governança vive em **uma** convenção declarada no `trackfw.yaml`, nunca no default
   implícito. Convenção sobreposta é dívida a consolidar, não pluralidade a tolerar.
4. **Todo gate declara sobre quantos artefatos opinou.** Verde sem denominador não é evidência — é a
   armadilha que esta própria decisão cria, e a regra existe para neutralizá-la.

## Consequences

**Positivas**

- Requisitos que só aparecem por uso: `analyzing`, attention hooks, `discover --init`.
- O acervo do repositório é o corpus de teste mais realista disponível, porque é o único que cresce
  por trabalho de verdade.
- Auto-hospedagem é evidência que documentação não substitui.

**Negativas, e assumidas**

- **Acoplamento entre gate do produto e governança de quem consome.** Um gate que congela um corpus
  dos roadmaps deste repositório falha em qualquer fork que não os tenha — medido: 108 basenames
  ausentes. A auto-governança tende a vazar para dentro do produto, e cada vazamento é uma quebra
  para consumidores.
- **Dívida acumulada vira ruído de fundo.** Com o gate reprovando de forma permanente, ninguém
  distingue "quebrei algo agora" de "junho continua lá". É o estado atual: 42 violações estáveis.
- Regra que incomoda o autor tende a ser afrouxada pelo autor. O contrapeso é que afrouxamento
  aparece no diff da regra, não no acervo.

## Alternatives Considered

**Governar o repositório por outra ferramenta.** Recusada: perderia a descoberta por uso, que
produziu cinco dos requisitos deste acervo.

**Auto-governança em modo informativo (`warn`), não bloqueante.** Recusada por antecipar o defeito
que se quer evitar: gate que não bloqueia é gate que ninguém lê. O sintoma já existe no CI, onde os
jobs de Windows rodam com `continue-on-error`.

**Manter as três convenções de artefato e ensinar o CLI a ler todas.** Foi tentado, e é o que a
`ADR-2026-09-03` decidiu para **leitura** — união de layouts. Mas para **escrita** a decisão é
convenção única: ler várias e escrever uma só. Tolerar escrita plural foi o que produziu as três
árvores sobrepostas.

## REQs governadas por esta decisão
- REQ-2026-06-14-rules-req-configuraveis
- REQ-2026-06-15-discover-init-hook-autoinstall
- REQ-2026-06-19-analyzing-state-ml-status-rules
- REQ-2026-06-19-architect-command-guidelines
- REQ-2026-06-20-attention-hooks-agent-clis
- REQ-2026-08-16-consolidar-arvores-governanca
