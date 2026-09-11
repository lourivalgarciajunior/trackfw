---
status: Open
date: 2026-09-10
author: "claude"
adr: "docs/adr/ADR-2026-09-05-o-repositorio-do-trackfw-e-governado-pelo-proprio-trackfw.md"
roadmap: "docs/roadmaps/claude/analyzing/ROADMAP-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md"
---

# REQ: baselines de suíte nunca foram versionados, e doze ACs ficaram inauditáveis **por construção**

> Date: 2026-09-10 | Status: Open

## 🔴 Correção de 2026-09-10 — são cinco ACs, não doze

O título e o nome deste arquivo dizem **doze**. **São cinco**, um em cada REQ. O número veio de uma
tabela escrita à mão — 2+3+4+1+2 — e passou por duas PRs, a #91 e a #92, sem ser derivado. O slug
fica como está: é identificador, e renomear moveria dois arquivos e todo link que aponta para eles.

**Derivado** varrendo o acervo inteiro, com o comando que refaz a medição:

```bash
grep -cE '\(d\) NAO VERIFICAVEL' docs/requisições/claude/*.md | grep -v ':0$'
```

Saem **11**, o mesmo total que a auditoria publicou — o que serve de controle do instrumento. Destes,
**cinco** têm a causa desta REQ; os outros seis têm causa diferente:

```
lista nomeada nao versionada                   5
  atualizar-para-a-upstream-main...symlink     95 falhas
  geradores-python-escrevem-crlf               198
  isatty-do-python-devolve-true-para-nul       105
  node-e-python-ignoram-home                   297 e 199
  trazer-o-barrier-dialeto-canonico            95

outras causas                                  6
  atualizar...symlink    processo daquele merge · criar symlink nesta maquina
  node...home            exige mutar produto
  slug-de-artefato       artifactId do pom · gate falhar com cada divergencia
  ruido-de-gofmt         nenhuma divergencia deliberada perdida
```

A lista de **REQs** estava certa: as cinco são estas. O que estava errado era a contagem de **ACs** —
a tabela dava 3 ao crlf e 4 ao isatty, e cada um tem um.

🔴 **E os cinco estão gravados como `(d)`, não como `(b)`.** A conversão para `(b)` é o AC5, e ainda
não foi feita. A #92 escreveu no roadmap que eles *"continuam `(b)`"*; era falso, e está corrigido lá.

É a quarta vez nesta semana que o denominador desta classe sai errado por contagem digitada — e desta
vez a lista digitada era a da própria REQ que existe para impedir isso.

## Motivation

A auditoria da `REQ-2026-09-10-onze-reqs` julgou 56 critérios de aceite, um a um. **Onze caíram em
`(d) não verificável aqui`, e cinco deles têm a mesma causa** — um em cada uma de cinco REQs:

