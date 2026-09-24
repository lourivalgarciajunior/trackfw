---
name: so-o-parser-de-verdade-decide-injecao-de-config
description: Injeção em arquivo de configuração só se confirma rodando o parser real; grep/Contains no arquivo escrito dá falso positivo quando o escritor escapa
metadata:
  type: feedback
---

Ao testar injeção de quebra de linha num arquivo de configuração (git config, INI, YAML, .env),
**a prova é o parser real lendo a chave injetada**, nunca `strings.Contains` no arquivo gravado.

**Why:** 2026-09-24, red team do runner do `trackfw-radar`. Mandei `DefinirAutor` gravar
`user.name = "Robo\n[core]\n\thooksPath = /tmp/evil"` e conferi com
`strings.Contains(config, "hooksPath")` — deu `true`, e eu quase escrevi "INJETOU" no relatório.
Re-medido com `git config --local --get core.hooksPath`: `rc=1`, chave **ausente**. O go-git escapa
e aspa o valor, então o `\n` fica literal dentro da string e nenhuma seção nova nasce. A substring
estava lá; a semântica, não. Virou "o que resistiu" em vez de achado — e um achado falso num
relatório de red team custa mais que um achado perdido, porque o time gasta o ML-2B corrigindo o
que não está quebrado.

**How to apply:** para cada vetor de injeção em formato estruturado, escreva a asserção em termos
do **leitor**: `git config --get <chave>`, `yaml.safe_load(...)["chave"]`, `python-dotenv`. Se o
leitor não estiver disponível no ambiente do teste, o achado vai para "não medido, e por quê" — não
para a tabela de achados. Vale também para o inverso: um escritor que NÃO escapa só se prova com o
leitor devolvendo o valor injetado. Ver [[feedback_verify_by_execution]].
