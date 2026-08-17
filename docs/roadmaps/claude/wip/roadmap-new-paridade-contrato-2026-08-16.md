---
name: roadmap-new-paridade-contrato-2026-08-16
title: "Contrato de roadmap new igual nos três runtimes"
status: wip
date: 2026-08-16
req: REQ-2026-08-16-roadmap-new-paridade-contrato
branch: fix/roadmap-new-paridade-contrato
---

# Roadmap: contrato de roadmap new

> Created: 2026-08-16 | Status: wip

REQ: `docs/requisições/claude/REQ-2026-08-16-roadmap-new-paridade-contrato.md`

## Diagnóstico / Contexto

A divergência não é só a exigência de REQ: a superfície de flags difere inteira entre os três, e o
Python não tem sequer como linkar uma REQ. O Go, além disso, faz no-op silencioso com exit 0
quando não há REQ. Tabela completa e a decisão de rota estão na REQ.

Origem: item 11 da dívida, achado de passagem em
`REQ-2026-08-16-consistencias-template-saida-e-eol`.

**Decisão:** sem REQ resolvível, os três **criam com aviso em stderr e saem 0**. O gate é o
`validate`, não o `new` — e `wip_has_req` só dispara em `wip/`, onde de fato importa.

## Critérios de Aceite

- [ ] `--title`, `--req` e `--from-req` presentes e equivalentes nos três
- [ ] Sem REQ: cria com aviso e exit 0 nos três
- [ ] Python grava a linha `REQ:` e mantém o título posicional
- [ ] Testes por runtime; suítes e gates verdes

---

## Wave 1 — Corrigir cada runtime

### ML-1 — Go: deixa de fazer no-op silencioso
**Status:** ✅ Concluído
**Arquivos afetados:** `internal/commands/roadmap.go`, `internal/commands/roadmap_new_test.go` (NOVO)
**Ações:**
1. No ramo `len(reqFiles) == 0`, trocar a mensagem + `return nil` por: aviso em stderr explicando
   que o roadmap nasce sem REQ e vai violar `wip_has_req` ao ir para `wip/`, e seguir criando.
2. Garantir que `--title` sozinho funcione — hoje o título é derivado da REQ selecionada, que é
   string vazia nesse caminho.
3. Teste cobrindo: sem REQ cria e avisa; com `--req` grava o link.
**Critérios de aceite:**
- [x] `roadmap new --title X` cria o arquivo e sai 0
- [x] Aviso em stderr, com a consequência explícita (`wip_has_req` ao mover para `wip/`)
- [x] `--req` continua gravando `REQ:`
- [x] Sem título **e** sem REQ agora falha de verdade, em vez de criar roadmap sem nome
- [x] Não-vacuoso: 2 dos 3 testes falham sem o fix
**Comandos de validação:** `go build ./... && go test ./internal/commands/ -run RoadmapNew`

### ML-2 — Node.js: aviso quando não há REQ
**Status:** ✅ Concluído
**Arquivos afetados:** `npm/src/commands/roadmap.js`, `npm/src/generators/roadmap.js`,
`npm/tests/roadmap_new.test.js` (NOVO)
**Ações:**
1. Emitir o mesmo aviso em stderr quando `--req` e `--from-req` estiverem ausentes.
2. Trocar o título default `'New Roadmap'` por erro claro se `--title` também faltar — hoje cria um
   roadmap chamado "New Roadmap" silenciosamente.
3. Teste equivalente ao do Go.
**Critérios de aceite:**
- [x] Aviso em stderr sem REQ, com a mesma consequência que o Go anuncia
- [x] `--req` grava `REQ:`
- [x] Sem `--title` e sem REQ: erro claro e exit ≠ 0, em vez de criar "New Roadmap"
- [x] Sem `--title` mas com `--req`, o título passa a vir do nome da REQ — como no Go
- [x] Não-vacuoso: 1 passed / 2 failed sem o fix
- [x] O teste roda o CLI por subprocesso, então cobre o contrato de verdade, não só o generator
**Comandos de validação:** `node npm/tests/roadmap_new.test.js`

### ML-3 — Python: ganha `--title`, `--req` e `--from-req`
**Status:** ⬜ Pendente
**Arquivos afetados:** `pypi/trackfw/commands/roadmap.py`, `pypi/trackfw/generators/roadmap.py`,
`pypi/tests/test_roadmap_new.py` (NOVO)
**Ações:**
1. No parser: tornar o posicional `title` opcional (`nargs="*"`) e acrescentar `--title`, `--req` e
   `--from-req`. Posicional e flag coexistem; a flag vence se ambos vierem.
2. `generate_roadmap` passa a aceitar `req_path` e gravar a linha `REQ:` no template.
3. `--from-req` gera o roadmap a partir dos critérios de aceite da REQ, como nos outros dois.
4. Mesmo aviso em stderr quando não há REQ.
5. Teste equivalente.
**Critérios de aceite:**
- [ ] `--title`, `--req` e `--from-req` funcionam
- [ ] Título posicional continua aceito
- [ ] `REQ:` gravado quando há REQ
**Comandos de validação:** `cd pypi && python -m pytest tests/test_roadmap_new.py -q`

---

## Wave 2 — Fechamento

### ML-4 — Paridade verificada de ponta a ponta
**Status:** ⬜ Pendente
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. Fixture única: rodar os três com `--title`, com `--req` e com `--from-req`, e comparar o
   arquivo gerado e o exit code.
2. `go test ./...`, `pytest tests/`, testes npm.
3. Os três gates de paridade.
**Critérios de aceite:**
- [ ] Mesmo exit code e mesmo conteúdo nos três, nos três modos
- [ ] Suítes e gates verdes
**Comandos de validação:** `go test ./... && bash scripts/check-cli-parity.sh`
