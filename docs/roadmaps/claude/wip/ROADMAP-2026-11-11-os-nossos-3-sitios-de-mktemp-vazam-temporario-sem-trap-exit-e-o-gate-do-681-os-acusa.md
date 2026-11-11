---
status: wip
date: 2026-11-11
req: "docs/requisições/claude/REQ-2026-11-11-os-nossos-3-sitios-de-mktemp-vazam-temporario-sem-trap-exit-e-o-gate-do-681-os-acusa.md"
squad: "claude"
---

# Roadmap: os nossos 3 sitios de mktemp vazam temporario sem trap EXIT e o gate do 681 os acusa

> Created: 2026-11-11 | Status: wip

## Context
<!-- Derived from REQ: REQ-2026-11-11-os-nossos-3-sitios-de-mktemp-vazam-temporario-sem-trap-exit-e-o-gate-do-681-os-acusa.md -->
REQ: docs/requisições/claude/REQ-2026-11-11-os-nossos-3-sitios-de-mktemp-vazam-temporario-sem-trap-exit-e-o-gate-do-681-os-acusa.md

O sync do `356fb79b` e o conserto dos 3 sítios vão **no mesmo PR**, e isso não é conveniência: um
PR que trouxesse só o sync nasceria **vermelho** no `parity-other-gates`, e um que trouxesse só o
conserto não teria o gate em árvore para provar nada. A ordem interna importa — o sync primeiro,
porque é ele que põe o instrumento no lugar.

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [ ] AC1 a AC8 da REQ vinculada, um a um, com medição ao lado de cada
- [ ] o veredito final é do gate **em árvore**, nunca da cópia que usei no scratchpad para prever

## Status Legend
⬜ Pending · 🔄 In progress · ✅ Done · ❌ Blocked

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Done
**Files affected:** nenhum (medição; nenhuma linha de implementação)
**Actions:**
1. **Completude da enumeração.** Não me limitei aos 3 arquivos que o gate acusou: varri
   `mktemp` nos **23** scripts que só existem neste fork (derivados por
   `git cat-file -e upstream/main:<f>`, não por lista à mão). São **9** ocorrências:

   ```
   3 ACUSADOS, sem trap   anexa-crlf:110 · check-contorno-dos-shims-caducou:223
                          check-copia-do-path-esta-atras:164
   5 COBERTOS, com trap   check-platform-predicates:24 · check-req-done-caducou-falsify:76
                          check-roadmap-done-com-ml-pendente:58
                          measure-os-predicate-sites:84 · run-local-gates:108
   1 PROSA                run-local-gates:78 — a justificativa do FORA, nao codigo
                                                                    3+5+1 = 9 ✓
   ```

   🔴 **E a varredura corrigiu o MEU classificador, não o dele.** O meu regex exigia `=$(mktemp`
   sem aspas e leu `WORK="$(mktemp -d)"` e `tmp="$(mktemp -d)"` como *"sem atribuição"* — 2 falsos
   em 3. O gate dele parseia a forma com aspas e **não** acusou nenhum dos dois, que têm trap.
   A lista está **fechada em 3**, e o padrão a copiar já existe aqui:
   `TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT`.

2. **Threat model — quem esvazia esta Wave 0 sem quebrar regra escrita?**
   - **T1.** Pôr o `trap` e deixar o `rm` explícito do caminho normal: o `rm` roda, o trap roda
     depois sobre diretório que já não existe. `rm -rf` de inexistente sai 0, então **não** quebra
     — mas se alguém trocar por `rmdir`, quebra. Mitigação: manter `rm -rf` e silenciar.
   - **T2.** O trap altera o código de saída do script e um gate passa a sair 0 por acidente.
     É o modo de falha **caro**, porque produz verde falso. Vira o AC3, medido nas duas direções.
   - **T3.** Com `set -u`, o trap dispara antes da atribuição e morre em variável não vinculada.
     Mitigação: citar `${V:-}`, que é uma das quatro formas que o gate aceita como DIRECT.
   - **T4.** Nos dois sítios em que o `mktemp` pode falhar (`|| TMPP=""`), o trap recebe string
     vazia e `rm -rf ""` erra. Mitigação: `2>/dev/null || :`, que preserva a citação de `${V:-}`.
   - **T5.** 🔴 **Declarar o conserto medindo o caminho feliz** — exatamente o que aconteceu na
     primeira sonda, que deu `0 vazado` porque o `rm` do fim rodou. Mitigação: o AC2 fixa o
     instrumento (vigiar o `TMPDIR`, matar pelo PID), e a medição pré-conserto fica como controle.

3. **Falsificação nas duas direções, por sítio.** Regressão: tirar o `trap` e o gate volta a
   acusar aquele arquivo (e só aquele). Regressão oposta: pôr um `trap` que **não** cita a
   variável e o gate continua acusando — é o que distingue "tem trap" de "tem trap que cobre".
   Os dois braços são verificáveis com o gate em árvore, por arquivo.

