---
status: Accepted
date: 2026-09-09
author: "claude"
---

# ADR: predicado de SO em sítio de classificação — o discriminante é a **origem do argumento**, não a intenção do autor

> Date: 2026-09-09 | Status: Accepted

## Context

O **AC2** da `REQ-2026-09-05-onda-2` pede um lint que reprove predicado de SO em sítio de
**classificação**, deixando de fora os sítios de **travessia** de sistema de arquivos. Ele delegou o
discriminante a uma fonte externa:

> *"Sítios de travessia ficam fora, por decisão do **D2 da `ADR-2026-09-04`**."*

🔴 **Essa ADR não existe neste repositório.** Medido em 2026-09-09: há **três** arquivos com aquela
data em `upstream/main:docs/adr/` — âncora POSIX em config, tolerância a CRLF no frontmatter, e
separador POSIX em artefato —, e a `ADR-2026-08-29` decide que **a governança do upstream não é
importada**.

O efeito prático é que o AC2 ficou **parado desde 2026-09-05 sem que ninguém soubesse dizer por
quê**: parecia falta de esforço, e era uma dependência de governança que o AC nunca declarou. Esta
ADR remove a dependência escrevendo o discriminante aqui, a partir da nossa própria medição.

### O que a medição mostrou

`scripts/measure-os-predicate-sites.sh`, sobre 507 arquivos de produto:

```
196 ocorrencias com arquivo de teste  ·  110 sem
```

E a distribuição, sem teste:

| runtime | predicado | sítios |
|---|---|---|
| go | `os.IsNotExist` | 61 |
| go | `filepath.IsAbs` | 19 |
| node | `process.platform` | 10 |
| node | `path.isAbsolute` | 9 |
| python | `os.path.isabs` | 9 |
| python | `os.name` | 2 |

**O achado que decide esta ADR:** classificados linha a linha, os 61 sítios de `os.IsNotExist` se
distribuem assim:

```
61 total  =  57 codigo, todos recebendo um valor de erro  +  4 comentarios  +  0 outros
```

🔴 **Zero sítios recebem algo que não seja um erro.** Não é "a maioria": é **todos**.

🔴 A primeira redação desta ADR dizia *"59 de 61, e os 2 restantes são comentários"*. Estava errada,
e pelo motivo de sempre: contei **ocorrências do padrão dentro das linhas** com `grep -oE` em vez de
classificar **linha a linha**. Os números certos são 57 e 4. A correção **fortalece** a decisão — o
que parecia regra com exceção é regra sem exceção —, mas o erro fica escrito porque a contagem por
ocorrência já falseou o denominador deste mesmo trabalho três vezes.

Ou seja: mais da metade da superfície se classifica por uma regra **mecânica**, olhando o
argumento — sem ler a intenção de quem escreveu.

## Decision

**O discriminante entre travessia e classificação é a ORIGEM DO ARGUMENTO do predicado.**

### D1 — Argumento que vem do sistema de arquivos é travessia. Fora de escopo.

Um predicado cujo argumento é **um erro devolvido por uma chamada de sistema** está perguntando ao
SO sobre o SO. É a pergunta certa, no lugar certo, e a resposta **deve** variar por plataforma.

`os.IsNotExist(err)` é travessia **por construção**: o `err` só existe porque uma chamada de sistema
aconteceu.

### D2 — Argumento que vem de um artefato, de config ou de entrada é classificação. Em escopo.

Um predicado aplicado a uma **string autorada em outro lugar** — caminho vindo do `trackfw.yaml`,
campo de frontmatter, argumento de linha de comando, valor de template — está decidindo **significado
que tem de ser o mesmo em todo SO**. Aí a resposta variar por plataforma é o defeito.

`filepath.IsAbs(destination)` é classificação: `destination` é uma string, e a mesma string tem de
significar a mesma coisa no Windows e no Linux.

### D3 — Predicado de plataforma lido UMA vez para uma constante nomeada é a costura, não a violação.

`process.platform` e `os.name` lidos no carregamento do módulo para uma constante nomeada
(`_platform`, `isWindows`) **são a implementação da fronteira**. Reprová-los seria reprovar o próprio
mecanismo que concentra a dependência de plataforma num ponto.

O que o lint tem de reprovar é o **consumo espalhado**: cada novo `process.platform === 'win32'`
fora da costura.

🔴 **Isto exige allowlist explícita, com motivo por entrada** — e allowlist sem motivo escrito é o
mesmo que não ter regra.

### D4 — O ônus é de quem quer excluir, e a exclusão é escrita

Sítio que não caia mecanicamente em D1 é **classificação até prova em contrário**. A prova é uma
linha escrita no allowlist, não um julgamento silencioso.

### D5 — Arquivo de teste conta, e conta separado

A superfície com teste é 196 e sem teste é 110. **As duas são reportadas**, sempre, e nenhuma é a
"verdadeira". Um teste que classifica errado documenta o comportamento errado — mas corrigi-lo tem
prioridade diferente de corrigir produto, e misturar os dois números foi o que fez o denominador
deste trabalho variar três vezes.

## Consequences

**Positivas**

- **55% da superfície fica decidida sem julgamento.** Os 57 sítios de código de `os.IsNotExist` saem por D1, por leitura
  do argumento — não por opinião sobre a intenção.
- **O AC2 volta a ser executável neste repositório**, sem esperar decisão de terceiro.
- O discriminante é **verificável por máquina** no caso majoritário, o que é o requisito de um lint.

**Negativas, e declaradas**

- 🔴 **D2 não é totalmente mecânico.** Saber se uma string veio de artefato ou do sistema de arquivos
  pode exigir seguir a variável para trás. O lint vai errar nos dois sentidos em algum sítio, e o
  remédio é a allowlist com motivo — não relaxar a regra.
- **Esta ADR pode divergir do D2 dele.** Não li a `ADR-2026-09-04` do upstream para decidir — de
  propósito: importá-la contradiria a `ADR-2026-08-29`. Se um dia a decisão dele for lida e for
  outra, isto vira divergência **escrita**, não surpresa.
- **D3 cria uma allowlist**, e allowlist é dívida que cresce em silêncio se ninguém a revisar. O
  gate tem de imprimir o tamanho dela.

## Alternatives Considered

**Importar a `ADR-2026-09-04` do upstream.** Rejeitada: contradiz a `ADR-2026-08-29`, e é
exatamente o resíduo que a `REQ-2026-09-09-governanca-do-upstream` acabou de medir — 28 REQs dele
vivendo no nosso `req_dir`, nenhuma removível. Acrescentar uma ADR ao mesmo passivo pelo mesmo motivo
seria repetir o erro com o registro fresco na mão.

**Discriminar por diretório** — `internal/generators` é classificação, `internal/commands` é
travessia. Rejeitada por medição: `agentfiles.go`, um único arquivo em `internal/generators`, tem
`os.IsNotExist(err)` em pelo menos 4 sítios, todos travessia legítima. A fronteira não é o diretório.

**Discriminar pela intenção declarada em comentário.** Rejeitada: é a forma que a auditoria externa
de 2026-09-05 pegou no achado A3 — *"um discriminante que nunca testamos"*. Comentário não é medição,
e não é executável por lint.

**Não escrever ADR e simplesmente cobrir a superfície inteira**, com exceções caso a caso.
Rejeitada porque joga os 61 `os.IsNotExist` — travessia legítima e majoritária — para dentro de uma
allowlist de 61 entradas. Uma allowlist maior que a regra não é regra.
