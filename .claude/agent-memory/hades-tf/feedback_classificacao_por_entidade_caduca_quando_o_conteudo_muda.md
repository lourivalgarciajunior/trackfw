---
name: classificacao-por-entidade-caduca-quando-o-conteudo-muda
description: Quando um ML classifica uma entidade como "não é dado sensível" e libera o filtro, releia essa classificação em todo ML posterior que acrescente campo àquela entidade
metadata:
  type: feedback
---

Quando uma regra de autorização libera uma entidade inteira com o argumento "isto não é dado de
pessoa", trate a classificação como **datada**. Em todo ML posterior que acrescente campo àquela
entidade — sobretudo campo JSON, que não exige migração nem revisão de schema —, reabra o sítio da
regra e refaça a pergunta.

**Why:** foi assim que nasceu o único achado alto do red team do painel do `trackfw-radar`
(2026-09-23, [[trackfw-radar-painel-redteam]]). O ML-1C escreveu no roadmap, com justificativa
explícita, que `Coleta` passa sem filtro para o coordenador porque "nome, caminho, score e contagens
não são dado de pessoa" — e estava **certo naquele dia**. O ML-1J, três commits depois, pôs
`autor_nome` e `autor_email` dentro de `coletas.cadeia`, que é `field.JSON`. A coluna não mudou, o
schema não mudou, nenhuma migração tocou a regra de privacidade, e a frase do ML-1C continuou lá,
lida por quem revisasse, agora falsa. O caminho de leitura (`painel.go`) transformou isso numa linha
nominal na tela de quem não podia ver aquela pessoa.

**How to apply:** ao revisar uma entrega em ondas, monte a lista de entidades que alguma regra
libera por classificação de conteúdo, e cruze com o diff de **todos** os MLs seguintes procurando
acréscimo de campo. `field.JSON` e mapa de string→string são os que escapam: aceitam campo novo sem
migração, que é exatamente o argumento com que costumam ser escolhidos. O sinal de alarme, no
roadmap, é a frase "a coluna aceita artefato com campo novo sem migração" escrita como vantagem.

O falsificador barato: pegue o payload real da entidade liberada e procure e-mail, nome próprio e
nome de arquivo autoral. Se achar, a classificação caducou — independentemente do que o comentário
ao lado da regra diga.
