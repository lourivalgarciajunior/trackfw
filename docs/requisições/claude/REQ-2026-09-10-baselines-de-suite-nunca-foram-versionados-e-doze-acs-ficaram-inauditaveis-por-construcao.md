---
status: Open
date: 2026-09-10
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/backlog/ROADMAP-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md"
---

# REQ: baselines de suíte nunca foram versionados, e doze ACs ficaram inauditáveis **por construção**

> Date: 2026-09-10 | Status: Open

## Motivation

A auditoria da `REQ-2026-09-10-onze-reqs` julgou 56 critérios de aceite, um a um. **Onze caíram em
`(d) não verificável aqui`, e doze deles têm a mesma causa** — espalhada por cinco REQs:

```
atualizar-para-a-upstream-main-com-o-fix-de-symlink   2 ACs
geradores-python-escrevem-crlf-no-windows             3
isatty-do-python-devolve-true-para-nul-no-windows     4
node-e-python-ignoram-home-no-windows                 1
trazer-o-barrier-dialeto-canonico-do-upstream         2
                                                     --
                                                     12
```

Todos pedem a mesma coisa, e pedem **bem**:

> *"Sem regressão na suíte pypi por **lista nomeada** contra 95 falhas, **nunca só por contagem**"*

O critério está certo. **O que faltou nunca foi rigor: foi alguém versionar a lista.** As de agosto —
95, 105, 198, 199 e 297 falhas — não existem em lugar nenhum do acervo. A única busca que devolve
algo é o `os-predicate-sites-baseline.txt`, de outra REQ e de 2026-09-09.

🔴 **Uma REQ cujo critério depende de artefato não versionado é inauditável por construção.** Não é
falta de esforço nem de acesso: é desenho. E explica como dez REQs puderam ficar `done` com critério
aberto sem ninguém perceber — parte delas nunca teve como ser conferida.

### A medição de hoje, e a ironia que ela expõe

A suíte pypi **roda nesta máquina**, e as falhas saem **nomeadas**:

```
15 failed · 1640 passed · 20 skipped        292s (4min52)

FAILED pypi/tests/test_agents_skills.py::test_update_alias_converts_only_present_codex_artifacts
FAILED pypi/tests/test_agents_skills.py::test_manager_rejects_symlink_parent
FAILED pypi/tests/test_barrier.py::test_barrier_cli_crlf_roadmap_gates_da_wave_...
...                                                          15 nomes, extraiveis por `grep '^FAILED'`
```

Os ACs de agosto falavam em **198** e **199**. Hoje são **15**. A melhora é enorme — e eu só consigo
afirmá-la **por contagem**, que é exatamente o que aqueles ACs recusam como evidência.

🔴 **A boa notícia é tão inauditável quanto a má.** Sem a lista de agosto, não dá para dizer *quais*
183 fecharam, nem se alguma das 15 de hoje é **nova**. É o argumento mais limpo possível para
versionar a lista: o mecanismo que impede maquiar regressão é o mesmo que impede provar progresso.

### O que esta REQ **não** é

Não é conversão de vermelho em verde. Os doze ACs vão receber **(b) não entregue**, com a razão
escrita — porque **um baseline tirado hoje não prova "sem regressão desde agosto"**. Prova "sem
regressão daqui para a frente". A afirmação de agosto é **irrecuperável**, e isso fica registrado em
vez de maquiado.

O que se troca é *"não dá para saber"* por *"não foi entregue, e agora dá para saber"*.

### E por que isto é UMA REQ, não cinco decisões

Doze ACs, cinco REQs, **uma causa**: critério que depende de artefato não versionado. A Regra Dura de
Causa Raiz decide — mesma causa, mesma REQ.

## Acceptance Criteria

- [ ] **AC1** — As listas de falha das suítes **pypi** e **npm** são geradas hoje, **por nome**, e
      versionadas em `scripts/testdata/`. Formato estável, uma falha por linha, ordenado — para que a
      comparação futura seja de **conjunto**, não de contagem.
- [ ] **AC2** — 🔴 **Gate que compara por NOME nos dois sentidos**: acusa falha **nova** e falha
      **sumida**, e diz explicitamente que **saldo zero não é conjunto igual**. É o defeito que uma
      queda de 33 para 32 escondeu em 2026-09-08.
- [ ] **AC3** — **Guarda de vacuidade**: o gate falha se a suíte não rodar, se o baseline estiver
      vazio, ou se o extrator devolver zero nomes. 🔴 Suíte que não carrega **não é** suíte sem
      falhas — é a distinção que a issue [#274](https://github.com/kgsaran/trackfw/issues/274) leva
      ao upstream, e ela vale aqui igual.
- [ ] **AC4** — **Falsificação nas duas direções**: baseline com uma falha a mais → o gate acusa
      "sumida"; com uma a menos → acusa "nova"; árvore intacta → passa. Só a terceira não é prova.
- [ ] **AC5** — Os **doze ACs** das cinco REQs recebem veredito **(b) não entregue**, cada um
      apontando para esta REQ. 🔴 **Nenhum é marcado como entregue**, e nenhum é reescrito para caber
      no estado atual — a afirmação sobre agosto é irrecuperável e fica dito.
- [ ] **AC6** — O gate entra no `run-local-gates.sh` **ou** é declarado fora **com o motivo medido**.
      🔴 A suíte pypi leva ~5 min e a npm mais; se o custo em CI for proibitivo, isso é decisão
      escrita, não omissão.
- [ ] **AC7** — `validate` e os gates verdes ao fim, com o binário da árvore reconstruído, e
      divergência de produto **zero**.

## Negative Scope

- **Não** marcar nenhum dos doze como entregue. O baseline é novo; o passado não foi verificado.
- **Não** reescrever os ACs de agosto para que o estado atual os satisfaça. É o que a auditoria de
  hoje desfez em dez REQs, e repetir seria pior com o registro fresco na mão.
- **Não** corrigir as 15 falhas do pypi. São produto do upstream; corrigi-las aqui criaria
  divergência, que hoje é zero. Se alguma for defeito real e não coberto, vira **issue**.
- **Não** versionar a suíte inteira, só a **lista de falhas**. O objetivo é detectar mudança de
  conjunto, não congelar saída de teste.

## Linked ADR
ADR: docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/backlog/ROADMAP-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md