4. **Residual declarado.** Os residuais **R1 a R4 do gate dele** (trap em subshell de
   `d=$(fn)`, reatribuição em laço, `exec` substituindo o shell, indireção de dois níveis)
   continuam fora de alcance — e nenhum dos nossos 3 sítios cai neles, conferido: os três são
   atribuição direta em escopo **global** dentro de um `if`, com as funções já fechadas antes.
   Fora de alcance também: `mktemp` em script **não** rastreado, porque o gate varre
   `git ls-files`.

**Acceptance criteria:**
- [x] The four sections above answered with evidence, not a one-line assertion
- [x] No implementation line written for this ML

**Wave gates:**
```bash
grep -q 'T=$(mktemp -d) || exit 1' scripts/anexa-crlf.sh
grep -q 'TMPP=$(mktemp -d 2>/dev/null) || TMPP=""' scripts/check-contorno-dos-shims-caducou.sh
grep -q 'TMPD=$(mktemp -d 2>/dev/null) || TMPD=""' scripts/check-copia-do-path-esta-atras.sh
```

## Wave 1 — Implementation (derived from REQ criteria)
> Dependencies: Wave 0.

### ML-1A — Sync do `356fb79b`: traz o gate e os 7 sítios dele consertados
**Status:** ✅ Done
**Files affected:** `Makefile`, `scripts/` (7 alterados + 1 novo), `bin/`
**Actions:**
1. `scripts/upstream-sync.sh`, que retém `docs/`, `vault/` e o `trackfw.yaml`, prova a retenção
   por efeito e aborta se não puder provar.
2. Conferir que os 2 conflitos previstos pelo `git merge-tree --write-tree` — os dois
   `modify/delete` em `docs/req/` e `vault/notes/index.md` — foram resolvidos **por retenção**, e
   que o conflito de **produto** é zero.
3. Não commitar nem empurrar neste ML: o conserto vem antes do push, senão o push nasce vermelho.
**Acceptance criteria:**
- [x] AC5 — retenção provada por efeito, zero conflito de produto
- [x] o gate novo existe em `scripts/check-mktemp-cleanup.sh` e o `--self-test` passa **aqui**
- [x] `go build ./...` sai 0 e o `bin/` é conferido pela **execução**, não pela existência

**Medido:**

```
previsto   PRODUTO 9 (Makefile + 8 scripts) · RETIDO 10 (docs 8 + vault 2)   = 19
o script   "9 de PRODUTO, 10 RETIDOS (de 19 no merge)"        <- exato, nome a nome
o falsificador nomeado (caminho fantasma por deteccao de renomeacao)  NAO disparou
retencao por efeito      0 de 5 arquivos dele amostrados presentes (indice ou disco)
invariante               0 caminho de docs/ ou vault/ no indice · staged = 9
go build ./...           exit 0        validate  0 antes · 0 depois
bin/ pela EXECUCAO       "trackfw 11.7.0"  rc=0
gate em arvore           --self-test  32 passed / 0 failed
gate sobre a nossa       rc=1 · 3 achados · 3 arquivos · TODOS nossos · 0 dele
```

🔴 **A última linha é a previsão do PR fechando exata** — os 7 arquivos dele que o gate acusava
antes do sync chegaram **consertados**, e sobraram só os nossos 3. Se tivesse acusado algum dele, o
#681 não teria fechado o que diz ter fechado.

### ML-1B — Limpeza garantida nos 3 sítios nossos
**Status:** ⬜ Pending
**Files affected:** `scripts/anexa-crlf.sh`, `scripts/check-contorno-dos-shims-caducou.sh`, `scripts/check-copia-do-path-esta-atras.sh`
**Actions:**
1. Um `trap` de EXIT por sítio, imediatamente após o `mktemp`, citando `${V:-}` (forma DIRECT do
   gate) e tolerando string vazia.
2. Manter o `rm` explícito do caminho normal — T1 do threat model.
3. Provar o fechamento por efeito com o instrumento do AC2, e provar o AC3 nas duas direções.
**Acceptance criteria:**
- [ ] AC1 — gate em árvore `rc=0`, `0 achados`, denominador impresso
- [ ] AC2 — vazamento fechado por efeito nos 3, com a medição pré-conserto como controle
- [ ] AC3 — código de saída intacto, medido nas duas direções

**Wave gates:**
```bash
bash scripts/check-mktemp-cleanup.sh --self-test
bash scripts/check-mktemp-cleanup.sh
```

## Wave 2 — Red team
> Dependencies: Wave 1.

### ML-2A — Leitura adversarial antes do PR
**Status:** ⬜ Pending
**Files affected:** nenhum (revisão)
**Actions:**
1. Confrontar cada teste/medição nova com a conclusão do próprio relatório — a Regra Dura de
   Reconciliação: toda afirmação entregue tem de sustentar uma conclusão medida aqui.
2. Procurar verde pelo motivo errado: gate que passa por premissa ausente, `rc` lido depois de
   cano, contagem digitada ao lado de um `rc` medido.
3. Conferir que nenhuma afirmação em **presente** entrou no handoff ou no `CLAUDE.md`.
**Acceptance criteria:**
- [ ] AC6 — `validate` 0 violações, avisos **derivados** da saída
- [ ] AC7 — `run-local-gates.sh` sobre a árvore final, com denominador
- [ ] AC8 — handoff carregando o que não se deriva

**Wave gates:**
```bash
./bin/trackfw validate
```
