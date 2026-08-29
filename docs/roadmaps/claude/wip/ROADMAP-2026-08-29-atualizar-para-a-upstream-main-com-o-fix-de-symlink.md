---
status: wip
date: 2026-08-29
req: REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink
squad: ""
---

# Roadmap: Atualizar para a upstream main com o fix de symlink

> Created: 2026-08-29 | Status: wip

## Context

Primeiro `git merge upstream/main` real depois da ancestralidade. Traz correcao de escrita
arbitraria por symlink (HIGH) mais dois pins de versao. Oito arquivos em colisao com os fixes
locais de CRLF, `homedir` e `tty`.

REQ: docs/requisições/claude/REQ-2026-08-29-atualizar-para-a-upstream-main-com-o-fix-de-symlink.md

## Acceptance Criteria

- [ ] Merge concluido, sem marcador de conflito
- [ ] Os seis gates verdes
- [ ] Cada fix local derrubado tem o gate que o acusou registrado — ou o buraco declarado
- [ ] `go build ./...` verde
- [ ] Suite pypi sem regressao por lista nomeada contra 95 falhas
- [ ] Symlink verificado como corrigido em execucao real, nos tres runtimes
- [ ] Governanca do upstream fora, conforme a ADR

## Wave 0 — Threat Model
> Dependencies: none. Blocks all implementation.

### ML-0A — Threat model for this roadmap
**Status:** pending
**Actions:**
1. Enumerar o que o merge traz e o que ele pode derrubar — nao so os 8 arquivos em colisao, mas
   qualquer fix local cuja funcao o upstream tenha reescrito.
2. Threat model: quem esvazia esta wave sem quebrar regra escrita.
3. Falsificacao nas duas direcoes.
4. Residual declarado.
**Acceptance criteria:**
- [ ] As quatro secoes respondidas com evidencia medida
- [ ] Nenhuma linha de implementacao escrita nesta ML

**Gates da wave:**
```bash
exit 1  # placeholder — substituir antes de marcar ML-0A done
```

## Wave 1 — O merge
> Dependencies: ML-0A

### ML-1A — Merge e resolucao
**Status:** pending
**Files affected:** os 8 em colisao, mais o que o merge trouxer limpo
**Actions:**
1. `git merge upstream/main`.
2. Resolver tomando o upstream como base e reaplicando os fixes locais por cima — mesma politica da
   ADR: produto vem do upstream, divergencia local e reaplicada com o motivo escrito.
3. Manter a governanca do upstream fora.
**Acceptance criteria:**
- [ ] Nenhum marcador de conflito em arquivo versionado
- [ ] `docs/` continua com a governanca local apenas
- [ ] `go build ./...` verde

### ML-1B — Recuperar o que o merge derrubou
**Status:** pending
**Actions:**
1. Rodar os seis gates. Para cada reprovacao, reaplicar o fix local.
2. **Registrar qual gate acusou cada perda.** Se um fix sumir sem nenhum gate reprovar, isso e
   buraco de cobertura e entra como achado, nao como detalhe.
**Acceptance criteria:**
- [ ] Seis gates verdes
- [ ] Tabela de "o que caiu / qual gate pegou" escrita aqui

## Wave 2 — Verificacao
> Dependencies: ML-1A, ML-1B

### ML-2A — Symlink e regressao
**Status:** pending
**Actions:**
1. Reproduzir a vulnerabilidade em arvore pre-merge e confirmar que some pos-merge, nos tres
   runtimes — verificacao por efeito, nao por leitura do diff.
2. Suite pypi por lista nomeada contra 95 falhas.
**Acceptance criteria:**
- [ ] Symlink apontando para fora do projeto **nao** e mais sobrescrito por `update`
- [ ] Symlink pendurado **nao** faz `discover --init` criar arquivo fora do projeto
- [ ] Zero falhas novas na lista nomeada
