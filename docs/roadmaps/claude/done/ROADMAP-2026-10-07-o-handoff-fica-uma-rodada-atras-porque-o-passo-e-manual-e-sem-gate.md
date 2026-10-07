---
status: done
date: 2026-10-07
req: "REQ-2026-10-07-o-handoff-fica-uma-rodada-atras-porque-o-passo-e-manual-e-sem-gate"
squad: "claude"
---

# Roadmap: o handoff fica uma rodada atras porque o passo e manual e sem gate

> Created: 2026-10-07 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-10-07-o-handoff-fica-uma-rodada-atras-porque-o-passo-e-manual-e-sem-gate.md

Ver a REQ. Em uma frase: **o passo 3 do Agent Protocol falhou duas vezes em 24 h, e nos dois casos
quem pegou foi o usuario** — o `validate`, o `barrier` e os catorze gates ficaram verdes.

## Acceptance Criteria

- [x] AC1 a AC6 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model do gate do handoff
**Status:** ✅ Concluído
**Files affected:** nenhum (medicao e decisao)
**Actions:**

**1. A enumeracao esta fechada?** Os passos obrigatorios do `CLAUDE.md` sem instrumento, derivados do
proprio arquivo: a atualizacao do handoff (este), o `trackfw context` antes de comecar (nao deixa
rastro no diff — nao e verificavel), e a reversao dos shims (ganhou gate ontem). **Um passo
obrigatorio com assinatura no diff e sem gate: este.**

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem comparar por **dois pontos**
(`main..HEAD` ou `HEAD..origin/main`) em vez de ancorar na base de merge. É a terceira vez que o
dois-pontos engana neste fork — a ultima reprovou o PR #192 com a divergencia real em zero. E quem
cobrar entrada em **todo** PR: sync, correcao de gate e documentacao nao fecham ciclo, seriam cobrados
a esmo, e o gate acabaria desligado.

**3. Falsificacao nas duas direcoes, e com artefato REAL.** O diff da PR #208 (moveu roadmap para
`done/`, nao tocou o handoff) tem de **reprovar**; o da #207 (tocou o handoff, nao moveu roadmap) tem
de **passar**. Os dois existem no historico; nenhum caso sintetico substitui isso, porque a #208 e
exatamente o que escapou.

**4. Residuo declarado.** O gate verifica **presenca**, nao conteudo: um PR que toque o arquivo com
uma linha vazia passa. Qualidade de texto nao e verificavel por gate, e fingir que e produziria
falso-verde pior que a ausencia. E o *"ao iniciar"* da mesma exigencia fica fora: inicio de ciclo nao
tem assinatura no diff, e inventar uma daria gate que reprova por adivinhacao.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita neste ML

**Gates da wave:**
```bash
test "$(git diff --name-only $(git merge-base 2a97172e 24938d28) 2a97172e | grep -cE 'docs/roadmaps/.*/done/')" -ge 1
```

## Wave 1 — O gate e a entrada que faltava
> Dependencies: Wave 0

### ML-1A — `check-handoff-cobre-o-ciclo.sh`, a declaracao e a entrada atrasada
**Status:** ✅ Concluído
**Files affected:** `scripts/check-handoff-cobre-o-ciclo.sh`, `scripts/run-local-gates.sh`, `docs/agents-working-context.md`, `CLAUDE.md`
**Actions:**
1. Gate novo: ancora na base de merge contra `origin/main`, procura roadmap entrando em `done/` e
   exige o `docs/agents-working-context.md` no mesmo diff.
2. Guardas: ref de comparacao ausente reprova nomeando o motivo; diff vazio passa **dizendo** que foi
   por vacuidade.
3. `--self-test` com os dois casos reais, por SHA, mais os de borda.
4. Declarar em `EXECUTAR` do `run-local-gates.sh`.
5. Escrever no `docs/agents-working-context.md` a entrada que faltou — a frente do alarme — e a desta.
6. Uma linha no `CLAUDE.md` dizendo que o passo 3 agora tem instrumento, sem apagar a exigencia.

**Acceptance criteria:**
- [x] AC1 a AC6 da REQ
- [x] O diff da #208 reprova e o da #207 passa, por SHA, no `--self-test`
- [x] `run-local-gates.sh` com a completude fechada e o novo gate executado
- [x] Este proprio PR passa o gate novo — ele move roadmap para `done/` e toca o handoff

**Gates da wave:**
```bash
bash scripts/check-handoff-cobre-o-ciclo.sh --self-test
grep -q 'check-handoff-cobre-o-ciclo.sh' scripts/run-local-gates.sh
test "$(git log -1 --format=%H -- docs/agents-working-context.md)" != ""
```

## Medicao do ML-1A

```
--self-test        8 caso(s) · 0 falha(s) · 2 real(is)
  2a97172e  #208 (alarme)   done=1 handoff=0  -> REPROVA
  8415b22e  #207 (entrada)  done=0 handoff=1  -> passa
este proprio PR    done=1 handoff=1 -> passa (prova de ponta a ponta)
run-local-gates    15 executado(s) · 0 falha(s)   (eram 14)
handoff            75 adicoes, ZERO remocoes
CLAUDE.md          3 adicoes, ZERO remocoes — a exigencia fica, ganha a linha do gate
```

🔴 **A guarda de vacuidade do self-test tem DOIS niveis** — o total e os casos reais em particular.
Sem o segundo, perder os dois SHAs deixaria o gate verde sobre so os sinteticos, que sao exatamente
os que nao pegaram o defeito na vida real.
