---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: Três CLIs nativos em vez de um núcleo com wrappers

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra a decisão fundadora da linha v2.x, tomada em 2026-06-13 e construída
> até 2026-06-18. Escrita em 2026-09-05 para dar lastro às 7 REQs abaixo.

## Context

O trackfw começou como binário Go. A adoção real esbarrou no canal de instalação: equipes Node
instalam por `npm`, equipes Python por `pip`, e nenhuma das duas quer um binário Go no `PATH` como
pré-requisito de um comando de governança.

As opções eram três: distribuir o binário Go embrulhado em pacotes npm/pip; expor a lógica por um
serviço; ou **reimplementar** o CLI em cada linguagem.

O que decidiu foi o ambiente-alvo. O trackfw é usado dentro de pipelines e de sessões de agente, em
máquinas onde frequentemente **existe um runtime e não os outros** — e onde baixar binário por
plataforma esbarra em política corporativa. Um wrapper que falha por não achar o binário embutido é
pior que não existir, porque falha tarde e com mensagem de outro nível de abstração.

Esta decisão é a **causa raiz** do custo estrutural do projeto: toda feature da linha v2.x — a saída
`--json`, o discovery mode, o `trackfw update`, os bugfixes de baseline e de parser YAML — precisou
ser construída três vezes. As 7 REQs abaixo são, todas, essa consequência.

## Decision

**Três implementações nativas e independentes: Go (`internal/`), Node.js (`npm/src/`) e Python
(`pypi/trackfw/`). Sem núcleo compartilhado, sem FFI, sem binário embutido.**

1. Cada runtime é instalável e utilizável **sozinho**, sem os outros dois presentes.
2. Cada um usa a biblioteca-padrão e o idioma da sua linguagem — cobra em Go, commander em Node,
   argparse em Python. Não se transliteram estruturas de uma para as outras.
3. A equivalência é garantida por **contrato observável**, não por código compartilhado. É a ADR irmã
   de paridade tri-runtime que define esse contrato e como verificá-lo.
4. O Python é CLI nativo, não wrapper — inclusive nos pontos onde isso custa (encoding de saída no
   Windows, ausência de tipagem forte no parser de configuração).

## Consequences

**Positivas**

- Instalação nativa em três ecossistemas, sem binário externo e sem etapa de download.
- Um runtime quebrado não impede os outros dois de funcionar.
- Três implementações independentes do mesmo contrato são um **detector de ambiguidade de
  especificação**: onde as três divergem, quase sempre o contrato estava mal definido, não o código.

**Negativas, e assumidas**

- **Custo triplicado em tudo**: feature, correção, teste, revisão. É a origem do alvo `parity` ser
  90% do tempo de parede de um PR.
- Superfície de divergência silenciosa permanente, que exige a regra dura de paridade como
  contrapeso. Sem ela, esta decisão degeneraria em três produtos parecidos.
- Cada runtime traz as armadilhas da sua plataforma para dentro do produto — e algumas só aparecem
  cruzadas com o sistema operacional (o CPython passando `lpApplicationName = NULL` ao
  `CreateProcess` é o exemplo caro).
- Reimplementar tem um modo de falha próprio: a **tradução plausível mas errada**, que passa nos
  testes daquele runtime porque os testes foram traduzidos junto.

## Alternatives Considered

**Binário Go embrulhado em npm e pip.** É o padrão da indústria (esbuild, ripgrep). Recusada pelo
ambiente-alvo: exige matriz de plataformas, etapa de download no install, e falha em rede restrita —
justamente o ambiente corporativo onde o CLI foi primeiro usado de verdade.

**Núcleo em WASM.** Elimina a divergência e roda nos três. Recusada por custo de ferramenta e por
degradar a experiência de erro: rastreamento de pilha através da fronteira WASM é ilegível, e o
trackfw é uma ferramenta de diagnóstico — a qualidade da mensagem de erro é o produto.

**Serviço com clientes finos.** Recusada de saída: governança de repositório precisa funcionar
offline, dentro de hook de commit, sem rede e sem estado remoto.

**Apenas Go.** É o que teria custado menos. Recusada porque teria limitado a adoção ao público
disposto a instalar um binário — e a base real de usuários chega por `npm` e `pip`.

## REQs governadas por esta decisão
- REQ-2026-06-13-discovery-mode-cmdb
- REQ-2026-06-13-gaps-v2-implementacao
- REQ-2026-06-13-python-cli-nativo
- REQ-2026-06-13-v2.4.1-baseline-ratchet-warnings
- REQ-2026-06-13-v2.5.1-json-fields-help-traceid
- REQ-2026-06-13-validate-json-output
- REQ-2026-06-18-trackfw-update-command
