---
name: config-listas-nao-silenciosas-2026-08-16
title: "Parser de trackfw.yaml para de descartar listas em silêncio"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-config-listas-nao-silenciosas
branch: fix/config-listas-nao-silenciosas
---

# Roadmap: listas do config não silenciosas

> Created: 2026-08-16 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-16-config-listas-nao-silenciosas.md`

## Diagnóstico / Contexto

O parser caseiro entende uma das três formas de lista do YAML e descarta as outras sem dizer nada.
O exemplo do próprio README usa uma das descartadas. Medições por forma e por bloco, e a decisão
de rota, estão na REQ.

Origem: item 4 da dívida — era um lead, virou achado com o README junto.

**Rota:** recusar em voz alta, não cobrir tudo. Exceção registrada na REQ: para o bloco não
indentado o alinhamento é para cima, porque o Python já o processa corretamente.

## Critérios de Aceite

- [x] Bloco não indentado funciona nos três
- [x] Lista inline avisa em stderr nos três, nomeando a chave e mostrando a forma correta
- [x] Aviso uma vez por processo; nenhum aviso para configs em bloco
- [x] README corrigido
- [x] Suítes e gates verdes

---

## Wave 1 — Parser por runtime

> Go define o formato da mensagem; npm e Python espelham palavra por palavra, para o usuário ver a
> mesma coisa em qualquer runtime.

### ML-1 — Go: aceita bloco não indentado e avisa sobre inline
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/config/config.go`, `internal/config/config_test.go`
**Ações:**
1. Tratar linhas `- x` como item de lista **antes** do teste de indentação, para que uma linha não
   indentada não dispare o flush dos blocos abertos — é isso que hoje as descarta.
2. Nas chaves de lista (`adr_dirs`, `agents`, `acceptance_markers`), detectar valor na mesma linha e
   acumular um aviso.
3. Emitir os avisos em stderr ao fim do `Load()`, dentro do `sync.Once` — uma vez por processo.
4. Testes: bloco não indentado popula; inline avisa e não popula; bloco não avisa.
**Critérios de aceite:**
- [x] `agents:` e `adr_dirs:` em bloco não indentado populam corretamente
- [x] `agents: [a, b]` deixa a chave vazia **e** emite aviso nomeando-a, com a forma correta
- [x] Config em bloco — indentado ou não — não emite aviso nenhum
- [x] Aviso sai uma vez, dentro do `sync.Once` do `Load()`
- [x] Não-vacuoso: removendo só o tratamento de `- ` sem indentação,
      `Agents: want [claude apolo], got []`; e sem a mudança de assinatura o pacote nem compila
**Comandos de validação:** `go build ./... && go test ./internal/config/`

### ML-2 — Node.js: espelha
**Status:** ✅ Concluído
**Arquivos afetados:** `npm/src/config/index.js`, `npm/tests/config.test.js`
**Ações:** mesmos três pontos do ML-1, com a mensagem idêntica.
**Critérios de aceite:**
- [x] Mesmo comportamento e mensagem idêntica à do Go
- [x] O teste captura `console.error`, cobrindo o que o usuário vê, não só o retorno do parser
**Comandos de validação:** `node npm/tests/config.test.js`

### ML-3 — Python: aviso de inline
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/trackfw/config.py`, `pypi/tests/test_config.py`
**Ações:**
1. O bloco não indentado já funciona — nada a mudar ali.
2. Acrescentar a detecção de inline e o mesmo aviso.
**Critérios de aceite:**
- [x] Aviso idêntico ao dos outros dois
- [x] Bloco não indentado continua funcionando — nada foi tocado nesse caminho
**Comandos de validação:** `cd pypi && python -m pytest tests/test_config.py -q`

---

## Wave 2 — Documentação e fechamento

### ML-4 — README e verificação de ponta a ponta
**Status:** ✅ Concluído
**Arquivos afetados:** `README.md`
**Ações:**
1. Trocar `agents: [claude, gemini, copilot]` pela forma de bloco em `README.md:199`.
2. Varrer o resto da documentação por outras ocorrências da forma inline em exemplo de config.
3. Fixture única nos três runtimes: bloco indentado, bloco não indentado e inline — comparar o que
   cada um popula e o que avisa.
4. Suítes e os três gates.
**Critérios de aceite:**
- [x] `README.md:199` passa a usar bloco, com nota explicando que a forma inline não é lida
- [x] Varredura em `README.md`, `docs/*.md` e `site/`: nenhum outro exemplo inline de config
- [x] Os três runtimes concordam nas três formas:

```
forma            go         npm        py
indentado        silencio   silencio   silencio
NAO indentado    silencio   silencio   silencio
inline           AVISA      AVISA      AVISA
```

- [x] `go test ./...` zero falhas, `go vet` limpo, `gofmt -l` zero
- [x] npm: 16 + 3 + 7 testes verdes
- [x] pypi: **291 passed**
- [x] Os três gates de paridade passam
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh`
