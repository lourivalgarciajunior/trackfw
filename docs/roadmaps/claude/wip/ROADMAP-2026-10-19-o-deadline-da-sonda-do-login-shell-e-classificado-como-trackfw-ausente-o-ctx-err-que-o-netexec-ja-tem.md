---
status: wip
date: 2026-10-19
req: "docs/requisições/claude/REQ-2026-10-19-o-deadline-da-sonda-do-login-shell-e-classificado-como-trackfw-ausente-o-ctx-err-que-o-netexec-ja-tem.md"
squad: ""
---

# Roadmap: O deadline da sonda do login shell e classificado como trackfw ausente - o ctx.Err que o netexec ja tem

> Created: 2026-10-19 | Status: wip

## Context
<!-- Derived from REQ -->
REQ: docs/requisições/claude/REQ-2026-10-19-o-deadline-da-sonda-do-login-shell-e-classificado-como-trackfw-ausente-o-ctx-err-que-o-netexec-ja-tem.md

Conserto numa regra de segurança, convergindo para o discriminante que o
`netexec.go` deste mesmo repositório já usa. ADR:
`docs/adr/ADR-2026-10-19-o-deadline-do-contexto-nao-e-veredito-da-sonda-portamos-o-ctx-err-do-netexec-para-a-regra-do-login-shell.md`.

