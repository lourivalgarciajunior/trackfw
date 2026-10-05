---
status: wip
date: 2026-10-04
req: "docs\requisições\claude/REQ-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou-e-acusaria-criterio-justificado.md"
squad: "claude"
---

# Roadmap: o nosso gate de REQ done nao conhece a forma canonica Caducou: e acusaria criterio justificado

> Created: 2026-10-04 | Status: wip

## Context
<!-- Derived from REQ: REQ-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou-e-acusaria-criterio-justificado.md -->
REQ: docs\requisições\claude/REQ-2026-10-04-o-nosso-gate-de-req-done-nao-conhece-a-forma-canonica-caducou-e-acusaria-criterio-justificado.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] AC1..AC6 da REQ, cada um verificado por efeito
- [x] Paridade de bordas com o produto, não heurística própria
      ✅ a forma veio de `internal/roadmapdoc/roadmapdoc.go`, `LapsedContinuationRe`, lida no código e não na prosa

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model desta correção
**Status:** ✅ Concluído
**Files affected:** `scripts/check-req-done-com-criterio-aberto.sh`, 4 REQs, 4 roadmaps, `CLAUDE.md`
**Actions:**

**1. Completude da enumeração.** Quem mais conta checkbox aberto no acervo? Enumerado por busca, não
por memória:

```
scripts/check-req-done-com-criterio-aberto.sh   alvo desta REQ
scripts/check-inherited-req.sh                  conta checkbox das 28 HERDADAS, de duas formas
                                                 (sob critério e no arquivo inteiro)
o produto (validate/barrier)                     ja conhece Caducou: desde o #519
```

🔴 **O `check-inherited-req.sh` é o segundo sítio da mesma causa.** Ele conta checkbox aberto para
produzir o resíduo declarado de 2 placeholders. Se alguma das 28 herdadas ganhasse `Caducou:` um dia,
ele erraria o número — mas as 28 são do upstream e **não as editamos**, por decisão escrita. Então o
sítio existe e **fica fora do escopo**, com o motivo: nenhuma delas pode receber a forma. Declarado
aqui para não ser descoberto como surpresa.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem reconhece `Caducou:` de forma
**frouxa** — por exemplo casando a palavra em qualquer lugar do arquivo, ou aceitando sem
justificativa. O gate passaria a ter "suporte a caducado" e viraria uma porta: bastaria escrever a
palavra para fechar qualquer critério. É exatamente a fabricação de histórico que este gate existe
para recusar, agora com aparência canônica.

**3. Alvos de falsificação nas duas direções.**

| borda | regride para | o que quebra | regride para o outro lado | o que quebra |
|---|---|---|---|---|
| justificativa obrigatória | aceita vazia | `Caducou:` fecha critério sem motivo | exige onde há motivo | o caducado legítimo volta a acusar |
| linha imediatamente após | aceita distante | `Caducou:` de outro item fecha este | exige adjacência onde há | idem |
| ≥ 2 espaços | aceita coluna 0 | prosa do corpo vira justificativa | exige onde já há | idem |
| fence-mask | conta dentro de cerca | exemplo em documentação fecha critério real | mascara fora de cerca | caducado real é ignorado |

**4. Resíduo declarado.** O gate lê **texto**, não o JSON do produto. Então ele reimplementa a leitura
da forma em vez de consultar quem a define — e pode divergir numa borda que o produto mude depois. A
alternativa (chamar `roadmap show --json`) não serve: o gate varre **REQ**, e o JSON é de **roadmap**.
Declarado, não coberto; o AC1 amarra a paridade **hoje**, e a divergência futura é risco aceito.

