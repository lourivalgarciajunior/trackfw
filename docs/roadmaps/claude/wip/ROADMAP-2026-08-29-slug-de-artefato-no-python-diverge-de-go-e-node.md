---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node
squad: ""
---

# Roadmap: Slug de artefato no Python diverge de Go e Node

> Created: 2026-08-29 | Status: wip

## Context

Os tres runtimes geram nomes de arquivo diferentes para o mesmo titulo quando ele contem
caractere nao-alfanumerico que nao seja espaco. Python **deleta** os nao-alfanumericos; Go e Node
os **substituem por hifen**. Medido com `adr new` em diretorio limpo por runtime:
`acao-cc-cafe` (Python) contra `acao-c-c-cafe` (Go e Node).

REQ: docs/requisições/claude/REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node.md

## Acceptance Criteria

- [ ] `adr new` produz o mesmo nome nos tres runtimes, em execucao real do CLI
- [ ] O `artifactId` do `pom.xml` concorda entre Go e Node (o Python nao tem esse gerador)
- [ ] A regra escolhida documentada em `docs/cli-parity.md`, com o motivo — nao so o comportamento
- [ ] `check-artifact-parity.sh` cobre `/`, `+` **e acento**, e **falha** com cada uma das duas
      divergencias reintroduzida separadamente
- [ ] `scripts/check-slug-inventory.sh` segue verde

> `req new`, `roadmap new` e `note new` ja concordam nos tres runtimes — medido em ML-0A. Nao sao
> trabalho; entram so como regressao a nao introduzir.

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** done
**Files affected:** `scripts/check-slug-inventory.sh` (novo)

#### 1. Completude da enumeracao

A REQ nomeava tres arquivos. A busca no repositorio devolve **dez implementacoes** em
**cinco superficies**, e a busca nao se limitou aos arquivos citados: procurei por funcao que
produza slug em todos os runtimes, e depois pelo literal que o artefato final contem.

| Runtime | Implementacoes | Observacao |
|---|---|---|
| Go | 1 — `internal/generators/adr.go:151 toSlug` | compartilhada por adr, req, roadmap, note **e `java.go`** |
| Node | 5 — `toSlug` em `adr.js`, `note.js`, `req.js`, `roadmap.js` + inline em `init.js:336` | as quatro `toSlug` sao byte a byte identicas (md5 `88e397b4`) |
| Python | 4 — `slugify` em `adr.py`, `note.py`, `req.py`, `roadmap.py` | **`adr.py` diverge das outras tres** |

Quatro tipos de artefato, nao tres: `adr`, `req`, `roadmap` e **`note`** — a REQ omitiu `note`.
Mais uma quinta superficie que nao gera artefato de governanca: o `artifactId` do `pom.xml`.

#### 2. O defeito real e mais estreito e mais largo que o descrito

**Mais estreito.** Medido com `adr|req|roadmap new "Acao C/C++ & Cafe"`, um diretorio limpo por
runtime:

```
adr new       go acao-c-c-cafe   node acao-c-c-cafe   py acao-cc-cafe    <- diverge
req new       go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
roadmap new   go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
note new      go acao-c-c-cafe   node acao-c-c-cafe   py acao-c-c-cafe
```

Nao e "o Python diverge". E **`pypi/trackfw/generators/adr.py:slugify` sozinho**: ele faz
`.replace(' ', '-')` e depois `re.sub(r'[^a-z0-9-]', '', slug)` — deleta. `note.py`, `req.py` e
`roadmap.py` fazem `re.sub(r"[^a-z0-9]+", "-", slug)` — colapsam, igual a Go e Node. O criterio da
REQ que dizia "vale para adr, req e roadmap" esta errado: os outros dois ja passam.

**Mais largo.** Uma segunda divergencia, independente, na superficie do `pom.xml`. O Go usa o
`toSlug` compartilhado, que dobra acento via NFKD; o Node usa expressao inline sem NFKD:

```
"Cafe App" (com acento)   ->   Go: cafe-app     Node: caf-app
```

O Node perde a letra em vez de dobrar. O Python nao tem esse gerador, entao a paridade ali e 2
runtimes, nao 3.

#### 3. Quem esvazia esta Wave 0 sem quebrar regra escrita

O inventario e a unica coisa que este gate protege, e ele e verificavel por listagem. Tres formas
de esvaziar:

1. **Adicionar uma decima primeira implementacao** em vez de reusar. Nada no repositorio proibe
   copiar `toSlug` para um gerador novo — o Node ja tem quatro copias, entao o precedente esta
   estabelecido e nenhuma regra e violada. **Coberto:** o gate lista e compara.
2. **Corrigir so o `adr.py`** e declarar a paridade resolvida, deixando a divergencia do `pom.xml`
   viva. O criterio da REQ, como estava escrito, permitia exatamente isso. **Coberto:** o criterio
   foi reescrito para nomear as duas divergencias.