```
atualizar-para-a-upstream-main-com-o-fix-de-symlink   1 AC
geradores-python-escrevem-crlf-no-windows             1
isatty-do-python-devolve-true-para-nul-no-windows     1
node-e-python-ignoram-home-no-windows                 1
trazer-o-barrier-dialeto-canonico-do-upstream         1
                                                     --
                                                      5
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

Não é conversão de vermelho em verde. Os cinco ACs vão receber **(b) não entregue**, com a razão
escrita — porque **um baseline tirado hoje não prova "sem regressão desde agosto"**. Prova "sem
regressão daqui para a frente". A afirmação de agosto é **irrecuperável**, e isso fica registrado em
vez de maquiado.

O que se troca é *"não dá para saber"* por *"não foi entregue, e agora dá para saber"*.

### E por que isto é UMA REQ, não cinco decisões

Cinco ACs, cinco REQs, **uma causa**: critério que depende de artefato não versionado. A Regra Dura de
Causa Raiz decide — mesma causa, mesma REQ.

## Acceptance Criteria

- [ ] **AC1** — A lista de falhas conhecidas é colhida de um **run de CI identificado**, nunca desta
      máquina, **por nome**, e versionada com a receita que a refaz. A diferença entre a lista e o que
      o **nosso** CI observa é declarada **por nome e com causa medida**. *(Reescrito em 2026-09-10 no
      ML-0A. A versão anterior pedia listas "geradas hoje" nesta máquina, em `scripts/testdata/`, e
      caiu por mérito: esta máquina não é o runner. A razão está no roadmap, seção "O que a espera
      invalidou".)*
- [ ] **AC2** — 🔴 **Gate que compara por NOME nos dois sentidos**: acusa falha **nova** e falha
      **sumida**, e diz explicitamente que **saldo zero não é conjunto igual**. É o defeito que uma
      queda de 33 para 32 escondeu em 2026-09-08.
- [ ] **AC3** — **Guarda de vacuidade**: o gate falha se a suíte não rodar, se o baseline estiver
      vazio, ou se o extrator devolver zero nomes. 🔴 Suíte que não carrega **não é** suíte sem
      falhas — é a distinção que a issue [#274](https://github.com/kgsaran/trackfw/issues/274) leva
      ao upstream, e ela vale aqui igual.
- [ ] **AC4** — **Falsificação nas duas direções**: baseline com uma falha a mais → o gate acusa
      "sumida"; com uma a menos → acusa "nova"; árvore intacta → passa. Só a terceira não é prova.
- [ ] **AC5** — Os **cinco ACs** das cinco REQs — hoje gravados como `(d)` — recebem veredito **(b) não entregue**, cada um
      apontando para esta REQ. 🔴 **Nenhum é marcado como entregue**, e nenhum é reescrito para caber
      no estado atual — a afirmação sobre agosto é irrecuperável e fica dito.
- [ ] **AC6** — O gate entra no `run-local-gates.sh` **ou** é declarado fora **com o motivo medido**.
      🔴 A suíte pypi leva ~5 min e a npm mais; se o custo em CI for proibitivo, isso é decisão
      escrita, não omissão.
- [ ] **AC7** — `validate` e os gates verdes ao fim, com o binário da árvore reconstruído, e
      divergência de produto **zero**.

### Convergência com o ratchet do upstream — decidida em 2026-09-10 (ML-0A)

O `scripts/check-windows-known-failures.py` do upstream — 1446 linhas, lido inteiro — roda no **nosso**
CI pelo `quality.yml` compartilhado, sem divergência nenhuma. Ele satisfaz AC1 a AC4 por desenho. O que
falta é do lado do fork, e está nomeado:

| AC | quem satisfaz | evidência | lacuna do fork |
|---|---|---|---|
| AC1 | `.github/windows-known-failures.json` | `_meta.source` com run, job e receita | 8 dos 38 não falham aqui — causa medida no ML-0A: o nosso `.gitattributes` |
| AC2 | passos 6 e 7 do ratchet | nova reprova; sumida gera aviso e exige `removal_note` | sumida é **aviso**, não reprovação — decisão escrita dele: consertar teste não pode quebrar o CI |
| AC3 | quatro guardas | lista vazia · artefato ausente · artefato sem resultado · marcadores de carga | nenhuma |
| AC4 | self-test T1–T22 | os dois braços | **não roda no nosso CI**: o `parity-rest` morre na linha 78 antes de chegar a ele |

**Construir um gate nosso seria a segunda solução para um problema que já tem uma.** A Wave 1 do
roadmap foi reescrita para fechar só as lacunas do fork.

## Negative Scope

- **Não** marcar nenhum dos cinco como entregue. O baseline é novo; o passado não foi verificado.
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
Roadmap: docs/roadmaps/claude/analyzing/ROADMAP-2026-09-10-baselines-de-suite-nunca-foram-versionados-e-doze-acs-ficaram-inauditaveis-por-construcao.md
