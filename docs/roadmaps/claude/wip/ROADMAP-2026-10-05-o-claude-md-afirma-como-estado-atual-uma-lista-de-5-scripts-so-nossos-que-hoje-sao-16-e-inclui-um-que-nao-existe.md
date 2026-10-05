---
status: wip
date: 2026-10-05
req: "REQ-2026-10-05-o-claude-md-afirma-como-estado-atual-uma-lista-de-5-scripts-so-nossos-que-hoje-sao-16-e-inclui-um-que-nao-existe"
squad: "claude"
---

# Roadmap: o CLAUDE.md afirma como estado atual uma lista de 5 scripts so nossos que hoje sao 16 e inclui um que nao existe

> Created: 2026-10-05 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-10-05-o-claude-md-afirma-como-estado-atual-uma-lista-de-5-scripts-so-nossos-que-hoje-sao-16-e-inclui-um-que-nao-existe.md

Ver a REQ. Em uma frase: **o `CLAUDE.md` afirmava em presente uma lista de 5 scripts que hoje são 16 e
que incluía um apagado há três semanas — e mais duas citações de linha que já não batem.**

## Acceptance Criteria

- [x] AC1 a AC5 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model da correção de documentação
**Status:** ✅ Concluído
**Files affected:** nenhum (medição e decisão)
**Actions:**

**1. Enumeração: que outras afirmações deste arquivo são falsificáveis?** Derivadas e testadas uma a
uma — lista de scripts só-nossos, divergência de produto, contagem da governança do upstream, censo do
lint de SO, acervo do kanban, dois gates com denominador publicado, ratchet de Windows, as quatro
citações de linha, e o estado do `jq`. **Treze afirmações, três erradas.**

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem **trocar a lista de 5 por uma lista de
16**. Fica certo hoje e errado no próximo script — exatamente o mecanismo que produziu o defeito.
A saída é a derivação, com o `run-local-gates.sh` como guarda.

**3. O risco do remédio.** Apagar as seções velhas "para limpar" destrói o registro de por que cada
guarda existe. Este arquivo tem três precedentes de aposentar afirmação **mantendo a medição que a
aposentou**; a correção segue essa forma.

**4. Resíduo declarado.** Os números datados continuam envelhecendo — nenhum gate os verifica. O que
este ML entrega é a **data ao lado do número**, para que o leitor saiba que está lendo um registro, e
a troca de enumeração por derivação onde havia como derivar. Um gate que verificasse números de prosa
seria outro escopo.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência
      ✅ (1) treze afirmações enumeradas e testadas, três erradas; (2) o esvaziador nomeado —
      trocar a lista de 5 por uma de 16, que erra no próximo script; (3) risco do remédio: apagar
      seção velha destrói o registro de por que a guarda existe, e há três precedentes de
      aposentar mantendo a medição; (4) resíduo: nenhum gate verifica número em prosa.
- [x] Nenhuma linha do `CLAUDE.md` alterada neste ML
      ✅ o ML-0A é medição e decisão; as edições estão todas no ML-1A.

**Gates da wave:**
```bash
test "$(git ls-tree -r --name-only upstream/main -- scripts | wc -l)" -gt 0
```

## Wave 1 — Correção
> Dependencies: Wave 0

### ML-1A — A lista vira derivação, e as citações de linha viram âncoras
**Status:** ✅ Concluído
**Files affected:** `CLAUDE.md`
**Actions:**
1. Substituir a lista enumerada pela derivação, com o registro do defeito e da janela.
2. Trocar `check-validate-rule-pins.sh:599` e `Makefile:58,60,61` por âncora de símbolo.
3. Pôr a medição de hoje ao lado de cada número datado, sem apagar o antigo.
4. Marcar a seção do `jq` como resolvida **nesta máquina**, com a medição e o limite.
**Acceptance criteria:**
- [x] AC1 a AC5 da REQ
      ✅ `validate` **0 violações · 3 avisos**; `check-gates-uma-linha-por-comando` 40 comandos;
      `check-req-marcador-ancorado` 0 só em prosa; e os dois gates de wave verdes, incluindo o que
      limita `check-subcommand-parity` a no máximo 2 ocorrências — hoje exatamente 2, ambas na nota
      que registra a retirada.
**Gates da wave:**
```bash
test "$(grep -c 'check-subcommand-parity' CLAUDE.md)" -le 2
```
