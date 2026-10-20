---
status: Done
date: 2026-10-19
author: "Lourival Garcia"
adr: "docs/adr/ADR-2026-10-19-o-deadline-do-contexto-nao-e-veredito-da-sonda-portamos-o-ctx-err-do-netexec-para-a-regra-do-login-shell.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-19-o-deadline-da-sonda-do-login-shell-e-classificado-como-trackfw-ausente-o-ctx-err-que-o-netexec-ja-tem.md"
---

# REQ: O deadline da sonda do login shell e classificado como trackfw ausente - o ctx.Err que o netexec ja tem

> Date: 2026-10-19 | Status: Open
| Linear Issue:
| Jira Issue:

## Motivation

A regra `guard_binary_probe` (ML-5D) emite violação dizendo que **o login shell
do Git Bash não acha o `trackfw` no PATH** quando, na verdade, foi o **deadline
de 5 s da própria sonda** que estourou. É regra de segurança: a mensagem afirma
que a cerca falha aberta.

**O código promete o contrário do que faz.** O doc de `guardRunBashLoginProbe`
separa três casos, e o terceiro — `("", false)` para *"bash could not start, or
the context deadline expired"* — nunca se realiza, porque
`exec.CommandContext` mata o processo no deadline e `cmd.Output()` devolve
`*exec.ExitError`. O `errors.As` casa, e o retorno é `("", true)`: o balde do
meio, *"bash rodou e disse que não tem"*.

**O discriminante correto JÁ EXISTE neste repositório**, e é isso que torna esta
REQ uma convergência e não uma proposta. `internal/commands/netexec.go`:

```go
// Returns (isTimeout=true, _) when ctx.Err() != nil — the context deadline expired.
func resolveNetworkErr(err error, ctx context.Context, cmd *exec.Cmd) (isTimeout, isWaitDelaySuccess bool) {
	if ctx.Err() != nil {
		return true, false
	}
```

🔴 **E os dois arquivos se citam, em uma direção só.** O `netexec.go` declara, no
comentário do `cmdWaitDelay`: *"Matches the precedent in
internal/validator/validator_guard_binary_probe.go"*. O `WaitDelay` viajou da
sonda para o netexec; o `ctx.Err()`, decidido na ADR D1 do netexec, **não voltou**.

**Medido em 2026-10-19**, réplica linha a linha da sonda num programa Go
isolado, com o `bash.exe` que a `guardFindGitBashExe` escolheria e com o
`trackfw` **presente** no PATH do login shell:

| timeout | hoje | com o `ctx.Err()` |
|---|---|---|
| 5s · 3s | resolveu | resolveu |
| 1s · 300ms · 1ms | **VIOLAÇÃO** | SKIP |

**Por que morde sem provocação:** a sonda custa **2,0 a 2,25 s** nesta máquina
(cinco passadas: 1997, 2172, 2251, 2238, 2051 ms) contra deadline de 5 s —
margem de ~2,2×. Observado sem provocar: numa corrida de `validate` com um
`du -sh` varrendo `node_modules` em segundo plano, a violação saiu **duas
vezes**; antes e depois, nada.

**Por que o ramo sobreviveu:** `guardRunBashLoginProbe` é **seam substituída em
todos os testes** (`stubGitBashSeams` troca as três). O
`TestGuardGitBashBinaryProbe_BashNaoInicia_Skip` afirma que o **chamador** pula
com `loginRan=false` — nunca que a função real devolve `false` no deadline. O
corpo da função nunca é exercitado.

