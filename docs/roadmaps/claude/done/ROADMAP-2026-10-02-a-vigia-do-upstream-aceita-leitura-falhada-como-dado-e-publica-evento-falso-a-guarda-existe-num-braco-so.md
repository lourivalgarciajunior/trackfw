---
status: done
date: 2026-10-02
req: "docs\requisições\claude/REQ-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md"
squad: "claude"
---

# Roadmap: a vigia do upstream aceita leitura falhada como dado e publica evento falso: a guarda existe num braco so

> Created: 2026-10-02 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md -->
REQ: docs\requisições\claude/REQ-2026-10-02-a-vigia-do-upstream-aceita-leitura-falhada-como-dado-e-publica-evento-falso-a-guarda-existe-num-braco-so.md

## Acceptance Criteria
<!-- Consolidated criteria for this roadmap. Detail per ML in the waves below. -->
- [x] AC1..AC6 da REQ, verificados por efeito e não por leitura do código
      ✅ AC1/AC2/AC3/AC5 pelo `check-vigia-forma.sh` (19 casos, 0 falhas) e por duas sabotagens;
      AC4 pelo próprio agregador (`12 executado(s) · 0 falha(s)`); AC6 por inspeção do custo
      declarado no cabeçalho, que não mudou: 0 + 1 + 1 chamadas por ciclo
- [x] A vigia passa a viver em `scripts/`, declarada FORA no agregador com motivo

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model desta correção
**Status:** ✅ Concluído
**Files affected:** `scripts/vigia-do-upstream.sh` (novo), `scripts/run-local-gates.sh`
**Actions:**

**1. Completude da enumeração.** A vigia tem **três** braços de leitura, e a guarda existe em um.
Enumerados lendo o script inteiro, não a REQ:

```
snap_main()  git ls-remote → awk '{print $1}'     sem validacao de forma
snap_prs()   gh api .../pulls --jq                sem validacao de forma   <- o 503 entrou aqui
snap_com()   gh api .../issues/comments --jq      guarda de vazio apenas
```

A lista está fechada: `grep -c 'snap_' ` no script devolve exatamente estes três produtores e seus
usos no laço. **Nenhum outro sítio produz snapshot.** A guarda de `snap_com` cobre *vazio*, não
*forma* — então nem ele está coberto contra corpo de erro não vazio.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem valida **linha por linha e filtra as
ruins**. Passa a ter "validação", o teste de forma fica verde, e o dano 2 (baseline truncado) continua
inteiro — pior, agora escondido atrás de um nome que sugere proteção. Por isso o AC1 exige invalidar o
**snapshot inteiro**.

Segunda forma de esvaziar: validar e, no caminho inválido, **cair para o snapshot anterior como se
fosse leitura nova**. Isso não move a base, mas também não distingue "não li" de "li e nada mudou" —
e some com o sinal de que a vigia está cega. O AC2 exige não comparar **e** não mover; o laço já
trata vazio como "não li".

**3. Alvos de falsificação nas duas direções.**

| braço | regride para | o que quebra | regride para o outro lado | o que quebra |
|---|---|---|---|---|
| `main` | aceita lixo | evento `MAIN mudou: <lixo>` | rejeita hexa válido | commit real nunca é visto |
| PRs | aceita corpo de erro | evento `PR #{"message"` + base envenenada | rejeita linha válida | merge dele nunca é visto |
| comentários | aceita corpo de erro | comentário fantasma | rejeita linha válida | resposta dele nunca é vista |

A coluna da direita é a que o AC3 cobre: sem ela, a correção "segura" é rejeitar tudo.

**4. Resíduo declarado.** A validação é de **forma**, não de **verdade**: um corpo bem-formado e
errado (resposta de outro repositório, por exemplo) passa. Não há como distinguir isso de fora sem
uma segunda fonte, e a vigia tem uma só. Declarado, não coberto.

