---
status: wip
date: 2026-10-06
req: "REQ-2026-10-06-a-secao-do-jq-do-claude-md-descreve-falha-aberta-que-o-527-removeu"
squad: "claude"
---

# Roadmap: a secao do jq do CLAUDE.md descreve falha aberta que o 527 removeu

> Created: 2026-10-06 | Status: wip

## Context

REQ: docs/requisições/claude/REQ-2026-10-06-a-secao-do-jq-do-claude-md-descreve-falha-aberta-que-o-527-removeu.md

Ver a REQ. Em uma frase: **o `#527` removeu a falha aberta na raiz, a secao do `jq` caducou, e o ponto
cego mudou de lugar — de "sem `jq`" para "sem `guard` no PATH".**

## Acceptance Criteria

- [ ] AC1 a AC6 da REQ, verificadas por efeito

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model da reescrita
**Status:** ✅ Concluído
**Files affected:** nenhum (medicao e decisao)
**Actions:**

**1. A enumeracao esta fechada?** Varridas as afirmacoes do `CLAUDE.md` que o merge do `#527` pode ter
tornado falsas, nao so a do `jq`: a secao do `jq` inteira, a frase *"sitio unico, conferido"* sobre o
padrao `jq`-ou-`sed`, a contagem de `scripts/` so nossos (os dois `.sh` de guard vieram do upstream e
encolheram para involucro), e a nota de que **contornar o hook esta vetado** — que continua valendo e
agora por outro motivo. Quatro afirmacoes tocadas, uma caducada por inteiro.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita?** Quem **apagar a secao** por estar
resolvida. O arquivo tem tres precedentes de aposentar afirmacao mantendo a medicao que a aposentou
(`_force_utf8_output`, "8 mascarados", `pin7-noexec`), e a propria secao pediu medicao em vez de fe.
Apagar perde o motivo de o involucro existir e de a #507 ter sido aberta.

E quem escrever *"a cerca agora funciona"* **sem** registrar que ela ficou inerte entre o merge e a
instalacao do binario: seria trocar um ponto cego por outro, em silencio.

**3. Falsificacao nas duas direcoes.** Para cada afirmacao nova: o lado positivo (bloqueia o que deve)
e o negativo (passa o que deve). O controle negativo e o `git status` rc=0 — sem ele, "bloqueia tudo"
passaria por "cerca funcionando", que e exatamente o que o involucro `.sh` faz e o que esta frente
recusa como solucao.

**4. Residuo declarado.** Os 14 avisos novos do `validate` sao de escopo GLOBAL e ficam sem conserto
nesta frente, por decisao de escopo. E o binario no PATH e compilado localmente: quando sair release
com `guard`, a reversao dos shims tem de ser feita a mao — nenhum gate verifica isso, e o comando fica
escrito no `CLAUDE.md` por isso.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida, nao por assercao
- [x] Nenhuma linha do `CLAUDE.md` alterada neste ML

**Gates da wave:**
```bash
test "$(grep -c 'jq' internal/generators/scaffold.go)" -le 6
```

## Wave 1 — A reescrita
> Dependencies: Wave 0

### ML-1A — A secao caduca COM a medicao, e o ponto cego novo entra
**Status:** ⬜ Pendente
**Files affected:** `CLAUDE.md`
**Actions:**
1. Bloco de caducidade no topo da secao do `jq`, com a tabela de rc medida no PowerShell e as duas
   linhas do multilinha que eram o mecanismo da #507 — a secao abaixo fica como registro.
2. Secao nova do ponto cego atual: o hook resolve `trackfw` no PATH; PATH sem `guard` deixa a cerca
   inerte, com as tres configuracoes medidas e o motivo de nenhuma versao publicada servir.
3. A armadilha do PowerShell (`.ps1` ganha do `.exe`) e a reversao dos shims, com o comando.
4. Re-derivar a frase do *"sitio unico"*: o que sobrou de `jq` e onde, e que o `sed` sobre
   `tool_input` vive hoje so em corpus congelado.
5. Os 14 avisos novos declarados como residuo de escopo global.

**Acceptance criteria:**
- [ ] AC1 a AC6 da REQ
- [ ] Nenhuma linha removida da secao antiga — so acrescentada
- [ ] Toda tabela de rc no arquivo tem controle negativo ao lado

**Gates da wave:**
```bash
grep -q 'pre-guard-bak' CLAUDE.md
grep -q 'corpus-pre-fix' CLAUDE.md
test "$(grep -c 'falha ABERTA' CLAUDE.md)" -ge 1
```
