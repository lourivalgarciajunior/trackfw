---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: trackfw é o trilho de governança para agentes de IA, e o artefato é a interface

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra a decisão fundadora do produto, tomada em 2026-06-13 e entregue no
> roadmap `trackfw-ai-agent-rail-2026-06-13`. Escrita em 2026-09-05 para dar lastro à REQ abaixo.

## Context

O trackfw v2.0.0 foi construído para governança de **times humanos**. O uso real mostrou outra
coisa: agentes de IA — Claude Code, Gemini CLI, Cursor — já operavam sobre a cadeia
`ADR → REQ → ROADMAP` **como trilho de orquestração**, sem que o produto tivesse sido desenhado para
isso.

O padrão funcionava por acidente, e o acidente tem explicação: um agente precisa de **estado
externo, durável e legível** para trabalho que atravessa sessões. Ele não tem memória entre
execuções, e a janela de contexto não é armazenamento. A cadeia de artefatos já era exatamente isso
— só não estava formalizada nem exposta como tal.

Formalizar muda o critério de projeto de forma concreta. Se o consumidor do artefato é um agente:

- **frontmatter tem de ser parseável sem ambiguidade**, não decorativo;
- tem de existir um comando que **despeja o estado de governança** num formato consumível, em vez de
  obrigar o agente a varrer o repositório e inferir;
- o artefato precisa carregar **por que** a decisão foi tomada, não só o que foi decidido — um agente
  que lê só o "o quê" reimplementa a alternativa já recusada.

Esta ADR existe também por um motivo de fronteira. O upstream `kgsaran/trackfw` tem a sua própria
`ADR-001-trackfw-como-trilho-de-governanca-para-agentes-ia`, e a `ADR-2026-08-29` decidiu que a
governança dele **não é importada** para cá. A `REQ-2026-06-13-trackfw-ai-agent-governance-rail`
deste acervo apontava para aquele arquivo, que não existe neste repositório — link quebrado desde a
adoção do upstream como base. **Registramos a decisão do nosso lado em vez de importar o arquivo
dele**, que é o que a política manda.

## Decision

**O trackfw é o trilho de governança para desenvolvimento orquestrado por agentes de IA. O artefato
é a interface entre o humano que decide e o agente que executa.**

1. **Frontmatter YAML estruturado** em ADR, REQ e ROADMAP. Metadado em prosa ou em markdown
   decorativo não é metadado — é texto que parece metadado.
2. **`trackfw context`** despeja o estado de governança num formato consumível por LLM: ADRs aceitas,
   REQs abertas, WIP atual, e o score. O agente lê o estado; não o reconstrói.
3. **O protocolo de agente é parte do produto**, não convenção de time: rodar `context` antes de
   começar, criar REQ e ROADMAP **antes** da branch, atualizar o contexto de trabalho ao encerrar, e
   passar no `validate` antes do PR.
4. **A ADR registra o porquê e as alternativas recusadas**, porque é o que impede um agente de
   reimplementar uma opção já descartada. Uma ADR que só diz o que foi decidido é um comentário.
5. **Sinalização de atenção**: quando o agente precisa de decisão humana no meio de um roadmap, ele
   escreve um arquivo que o board exibe. O agente não decide no lugar do humano por falta de canal.

## Consequences

**Positivas**

- O agente opera com estado durável fora da janela de contexto, e trabalho sobrevive à sessão.
- O `validate` vira gate objetivo para trabalho gerado por agente, em vez de revisão por leitura.
- A ADR com alternativas recusadas economiza o ciclo mais caro que existe com agente: reimplementar
  o que já foi descartado, com argumentos plausíveis.

**Negativas, e assumidas**

- **O artefato vira dependência de execução.** Se o `context` mente, o agente age sobre o estado
  errado com convicção total. É por isso que vacuidade — regra que avalia denominador reduzido e
  devolve verde — é mais grave neste produto que num CLI comum: aqui o consumidor não desconfia.
- **Cerimônia antes de código.** REQ e ROADMAP antes da branch custam tempo em mudança trivial, e a
  regra convida a burlar. As exceções precisam ser explícitas, ou viram exceção implícita.
- **Formalizar convida a otimizar para o agente**, e o artefato tem dois leitores. Um frontmatter
  perfeito para parsing e ilegível para humano falharia no propósito.
- Acoplamento com o formato de cada ferramenta de agente, que muda sem aviso — custo recorrente já
  materializado na ADR de subcomando nativo por ferramenta.

## Alternatives Considered

**Deixar o padrão implícito.** Era o estado de 2026-06-13: funcionava, e os agentes já usavam a
cadeia. Recusada porque o que funciona por acidente quebra sem aviso — nada garantia que o
frontmatter continuasse parseável, e não havia comando de contexto: cada agente varria o repositório
e **inferia**, com resultado diferente por agente.

**Uma camada de API/MCP em vez de artefato em disco.** Recusada: o artefato em disco é versionado,
revisável em PR, e legível pelo humano sem ferramenta. Uma API entrega o estado ao agente e o retira
do controle de versão, que é onde a governança precisa estar.

**Um formato próprio, otimizado para LLM.** Recusada pelo segundo leitor: o artefato é lido por quem
decide. Markdown com frontmatter YAML é o compromisso — parseável por máquina e legível por humano
sem tradução.

**Importar a `ADR-001` do upstream para resolver o link quebrado.** Recusada pela
`ADR-2026-08-29`: a governança do upstream não é importada. Registrar a decisão do nosso lado
mantém a fronteira e produz um documento que fala do **nosso** uso.

## REQs governadas por esta decisão
- REQ-2026-06-13-trackfw-ai-agent-governance-rail
