---
name: trackfw-radar-coletor-redteam
description: trackfw-radar ML-2A red team of the coletor (2026-09-22) — 81 vectors, 13 findings, the one high (cross-tenant clone pre-emption) and where the report lives
metadata:
  type: project
---

Red team do coletor do `trackfw-radar` (ROADMAP-2026-09-21-coletor-e-modelo-de-eventos, ML-2A),
contra `c6082f8`. Relatório: `docs/security/red-team-coletor.md`. 81 vetores, 4 controles negativos,
13 achados: 1 alta, 4 médias, 4 baixas, 4 informativas. Nenhum achado foi corrigido por mim —
reporte, não conserto (Reporting boundary).

**O alto (RT-1) é de desenho, não de bug:** o `caminho` do clone é `UNIQUE` global, e o threat model
(S5) trata isso como o controle que impede uma empresa de ver o clone da outra. Não impede — só
impede o **segundo** registro. Quem registra primeiro leva: a empresa A registrou o caminho do clone
da B, coletou, e passou a ver roadmap, nome, e-mail, hash e data de commit da B; a B levou 409 ao
tentar registrar o próprio clone. Reproduzido no Postgres real via `Servico.UmaVolta`. Correção
sugerida: marcador no clone escrito pelo operador (`.radar-empresa` com o id), conferido no registro
e no `Abrir` — a verdade na fonte, não na ordem de chegada.

**A classe mais produtiva (RT-2) foi runa × byte:** `texto()` e `truncar()` do coletor contam runas,
os validadores `MaxLen` do ent contam bytes, e o nome do ML sai de `^### (ML-\S+)` sem teto nenhum.
Efeito medido: a coleta falha inteira e **nenhuma linha de coleta é gravada** — só uma linha de log —
porque `UmaVolta` só loga o erro de `Registrar`. Com `agents: ["<3000×é>"]` no `trackfw.yaml`, quem
falha é a gravação da própria falha (`Coleta.erro`, MaxLen 2000 bytes vs `truncar(…, 2000)` runas).

O que resistiu e vale lembrar: a camada de privacidade do ent (10 vetores, nenhum passou), o
executor (`cmd.Env` literal, `PATH` num `MkdirTemp`), o formato estrito da saída do trackfw (10 de 11
vetores), o go-git (não expande `include.path`, confina `alternates` no chroot billy de
`<clone>/.git`), e o painel (zero sinks de HTML em `web/`).

Ver [[feedback_verify_tree_did_not_move_during_redteam]] — a árvore se moveu de novo nesta sessão.
Contexto do red team anterior no mesmo repo: [[trackfw-radar-multi-empresa-redteam]].
