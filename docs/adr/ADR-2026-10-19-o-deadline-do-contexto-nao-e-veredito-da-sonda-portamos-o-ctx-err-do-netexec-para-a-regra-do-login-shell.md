---
status: Accepted
date: 2026-10-19
author: "Lourival Garcia"
---

# ADR: O deadline do contexto nao e veredito da sonda - portamos o ctx.Err do netexec para a regra do login shell

> Date: 2026-10-19 | Status: Accepted

## Context

A regra `guard_binary_probe` (ML-5D) classifica o **estouro do deadline** da
sonda do login shell como *"o Git Bash não acha o `trackfw` no PATH"* e emite
violação. O doc da própria função promete o contrário — o terceiro caso,
`("", false)` para *"the context deadline expired"*, nunca se realiza, porque
`exec.CommandContext` mata o processo e `cmd.Output()` devolve `*exec.ExitError`.

Medido em 2026-10-19 e levado ao upstream na
[#589](https://github.com/kgsaran/trackfw/issues/589): com o `trackfw`
**presente** no PATH do login shell, timeout de 1 s, 300 ms ou 1 ms produz
violação; a sonda custa 2,0 a 2,25 s nesta máquina contra deadline de 5 s.

🔴 **O discriminante correto já está neste repositório, e os dois arquivos se
citam em uma direção só.** `internal/commands/netexec.go` decide, pela ADR D1 do
prazo de rede:

```go
// Returns (isTimeout=true, _) when ctx.Err() != nil — the context deadline expired.
if ctx.Err() != nil {
    return true, false
}
```

E o comentário do `cmdWaitDelay`, no mesmo arquivo, diz: *"Matches the precedent
in internal/validator/validator_guard_binary_probe.go"*. O `WaitDelay` viajou da
sonda para o netexec; o `ctx.Err()` não voltou.

Esta ADR existe porque a decisão **de portar** é nossa: a ADR que decidiu a
classificação é do upstream, e o `upstream-sync.sh` retém `docs/` — a governança
dele não entra aqui. Sem este registro, o conserto apareceria como invenção
local em vez de convergência.

## Decision

**A classificação do erro da sonda do login shell passa a perguntar ao contexto
primeiro, e a classificação vive em função própria.**

1. `ctx.Err() != nil` → **skip** (`ran=false`). Deadline não é veredito do login
   shell, e isso vale qualquer que seja o erro que o `exec` devolva.
2. Só depois se pergunta se o erro é `*exec.ExitError` — aí sim, bash rodou e
   saiu ≠ 0, e `ran=true`.
3. A classificação sai do corpo de `guardRunBashLoginProbe` para uma função
   própria, **pelo mesmo motivo escrito no `resolveNetworkErr`**: *"so the
   classification logic is tested once and applied consistently"*. É isso que
   torna o terceiro caso do doc testável sem executável falso.

🔴 **Não se aumenta o deadline.** Aumentar reduz a frequência e **não muda a
classificação**: com carga suficiente o falso positivo volta. O defeito é o
balde, não o número.

## Consequences

**O que melhora.** Uma regra de segurança deixa de acender sem causa. O custo de
aviso que acende sozinho já está nomeado neste repositório — é o diagnóstico da
[#530](https://github.com/kgsaran/trackfw/issues/530): ruído permanente faz aviso
deixar de ser lido, e aqui a mensagem afirma que a cerca falha aberta.

**O terceiro caso do doc passa a ser verdade, e ganha teste.** Hoje
`guardRunBashLoginProbe` é seam substituída em **todos** os testes
(`stubGitBashSeams` troca as três), e o corpo nunca é exercitado — é por isso que
o ramo sobreviveu desde o ML-5D. Extrair a classificação é o que permite
afirmá-la sem depender de processo externo, que no Windows seria frágil.

**O que NÃO muda, e é o que impede o conserto de ser "silenciar tudo".** `command
-v` que sai ≠ 0 com o contexto vivo continua devolvendo `ran=true`, e a regra
continua acusando. O cenário do ML-5D — `~/bin` com binário velho sombreando —
segue coberto pelos testes existentes, sem mudança neles.

**Divergência de produto, declarada.** Este conserto cria divergência contra o
`upstream/main`, que hoje é zero. É deliberada e temporária: a issue está aberta
lá, e a divergência some quando ele mesclar — ou quando um PR nosso for aceito.
Medida ancorada na **base de merge**, nunca por dois-pontos.

**O que fica no ar.** Não medi a interação com o `WaitDelay` de 5 s: nas passadas
feitas o processo morreu pelo contexto antes dele. E a violação saiu **duas
vezes** na mesma corrida, o que não foi isolado — o sítio da chamada retorna na
primeira mensagem não vazia, então a duplicação deve vir do `validate` avaliar a
regra para mais de um escopo de settings. Observação, não diagnóstico.

## Alternatives Considered

**Aumentar o deadline de 5 s para 15 s.** Rejeitada por não tocar na causa: a
classificação continuaria errada, e o falso positivo voltaria sob carga maior.
Trocaria um defeito visível por um defeito raro — pior de diagnosticar.

**Tornar o deadline configurável por variável de ambiente.** Rejeitada por ser
conceito novo na superfície do produto. O `TRACKFW_NETWORK_TIMEOUT` existe para
operação de rede; sonda local não tem essa porta, e abrir uma exigiria decisão
própria com contrato documentado.

**Reescrever a sonda para não usar processo externo.** Rejeitada: ler o PATH do
**login shell** exige iniciar o login shell. Não há atalho que responda a mesma
pergunta.

**Deixar como está e só registrar na memória de agente.** Rejeitada porque foi o
que já havia: a nota existe, e eu mesmo quase relatei o falso positivo como fato
sobre o PATH desta máquina. Nota não conserta regra.

**Esperar o upstream consertar, sem divergir.** Rejeitada **nesta onda**: o
conserto é de três linhas e a regra acende em toda corrida de `validate` sob
carga. O precedente desta casa é levar a medição **e** oferecer o PR — foi o
caminho da #581, que virou produto do upstream em menos de 24 h.
