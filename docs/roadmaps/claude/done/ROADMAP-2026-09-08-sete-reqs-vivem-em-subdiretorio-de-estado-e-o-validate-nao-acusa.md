---
status: done
date: 2026-09-08
req: "docs/requisições/claude/REQ-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md"
squad: "claude"
---

# Roadmap: sete REQs vivem em subdiretório de estado, e o `validate` não acusa

> Created: 2026-09-08 | Status: done

## Context

REQ: docs/requisições/claude/REQ-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md

A `ADR-2026-09-03` D1 escreve que REQ **não** tem dimensão de estado. Sete REQs estão em pasta de
estado, e o `validate` diz `✓ No violations found`. ADR decide, gate não verifica — pela terceira vez
em dois dias, e a primeira numa decisão nossa.

## Acceptance Criteria

- [x] Gate acusa REQ fora de `req_dir/<agente>/*.md`, falsificado nas duas direções, com denominador
      impresso.
- [x] As 7 REQs saem das pastas de estado, com o `status` reconciliado arquivo a arquivo.
- [x] O número de "REQ `Done` com AC aberto" é refeito com glob recursivo.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Enumeração, ameaça e falsificação
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**
1. **Enumeração completa.** Achar toda REQ fora do layout canônico — e não só sob `req_dir`. 🔴 O
   próprio achado que originou esta REQ veio de um caminho que ninguém procurava: varrer também
   `docs/req/` (resíduo do upstream) e qualquer diretório que o `req_dir` de outra config alcance.
   Declarar a lista fechada com o comando que a produziu.
2. **Quem esvazia esta wave sem quebrar regra escrita?** Formas conhecidas, a registrar com remédio:
   (a) gate com glob de um nível, que é **exatamente o defeito que produziu o número errado da
   PR #65**; (b) gate que varre zero REQs e sai 0; (c) gate que acusa o próprio `req_dir` como se
   fosse subdiretório.
3. **Falsificação nas duas direções.** REQ plantada em `<agente>/wip/` reprova; árvore corrigida
   passa. E o controle inverso: o gate **não** pode acusar `req_dir/<agente>/x.md`, que é o layout
   canônico.
4. **Residual declarado.** O que este desenho aceita não cobrir.
**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência, não com asserção de uma linha
- [x] Nenhuma linha de implementação escrita neste ML

**Enumeração ampla, os três lugares:**

```
sob req_dir, profundidade > 1                7 REQs   <- o alvo
FORA de req_dir, em docs/req/                3 REQs   <- NAO sao alvo (ver abaixo)
qualquer outro REQ-*.md na arvore            0
```

🔴 **`docs/req/` fica fora por decisão escrita, não por esquecimento.** Não é `req_dir` deste
projeto, e as três são **fixture de teste do produto**, lidas por caminho literal nos 3 runtimes
(`REQ-2026-09-05-tres-reqs-de-docs-req`). Acusá-las levaria a removê-las, e removê-las quebra `go`,
`node` e `python` — foi medido em 2026-09-05, com o CI vermelho.

**Ameaça (a): glob de um nível.** É o defeito que produziu o número errado da PR #65 e que este
gate existe para achar. O gate usa `find` recursivo, e a falsificação planta a REQ **dois** níveis
abaixo justamente para pegar isso.

**Ameaça (b): varrer zero.** Guarda de vacuidade, exit 1 com a mensagem nomeando o `req_dir`.

**Ameaça (c): acusar o próprio canônico.** Controle inverso obrigatório — o gate tem de sair 0 na
árvore corrigida, e não só reprovar na quebrada.

## Wave 1 — O gate e a correção do acervo

### ML-1A — Gate do invariante de layout
**Status:** ✅ Concluído
**Files affected:** `scripts/check-req-layout.sh` (novo)
**Actions:**
1. Lê `req_dir` e os agentes do `trackfw.yaml` — nunca chumbado.
2. Acusa `.md` com profundidade > 1 abaixo de `req_dir`, nomeando arquivo e o nível sobrando.
**Acceptance criteria:**
- [x] 🔴 Denominador impresso: `N REQs varridas`, e falha se `N == 0`
- [x] Falsificação: REQ plantada em `<agente>/wip/` reprova nomeando o arquivo
- [x] Controle inverso: o layout canônico **não** é acusado
- [x] O gate passa na árvore já corrigida pelo ML-1B

