---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: i18n por detecção de ambiente com fallback `en-US`, e templates seguem o idioma

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra decisão tomada em 2026-06-12, após o primeiro uso real em ambiente
> corporativo. Escrita em 2026-09-05 para dar lastro à REQ abaixo.

## Context

O primeiro uso do trackfw em produção foi num ambiente Windows corporativo com equipes em **pt-BR,
en-US e es-ES**. O retorno foi que um CLI de governança em inglês fixo tem um custo específico: os
artefatos que ele gera — ADR, REQ, ROADMAP, `CLAUDE.md` — **são lidos por humanos que decidem**, e o
idioma do template contamina o idioma do conteúdo. Uma equipe pt-BR recebendo um template com
`## Context` e `## Decision` escreve em inglês por inércia, e escreve pior.

A superfície de i18n do trackfw é, portanto, maior que a de um CLI comum: não é só mensagem de
console, é **template de artefato**. E artefato gerado é persistente — fica versionado no
repositório do usuário, e mudar a decisão depois não reescreve o que já foi criado.

Isso separa dois requisitos que costumam vir juntos:

- **mensagem de console** — efêmera, pode mudar de idioma entre execuções sem consequência;
- **template de artefato** — durável, e o idioma escolhido no momento da geração fica.

## Decision

**Detecção automática pelo ambiente, com `en-US` como fallback, e o idioma detectado vale também
para os templates de artefato.**

1. Detecção por `LANG`, `LC_ALL`, `LANGUAGE`, nesta ordem de precedência.
2. Fallback **`en-US`** quando nenhuma resolve, ou quando resolve para idioma não suportado. Nunca
   falhar por causa de idioma.
3. Idiomas suportados: `pt-BR`, `en-US`, `es-ES`. Cada um em `locales/<tag>.json`, com o **mesmo
   conjunto de chaves** — a paridade de chaves entre locales é parte do contrato.
4. **Templates de artefato seguem o idioma detectado**, não só as mensagens de console.
5. A tabela de locales é a mesma nos três runtimes, por ser comportamento observável (ver ADR de
   paridade tri-runtime).

## Consequences

**Positivas**

- Equipes escrevem governança no idioma em que de fato pensam, que é o ponto do artefato.
- Fallback para `en-US` mantém o CLI utilizável em qualquer ambiente, inclusive container sem locale.
- Detecção por ambiente não exige configuração — funciona no primeiro uso, que é quando a barreira
  de adoção é maior.

**Negativas, e assumidas**

- **O artefato gerado é durável e o idioma dele também.** Um repositório onde contribuidores têm
  `LANG` diferentes acumula artefatos em idiomas misturados, e nada no sistema acusa. Este acervo é
  exatamente esse caso — `req_dir: docs/requisições` em português, cabeçalhos de template em inglês.
- Triplica o custo de toda string nova: três runtimes × três locales.
- **Divergência de chave entre locales é silenciosa**: a chave ausente cai no fallback e a mensagem
  aparece em inglês no meio do texto traduzido, sem erro.
- Cabeçalho de artefato em idioma variável colide com verificador que casa por literal — é
  exatamente a classe "gerador e verificador que discordam", e já se manifestou aqui com o cabeçalho
  de critérios de aceite em pt vs en.

## Alternatives Considered

**Só inglês.** Menor custo, e é o padrão de CLIs de desenvolvedor. Recusada pelo retorno de uso: o
problema não é o desenvolvedor ler o comando, é a equipe **escrever o artefato**.

**Idioma por flag explícita (`--lang`), sem detecção.** Recusada por atrito no primeiro uso — e
porque a flag seria esquecida justamente na geração de artefato, que é onde a escolha é durável.

**Idioma fixado no `trackfw.yaml` do projeto, não no ambiente.** É a alternativa mais forte, e
resolveria a mistura de idiomas num mesmo repositório. Recusada em 2026-06-12 por precedência: o
ambiente do usuário chega antes do arquivo de projeto na primeira execução, incluindo o `init`, que é
quando o `trackfw.yaml` ainda não existe. **Continua sendo a candidata natural** se a mistura de
idiomas por repositório virar problema medido — e o `docs/requisições` deste acervo sugere que já é.

## REQs governadas por esta decisão
- REQ-2026-06-12-i18n-wizard-java-scaffold