Issue no upstream: [#589](https://github.com/kgsaran/trackfw/issues/589).

## Acceptance Criteria
- [x] Deadline do contexto → skip; `*exec.ExitError` com contexto vivo → violação
- [x] A classificação em função própria, testada uma vez (desenho do `resolveNetworkErr`)
- [x] Teste que afirma o terceiro caso do doc — hoje não existia nenhum
- [x] Verdadeiro positivo preservado, e os testes do ML-5D intocados
- [x] `go build ./...` e `go test ./internal/validator/...` passam — medido na
      branch-veiculo, que e onde o produto vive
- [x] `run-local-gates` sem falha nova — 16 executado(s), 0 falha(s), rc=0
- [x] **Divergencia de produto na nossa `main`: ZERO.** O conserto NAO entra aqui;
      ele vive na branch-veiculo e chega pelo `upstream-sync.sh`

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído
**Files affected:** apenas este roadmap

**1. Completude da enumeração.** A pergunta não foi *"onde está este defeito"* —
foi *"quantos sítios do repositório classificam erro de `exec` sem perguntar ao
contexto"*. Varredura por `exec.CommandContext` em `internal/` e `cmd/`, fora de
teste, **denominador impresso**:

```
6 sitios, em 3 arquivos

internal/commands/netexec.go                        2 sitios   ctx.Err()  3x   -> CORRETO
internal/discover/discover.go                       1 sitio    ctx.Err()  1x   -> CORRETO
internal/validator/validator_guard_binary_probe.go  3 sitios   ctx.Err()  0x   -> o defeito
```

🔴 **O achado que a REQ não previa: o arquivo da sonda é o único dos três que
nunca pergunta ao contexto, e ele tem TRÊS sítios, não um.** A REQ falava do
login shell; a varredura trouxe os outros dois. Classificados um a um:

| sítio | o que o prazo produz hoje | veredito |
|---|---|---|
| `guardRunBashLoginProbe` (`command -v trackfw`) | `("", true)` → violação *"não acha o trackfw no PATH"* | **mesmo defeito** |
| `guardRunProbe` (`trackfw guard --help`) | erro não nulo → violação *"does not have the guard subcommand"* | **mesmo defeito, segundo sítio** |
| `guardGetPSPolicy` (`Get-ExecutionPolicy`) | `err != nil` → `return ""`, e `""` não é `"Restricted"` | **seguro** |

O terceiro falha para o **silêncio**, não para a acusação falsa. Mudá-lo seria
inventar violação no prazo — pior que o que existe. Fica como residual (item 4).

**Mesma causa, mesma REQ, mesmo PR**, como a Regra Dura manda: os dois sítios
afetados entram no mesmo ML, e não em REQ nova.

**2. Threat model — quem esvazia esta wave sem quebrar regra escrita.** Quatro
caminhos enumerados, e o primeiro **aconteceu de verdade**:

- 🔴 **(a) o teste de ponta a ponta pula na plataforma que importa.** A primeira
  versão tinha `t.Skip` no Windows — e Windows é onde a regra existe. Eu teria
  enviado um teste que **nunca vi passar**. Fechado: o teste passou a achar o Git
  Bash **real** pela própria `guardFindGitBashExe` no Windows, e a usar script
  stub só no POSIX. Roda e passa nas duas.
- **(b) o teste afirma o skip com um `bashExe` inexistente** — que já caía em
  `("", false)` **antes** do conserto, logo passaria sem ele. Fechado pelo
  controle positivo: antes do caso curto, o mesmo `bashExe` roda com prazo
  folgado e tem de devolver `ran=true`.
- **(c) o conserto é posto depois do `errors.As`** e o prazo continua no balde do
  meio. Fechado por leitura do diff e pela falsificação do item 3.
- **(d) o verdadeiro positivo deixa de ser pego.** Fechado por controle positivo
  no teste do segundo sítio: erro comum, sem o sentinela, continua acusando
  `does not have the guard subcommand`.

**3. Falsificação nas duas direções, medida.** Não por leitura:

```
conserto ARMADO     TestGuardRunBashLoginProbe_PrazoEstourado_NaoAfirmaNada   PASS (2,03 s)
conserto DESARMADO  o mesmo teste                                            FAIL
  "prazo estourado devolveu ran=true (o balde de \\"trackfw ausente do PATH\\")"
```

O desarme foi cirúrgico — `if false && guardProbeEndedByDeadline(ctx)` **só** no
sítio do login shell —, e o arquivo foi restaurado de cópia, com
`grep -c DESARMADO` = 0 conferido depois.

Na direção oposta: `guardRunProbe` devolvendo erro comum **continua** produzindo
a violação, afirmado por teste. Conserto que silencia o caso real seria o pior
dos dois resultados, porque a mensagem fala de cerca falhando aberta.

**4. Residual declarado.**

- **`guardGetPSPolicy` não foi tocado.** Prazo estourado ali vira política vazia,
  logo **falso negativo**: uma política `Restricted` de verdade passaria batido
  se a sonda estourasse. É mais brando que acusação falsa, e consertá-lo exigiria
  decidir o que afirmar sem leitura — decisão própria, não deste ML.
- **Não medi a interação com o `WaitDelay` de 5 s.** Nas passadas feitas o
  processo morreu pelo contexto antes dele.
- **A violação saiu DUAS vezes na mesma corrida e eu não isolei por quê.** O
  sítio da chamada retorna na primeira mensagem não vazia, então a duplicação
  deve vir de o `validate` avaliar a regra para mais de um escopo de settings.
  Observação, não diagnóstico.
- **Uma máquina.** Windows 11, Git for Windows em `C:\Program Files\Git`. O
  teste roda no POSIX por stub, mas eu não o executei em Linux — isso o CI faz.

**Acceptance criteria:**
- [x] As quatro seções respondidas com evidência, não com asserção de uma linha
- [x] A varredura do item 1 com denominador impresso
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
# cada linha roda como um sh -c separado — ver docs/cli-parity.md regra 5
test "$(grep -c '^\*\*4\. Residual declarado' docs/roadmaps/claude/*/ROADMAP-2026-10-19-o-deadline-da-sonda-*.md)" = "1"
grep -q 'denominador impresso' docs/roadmaps/claude/*/ROADMAP-2026-10-19-o-deadline-da-sonda-*.md
```

## Wave 1 — Implementation
> Dependencies: Wave 0.

### ML-1A — A classificação em função própria, e o teste que afirma o terceiro caso
**Status:** ✅ Concluído
**Files affected:**
- `internal/validator/validator_guard_binary_probe.go`
- `internal/validator/validator_guard_binary_probe_gitbash_test.go`

**O que entrou:**

1. `guardProbeEndedByDeadline(ctx)` — um sítio só, consumido pelas duas sondas
   afetadas, com o comentário citando o `resolveNetworkErr` e a medição.
2. `guardRunBashLoginProbe` pergunta o prazo **antes** do `errors.As`, e o
   terceiro caso do doc passa a ser verdade.
3. `guardRunProbe` embala o prazo no sentinela `errGuardProbeDeadline` com
   `errors.Join`, e o chamador pula com `errors.Is`. 🔴 **O sentinela existe para
   não mudar a assinatura da seam** — ela é `func(bin string) error` e é
   substituída em muitos testes; mudá-la custaria reescrevê-los sem ganho.
4. `guardProbeTimeout` vira var de pacote nos três sítios, pelo precedente
   explícito do `cmdWaitDelay` no `netexec.go` (*"overridable in tests"*). Sem
   isso o terceiro caso só seria testável com um processo que dorme 5 s.

**Três testes, cada um com a frase de reconciliação no comentário de abertura:**

| teste | o que afirma | resultado |
|---|---|---|
| `GuardProbeEndedByDeadline_Discriminante` | a pergunta é do contexto, não do tipo do erro | PASS |
| `GuardRunBashLoginProbe_PrazoEstourado_NaoAfirmaNada` | o terceiro caso do doc existe — **corpo real**, Git Bash real no Windows | PASS (2,03 s) |
| `GuardBinaryProbeOnce_PrazoDoGuardHelp_NaoAcusaOBinario` | o segundo sítio também pula, **e o erro comum continua acusando** | PASS |

🔴 **O PRODUTO NAO ENTRA NA NOSSA `main`, e isso foi o CI que ensinou.** A PR #275
levava os dois arquivos de `internal/validator/`, e o job `gates-locais` reprovou:

```
Divergencia de produto tem de ser ZERO
  DIVERGE (compartilhado, mudado por nos): internal/validator/validator_guard_binary_probe.go
  DIVERGE (compartilhado, mudado por nos): internal/validator/validator_guard_binary_probe_gitbash_test.go
arquivos compartilhados que diferem: 2
::error::divergencia de produto deixou de ser zero
```

**O gate esta certo, e nao se afrouxa gate para caber.** Ele e o invariante do fork
— *"arquivo COMPARTILHADO que NOS mudamos"* —, e o ADR deste roadmap ja previa a
divergencia como *"deliberada e temporaria"*. O que o ADR nao tirou foi a
consequencia: temporaria **em branch**, nunca na `main`.

**O precedente desta casa e explicito:** as 14 branches `upstream-pr/*` carregaram
contribuicao ao upstream e **nunca foram mescladas na nossa `main`** — o conteudo
chegou pela `main` dele, por squash. Removidas em 2026-10-05, com o conteudo
sobrevivendo em `refs/pull/<N>/head`.

Entao a divisao fica assim, e e a mesma de sempre:

| onde | o que leva |
|---|---|
| `chore/pr-upstream-prazo-da-sonda` → [kgsaran/trackfw#590](https://github.com/kgsaran/trackfw/pull/590) | **o produto**, nascido de `upstream/main`, 2 arquivos |
| `fix/o-deadline-da-sonda-do-login-shell` → nossa `main` | **a governanca**: ADR, REQ, este roadmap, handoff |

O conserto chega a nossa `main` pelo `upstream-sync.sh`, quando o upstream
mesclar — e ai a divergencia volta a zero por convergencia, nao por reversao.

🔴 **As medicoes acima continuam valendo, e foram feitas onde o produto esta.**
`go build`, os tres testes, a falsificacao por desarme e a comparacao da suite por
nome rodaram com os dois arquivos na arvore. Fica declarado para que ninguem leia
"o produto nao esta na main" como "o conserto nao foi medido".

**Acceptance criteria:**
- [x] Contexto expirado → `ran=false`, afirmado por teste
- [x] `ExitError` com contexto vivo → `ran=true`, afirmado por teste
- [x] O teste de ponta a ponta usa um `bashExe` que **existe** — nunca um
      inexistente, que passaria sem o conserto
- [x] `stubGitBashSeams` e os testes do ML-5D não mudam — os 7 continuam passando
- [x] `go build ./...` · `go test ./internal/validator/...`
- [x] Cada teste novo declara qual conclusão deste ML ele afirma

**Gates da wave:**
```bash
# cada linha roda como um sh -c separado
go build ./...
go test ./internal/validator/... -run 'GuardGitBash|LoginProbe|GuardProbeEnded|PrazoDoGuardHelp' -count=1
# o produto NAO entra na nossa main (ver ML-1A): aqui o numero certo e ZERO
test "$(git diff --name-only origin/main -- internal cmd | wc -l | tr -d ' ')" = "0"
```
