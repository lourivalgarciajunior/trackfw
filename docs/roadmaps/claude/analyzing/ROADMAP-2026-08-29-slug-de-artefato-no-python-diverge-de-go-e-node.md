---
status: analyzing
date: 2026-08-29
req: REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node
squad: ""
---

# Roadmap: Slug de artefato no Python diverge de Go e Node

> Created: 2026-08-29 | Status: analyzing

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
**Status:** pending
**Files affected:** `docs/cli-parity.md`
**Actions:**
1. Escolher entre colapso por hifen (Go e Node, hoje 2 contra 1) e delecao (Python).
2. Registrar a decisao e o motivo. Colapso por hifen preserva a fronteira de palavra —
   `C/C++` vira `c-c` e nao `cc` — o que argumenta a favor dele, mas a decisao e explicita.
**Acceptance criteria:**
- [ ] Regra escrita em `docs/cli-parity.md` com o motivo, nao so o comportamento

### ML-1B — Alinhar o `slugify` do `adr.py`
**Status:** pending
**Files affected:** `pypi/trackfw/generators/adr.py` (funcao `slugify`, linhas 19-23)
**Actions:**
1. Trocar `.replace(' ', '-')` + `re.sub(r'[^a-z0-9-]', '', slug)` pelo
   `re.sub(r"[^a-z0-9]+", "-", slug)` que `note.py`, `req.py` e `roadmap.py` ja usam.
2. Verificar em execucao real do CLI, diretorio limpo por runtime.
**Acceptance criteria:**
- [ ] `adr new "Acao C/C++ & Cafe"` produz `acao-c-c-cafe` nos tres runtimes
- [ ] `req`, `roadmap` e `note` continuam concordando — nao regrediram
- [ ] Suites sem regressao contra a medicao de 2026-08-29 (Go 6 pacotes FAIL, npm 297, pypi 213)

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
