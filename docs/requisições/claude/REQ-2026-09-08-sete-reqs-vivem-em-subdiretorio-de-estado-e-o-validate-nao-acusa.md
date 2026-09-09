---
status: Done
date: 2026-09-08
author: "claude"
adr: "docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md"
---

# REQ: sete REQs vivem em subdiretório de estado, e o `validate` não acusa

> Date: 2026-09-08 | Status: Done

## Motivation

A `ADR-2026-09-03`, decisão **D1**, escreve o invariante:

> *"`backlog`/`analyzing`/`wip`/`blocked`/`done`/`abandoned` são conceito de **roadmap**. REQ tem
> `status` no frontmatter (`Open`/`Done`), não pasta de estado."*

E diz por que precisou ser escrito:

> *"Enquanto o invariante não estiver escrito, o próximo leitor **inventa o mesmo nível de novo**."*

Medido em 2026-09-08, cinco dias depois da ADR ser aceita:

```
docs/requisições/apolo/abandoned/    1 REQ    status Closed   AC abertos 0
docs/requisições/apolo/done/         2 REQs   status done     AC abertos 0
docs/requisições/artemis/done/       2 REQs   status done     AC abertos 0
docs/requisições/claude/backlog/     2 REQs   status Done     AC abertos 8 cada
                                     -------
                                     7 REQs em pasta de estado
```

E o veredito da ferramenta sobre isso:

```
$ trackfw validate
✓ No violations found.
```

🔴 **ADR decide, gate não verifica.** É a terceira vez em dois dias que este padrão aparece —
[#278](https://github.com/kgsaran/trackfw/issues/278) (regra sem denominador),
[#290](https://github.com/kgsaran/trackfw/issues/290) (contrato no `cli-parity.md` com
`gap reason=nenhum gate verifica`) — mas as duas primeiras eram do upstream. **Esta é nossa**, sobre
uma decisão que nós mesmos escrevemos.

### Como isto apareceu, e por que importa para além do layout

Não apareceu por varredura de governança. Apareceu **ao limpar worktrees órfãos**: um deles guardava
uma sonda antiga cujo arquivo de controle apontava para
`docs/requisições/claude/backlog/REQ-multi-ai-support-2026-06-11.md`. O caminho tinha um nível a mais
do que deveria existir.

E o achado imediatamente **invalidou um número que eu havia publicado uma hora antes**, na PR #65:

| | REQs `Done` com AC aberto | ACs |
|---|---|---|
| publicado na PR #65 | 6 | 54 |
| medido depois deste achado | **8** | **70** |

A varredura da #65 usou `docs/requisições/claude/*.md` — **um nível só**. As duas REQs de
`claude/backlog/`, ambas `Done` com 8 ACs abertos cada, ficaram fora. **Um layout que a ADR proíbe
produziu um ponto cego de medição**, que é um custo maior que a desarrumação em si.

### O status também diverge, e o gate também não vê

Cinco das sete usam `done`/`Closed` em minúsculo ou fora do par declarado pela ADR
(`Open`/`Done`). Não é o objeto principal desta REQ, mas está no mesmo raio e é medido aqui para não
virar descoberta separada depois.

## Acceptance Criteria

- [x] **AC1** — Existe um gate que acusa REQ fora do layout canônico `req_dir/<agente>/*.md`, isto é,
      qualquer `.md` de REQ com profundidade maior que um nível abaixo de `req_dir`.
- [x] **AC2** — **Falsificação nas duas direções.** Plantar uma REQ em `req_dir/<agente>/wip/`
      reprova o gate nomeando o arquivo; a árvore corrigida passa. Só uma das duas não é prova.
- [x] **AC3** — 🔴 **Guarda de vacuidade com denominador escrito**: o gate imprime quantas REQs
      varreu, e falha se varrer zero. Verde sobre acervo vazio não conta — é o defeito que esta REQ
      existe para fechar, e o gate não pode nascer com ele.
- [x] **AC4** — As 7 REQs saem das pastas de estado, e o `status` de cada uma é reconciliado com o
      par declarado pela ADR. 🔴 O `status` que vale é o do frontmatter — mover o arquivo **não**
      pode mudar o significado, e a reconciliação tem de ser justificada arquivo a arquivo, não em
      massa.
- [x] **AC5** — A varredura de "REQ `Done` com AC aberto" é **refeita com glob recursivo** e o número
      corrigido publicado. A PR #65 já recebeu a correção em comentário; o valor final vive aqui.
- [x] **AC6** — `trackfw validate` sem violação e com denominador conferido, medido com o binário da
      árvore reconstruído.

## Negative Scope

- **Não** tocar produto. O gate é nosso, em `scripts/`, como o `check-platform-predicates.sh` e o
  `upstream-sync.sh` — adição de arquivo só nosso não cria divergência.
- **Não** propor a regra ao upstream nesta REQ. O invariante é de uma ADR **nossa**; se o gate se
  provar útil e a regra couber no produto, isso é issue própria, depois de medido.
- **Não** decidir o destino dos ACs abertos das 8 REQs de junho. Isso é decisão do usuário, já
  registrada como pendente na PR #65 — aqui só o **número** é corrigido.

## Residual declarado

- **O snapshot congelado do barrier segue apontando para o caminho antigo**, de propósito
  (`scripts/testdata/roadmap-barrier-corpus-snapshot/roadmap-multi-ai-support-...`). Corrigi-lo para
  acompanhar o move seria regenerar o snapshot — que é exatamente o que não se faz. É mais uma
  instância do acoplamento reportado no [#277](https://github.com/kgsaran/trackfw/issues/277), e
  aparece aqui como consequência, não como defeito novo.
- **O gate cobre layout, não grafia de `status`.** A normalização de `done`→`Done` foi feita à mão,
  arquivo a arquivo. Um gate que verifique o par declarado pela ADR é trabalho próprio — e só vale
  se vier com a lista de estados que o CLI de fato aceita, medida, não deduzida.
- **O destino dos 70 ACs abertos continua com o usuário.** Esta REQ corrigiu o **número**, não a
  decisão. As 8 REQs são de junho de 2026, anteriores à adoção do upstream.

## Linked ADR
ADR: docs/adr/ADR-2026-09-03-layout-canonico-de-req-em-by-agent-e-o-invariante-de-que-req-nao-tem-dimensao-de-estado.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-09-08-sete-reqs-vivem-em-subdiretorio-de-estado-e-o-validate-nao-acusa.md
