---
id: REQ-2026-08-16-suite-pypi-verde
title: Suíte pypi precisa fechar verde — pytest declarado e asserção de borda corrigida
status: approved
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: Suíte pypi verde

Roadmap: docs/roadmaps/claude/done/suite-pypi-verde-2026-08-16.md

## Problema

A suíte Go fecha com zero falhas desde `REQ-2026-08-16-testes-go-portaveis-windows`. A pypi não —
e por isso todas as entregas desta sessão tiveram que comparar contagem de falhas contra uma
baseline em vez de exigir verde. Duas causas independentes.

### D1 — `pytest` é o runner do projeto, mas não está declarado nem instalado

Seis módulos de teste são **pytest-style**: funções soltas `test_*` com a fixture `tmp_path`, que o
`unittest` não sabe coletar. São `test_context_req_by_agent`, `test_discover`, `test_req_by_agent`,
`test_rules_req_configuraveis`, `test_serve_api` e `test_traceid`.

Sob `python -m unittest`, os seis viram `ModuleNotFoundError: No module named 'pytest'` — os 6
"errors" que apareceram em toda medição de baseline desta sessão. Não é defeito de código: é
dependência de desenvolvimento ausente.

O `CLAUDE.md` já documenta `python3 -m pytest tests/` como o comando da suíte, e o
`pypi/pyproject.toml` **não declara pytest em lugar nenhum** — nem em `optional-dependencies`, nem
em arquivo de requisitos. Quem clona o repo não tem como saber.

Convertê-los para `unittest` seria remar contra a convenção do próprio projeto e reescrever muita
coisa: os três maiores usam `tmp_path` 18, 35 e 38 vezes.

Medição com pytest instalado num venv: **282 passed, 1 failed** — contra 245 testes e 6 módulos
inteiros ignorados no `unittest`. São 37 testes que nunca rodaram nesta máquina.

### D2 — `test_stale_wip_warning_arquivo_antigo` assevera numa borda de faca

O teste grava o mtime em **exatamente** `time.time() - 10 dias` e exige que a mensagem diga
`"10 days"`. A produção calcula `int((datetime.now().timestamp() - mtime) / 86400)`.

Os dois lados usam relógios diferentes. Medido nesta máquina, 20 mil amostras:

```
datetime.now().timestamp() - time.time()
  menor:      -0.000001 s
  maior:      +0.001311 s
  negativos:  16889 de 20000   (84%)
```

Quando a leitura da produção cai **antes** da do teste — 84% das vezes — a idade dá `9.999999` dias
e o `int()` trunca para **9**. A mensagem sai `"9 days"` e a asserção falha.

Não é fragilidade de data nem de fuso: é asserção exata sobre um valor truncado, colocada
precisamente no ponto de descontinuidade. Explica por que o teste passa isolado e falha no módulo —
é cara-ou-coroa viciado em 84% para falhar, e a ordem de execução só muda o jitter.

A produção está correta: truncar a idade em dias é o comportamento esperado. O defeito é do teste.

## Requisitos

### R1 — Declarar `pytest` como dependência de desenvolvimento
`[project.optional-dependencies]` com um grupo `dev` em `pypi/pyproject.toml`, e o comando de
instalação documentado no `CLAUDE.md` junto do comando da suíte.

### R2 — Tirar a asserção da borda
O teste passa a gravar o mtime com folga sobre o limiar, em vez de exatamente sobre ele. A
asserção sobre `"10 days"` continua valendo, agora sem depender de qual relógio leu primeiro.

### R3 — Suíte verde de ponta a ponta
`pytest tests/` com zero falhas, e o `unittest` continuando a rodar os módulos que são
`TestCase` — ninguém perde o runner que já usa.

## Critérios de Aceite

- [x] `pypi/pyproject.toml` declara `pytest` em `optional-dependencies.dev`
- [x] `CLAUDE.md` documenta como instalar a dependência de desenvolvimento
- [x] `pytest tests/` fecha com **zero** falhas e roda os 6 módulos antes ignorados
- [x] `test_stale_wip_warning_arquivo_antigo` passa 10 execuções seguidas
- [x] `python -m unittest discover -s tests -t .` segue rodando, sem falha nova
- [x] `go test ./...` segue com zero falhas e os três gates de paridade passam
