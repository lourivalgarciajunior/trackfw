---
name: trackfw-radar-runner-redteam
description: trackfw-radar red team do runner de delegação (2026-09-24) — 113 vetores, 24 achados, as 5 altas e onde o relatório mora
metadata:
  type: project
---

Red team do runner de delegação do `trackfw-radar` (ROADMAP-2026-09-21-delegacao-de-tarefa-a-agente,
ML-2A), contra `ab0c7c6`. Relatório: `docs/security/red-team-runner.md`. 113 vetores, 24 achados:
5 altas, 10 médias, 5 baixas, 4 informativas. Nada corrigido — reporte, não conserto.

**A mais bonita (RT-2) é de ordem de pais:** `ConferirAutoria` (`internal/runner/area.go:207`) faz
`return erroParada` ao achar a base, e isso encerra o `ForEach` INTEIRO, não o ramo. Num merge cujo
**primeiro pai é a base**, o segundo ramo nunca é conferido. Medido: 2 commits de
`mallory@fora.example` passaram (`conferidos=1 err=<nil>`); com os pais invertidos, recusa. O
discriminante é o campo que o atacante escolhe. O verificador de bundle não pega — autoria não é
nenhuma das 5 propriedades dele, e a ADR diz que "quem produz não pode ser quem aprova".

**A classe mais produtiva foi controle declarado e não reusado.** O S4 escreve "o ML-1E reusa, não
reinventa" sobre as armadilhas do coletor; `runner.Preparar` reusa **zero** das 7 de
`coletor.Abrir`. Medido com o coletor como controle em cada linha: `alternates`, `.git`-arquivo e
clone raso — coletor recusa os 3, runner aceita os 3, e nos dois primeiros o repositório de outra
empresa aparece DENTRO da área de escrita. E `Dentro`, que o S4 apresenta como "a verificação que o
código faz antes de tocar em qualquer coisa", tem **zero chamadores** no produto.

**A que só aparece medindo o `cmd` (RT-6):** `cmd/api/runner.go:34` monta o `Servico` sem
`Orcamento`. Os três `RADAR_TAREFA_TETO_*` são carregados e validados no `config` e **nunca lidos**.
Efeito nos dois sentidos: `Duracao=0` faz `context.WithTimeout(ctx, 0)` nascer vencido (toda tarefa
morre no `Preparar`), e `Estourou` guarda com `> 0` (nenhum teto dispara). A suíte não pega porque
o `montar` dos testes preenche o campo à mão — ver
[[feedback_medir_pelo_caminho_do_cmd_nao_pela_fixture]].

**Números que valem guardar:** bomba de zlib no verificador de bundle — 305 KB de packfile →
**2,4 GiB alocados**, razão medida 1029:1, e a recusa vem DEPOIS da alocação; com o teto de 20 MiB
isso é ~20 GiB no `api`. Bomba de contagem: 3,5 MiB → 200 mil objetos → 240 MiB e 25,8 s.

**Runa × byte apareceu de novo**, terceiro red team seguido neste repo: `falhar` trunca `erro` por
runa (`servico.go:270`) e a coluna valida por byte. Efeito medido: 40 chamadas do motor para uma
tarefa (contra 1 no controle ASCII) e o erro do motor **nunca gravado** — só o teto de turnos a
encerra, com uma mensagem que mente sobre a causa.

O que resistiu e vale lembrar: `DefinirAutor` **não** injeta no `.git/config` (go-git escapa; o git
real lê `user.name` literal e `core.hooksPath` sai ausente) — minha primeira leitura com
`strings.Contains` deu falso positivo, ver
[[feedback_so_o_parser_de_verdade_decide_injecao_de_config]]; a máquina de estados no ent (lote
recusado, final sem destino); o portão A travado por IDENTIDADE e não por papel (2º admin vê 200 e
leva 403); 5 de 10 variantes de cabeçalho de bundle recusadas com a mensagem certa; e 0 sinks de
HTML em 47 arquivos de `web/src`.

Contexto dos red teams anteriores no mesmo repo: [[trackfw-radar-multi-empresa-redteam]],
[[trackfw-radar-coletor-redteam]] e [[trackfw-radar-painel-redteam]]. Desta vez a árvore **não** se
moveu (`ab0c7c6` no início e no fim) — ver [[verify-tree-did-not-move-during-redteam]]. Criei o
`docs/agents-working-context.md`, que o repo nunca teve.
