---
status: done
date: 2026-08-29
req: docs/requisições/claude/REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate.md
---

# Roadmap: Politica de conteudo do upstream sem gate

> Created: 2026-08-29 | Status: done

## Context

A ADR diz que conteudo do upstream nao e importado. A politica nao e auto-aplicavel: entrou tres
vezes nesta sessao, sempre sem conflito, porque caminho novo nao colide com nada.

REQ: docs/requisições/claude/REQ-2026-08-29-politica-de-conteudo-do-upstream-sem-gate.md

## Acceptance Criteria

- [x] Reprova com cada um dos tres vazamentos historicos, um a um
- [x] Passa no estado atual
- [x] Lista de mantidos explicita, cada entrada com motivo
- [x] Sem `upstream/main`, falha dizendo isso — nunca passa por nao conseguir checar

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** ✅ Concluído

#### 1. Completude da enumeracao

O que a politica cobre, medido em `upstream/main` contra a arvore local:

| Area | Arquivos coincidentes | Situacao |
|---|---|---|
| `docs/` | 10 | todos legitimos, viram a lista de mantidos |
| `vault/` | 0 | removido na #19 e na #29 |

**Fora de escopo, e o oposto:** `internal/`, `npm/src/`, `pypi/trackfw/`, `scripts/`. Ali coincidir
com o upstream e o comportamento **desejado** — produto vem dele. Um gate que reclamasse disso
estaria invertido.

#### 2. Quem esvazia esta Wave 0 sem quebrar regra escrita

1. **Acrescentar o arquivo novo a lista de mantidos** em vez de remove-lo. E o caminho de menor
   resistencia quando o gate reprova no meio de um merge. **Coberto parcialmente:** o criterio
   exige motivo escrito por entrada, o que torna o silencio visivel — mas nao impede alguem de
   escrever um motivo ruim.
2. **Rodar o gate sem `upstream/main` buscado.** Sem a referencia ele nao tem contra o que comparar
   e passaria vazio. **Coberto:** falha explicita, nunca passe silencioso.
3. **Comparar contra `v7.3.0` em vez de `upstream/main`.** A tag e antiga; arquivo novo do upstream
   nao estaria nela e passaria. **Coberto:** o gate fixa `upstream/main`.
4. **Ampliar o escopo para `internal/`** achando que "mais cobertura e melhor". Inverteria o
   sentido e reprovaria todo o produto. **Coberto:** escopo declarado na REQ e comentado no gate.

#### 3. Alvos de falsificacao, nas duas direcoes

| Regride para | Quebra o que |
|---|---|
| sem gate (hoje) | conteudo do upstream entra sem conflito; ja aconteceu tres vezes |
| gate que ignora `vault/` | os dois vazamentos de #28 e #29 voltam a passar |
| gate que passa sem `upstream/main` | verde por nao conseguir checar — o pior estado, porque parece cobertura |
| lista de mantidos sem motivo | vira deposito: cada reprovacao acrescenta uma linha e a politica evapora |

A ultima e a mais provavel a longo prazo, e nenhum gate a impede sozinho. Por isso o motivo escrito
e criterio de aceite, e nao gosto pessoal.

#### 4. Residual declarado

- **Nao cobre conteudo do upstream que chegue com outro nome.** Se alguem copiar uma nota do vault
  para `docs/notas/`, o caminho nao coincide e o gate nao ve. O sinal e proveniencia por caminho,
  nao por conteudo.
- **Nao cobre `.claude/`, `.codex/` e afins.** O merge tambem traz configuracao de ferramenta de IA
  do upstream. Fora de escopo aqui; se virar problema, vira REQ propria.
- Depende de `git fetch upstream`. Nao ha CI neste repo (`ci: none`), entao o gate e local por
  natureza.

**Acceptance criteria:**
- [x] As quatro secoes respondidas com evidencia medida
- [x] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
bash scripts/check-upstream-content.sh
```

## Wave 1 — O gate

### ML-1A — Escrever e falsificar o gate
**Status:** ✅ Concluído
**Files affected:** `scripts/check-upstream-content.sh` (novo)
**Actions:**
1. Comparar `git ls-files docs vault` contra `git ls-tree -r upstream/main docs vault`.
2. Reprovar a interseccao que nao estiver na lista de mantidos.
3. Falhar explicitamente se `upstream/main` nao existir localmente.
**Acceptance criteria:**
- [x] Passa no estado atual
- [x] Reprova com cada um dos tres vazamentos historicos, testado um a um
- [x] Reprova sem `upstream/main`

---

## Falsificacao — os quatro criterios, um a um

Nao em bloco: cada vazamento historico reintroduzido sozinho, testado, e removido antes do proximo.

```
#28  vault/notes/index.md    rc=1  acusa vault/notes/index.md
#29  nota de vault           rc=1  acusa update-segue-symlink-...-2026-08-28.md
#31  ADR do upstream         rc=1  acusa ADR-2026-08-28-gate-de-ci-...

sem upstream/main            rc=1  "nao consigo checar — rode git fetch upstream"
estado atual                 rc=0  "nada indevido em docs/ nem em vault/"
```

O quarto e o que separa este gate de um teatro: **verde por nao conseguir checar seria pior que
vermelho**, porque pareceria cobertura. Foi a licao que atravessou a sessao inteira — gate que passa
pelo motivo errado.

## O que este gate NAO resolve

A lista de mantidos pode virar deposito. Nada impede que a proxima reprovacao no meio de um merge
seja "resolvida" acrescentando uma linha ao `KEEP`. O motivo escrito por entrada torna isso visivel
a quem le, e nao mais que isso — e por isso o motivo e criterio de aceite, nao gosto.
