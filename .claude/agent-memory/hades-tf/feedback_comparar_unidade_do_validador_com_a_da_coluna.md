---
name: comparar-unidade-do-validador-com-a-da-coluna
description: Em toda revisão de dado não confiável que vai para o banco, compare a UNIDADE do validador da aplicação com a da coluna — runa vs byte é achado, não detalhe
metadata:
  type: feedback
---

Quando dado do cliente atravessa um saneador da aplicação antes de virar coluna, meça **em que
unidade cada lado conta** e procure o degrau. Runa × byte é o caso mais comum; o outro é
caractere × code point.

**Why:** 2026-09-22, red team do coletor do `trackfw-radar` ([[trackfw-radar-coletor-redteam]]). O
coletor sanea com `utf8.RuneCountInString(s) > max` e os validadores gerados pelo ent usam
`len(s) > max` (bytes), com os mesmos números nos dois lados (200, 254, 300, 2000). Resultado
medido: 150 runas `é` passam em `texto(…, 200)` e estouram `MaxLen(200)`; a transação inteira cai e
**nenhuma linha de coleta é gravada**, porque o laço do serviço só loga o erro. O mesmo degrau
atingiu a gravação da *falha* (`truncar(msg, 2000)` runas vs `Coleta.erro` MaxLen 2000 bytes), então
o repositório fica invisível para sempre no painel.

**How to apply:** ao revisar qualquer entidade nova que receba conteúdo não confiável, faça a tabela
de três colunas — campo · onde o app limita (arquivo:linha e unidade) · onde o banco/ORM limita
(schema e unidade) — e ataque cada linha onde as unidades diferem, com multibyte. Duas perguntas a
mais, que foi onde saiu o resto do achado: **existe campo sem limite nenhum do lado do app?** (ali
era o nome do ML, vindo de `\S+`); e **o que acontece quando o validador reprova — o sistema
registra a falha ou some com ela?** A segunda é o que separa "dado rejeitado" de "serviço
silenciosamente morto". Ver [[feedback_measure_the_real_code_path_not_an_isolated_proxy]]: testar o
validador isolado não mostra nada disso.
