---
name: suite-pypi-verde-2026-08-16
title: "Suíte pypi fecha verde — pytest declarado e asserção de borda corrigida"
status: done
date: 2026-08-16
req: REQ-2026-08-16-suite-pypi-verde
branch: fix/suite-pypi-verde
---

# Roadmap: suíte pypi verde

> Created: 2026-08-16 | Status: done

REQ: `docs/requisições/claude/REQ-2026-08-16-suite-pypi-verde.md`

## Diagnóstico / Contexto

A suíte Go fecha verde desde `REQ-2026-08-16-testes-go-portaveis-windows`; a pypi não, e por isso
todas as entregas desta sessão compararam contagem de falhas contra baseline em vez de exigir
verde. Duas causas: `pytest` é o runner de 6 módulos mas não está declarado nem instalado, e um
teste assevera exatamente sobre uma borda de truncamento. Diagnóstico completo, com a medição de
skew entre relógios, está na REQ.

Origem: itens 10 e 12 da dívida acumulada nesta sessão.

## Critérios de Aceite

- [x] `pytest tests/` com zero falhas, rodando os 6 módulos antes ignorados
- [x] `test_stale_wip_warning_arquivo_antigo` passa 10 execuções seguidas
- [x] `unittest discover` segue rodando sem falha nova
- [x] Go verde e gates passam

---

## Wave 1 — As duas correções (independentes)

### ML-1 — D2: tirar a asserção da borda de truncamento
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/tests/test_validator.py`
**Ações:**
1. Trocar o recuo de mtime de `10 * 24 * 60 * 60` exatos por `10 dias + 1 hora`, mantendo a
   asserção sobre `"10 days"`.
2. Comentar no código o porquê da folga: a produção lê o relógio por `datetime.now()` e o teste por
   `time.time()`; com o recuo exato, a leitura da produção cai antes da do teste em 84% das vezes e
   o `int()` trunca para 9.
3. Rodar o teste 10 vezes seguidas para confirmar estabilidade.
**Critérios de aceite:**
- [x] 10 execuções seguidas de `tests.test_validator`, zero falhas
- [x] A asserção segue exigindo `"10 days"` — a folga move o valor para longe da descontinuidade
      sem afrouxar o que é verificado
**Comandos de validação:** `cd pypi && python -m unittest tests.test_validator`

### ML-2 — D1: declarar `pytest` como dependência de desenvolvimento
**Status:** ✅ Concluído
**Arquivos afetados:** `pypi/pyproject.toml`, `CLAUDE.md`
**Ações:**
1. Acrescentar `[project.optional-dependencies]` com grupo `dev = ["pytest>=7"]`.
2. Documentar no `CLAUDE.md`, na seção de testes do Python, o `pip install -e ".[dev]"` antes do
   `pytest tests/`, e registrar que 6 módulos são pytest-style e não rodam sob `unittest`.
3. Confirmar que o runtime segue sem dependência externa — a adição é só de desenvolvimento.
**Critérios de aceite:**
- [x] `pyproject.toml` declara `dev = ["pytest>=7"]` em `optional-dependencies`
- [x] `CLAUDE.md` explica a instalação, nomeia os 6 módulos pytest-style e registra o `-t .` do
      `unittest discover`
- [x] Nenhuma dependência no pacote em si — `[project]` segue sem `dependencies`
- [x] Validado num venv limpo: `pip install -e ".[dev]"` seguido de `pytest tests/` dá
      **283 passed**
**Comandos de validação:** `grep -A4 optional-dependencies pypi/pyproject.toml`

---

## Wave 2 — Fechamento

### ML-3 — Suíte verde e não-regressão
**Status:** ✅ Concluído
**Arquivos afetados:** nenhum (verificação)
**Ações:**
1. `pytest tests/` num venv com o grupo `dev` instalado — exigir zero falhas.
2. `python -m unittest discover -s tests -t .` — sem falha nova.
3. `go test ./...` e os três gates de paridade.
**Critérios de aceite:**
- [x] `pytest tests/` — **283 passed, zero falhas**
- [x] `unittest discover -s tests -t .` — 245 testes, **zero failures**; restam só os 6 erros de
      import dos módulos pytest-style, agora documentados como esperados
- [x] `go test ./...` zero falhas, `gofmt -l` zero
- [x] Os três gates de paridade passam

**Ganho de cobertura:** 283 testes rodando contra os 245 de antes. Os 37 a mais vêm dos 6 módulos
que nunca haviam rodado nesta máquina.
**Comandos de validação:** `cd pypi && pytest tests/ -q`