**Acceptance criteria:**
- [x] As quatro seções acima respondidas com evidência, não com asserção de uma linha
      ✅ e a seção 2 (*"quem esvazia esta Wave 0"*) **previu o defeito que de fato apareceu**: a
      primeira versão do gate validava sem exercitar os braços. Ver ML-1B.
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
test "$(grep -cE '^snap_(main|prs|com)\(\)' scripts/vigia-do-upstream.sh)" = 3
```

## Wave 1 — Implementação
> Dependencies: Wave 0

### ML-1A — Validação de forma por braço, e o script sai do scratchpad
**Status:** ✅ Concluído
**Files affected:** `scripts/vigia-do-upstream.sh` (novo), `scripts/run-local-gates.sh`
**Actions:**
1. Promover o script do scratchpad para `scripts/vigia-do-upstream.sh`, sem mudar o custo de API.
2. Acrescentar um validador por braço, aplicado ao **snapshot inteiro**: hexa de 40 para `main`;
   `^[0-9]+:(MERGED|OPEN|CLOSED)$` para PRs; `^[0-9]+\t[0-9]+\t[^\t]+\t(issue|pull)$` para
   comentários. Qualquer linha fora da forma → snapshot vazio (= leitura que falhou).
3. Declarar o script na lista FORA do `run-local-gates.sh`, com o motivo: é daemon de laço infinito,
   não gate; executá-lo no agregador o penduraria.
4. Remover a dependência de caminho absoluto chumbado (`cd /c/dev/...`), que era aceitável no
   scratchpad e não é num script do repositório: derivar a raiz do próprio caminho do script.
**Acceptance criteria:**
- [x] AC1, AC4 e AC6 da REQ
      ✅ `scripts/vigia-do-upstream.sh`, com `RE_MAIN`/`RE_PRS`/`RE_COM` e `valida_forma` nos três
      braços; raiz derivada de `BASH_SOURCE`, sem caminho chumbado; custo por ciclo inalterado
- [x] `bash -n` no script novo
      ✅ `bash -n` sai 0 nos dois arquivos novos e no agregador alterado
- [x] O agregador continua `0 falha(s)` — é ele que prova o AC4
      ✅ `run-local-gates: 12 executado(s) · 0 falha(s)`, com a vigia aparecendo em
      "declarados FORA, com motivo"
**Gates da wave:**
```bash
bash -n scripts/vigia-do-upstream.sh
bash scripts/run-local-gates.sh
```

### ML-1B — Falsificação nas duas direções, com o corpo de erro real
**Status:** ✅ Concluído
**Files affected:** `scripts/check-vigia-forma.sh` (novo), `scripts/run-local-gates.sh`

🔴 **Desvio do plano, declarado:** este ML previa *"nenhum arquivo (medição)"*. A falsificação virou
**gate** (`check-vigia-forma.sh`, na lista EXECUTAR) porque medição de uma vez não impede a regressão
— e a regressão aconteceu **dentro deste próprio ML**, ver abaixo.
**Actions:**
1. Injetar o corpo de erro real do 503 (`{"message":"...","documentation_url":...}`) em cada um dos
   três braços, via função sobrescrita com `VIGIA_TEST=1`, e provar: zero evento, base inalterada.
2. Provar o outro lado: leitura válida com uma transição → evento emitido **uma vez**; segundo ciclo
   sem mudança → nenhum evento.
3. Provar que comentário de autoria própria continua não virando evento, e que o `comm` continua
   recebendo entrada ordenada na mesma colação.
**Acceptance criteria:**
- [x] AC2, AC3 e AC5 da REQ, cada um com a saída observada escrita no relatório
      ✅ 19 casos, 0 falhas. Casos 1-3: corpo de erro real do 503 não passa em nenhum dos três
      braços. 4-6: leitura válida atravessa intacta. 7: snapshot misto (2 boas + 1 ruim) é
      invalidado **por inteiro**. 8-9: transição real emite uma vez, e sem mudança não emite.
      10-11: comentário de outro autor emite, o nosso não. 12: entrada fora de ordem não inventa
      evento. 13: leitura inválida não move a base; leitura válida move.
- [x] Uma frase por verificação dizendo qual conclusão da REQ ela afirma
      ✅ cada caso do gate tem o rótulo escrito na própria chamada, e o cabeçalho do arquivo diz
      qual medição de 2026-10-01 cada bloco afirma.

🔴 **A primeira versão deste gate era DECORATIVA, e quem pegou foi a sabotagem.** Ela exercitava
`valida_forma` direto e nunca os braços: ao remover `| valida_forma "$RE_PRS"` de `snap_prs` — isto é,
ao reintroduzir o defeito original — o gate continuou `15 casos · 0 falhas`. É a Regra Dura de
Reconciliação atingida pelo artefato que eu mesmo acabara de escrever, e no mesmo ML cuja Wave 0
previa este modo de esvaziamento.

Corrigido com os casos 14-17, que exercitam os braços de ponta a ponta substituindo `gh` e `git` por
**função** (não por stub em arquivo, que precisaria de bit de execução — vetado aqui desde
2026-08-29). Medido depois:

```
sabotagem 1  tirar valida_forma de snap_prs        -> FAIL "snap_prs com corpo de erro -> vazio"
sabotagem 2  filtrar a linha ruim em vez de        -> FAIL nos casos 7 e 7b
             invalidar o snapshot inteiro
restaurado                                         -> 19 caso(s) · 0 falha(s)
```

A sabotagem 2 é a que a Wave 0 nomeou como forma de esvaziar a correção — e agora reprova.
**Gates da wave:**
```bash
bash -n scripts/vigia-do-upstream.sh
```

## Wave 2 — Fechamento do ciclo
> Dependencies: Wave 1

### ML-2A — O `agents-working-context.md` volta a dizer o estado
**Status:** ✅ Concluído
**Files affected:** `docs/agents-working-context.md`
**Actions:**
1. Escrever a entrada do ciclo de 2026-10-02: o que entrou, o que está bloqueado e por quê, e o que
   está na mão do mantenedor. A última entrada é de 2026-09-11, e o `CLAUDE.md` manda atualizar ao
   iniciar e encerrar cada ciclo.
**Acceptance criteria:**
- [x] A entrada nomeia PR, issue e commit de cada item, sem adjetivo sem número
      ✅ entrada de 2026-10-02 com a tabela dos cinco commits do upstream, os três itens na mão do
      mantenedor (#509, #507, #502), o estado do fork e os dois instrumentos consertados
- [x] `trackfw validate` sem violação
      ✅ 0 violações · 2 avisos de grandfathering conhecidos · 74 REQs varridas
**Gates da wave:**
```bash
./bin/trackfw validate
```
