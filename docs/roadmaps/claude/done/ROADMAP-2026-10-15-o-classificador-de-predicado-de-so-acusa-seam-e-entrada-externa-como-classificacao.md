---
status: done
date: 2026-10-15
req: "docs/requisições/claude/REQ-2026-10-15-o-classificador-de-predicado-de-so-acusa-seam-e-entrada-externa-como-classificacao.md"
squad: "claude"
---

# Roadmap: o classificador de predicado de SO acusa seam e entrada externa como classificacao

> Created: 2026-10-15 | Status: done

## Context
<!-- Derived from REQ: REQ-2026-10-15-o-classificador-de-predicado-de-so-acusa-seam-e-entrada-externa-como-classificacao.md -->
REQ: docs/requisições/claude/REQ-2026-10-15-o-classificador-de-predicado-de-so-acusa-seam-e-entrada-externa-como-classificacao.md

## Acceptance Criteria

- [x] Getter de plataforma reconhecido como costura, com regra estreita que recusa a forma com
      comparação — e falsificada nas duas direções.
- [x] `IsAbs` sobre valor de variável de ambiente declarado no BASELINE com o motivo, por ser a
      mesma classe dos nove anteriores.

## Status Legend
⬜ Pendente · 🔄 Em andamento · ✅ Concluído · ❌ Bloqueado

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model deste roadmap
**Status:** ✅ Concluído
**Files affected:** `scripts/check-os-predicate-classification.sh` (leitura)
**Actions:**

**1. Completude da enumeração.** A lista de superfícies é fechada e foi derivada, não escrita à
mão. O gate reprovou nomeando **2** sítios; a varredura pelos nove predicados no escopo
(`internal/**/*.go`, `cmd/**/*.go`) devolve **298** sítios, e os dois acusados são os únicos fora
do baseline. Para a classe nova, a busca não parou no arquivo que a REQ nomeia:

```
forma do getter   `^\s*return\s+<plataforma>\s*$`      1 sitio  (agentconfig.go:89)
forma comparada   `^\s*return\s+runtime.GOOS\s*==`     0 sitios
```

O segundo número é o que fecha a enumeração: **a classe nova não tem nenhum outro consumidor
hoje**, e a forma que ela precisa recusar não existe no acervo — a regra já a recusa para quando
existir.

**2. Quem esvazia esta Wave 0 sem quebrar regra escrita.** Quem lê os dois sítios **em bloco** e
declara os dois como falso positivo — foi exatamente o que a primeira leitura fez. Nenhuma regra
escrita impede: a ADR fala de "origem do argumento", e `os.Getenv` *parece* origem externa. O que
desmentiu foi comparar com a **forma dos nove já declarados**, não reler a ADR. 🔴 A lição é de
método: antes de declarar sítio novo como classe nova, confira se ele tem a forma de algum sítio
**já declarado** — se tiver, é a mesma classe, e tratá-lo como nova afrouxa o ratchet.

**3. Falsificação nas duas direções.**

| direção | o que quebra |
|---|---|
| a regra regride (deixa de reconhecer o getter) | o gate volta a `rc=1` nomeando `agentconfig.go:89` — medido, é o estado de antes deste ML |
| a regra regride ao contrário (alarga e aceita comparação) | as cinco formas comparadas passariam a contar como costura, e o ratchet fecharia trocando `==` por ajudante — as 5 estão na tabela do ML-1A, e as 5 são recusadas |

**4. Resíduo declarado.** O cego do `effectiveGOOS() ==` — **2 ocorrências medidas**, invisíveis ao
gate porque não usam nenhum dos nove predicados. Fica fora por escopo, com o número de partida
escrito na REQ. E o limite já registrado do gate continua: ele só vê conteúdo **rastreado**
(`git grep`), então sítio em arquivo não commitado passa.

**Acceptance criteria:**
- [x] As quatro seções acima respondidas com evidência, não com asserção de uma linha
- [x] Nenhuma linha de implementação escrita neste ML

**Gates da wave:**
```bash
bash scripts/check-os-predicate-classification.sh
```

## Wave 1 — Implementação
> Dependencies: Wave 0

### ML-1A — O getter de plataforma é costura (D3), com regra estreita
**Status:** ✅ Concluído
**Files affected:** `scripts/check-os-predicate-classification.sh`
**Actions:**
1. Alínea (c) em `eh_d3_costura`: `^[[:space:]]*return[[:space:]]+(${PLATAFORMA})[[:space:]]*$`.
2. Âncora no **fim** da linha, que é o que mantém a regra estreita.
3. Motivo e medição escritos no comentário do próprio classificador.

**Falsificado nas duas direções — 7 formas, 7 acertos:**

```
COSTURA        return runtime.GOOS
COSTURA        return sys.platform
nao-costura    return runtime.GOOS == "windows"
nao-costura    return runtime.GOOS != "windows"
nao-costura    return strings.Contains(runtime.GOOS, "win")
nao-costura    if runtime.GOOS == "windows" {
nao-costura    return fmt.Sprintf("%s", runtime.GOOS)
```

As cinco últimas são o que importa: **comparar ou embrulhar é classificar**, e a regra recusa as
cinco. A sétima entrou porque `Sprintf` não é comparador e passaria por "argumento inteiro" na
alínea (b) se a âncora fosse frouxa.

**Acceptance criteria:**
- [x] As 7 formas medidas, com o veredito esperado declarado antes da execução
- [x] O gate sai `rc=0` com o denominador reconciliando: 186 + 64 + 7 + 27 + 14 = 298

### ML-1B — O `IsAbs` sobre variável de ambiente entra no BASELINE com o motivo
**Status:** ✅ Concluído
**Files affected:** `scripts/check-os-predicate-classification.sh`
**Actions:**
1. Entrada `internal/agentconfig/agentconfig.go` no `BASELINE`, com o motivo escrito: é a mesma
   forma dos nove anteriores, e o motivo registra que a primeira leitura errou e o que desmentiu.
2. O motivo nomeia que o sítio `:89` do **mesmo arquivo** não está ali, por ser seam.

🔴 **E a primeira redação do motivo levou BACKTICK, que o bash executou** — o `BASELINE` é string
de aspas duplas, então `` `!filepath.IsAbs(clean)` `` virou substituição de comando e o gate saiu
`rc=2` com `syntax error near unexpected token`. Nenhuma das nove entradas anteriores usa backtick,
e agora está escrito por quê. É a memória `backtick-na-mensagem-de-commit-e-executado`, cometida
dentro do arquivo que ela deveria proteger.

**Acceptance criteria:**
- [x] O motivo está escrito, e nomeia a medição que corrigiu a leitura (D4: baseline sem motivo é
      o mesmo que não ter regra)
- [x] O gate sai `rc=0`, e o arquivo aparece entre os declarados: `14 em 10 arquivo(s) declarado(s)`

**Gates da wave:**
```bash
bash scripts/check-os-predicate-classification.sh
bash scripts/run-local-gates.sh
```
