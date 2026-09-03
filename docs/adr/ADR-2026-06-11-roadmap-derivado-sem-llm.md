---
status: Accepted
date: 2026-06-11
author: apolo
---

# ADR: Roadmap é derivado da REQ deterministicamente, não gerado por LLM

> Date: 2026-06-11 | Status: Accepted

REQ: REQ-roadmap-ai-generation-2026-06-11

> **Reconstrução retroativa, escrita em 2026-08-16 — e esta ADR diverge do que a REQ pediu.**
>
> `REQ-roadmap-ai-generation-2026-06-11` está marcada `status: done` e especifica um pacote
> `internal/ai/` com clientes Anthropic e OpenAI, `anthropic-sdk-go` no `go.mod`, seleção de
> provider e fallback por chave de API. **Nada disso existe no repositório.** Verificado em
> 2026-08-16: não há diretório `internal/ai/`; não há nenhuma menção a `anthropic` ou `openai` em
> código Go; o `go.mod` não tem dependência de IA; não há tratamento de chave de API em lugar
> nenhum. O roadmap correspondente está em `done/` com **todos os MLs `⬜ Pendente`**.
>
> O que existe é `roadmap new --from-req`, presente nos três runtimes, que deriva os MLs dos
> critérios de aceite da REQ sem chamar modelo nenhum. Esta ADR registra a decisão que o código
> sustenta. Ver `REQ-2026-08-16-adrs-retroativas`.

## Context

`trackfw roadmap new` gerava um template vazio. O pedido original era preencher esse template por
IA: o usuário escolhe uma REQ, um LLM lê os critérios de aceite e escreve os microlotes com
paralelização prevista.

O trackfw é um gate de governança. Roda em pre-commit e em CI, e sua saída entra no repositório como
artefato versionado. Isso impõe três restrições que a proposta original não atendia:

- **Reprodutibilidade.** Dois desenvolvedores rodando o mesmo comando na mesma REQ precisam obter o
  mesmo roadmap. Um LLM não garante isso.
- **Funcionar offline e sem credencial.** Um gate que depende de chave de API falha em máquina nova,
  em CI sem secret e em rede fechada — exatamente onde ele mais precisa funcionar.
- **Dependência zero.** O runtime Python é stdlib-only por decisão, e o Go tinha um grafo de
  dependências enxuto. Um SDK de IA quebraria os dois.

## Decision

O roadmap é derivado da REQ **deterministicamente**. `roadmap new --from-req <path>` lê a seção de
critérios de aceite da REQ e emite um stub de ML por critério — título, `**Status:** pending`,
arquivos afetados, ações e critérios de aceite — mais o link de volta para a REQ e a ADR, quando
houver.

Nenhuma chamada de rede, nenhuma chave, nenhuma dependência externa. O parsing vive em
`parseREQForRoadmap` (Go), `parseReqForRoadmap` (Node.js) e `_parse_req_for_roadmap` (Python), com
saída idêntica nos três.

O preenchimento do conteúdo dos MLs continua sendo trabalho de quem implementa — assistido por IA
fora do CLI, se a pessoa quiser. O trackfw entrega o esqueleto rastreável; não escreve o plano.

## Consequences

**Positivas.** O comando funciona em qualquer máquina, offline, sem configuração. A saída é
reprodutível e revisável em diff. Os três runtimes conseguem produzir exatamente o mesmo arquivo — o
que é verificável, e é verificado: a paridade de `--from-req` tem teste nos três.

**Negativas.** O roadmap gerado é um esqueleto, não um plano. Um ML por critério de aceite é uma
heurística grosseira: não infere dependência entre MLs, não sugere ondas de paralelização, e a
qualidade do resultado é inteiramente a qualidade dos critérios da REQ. Quem escreve critério ruim
recebe roadmap ruim, e o comando não avisa.

**Débito registrado.** A REQ ficou marcada `done` para trabalho que não aconteceu, e o roadmap dela
está em `done/` com os MLs pendentes. Isso não é corrigido por esta ADR — é achado de governança
separado, registrado em `REQ-2026-08-16-adrs-retroativas`.

## Alternatives Considered

**Geração por LLM com fallback para template vazio** — a proposta original da REQ. Descartada pelas
três restrições acima: reprodutibilidade, funcionamento sem credencial e dependência zero. O
fallback não resolve: um comando que produz saída diferente conforme haja ou não chave configurada
é pior que um comando com uma saída só.

**Geração por LLM em comando separado** (`trackfw roadmap ai-draft`), isolando a dependência. Mais
honesto que o fallback, e continua viável no futuro. Descartada por ora: o esqueleto determinístico
resolve o caso comum, e um segundo caminho de geração exigiria manter paridade de IA entre três
runtimes — custo alto para ganho incerto.