Levado ao upstream na issue [#589](https://github.com/kgsaran/trackfw/issues/589).

## Acceptance Criteria

- [x] O deadline do contexto é classificado como **skip**, não como violação, e
      a classificação vive numa função própria — o mesmo desenho do
      `resolveNetworkErr`, que existe para ser *"tested once and applied
      consistently"*.
- [x] O terceiro caso do doc de `guardRunBashLoginProbe` passa a ser verdade, e
      há teste que o afirma. Hoje não há nenhum.
- [x] **O verdadeiro positivo continua pego**: `command -v` que sai ≠ 0 com o
      contexto vivo segue devolvendo `("", true)` e a regra segue acusando.
      Conserto que silencia o caso real não é conserto.
- [x] O cenário do ML-5D — `~/bin` com binário velho sombreando — continua
      coberto pelos testes que já existem, sem mudança neles.
- [x] `go build ./...` e `go test ./internal/validator/...` passam.
- [x] `run-local-gates` sem falha nova — medido na árvore sincronizada em 2026-10-20:
      **16 executado(s) · 0 falha(s)**, com os 4 declarados FORA nomeando o motivo. O job
      **Gates locais do fork** roda o mesmo agregador a cada PR, num runner limpo.
- [x] A divergência de produto contra o `upstream/main`, medida **ancorada na
      base de merge**, é exatamente este conserto — e some quando ele for
      mesclado lá.


### Onde cada critério se comprova — fechado em 2026-10-20, depois do merge do #590

O upstream mesclou o [#590](https://github.com/kgsaran/trackfw/pull/590) às **13:33 (-0300)**,
commit `81130826`, e a [#589](https://github.com/kgsaran/trackfw/issues/589) fechou sozinha
pelo `Closes`. O conserto chegou aqui pelo `upstream-sync.sh` — **por convergência, não por
reversão**, como a REQ previa.

| critério | sítio que comprova |
|---|---|
| classificação em função própria | `guardProbeEndedByDeadline` no produto sincronizado |
| terceiro caso do doc, com teste | `TestGuardRunBashLoginProbe_PrazoEstourado_NaoAfirmaNada` |
| verdadeiro positivo continua pego | controle positivo **dentro** dos dois testes de prazo: erro comum sem a sentinela segue acusando e nomeando o caminho |
| ML-5D sem mudança | os testes do ML-5D passam sem edição, dentro dos 10 do recorte |
| divergência some quando ele mesclar | **medido**: `git diff --name-only upstream/main -- internal cmd Makefile` devolve **0** |

**Medido na árvore sincronizada, com o denominador à vista:**

```
go build ./...                       rc=0
recorte ML-1A+1B, com -v             10 PASS · 0 FAIL · 0 SKIP
  TestGuardGitBashBinaryProbe_PrazoNoSegundoBinario_NaoAfirmaNada  PASS
produto que difere do upstream       0 arquivo(s)
validate                             0 violações · 3 avisos (o piso)
```

🔴 **O critério `go test ./internal/validator/...` está marcado pelo sítio do CI, não por
esta máquina — e a diferença fica declarada.** A suíte **completa** do pacote sai `rc=1`
aqui, em 504,6 s, com três falhas do **Group A**
(`TestStaleWIPReportsWIPWalkError`, `TestFolderStatus_DiretorioNaoLegivel_P2`,
`TestFilenameUniqueness_…_P2`). As três estão declaradas no
`.github/windows-known-failures.json`, e o **controle em worktree sobre o commit base
`a4dbec34`** — sem o conserto — reprova as mesmas três. Quem comprova o critério é o
`windows-full-suites` do #590, `SUCCESS` no head `8ab6e84c`, que roda a suíte com o ratchet.

🔴 **Uma armadilha de medição no caminho, da família "verde sem denominador":** a primeira
passada do recorte foi sem `-v`, e o meu contador devolveu **`PASS: 0` com `rc=0`** — que é
indistinguível de *"nenhum teste casou o filtro"*. Sem `-v` o Go não imprime linha por
teste. Refeito com o denominador à vista, e o nome do teste do ML-1B conferido na saída.

## Negative scope

Nao se faz nesta REQ:

- **Não se aumenta o deadline de 5 s.** Aumentar reduz a frequência e não muda a
  classificação: com carga suficiente o falso positivo volta. A causa é o balde,
  não o número.
- **Não se torna o deadline configurável por variável de ambiente.** Seria
  conceito novo na superfície do produto, e o `TRACKFW_NETWORK_TIMEOUT` existe
  para operação de rede, não para sonda local. Se vier, é decisão própria.
- **Não se mexe no `WaitDelay`.** Ele cobre neto segurando pipe, e nas passadas
  medidas o processo morreu pelo contexto antes disso. Não medi a interação —
  está declarado como limite, não resolvido.
- **Não se investiga por que a violação saiu DUAS vezes** na mesma corrida. O
  sítio da chamada retorna na primeira mensagem não vazia, então a duplicação
  deve vir de o `validate` avaliar a regra para mais de um escopo de settings.
  É observação, não diagnóstico, e não bloqueia este conserto.
- **Não se reescreve a sonda para não usar processo externo.** Ler o PATH do
  login shell exige o login shell.
- **Nenhuma outra regra do `validator` é tocada**, mesmo que compartilhe a forma.
  Se houver outro sítio com o mesmo defeito, ele entra **como ML nesta REQ** —
  mesma causa, mesma REQ —, não como REQ nova.

## Linked ADR

ADR: docs/adr/ADR-2026-10-19-o-deadline-do-contexto-nao-e-veredito-da-sonda-portamos-o-ctx-err-do-netexec-para-a-regra-do-login-shell.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap

Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-19-o-deadline-da-sonda-do-login-shell-e-classificado-como-trackfw-ausente-o-ctx-err-que-o-netexec-ja-tem.md
