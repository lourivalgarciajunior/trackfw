---
status: Done
date: 2026-10-06
author: ""
adr: "docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-06-o-contorno-dos-shims-do-npm-nao-tem-alarme-para-o-dia-em-que-caducar.md"
---

# REQ: o contorno dos shims do npm nao tem alarme para o dia em que caducar

> Date: 2026-10-06 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation

Em 2026-10-06 o merge do [#527](https://github.com/kgsaran/trackfw/pull/527) deixou a cerca de git
**inerte** nesta máquina: o hook passou a chamar `trackfw guard <nome>`, resolvido no PATH, e o PATH
tinha a 9.1.0 do npm, sem o subcomando. O contorno adotado foi instalar o binário **compilado da
árvore** em `%APPDATA%/npm/trackfw.exe` e **mover** os três shims do npm para `*.pre-guard-bak`.

O contorno está escrito no `CLAUDE.md`, com o roteiro de reversão. 🔴 **E a própria nota admite o
furo:**

> *"E nenhum gate verifica a reversão. Quando a release com `guard` sair, ela é manual."*

**Isto é a mesma classe de defeito que este repositório já pagou três vezes** — o contorno do
`docs/roadmaps/done/.gitkeep` que ficou doze dias depois de o upstream consertar a causa, a nota do
`_force_utf8_output` e a dos "8 mascarados". Em todos, o que faltou não foi a medição: foi **alguém
notar que o mundo mudou**.

E aqui o custo de não notar é maior que nos três, porque o contorno virou **global**: o
`trackfw update harness` migrou sete CLIs de agente para `trackfw guard`, e todos dependem do PATH.
Um `npm i -g trackfw` antes da release recria os shims, o `.exe` deixa de ser resolvido e **todas as
cercas, em todos os projetos, ficam inertes de uma vez** — em silêncio.


## Acceptance Criteria

- [x] AC1 — Existe gate que fica **VERDE** enquanto nenhuma release publicada contiver o subcomando
      `guard`, e **VERMELHO** no dia em que contiver, enquanto o contorno ainda estiver documentado
- [x] AC2 — O veredito é **derivado**, não chumbado: tag do upstream que contém o commit do `guard`,
      cruzada com a versão publicada no npm
- [x] AC3 — Leitura que falhou **nunca** vira veredito verde: commit inalcançável, `npm` inacessível
      ou `CLAUDE.md` ilegível reprovam **nomeando o motivo**
- [x] AC4 — O gate é independente de SO, para poder rodar no CI em `ubuntu-latest` — o que ele afirma
      é estado do MUNDO (release publicada), não estado desta máquina
- [x] AC5 — Falsificado nas **duas** direções, com as duas leituras injetáveis só para a sonda e com
      aviso impresso quando injetadas, para que execução de sonda nunca passe por veredito real
- [x] AC6 — Declarado em `EXECUTAR` do `run-local-gates.sh`, e a guarda de completude do agregador
      continua fechada


## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-09-05-windows-e-plataforma-de-primeira-classe-e-o-defeito-se-mede-nela-nao-se-contorna.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-06-o-contorno-dos-shims-do-npm-nao-tem-alarme-para-o-dia-em-que-caducar.md

## Context

## O discriminante: estado do MUNDO, não desta máquina

O contorno tem duas metades, e só uma é verificável de fora:

| metade | onde é observável |
|---|---|
| os shims estão movidos? (`*.pre-guard-bak`) | só nesta máquina |
| existe release publicada com `guard`? | em qualquer lugar com rede |

🔴 **O gate afirma a segunda, de propósito.** A primeira é conhecida-verdadeira até alguém reverter, e
checá-la num runner de CI daria sempre "contorno ausente" — passaria descrevendo o vazio, que é o
defeito que o `run-local-gates.sh` existe para fechar. A segunda é o que **muda sem ninguém avisar**, e
é ela que precisa de alarme.

## A derivação

```
commit do guard      782f5767ad1a2e1de3939a305206cd74e80c9060
                     "feat(guard): hooks de guard viram trackfw guard <nome> ... (#527)"
tag que o contem     git tag --contains <commit>     hoje: NENHUMA
release publicada    npm view trackfw version        hoje: 9.2.0
v9.2.0 aponta para   0d14f7bc (04/10 16:46)          ANTES do commit do guard
```

Veredito: **vermelho** quando existir tag contendo o commit **e** a versão publicada for maior ou
igual a essa tag. Hoje nenhuma das duas condições vale, e o gate é verde **dizendo por quê**, não por
não ter olhado.

## Três guardas, cada uma por um modo de falha já medido neste repositório

1. **Commit inalcançável reprova.** Sem `git fetch upstream --tags`, `git tag --contains` devolve
   vazio — indistinguível de *"nenhuma release tem o guard"*. É a forma do
   `check-inherited-req.sh`, que falha dizendo o motivo em vez de derivar zero e passar.
2. **`npm` inacessível reprova.** Rede fora faria a leitura sair vazia e o gate concluir
   *"não há release"* — verde por cegueira. Ver [[verde-sem-denominador-nao-e-evidencia]].
3. **Premissa ausente é relatada, não assumida.** Se o `CLAUDE.md` já não documentar o contorno
   (`pre-guard-bak` ausente), alguém o aposentou: o gate diz isso e passa, em vez de reprovar por um
   contorno que não existe mais.

## Escopo negativo

- 🔴 **O gate não reverte nada.** Ele acende; a reversão é decisão do usuário, porque troca binário
  no PATH dele. Gate que conserta sozinho esconde a mudança.
- Não se verifica a metade local (`*.pre-guard-bak`): num runner ela é sempre falsa, e um gate que
  passa descrevendo o vazio é pior que gate nenhum.
- Não se tenta instalar a versão publicada para inspecionar se tem `guard`. A derivação por tag
  responde a mesma pergunta sem baixar nada e sem mexer no PATH durante um gate.

## Onde cada AC foi entregue

| AC | sitio |
|---|---|
| AC1 | `veredito()` em `scripts/check-contorno-dos-shims-caducou.sh`; verde hoje, vermelho com `v9.3.0`/`9.3.0` |
| AC2 | `git tag --contains $GUARD_COMMIT` cruzado com `npm view trackfw version` — nada chumbado alem do commit |
| AC3 | as tres guardas, falsificadas uma a uma: commit inalcancavel rc=1, npm vazio rc=1, premissa ausente relata e passa |
| AC4 | zero dependencia de SO: afirma release publicada, nao `*.pre-guard-bak`; roda em `ubuntu-latest` |
| AC5 | `--self-test` 10 casos · 0 falhas, e `SONDA_*` imprime `🔴 AVISO ... NAO e um veredito real` |
| AC6 | `EXECUTAR` do `run-local-gates.sh`: 14 executados · 0 falhas, completude fechada |