3. **Ampliar a fixture do `check-artifact-parity.sh` com `/` e `+` mas nao com acento**, o que
   pegaria o defeito do `adr.py` e nao o do `pom.xml`. **Nao coberto por gate** — fica como
   criterio explicito no ML-2A.

#### 4. Alvos de falsificacao, nas duas direcoes

| Superficie | Regride para | Quebra o que |
|---|---|---|
| `adr.py` | delecao (hoje) | ADR criada pelo Python nao casa com a referencia escrita por Go ou Node; `ref_targets_exist` acusa link morto |
| `adr.py` | colapso, mas sem `strip('-')` | slug com hifen na ponta; nome de arquivo valido, cadeia quebra silenciosamente |
| `pom.xml` Node | sem NFKD (hoje) | `artifactId` perde letra; build Maven gerado por Node e por Go diferem |
| `pom.xml` Go | sem NFKD tambem | os dois passam a concordar **no valor errado** — paridade verde, comportamento pior. E por isso que o criterio exige a regra documentada, nao so "os tres iguais" |
| inventario | uma copia nova | divergencia futura sem ninguem notar |

A quarta linha e a que importa: **paridade sozinha nao e criterio suficiente**. Tres runtimes
concordando num slug que perde caractere e um estado verde e errado.

#### 5. Residual declarado

Fora de escopo, por contrato proprio e verificado:

- `internal/identity/slug.go` + `npm/src/identity/slug.js` + `pypi/trackfw/identity/` — slug de
  identidade de agente, com fixture de vetores em `internal/identity/testdata/slug_vectors.json`.
  Contrato diferente: rejeita entrada vazia, so-hifens, emoji e nome longo, coisas que o slug de
  artefato aceita.
- `deriveSlug` / `_derive_slug` nos tres runtimes — deriva slug de URL em `thirdparty`, nao de
  titulo.
- `normalizeBranchSlug` / `normalize_branch_slug` — normaliza nome de branch para casar com
  roadmap. Nao produz nome de arquivo.

Nao coberto e aceito: o `note new` do Python imprime `vault/notesrquivo.md`, com separador
misto, enquanto Go e Node imprimem `vault
otesrquivo.md`. E divergencia de saida no Windows,
nao de nome de arquivo — o arquivo criado e o mesmo. Fica registrado sem virar trabalho.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida, nao assercao de uma linha
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
bash scripts/check-slug-inventory.sh
```

O gate lista as dez implementacoes e compara com o inventario declarado. Passa hoje; **falha**
com uma decima primeira adicionada — verificado, nao assumido:

```
Wave 0: inventario de slug mudou.
6a7
> pypi/trackfw/generators/_naovacuidade.py:slugify
rc=1
```

## Wave 1 — Alinhar a regra
> Dependencies: ML-0A

### ML-1A — Decidir e documentar a regra de colapso
**Status:** done
**Files affected:** `docs/cli-parity.md` (nova secao `## Artifact slug contract`, linha 166)

**Decisao: colapso por hifen.** `[^a-z0-9]+` -> um hifen, nunca delecao.

Dois motivos, nesta ordem:

1. **Delecao junta tokens que o titulo separava.** `C/C++ & Cafe` vira `cc-cafe` em vez de
   `c-c-cafe`; `AWS+GCP` vira `awsgcp` em vez de `aws-gcp`. O nome de arquivo existe para ser lido
   por gente, e a fronteira de palavra e o que o torna legivel.
2. **9 das 10 implementacoes ja colapsam.** Alinhar a decima e a mudanca menor.

#### A descoberta que explica a origem do defeito

Ao escrever a secao, o `cli-parity.md` revelou que o contrato de slug de **identidade de agente**
manda **descartar** o caractere fora de `[a-z0-9-]` — o oposto do de artefato. Medido:

| Entrada | Identidade | Artefato |
|---|---|---|
| `C/C++` | `cc` | `c-c` |
| `AWS+GCP` | `awsgcp` | `aws-gcp` |
| `Meu Agente` | `meu-agente` | `meu-agente` |

Sao dois contratos separados de proposito: identidade e identificador curto, validado e sujeito a
colisao; artefato e nome de arquivo legivel. A terceira linha e a armadilha — eles coincidem no
caso comum.

O defeito nao e um erro aleatorio: **`pypi/trackfw/generators/adr.py:slugify` implementa a regra de
identidade onde vai a de artefato.** As duas secoes do `cli-parity.md` agora se referenciam
mutuamente, com a instrucao explicita de nao unificar.

**Acceptance criteria:**
- [x] Regra escrita em `docs/cli-parity.md` com o motivo, nao so o comportamento
- [x] A separacao contra o contrato de identidade documentada nas duas direcoes
- [x] `check-parity-contract-coverage.sh` verde (as tres subsecoes novas anotadas; a anotacao da
      secao de identidade, que minha insercao havia deslocado, devolvida ao lugar)

