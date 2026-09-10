---
status: backlog
date: 2026-09-10
req: "docs/requisições/claude/REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md"
squad: "claude"
---

# Roadmap: baselines de suíte nunca foram versionados, e doze ACs ficaram inauditáveis por construção

> Created: 2026-09-10 | Status: backlog

## Context

REQ: docs/requisições/claude/REQ-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md

**Doze ACs, cinco REQs, uma causa:** o critério exige comparação contra **lista nomeada** de uma
corrida de agosto — 95, 105, 198, 199, 297 falhas — e **nenhuma dessas listas foi versionada**.

Medido hoje: a suíte pypi roda em ~5 min e sai com **15 falhas nomeadas**. O critério é
executável; o que faltava era o ponto de referência existir.

## Acceptance Criteria

- [ ] Listas de falha do pypi e do npm geradas hoje, por nome, versionadas.
- [ ] Gate compara por nome nos dois sentidos: nova **e** sumida.
- [ ] Guarda de vacuidade: suíte que não carrega não é suíte sem falhas.
- [ ] Falsificação nas duas direções.
- [ ] Os doze ACs recebem **(b)**, nenhum marcado como entregue.

## 🔴 Por que este roadmap está parado em `backlog/` — decisão de 2026-09-10

**Não é falta de trabalho pronto, nem dependência interna.** A Wave 0 está desenhada e pode começar
hoje. A espera é **deliberada, e a causa é convergência.**

Em 2026-09-10, poucas horas depois de esta REQ ser aberta, o mantenedor entregou na branch dele:

```
scripts/check-windows-known-failures.py   603 linhas
Makefile                                    +5
"ratchet por nome — lista de 38 vermelhos colhida do run 34478752778"  (ML-2A, #275)
```

**É a mesma solução, para o mesmo problema, escrita no mesmo dia.** Lista de falhas colhida de um run
identificado, versionada, com gate que compara **por nome**. É o que o AC1 e o AC2 desta REQ pedem.

E há mais que pode nos servir: ele já implementou no `quality.yml` a distinção *"suíte que não
carrega"* × *"teste que reprova"* **por tipo de evento** — que é exatamente o AC3 desta REQ, e a
issue [#274](https://github.com/kgsaran/trackfw/issues/274) que levamos a ele.

### A decisão

**Esperar o trabalho dele chegar ao `main`, ler o `check-windows-known-failures.py`, e só então
desenhar o nosso.** Se a solução dele couber aqui, convergimos; se não couber, o motivo fica escrito
e construímos o nosso sabendo o que rejeitamos e por quê.

Construir agora produziria uma **segunda** solução para um problema que já tem uma — e o próximo
merge do upstream teria de reconciliar as duas.

### Condição de retomada, e ela tem gatilho

`upstream/main` receber os commits das branches `fix/ratchet-por-nome-...` e
`fix/fechar-os-grupos-de-falha-de-windows-...`. **A vigia está armada** e avisa quando o `main` dele
mudar — parar sem gatilho não é esperar, é abandonar com outro nome.

### O que NÃO muda enquanto espera

🔴 **Os doze ACs continuam abertos e continuam `(b)` em aberto.** Nenhum é marcado, nenhum é
reescrito. A espera é sobre **como** construir o gate, não sobre o veredito — que já está decidido e
não depende dele.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. **Bloqueia a implementação.**

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ⬜ Pendente
**Files affected:** —
**Actions:**

1. **Enumeração derivada.** Os doze ACs, localizados por varredura das cinco REQs — não pela lista
   desta REQ, que foi escrita à mão. 🔴 O denominador desta classe já saiu errado três vezes esta
   semana, e as três por contagem digitada.

2. **Modelo de ameaça — quem esvazia esta wave sem quebrar regra escrita:**

   | forma | remédio |
   |---|---|
   | gerar o baseline e marcar os doze como entregues | AC5: todos recebem **(b)**; o baseline é novo, o passado não foi verificado |
   | comparar por contagem "porque é mais simples" | AC2 exige os dois sentidos, e o texto do gate diz que saldo zero não é conjunto igual |
   | rodar a suíte, ela não carregar, e gravar baseline vazio | AC3: guarda de vacuidade, e é a distinção da #274 |
   | reescrever o AC de agosto para caber no baseline novo | escopo negativo; é o que a auditoria de hoje desfez em dez REQs |
   | versionar só o pypi porque o npm é lento | AC6: exclusão é **declarada com o motivo medido**, nunca omitida |

3. **Falsificação nas duas direções.** Baseline com uma falha a mais → acusa "sumida"; com uma a
   menos → acusa "nova"; intacto → passa.

4. **Residual declarado.**

**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência
- [ ] Nenhuma linha de implementação escrita neste ML

## Wave 1 — Os baselines

### ML-1A — Gerar e versionar, por nome
**Status:** ⬜ Pendente
**Files affected:** `scripts/testdata/`
**Acceptance criteria:**
- [ ] `pypi` e `npm`, uma falha por linha, ordenado, formato estável
- [ ] O comando que gera fica **escrito no cabeçalho do próprio baseline** — baseline sem receita
      envelhece e ninguém sabe refazer
- [ ] Denominador impresso: quantos testes rodaram, quantos falharam

### ML-1B — O gate
**Status:** ⬜ Pendente
**Files affected:** `scripts/`
**Acceptance criteria:**
- [ ] Compara por **conjunto**: acusa **nova** e **sumida**, separadamente
- [ ] Diz explicitamente que saldo zero não é conjunto igual
- [ ] Falha se a suíte não rodar, se o baseline estiver vazio, ou se o extrator devolver zero nomes
- [ ] 🔴 Falha **sumida** também é achado, não boa notícia: pode ser teste removido, renomeado, ou
      suíte que deixou de carregar

## Wave 2 — Os doze ACs

### ML-2A — Veredito, um por AC
**Status:** ⬜ Pendente
**Files affected:** `docs/requisições/claude/**`
**Acceptance criteria:**
- [ ] Cada um dos doze recebe **(b) não entregue**, apontando para esta REQ
- [ ] 🔴 Nenhum marcado como entregue; nenhum reescrito
- [ ] Fica escrito, por AC, que **a afirmação sobre agosto é irrecuperável**

### ML-2B — Execução
**Status:** ⬜ Pendente
**Files affected:** `scripts/run-local-gates.sh`, `CLAUDE.md`
**Acceptance criteria:**
- [ ] O gate entra no agregador **ou** é declarado fora com o motivo medido
- [ ] 🔴 Se ficar fora por custo, o custo é **medido em segundos**, não estimado — a pypi levou 292s
      hoje, a npm estourou 300s sem terminar

## Residual declarado

- **Um baseline de hoje não valida o passado.** Ele fecha a auditabilidade daqui para a frente. A
  afirmação de agosto morre como não verificada, e isso é o resultado honesto.
- **As 15 falhas do pypi ficam.** São produto do upstream; corrigi-las aqui criaria divergência.
- **Suíte com teste instável move o baseline sozinha.** Um dos ACs de agosto já registrava isso —
  *"a suíte pypi tem teste instável de skew de relógio que move o total sozinho"*. Comparar por nome
  reduz o problema mas não o elimina: um teste instável entra e sai do conjunto. Se aparecer, é
  declarado, não silenciado.