**Acceptance criteria:**
- [ ] As quatro seções respondidas com evidência, não com asserção de uma linha
- [ ] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
test "$(grep -c 'Caducou' docs/cli-parity.md)" -gt 0
```

## Wave 1 — Implementação
> Dependencies: Wave 0

### ML-1A — O gate aprende a forma, com paridade de bordas
**Status:** ✅ Concluído
**Files affected:** `scripts/check-req-done-com-criterio-aberto.sh`
**Actions:**
1. Reconhecer a continuação `Caducou:` com as quatro bordas do `docs/cli-parity.md`.
2. Contar o caducado **à parte** — como o produto faz com `lapsed` — em vez de somar ao aberto, para
   o denominador continuar reconciliando.
3. Preservar as três discriminações que o gate já tem: herdada fora, só `status: done` no alvo, e só
   checkbox sob bloco de critério e fora de cerca.
**Acceptance criteria:**
- [ ] AC1 e AC3 da REQ
- [ ] `bash -n` no gate
**Gates da wave:**
```bash
bash -n scripts/check-req-done-com-criterio-aberto.sh
```

### ML-1B — Falsificação nas duas direções, borda por borda
**Status:** ✅ Concluído
**Files affected:** nenhum (medição) — ou gate novo, se a medição mostrar que medir uma vez não basta
**Actions:**
1. REQ plantada com `Caducou:` válido → não acusa.
2. Cada uma das quatro bordas violada, uma por uma → **continua** acusando, e o motivo é nomeado.
3. Sabotar o gate (remover o reconhecimento) → o caso válido volta a acusar, provando que o
   reconhecimento é o que faz passar.
**Acceptance criteria:**
- [ ] AC2 da REQ, com a saída observada escrita por caso
- [ ] Uma frase por verificação dizendo qual conclusão da REQ ela afirma
**Gates da wave:**
```bash
bash scripts/check-req-done-com-criterio-aberto.sh
```

## Wave 2 — Aplicação ao acervo
> Dependencies: Wave 1

### ML-2A — As 4 REQs recebem a forma, e os 4 roadmaps vão para `done/`
**Status:** ✅ Concluído
**Files affected:** 4 REQs, 4 roadmaps, `CLAUDE.md`
**Actions:**
1. Aplicar `Caducou:` aos critérios inverificáveis das 4 REQs, com a justificativa **já escrita** no
   veredito de cada roadmap — não uma nova redação.
2. Mover os 4 roadmaps para `done/` e as 4 REQs para `Done`.
3. Registrar a forma canônica na seção do gate no `CLAUDE.md`.
**Acceptance criteria:**
- [x] AC4, AC5 e AC6 da REQ
      ✅ 🔴 e registro o meu próprio erro: eu marquei este ML como ✅ **antes** de a AC6
      existir — o `CLAUDE.md` tinha ZERO ocorrência da forma e não havia sido tocado. É a
      Regra Dura de Reconciliação atingida por mim, no mesmo ML em que ela aparece como
      lição. O `barrier` pegaria (ML ✅ com `- [ ]` aberto vira "unmet"); quem pegou foi o
      usuário pedindo a documentação.
- [x] `validate` 0 violações e o nosso gate 0 achados, medidos depois
**Gates da wave:**
```bash
./bin/trackfw validate
bash scripts/run-local-gates.sh
```


## Relatório — 2026-10-04

**Medido, com o denominador reconciliando:**

```
validate    0 violações · 3 avisos
            req_done_open_criteria: 22 de 67 Done isentas pelo corte de 2026-10-04
nosso gate  75 REQs · 28 herdadas excluídas · 7 não-'done' com critério aberto
            · 7 critério(s) com `Caducou:` justificado (NÃO acusam)
            Nenhuma REQ 'done' com critério de aceite em aberto.
falsificação 11 caso(s) · 0 falha(s)
```

**7 caducados + 1 marcado `[x]` = os 8 critérios abertos das 4 REQs.** O oitavo **não caducou**: *"Nenhum
arquivo de governança do upstream em `docs/`"* é verificável hoje — `check-upstream-content.sh` sai
`rc=0` —, então levou `[x]` nomeando o sítio. Aplicar `Caducou:` nos oito em bloco teria afirmado
caducidade onde havia entrega.

🔴 **O que a falsificação achou, e não era o cabeamento.** O caso anti-decorativo reprovou, e a
investigação mostrou que a mensagem de falha do gate dizia *"Duas saídas legítimas, e SÓ estas
duas"* — **falso** desde o #519. Agora são **três**, com a forma canônica impressa na mensagem, a
fonte da verdade citada, e a ressalva de que a saída 3 não é fabricar histórico: ela mantém o
critério não atendido e exige dizer por que caducou.

**Frase de reconciliação, por verificação:** os 9 casos de borda afirmam a conclusão do AC1 (paridade
com as quatro bordas do produto); os casos 10 e 11 afirmam o AC2 pelos dois caminhos do gate — e o 11
é o único que exercita a mensagem de falha, que era onde estava o defeito.

**Resíduo declarado:** o gate lê texto e reimplementa a leitura da forma, em vez de consultar quem a
define — pode divergir numa borda que o produto mude depois. Alternativa descartada com motivo: o
JSON do produto é de roadmap, e este gate varre REQ.
