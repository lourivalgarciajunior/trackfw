---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: Paridade tri-runtime — nenhuma mudança de comportamento entra num CLI só

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra decisão tomada e implementada entre 2026-08-16 e 2026-08-29. Escrita
> em 2026-09-05 para dar lastro às 10 REQs abaixo, que a aplicaram sem que ela existisse por escrito.

## Context

O trackfw é distribuído em **três implementações independentes**: Go (`internal/`), Node.js
(`npm/src/`) e Python (`pypi/trackfw/`). Não são bindings — cada uma reimplementa a lógica na sua
linguagem, sem núcleo compartilhado (ver ADR irmã sobre três CLIs nativos).

Isso cria uma superfície de divergência silenciosa: um usuário que roda `trackfw validate` pelo npm e
outro que roda pelo pip podem receber **vereditos diferentes sobre o mesmo repositório**, e nada no
sistema acusa. O modo de falha não é erro — é discordância que ninguém observa, porque quase ninguém
roda os três.

A regra existia como texto no `CLAUDE.md` ("Regra Dura de Paridade — 3 CLIs (INVIOLÁVEL)") e como
gates em `scripts/`, mas **nunca foi registrada como decisão**. As 10 REQs que a aplicaram ficaram
órfãs de ADR, e o `validate` as acusou — corretamente.

A divergência não é hipotética. Casos medidos neste acervo:

- o `slugify` do Python **deletava** não-alfanuméricos onde Go e Node **colapsavam**, então
  `adr new` e `req new` geravam nomes de arquivo diferentes conforme o CLI;
- `adr list` e `req list` não existiam no Python;
- as listas do `trackfw.yaml` eram descartadas em silêncio por um dos parsers;
- o `status` do Python tinha o bucket `Other` que Go e Node não tinham — e, no sentido oposto, o
  contador de REQ do Python ignora o layout que os outros dois resolvem.

O último caso é o que fecha o argumento: **a paridade quebra nas duas direções**. Não existe um
runtime "de referência" que esteja sempre certo.

## Decision

**Toda mudança de comportamento observável entra nos três runtimes, no mesmo PR.**

1. Comportamento observável é: saída de comando, formato de artefato gerado, veredito de regra,
   código de saída, nome de arquivo, e mensagem de erro.
2. **Divergência intencional é permitida, mas tem de ser declarada** em `docs/cli-parity.md` com o
   motivo. Divergência não declarada é defeito.
3. **A verificação é por gate cross-CLI**, não por suíte unitária. Cada runtime testando a si mesmo
   não detecta o caso em que os três herdaram a mesma premissa errada — e isso já aconteceu: três
   suítes verdes concordando com um fixture desatualizado, pego só pelo gate que compara os binários
   reais byte a byte.
4. Exceções de escopo: mudança só de documentação, de infraestrutura, e de template de artefato.

## Consequences

**Positivas**

- O veredito do `trackfw` deixa de depender de por qual gerenciador de pacotes ele foi instalado.
- Um defeito encontrado num runtime vira busca nos outros dois por construção, o que multiplicou o
  alcance de várias correções deste acervo.
- O gate cross-CLI cobre a classe de falha que suíte unitária não cobre.

**Negativas, e assumidas**

- **Custo triplicado** por mudança de comportamento. É a razão principal de o alvo `parity` ser o
  caminho crítico do CI (medido no upstream: 780 s, 90% do tempo de parede de um PR).
- Um defeito de paridade só aparece quando alguém roda os três. Contribuidor que roda um só não vê.
- A regra convida ao remédio errado sob pressa: **igualar o teste em vez de igualar o produto**.
  Quando os três discordam, é obrigatório determinar **qual está certo** antes de convergir — pode ser
  que dois estejam errados e concordando.

## Alternatives Considered

**Um núcleo em Go com wrappers finos para npm e pip.** Elimina a divergência por construção. Recusada
pela ADR irmã (três CLIs nativos): exigiria distribuir binário por plataforma e perderia a
instalação nativa em ambientes onde só um dos runtimes existe.

**Eleger um runtime de referência e derivar os outros por teste de conformidade.** Recusada por não
sobreviver à medição: o Python já foi referência correta do bucket `Other` e defeituoso na
enumeração de REQ **no mesmo arquivo**. Nomear um runtime "certo" cria autoridade que os fatos não
sustentam.

**Aceitar divergência e documentá-la.** É o que `docs/cli-parity.md` já faz para as exceções
intencionais — mas como política geral degeneraria: o documento tem 65 gaps declarados, e sem a regra
dura esse número cresceria sem limite até o produto ser três produtos.

## REQs governadas por esta decisão
- REQ-2026-08-16-aspas-em-itens-de-lista
- REQ-2026-08-16-config-listas-nao-silenciosas
- REQ-2026-08-16-consistencias-template-saida-e-eol
- REQ-2026-08-16-roadmap-move-sincroniza-status
- REQ-2026-08-16-roadmap-new-paridade-contrato
- REQ-2026-08-16-suite-pypi-verde
- REQ-2026-08-17-adr-list-python
- REQ-2026-08-17-gate-paridade-subcomando
- REQ-2026-08-17-req-list-python
- REQ-2026-08-29-slug-de-artefato-no-python-diverge-de-go-e-node