> **Quarto bloqueio de Windows encontrado aqui, fora de escopo:**
> `scripts/check-parity-contract-coverage.sh` morre com `UnicodeEncodeError` no `->` em console
> cp1252. Pre-existente — verificado rodando o gate na `main` sem esta mudanca, com 65 ocorrencias
> do caractere no doc. So roda com `PYTHONIOENCODING=utf-8`. Junta-se ao UTF-8 do CLI, ao `homedir`
> e ao `credential_guard_hook_resolvable`.

### ML-1B — Alinhar o `slugify` do `adr.py`
**Status:** done
**Files affected:** `pypi/trackfw/generators/adr.py` (funcao `slugify`)

**O que mudou:** `.replace(' ', '-')` + `re.sub(r'[^a-z0-9-]', '', slug)` viraram
`re.sub(r"[^a-z0-9]+", "-", slug)` — o mesmo corpo que `note.py`, `req.py` e `roadmap.py` ja
tinham. A docstring registra que a versao antiga aplicava a regra do slug de *identidade de
agente*, para ninguem "corrigir de volta".

**Medicao — `new "Acao C/C++ & Cafe"`, diretorio limpo por runtime, quatro tipos de artefato:**

```
go    ADR-...-acao-c-c-cafe.md  REQ-...-acao-c-c-cafe.md  ROADMAP-...-acao-c-c-cafe.md  acao-c-c-cafe-....md
node  ADR-...-acao-c-c-cafe.md  REQ-...-acao-c-c-cafe.md  ROADMAP-...-acao-c-c-cafe.md  acao-c-c-cafe-....md
py    ADR-...-acao-c-c-cafe.md  REQ-...-acao-c-c-cafe.md  ROADMAP-...-acao-c-c-cafe.md  acao-c-c-cafe-....md
```

**Regressao:** `test_generators_{adr,req,roadmap}.py` dao **6 failed / 73 passed** com o fix e
**6 failed / 73 passed** sem ele — identico, medido trocando o arquivo pelo do HEAD e voltando. As
6 sao as falhas de Windows ja registradas na migracao.

**Acceptance criteria:**
- [x] `adr new "Acao C/C++ & Cafe"` produz `acao-c-c-cafe` nos tres runtimes
- [x] `req`, `roadmap` e `note` continuam concordando — nao regrediram
- [x] Suites sem regressao: suite pypi completa deu **198 failed / 1294 passed**, contra
      213/1307 medidos na migracao. Melhorou; a diferenca vem dos testes locais removidos la

> **Buraco conhecido ate ML-2A:** nenhum teste da suite falha com a divergencia reintroduzida — a
> suite pypi passa identica nos dois estados. O fix esta guardado hoje **so por medicao manual**.
> E exatamente o que o ML-2A existe para fechar, e por isso ele nao e opcional.

### ML-1C — Alinhar o slug do `artifactId` no `pom.xml`
**Status:** pending
**Files affected:** `npm/src/generators/init.js:336` (`generatePomXml`)
**Actions:**
1. O Go usa `toSlug`, que dobra acento via NFKD; o Node usa expressao inline sem NFKD e por isso
   perde a letra: `Cafe App` (com acento) vira `caf-app` no Node e `cafe-app` no Go.
2. Alinhar o Node ao Go — reusar o `toSlug` do proprio `npm/src/generators/`, nao escrever uma
   quinta variante inline.
**Acceptance criteria:**
- [ ] `Cafe App` (com acento) produz `cafe-app` nos dois runtimes
- [ ] O inline de `init.js` deixa de existir; `check-slug-inventory.sh` atualizado para 9

## Wave 2 — Fechar o buraco do gate
> Dependencies: ML-1B

### ML-2A — Ampliar a fixture de `check-artifact-parity.sh`
**Status:** pending
**Files affected:** `scripts/check-artifact-parity.sh`
**Actions:**
1. Incluir `/` e `+` no `TITLE` da linha 43 — hoje e `"Autenticacao e Sessao"`, so acento, que e
   exatamente por que o gate passa enquanto o defeito do `adr.py` existe.
2. Manter o acento: ele e o que pega a divergencia do `pom.xml`. As duas classes precisam estar na
   mesma fixture, ou o gate cobre uma e perde a outra — ver ML-0A secao 3, forma 3.
**Acceptance criteria:**
- [ ] Gate passa com as duas correcoes
- [ ] Gate **falha** com a divergencia do `adr.py` reintroduzida sozinha
- [ ] Gate **falha** com a divergencia do `pom.xml` reintroduzida sozinha
- [ ] Nao-vacuidade verificada nas duas, com a saida colada aqui
