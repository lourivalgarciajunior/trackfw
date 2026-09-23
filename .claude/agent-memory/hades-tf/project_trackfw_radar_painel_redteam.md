---
name: trackfw-radar-painel-redteam
description: trackfw-radar painel do gestor red team (2026-09-23) — 64 vetores, 14 achados, a alta (coleta sem filtro carrega autoria de ADR) e onde o relatório mora
metadata:
  type: project
---

Red team do painel do gestor do `trackfw-radar` (ROADMAP-2026-09-21-painel-do-gestor-mvp, ML-2A),
contra `41446f0`. Relatório: `docs/security/red-team-painel.md`. 64 vetores (54 ao vivo contra
Postgres real via HTTP, 10 por leitura), 14 achados: 1 alta, 8 médias, 2 baixas, 3 informativas.
Nada corrigido — reporte, não conserto.

**A alta (RT-1) é de classificação caducada, não de bug:** o ML-1C classificou `Coleta` como "não é
dado de pessoa" e deixou `*ent.ColetaFilter` passar sem filtro em `restringeAEquipes`
(`escopo.go:135-137`). O ML-1J, depois, pôs `autor_nome`/`autor_email` dentro de `coletas.cadeia`.
Ninguém reabriu o escopo. Medido: coordenador da equipe X recebe
`tipo=nao_atribuida nome="Bruno de Fora" decisoes=1` — pessoa da equipe Y, com nome real e um
indicador por pessoa. Ver [[feedback_classificacao_por_entidade_caduca_quando_o_conteudo_muda]].

**A classe mais produtiva foram os controles declarados e inexistentes — quatro:** S4 diz ter "teto e
passo do período no contrato" (o contrato não tem nenhum parâmetro além de `empresaId`); S6 diz que
"a remoção do vínculo desfaz o mapeamento" (medido: o nome do commit continua na tela); S3 diz que
"ignorada tem série própria" (cai em `nao_atribuida`); S2 diz que `painel.ver_proprio` "decide o
recorte" (não está em rota nenhuma; o papel de fábrica `programador` leva 403 nas cinco telas, e o
comentário do teste que sustenta a AC do ML-1C diz que ele "não tem permissão de painel nenhuma" —
tem). Os quatro residuais declarados, ao contrário, são honestos.

**RT-11, o mais interessante e o mais silencioso:** o estado do item é derivado do subconjunto de
eventos que o papel enxerga, então o MESMO roadmap sai `done` para o gestor e `wip parado há 30 dias`
para o coordenador. O ML-0A previu "aperta demais" na forma de `deny` (barulhento, corrigido no
ML-1C); a forma que sobrou é número errado.

**RT-3, custo:** `/linha-do-tempo` = 22,55 s e 6,5 MiB com 40.000 eventos. Discriminante: mesmos
40.000 eventos com 10× menos itens de raia → 3,98 s. O gargalo é `repoDoEvento` (`painel.go:430`),
O(itens × eventos), não a carga de banco.

**O gate `check-painel-sem-ranking.sh` foi atacado em 15 vetores:** pega o controle positivo e a
vacuidade; 8/8 sinônimos passam (`classificacao` + sort desc é ranking funcionando), 5/5 tipos de
arquivo passam (`.jsx`/`.js`/`.json` dentro da própria pasta do painel, `api/*.yml`), e o marcador
`adr-ociosidade:fora-do-produto` na mesma linha passa **em silêncio** — as 3 ocorrências atuais não
são pinadas em lugar nenhum.

O que resistiu e vale lembrar: o filtro de `Evento`/`IdentidadeGit` (incluindo o predicado impossível
para lista vazia), zero sinks de HTML em 44 arquivos de `web/src`, 404 para empresa alheia, 405/401,
e a ausência de id nos 4 endpoints (sem superfície de IDOR por construção).

Contexto dos red teams anteriores no mesmo repo: [[trackfw-radar-multi-empresa-redteam]] e
[[trackfw-radar-coletor-redteam]]. O repo continua sem `docs/agents-working-context.md`.
