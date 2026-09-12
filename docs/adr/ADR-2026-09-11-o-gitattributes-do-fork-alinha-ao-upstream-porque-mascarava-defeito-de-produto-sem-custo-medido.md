---
status: Accepted
date: 2026-09-11
author: claude
---

# ADR: o `.gitattributes` do fork alinha ao do upstream — ele mascarava defeito de produto, e alinhar não tem custo medido

## Context

O `.gitattributes` deste fork carregava um bloco próprio, de 2026-08-16
(`REQ-2026-08-16-consistencias-template-saida-e-eol`), que força `eol=lf` em `*.md`, `*.json`,
`*.toml`, `*.yml`, `*.html`, `*.css` e outros, com `* text=auto` por cima.

O do upstream força LF **só nos fontes** e exclui o resto **de propósito, com medição escrita**: os
assets de integração e os goldens são entrada que o produto parseia, e o parser de frontmatter não
lida com CRLF. Forçar LF ali esconde o defeito em vez de curá-lo.

**Efeito medido:** 9 das 38 entradas do `.github/windows-known-failures.json` **não falham** aqui,
enquanto falham no CI do upstream. Idênticas por nome nos runs `34660260112` e `34659208572`.

A `ADR-2026-08-29` classificava este arquivo como **local**, "configuração deste repositório", ao
lado do `trackfw.yaml`. A medição derruba a premissa: ele **não é inerte** para o produto.

## Decision

**Opção A — alinhar ao do upstream, byte a byte.** O bloco local de 2026-08-16 sai inteiro.

E, como emenda à `ADR-2026-08-29`: o `.gitattributes` **deixa de ser classificado como local** e
passa a **upstream**, pelo mesmo critério das outras linhas daquela tabela — arquivo cujo conteúdo
muda o comportamento do produto não é configuração deste repositório.

## Consequences

**O que a medição sustenta, e é por isso que A vence C:**

| medida | resultado |
|---|---|
| AC1 — arquivos que mudam de fim de linha (1211 rastreados) | A move 526 · C move 346 |
| AC1 — entradas que o produto parseia (238) | sob A e sob C, voltam a `unspecified` |
| AC2 — gates locais e `validate` com **180 de 180** docs em CRLF | **9 gates rc=0 e `validate` limpo** |

🔴 **A opção C existia para evitar um custo que não existe.** Ela manteria `docs/**` e `vault/**` em
LF ao preço de uma divergência permanente num arquivo compartilhado — e toda divergência assim é paga
por cada merge futuro. Com o AC2 verde, ela compra proteção contra um dano medido como zero.

**Por que não B (manter):** mascara defeito de produto do upstream com configuração local, que é
exatamente a classe que esta ADR nomeia.

**Residual declarado:** no Windows, `docs/**` passa a chegar em CRLF no checkout. Medido inofensivo
para os 9 gates locais e para o `validate`. O `.trackfw-log` mantém `merge=union`, que já vem do
arquivo do upstream.

**Verificação exigida:** depois desta decisão, as 9 entradas têm de **falhar** no nosso
`windows-full-suites`, e o ratchet passa a observar 38 de 38. Enquanto isso não for observado em CI,
a decisão está aplicada mas não provada.

## Alternatives Considered

- **C — `eol=lf` só em `docs/**` e `vault/**`.** Recusada pela medição do AC2, acima.
- **Remédio de uma linha** (`internal/integrations/testdata/** text eol=lf`): falsificado no ML-0A da
  REQ dos baselines — os goldens ficaram LF e as entradas continuaram falhando, porque o renderizador
  lê os assets (`//go:embed assets`), não só os goldens.
