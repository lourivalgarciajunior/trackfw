---
status: wip
date: 2026-10-06
req: "REQ-2026-10-06-o-contorno-dos-shims-do-npm-nao-tem-alarme-para-o-dia-em-que-caducar"
squad: "claude"
---

# Roadmap: o contorno dos shims do npm nao tem alarme para o dia em que caducar

> Created: 2026-10-06 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-10-06-o-contorno-dos-shims-do-npm-nao-tem-alarme-para-o-dia-em-que-caducar.md

Ver a REQ. Em uma frase: **o contorno dos shims sustenta SETE cercas globais e nada acusa o dia em que
ele caducar** — e a propria nota do `CLAUDE.md` admite o furo.

## Acceptance Criteria

- [ ] AC1 a AC6 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model do alarme
**Status:** ✅ Concluído
**Files affected:** nenhum (medicao e decisao)
**Actions:**

**1. A enumeracao esta fechada?** Os contornos vivos deste repositorio, derivados do `CLAUDE.md` e nao
de memoria: os shims do npm (este), o `pin7-noexec` (resolvido pelo #522, ja marcado), os tres gates
de PATH curado (ponto cego de ambiente, sem contorno), e o roadmap de `backlog/` com a premissa velha
(declarado como residuo). **Um contorno vivo sem alarme: este.** Os outros ou caducaram com registro,
ou sao ponto cego declarado, que e coisa diferente de contorno.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem fizer o gate checar
`*.pre-guard-bak` na maquina. Num runner de CI nao ha nenhum, entao ele passaria **descrevendo o
vazio** — e a mensagem diria "contorno ausente", que soa como boa noticia. É a forma exata do defeito
que o `run-local-gates.sh` existe para fechar.

E quem derivar "nao ha release com guard" de `git tag --contains` **sem** conferir que o commit e
alcancavel: sem `fetch --tags` a saida e vazia, e vazio seria lido como veredito.

**3. Falsificacao nas duas direcoes.** Verde com o mundo de hoje (nenhuma tag contem o commit, npm em
9.2.0) e **vermelho** com as duas leituras injetadas simulando release futura. Sem o lado vermelho o
gate seria decorativo; sem o verde, ele reprovaria sempre e seria desligado na primeira semana.

**4. Residuo declarado.** O gate afirma estado do MUNDO, nao desta maquina — ele nao sabe se os shims
voltaram. Se alguem reverter e esquecer de tirar a secao do `CLAUDE.md`, o gate continua verde ate
sair release; o inverso (secao removida, shims movidos) ele relata e passa. E o gate nao mede se a
versao publicada **realmente** responde `guard`: deriva por tag, que e a pergunta respondida sem
baixar nada.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia derivada, nao por assercao
- [x] Nenhuma linha de implementacao escrita neste ML

**Gates da wave:**
```bash
test -z "$(git tag --contains 782f5767ad1a2e1de3939a305206cd74e80c9060 2>/dev/null)"
```

## Wave 1 — O gate
> Dependencies: Wave 0

### ML-1A — `check-contorno-dos-shims-caducou.sh` e a declaracao no agregador
**Status:** ⬜ Pendente
**Files affected:** `scripts/check-contorno-dos-shims-caducou.sh`, `scripts/run-local-gates.sh`, `CLAUDE.md`
**Actions:**
1. Gate novo: deriva a tag que contem o commit do `guard` e a versao publicada no npm, e cruza as
   duas. Imprime os dois numeros sempre — veredito sem denominador nao e evidencia.
2. As tres guardas: commit inalcancavel reprova, `npm` inacessivel reprova, premissa ausente no
   `CLAUDE.md` e relatada e passa.
3. `--self-test` com os dois lados, pelas leituras injetaveis, e aviso impresso quando injetadas.
4. Declarar em `EXECUTAR` do `run-local-gates.sh`.
5. Uma linha no `CLAUDE.md` apontando o gate onde hoje se le *"nenhum gate verifica a reversao"* —
   sem apagar a frase, porque ela e o registro do motivo.

**Acceptance criteria:**
- [ ] AC1 a AC6 da REQ
- [ ] `--self-test` verde, com os dois lados exercitados
- [ ] `run-local-gates.sh` continua com a guarda de completude fechada e o novo gate executado
- [ ] Sabotagem: tirada a guarda do commit inalcancavel, o self-test reprova

**Gates da wave:**
```bash
bash scripts/check-contorno-dos-shims-caducou.sh --self-test
bash scripts/check-contorno-dos-shims-caducou.sh
grep -q 'check-contorno-dos-shims-caducou.sh' scripts/run-local-gates.sh
```