**Medido com o exit code real, sem pipe:**

| caso | saída | exit |
|---|---|---|
| REQ plantada em `claude/wip/` | `FAIL [layout/claude/wip/...]: nivel 'wip' sobrando` | **1** |
| `req_dir` vazio | `GUARDA DE VACUIDADE -- zero REQs varridas` | **1** |
| árvore canônica | `64 REQ(s) varrida(s) - 0 fora do layout` | **0** |

🔴 **A primeira leitura do caso de vacuidade disse `exit=0` e estava errada** — eu tinha capturado o
`$?` do `sed` no fim do pipe, não o do script. Remedido sem pipe. É o mesmo modo de falha que fez a
tarefa em segundo plano reportar "exit 0" para um gate que saíra 1, em 08/09.

### ML-1B — As 7 REQs saem das pastas de estado
**Status:** ✅ Concluído
**Files affected:** `docs/requisições/{apolo,artemis,claude}/**`
**Actions:**
1. Mover cada uma para `req_dir/<agente>/`.
2. Reconciliar o `status` com o par da ADR (`Open`/`Done`), **arquivo a arquivo**.
**Acceptance criteria:**
- [x] 🔴 Cada `status` alterado tem justificativa escrita. Mover arquivo **não** muda o significado
      do frontmatter, e reconciliar em massa seria inventar estado

      **Alterados: 4.** Os quatro tinham `done` minúsculo e passaram a `Done`. A justificativa é
      que isso **não muda nada** — o CLI já os contava como `Done` antes da edição, e a prova é a
      distribuição idêntica:

      ```
      antes   64 REQs (2 Open · 61 Done · 1 Closed)
      depois  64 REQs (2 Open · 61 Done · 1 Closed)
      ```

      **Não alterado: 1.** `REQ-roadmap-ai-generation` tem `status: Closed`, que é estado
      reconhecido pelo CLI e aparece na contagem — não é grafia solta. Mudá-lo para `Done` seria
      inventar estado, exatamente o que este AC proíbe.

- [x] Nenhuma referência a essas REQs quebra — varredura de referência na **árvore inteira**, não
      num diretório escolhido

      Três referências ao caminho antigo, e as três com destino diferente:

      | onde | ação |
      |---|---|
      | `docs/roadmaps/claude/done/roadmap-multi-ai-support-...` | **corrigida** — é vínculo vivo |
      | `docs/requisições/claude/REQ-2026-09-08-sete-reqs-...` | **preservada** — é a própria REQ citando o caminho como o achado |
      | `scripts/testdata/roadmap-barrier-corpus-snapshot/...` | 🔴 **preservada de propósito** — é o corpus **congelado** do barrier. Editá-lo para acompanhar o move seria regenerar o snapshot, que é justamente o que não se faz |

- [x] `trackfw validate` sem violação, com denominador conferido — e
      `check-referential-integrity.sh` verde antes **e** depois do move (`Referential integrity OK`,
      exit 0 nos dois)

### ML-1C — O número de "Done com AC aberto" refeito
**Status:** ✅ Concluído
**Files affected:** —
**Actions:**
1. Refazer a varredura com glob **recursivo**, excluindo blocos de código e exigindo título de seção
   de AC — as três correções que a medição de 2026-09-08 já precisou.
**Acceptance criteria:**
- [x] O número final é publicado com o comando que o produziu

      ```
      PR #65 (glob de 1 nivel)   6 REQs · 54 ACs
      correcao no comentario     8 REQs · 70 ACs
      recursivo, aqui            8 REQs · 70 ACs
      ```

      As três medições convergem no valor certo, e a do meio foi feita **antes** do move — o que
      confirma que o número não dependia do layout, só da varredura.

- [x] A diferença para o publicado na PR #65 fica **explicada**, não só corrigida: o glob de um
      nível não descia em `<agente>/backlog/`, e as duas REQs que moravam lá têm 8 ACs abertos cada.
      8 + 6 = 14 REQs? Não: as duas **somam** às 6, dando 8 REQs e 54 + 16 = 70 ACs.

## Residual declarado

- Este roadmap **não** decide o destino dos ACs abertos das REQs de junho. É decisão do usuário,
  registrada como pendente. Aqui só o número é corrigido.
- O gate é **nosso**. Propor a regra ao upstream é issue própria, depois de medido — o invariante
  vem de uma ADR nossa, não do produto.
