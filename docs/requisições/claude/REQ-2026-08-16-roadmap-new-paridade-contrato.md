---
id: REQ-2026-08-16-roadmap-new-paridade-contrato
title: roadmap new tem contrato diferente em cada runtime
status: approved
priority: medium
type: bug
created: 2026-08-16
author: claude
---

# REQ: Contrato de `roadmap new` nos três runtimes

Roadmap: roadmap-new-paridade-contrato-2026-08-16.md

## Problema

O item entrou na dívida como "o `roadmap new` do Go exige uma REQ existente, npm e Python não".
A investigação mostrou que a divergência é da **superfície inteira do comando**, não só do
requisito de REQ:

| | Go | Node.js | Python |
|---|---|---|---|
| título | `-t/--title` | `-t/--title` | **posicional** (`nargs="+"`) |
| `--req` | sim | sim | **não existe** |
| `--from-req` | sim | sim | **não existe** |
| `--agent` | não | não | **só aqui** |
| sem REQ disponível | mensagem em stderr e **sai 0 sem criar nada** | cria, título default `"New Roadmap"` | cria |
| grava `REQ:` no arquivo | sim | sim | **não** |

Ou seja: o Python **não tem como** linkar uma REQ ao criar um roadmap. A "não exigência de REQ"
não é permissividade — é ausência do mecanismo.

### O defeito mais grave é do Go

`internal/commands/roadmap.go:73` imprime a mensagem em stderr e faz `return nil` — **exit code 0**.
O comando não cria nada e reporta sucesso. Script que confie no código de saída segue adiante
achando que o roadmap existe.

### Por que os gates não pegam

`check-cli-parity.sh` compara o **conjunto de comandos** e a saída de `version`. Não compara flags
nem comportamento de subcomando. Uma divergência inteira de contrato passa batido.

## Decisão de rota

Duas saídas possíveis quando não há REQ resolvível: recusar (posição atual do Go) ou criar com
aviso (posição de npm e Python).

**Escolha: criar, com aviso explícito em stderr, saindo 0.** Motivos:

1. O validator já trata isso na hora certa. `wip_has_req` é `error`, mas só dispara quando o
   roadmap está em `wip/`. Um roadmap em `backlog/` sem REQ é estado legítimo do modelo.
2. Recusar quebraria usuários de npm e pypi que hoje criam roadmap sem REQ.
3. A recusa atual do Go não é nem recusa — é no-op silencioso com sucesso, que é pior que os dois.

O aviso mantém a governança visível sem transformar o `roadmap new` em gate — o gate é o
`validate`.

## Requisitos

### R1 — Mesma superfície de flags nos três
`--title/-t`, `--req/-r` e `--from-req` presentes e com o mesmo significado. O Python mantém o
título posicional como forma aceita, por retrocompatibilidade, mas passa a aceitar `--title`
também.

### R2 — Python grava o link da REQ
Quando `--req` ou `--from-req` for passado, o arquivo gerado traz a linha `REQ:` como nos outros
dois.

### R3 — Sem REQ disponível: criar com aviso, exit 0
Comportamento idêntico nos três. O Go deixa de fazer no-op silencioso.

### R4 — `--agent` fica onde está
É capacidade extra do Python, não quebra de contrato: Go e npm derivam o agente do `trackfw.yaml`.
Registrado como divergência conhecida, fora do escopo.

## Critérios de Aceite

- [x] `roadmap new --title X` cria o roadmap nos três runtimes, sem REQ, com aviso em stderr e exit 0
- [x] `roadmap new --title X --req <path>` grava a linha `REQ:` nos três
- [x] `roadmap new --from-req <path>` funciona nos três
- [x] Python continua aceitando o título posicional
- [x] Teste por runtime cobrindo: com `--req`, sem REQ, e `--from-req`
- [x] `go test ./...` zero falhas; `pytest tests/` zero falhas; testes npm verdes
- [x] Os três gates de paridade passam
