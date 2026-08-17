---
status: Accepted
date: 2026-06-14
author: artemis
---

# ADR: Handlers do serve são funções puras sobre um diretório, testados sem subir servidor

> Date: 2026-06-14 | Status: Accepted

REQ: REQ-2026-06-14-serve-api-tests-nodejs

> **Reconstrução retroativa, escrita em 2026-08-16.** Decisão tomada em 2026-06-14 e nunca
> registrada. Reconstruída do texto da REQ, do roadmap `ROADMAP-2026-06-14-serve-api-tests-nodejs.md`
> e do código atual. Verificado: `npm/tests/serve_api.test.js` importa `handleBoard`, `handleFile`,
> `handleMetrics` e `getAttention` diretamente de `npm/src/serve/`, e não há nenhum `listen` nem
> bind de porta no arquivo. Ver `REQ-2026-08-16-adrs-retroativas`.

## Context

O `trackfw serve` sobe um dashboard local de governança: kanban, cadeia ADR→REQ→ROADMAP, métricas e
o banner de atenção dos agentes. Precisava de cobertura de teste, incluindo os casos que importam
para segurança — path traversal no endpoint de arquivo — e os degenerados, como log de transições
ausente.

O caminho óbvio seria teste de integração: subir o servidor numa porta, fazer requisições HTTP,
conferir status e corpo. Isso traz três problemas num projeto tri-runtime:

- **Porta é estado global.** Testes paralelos colidem; CI com porta ocupada falha por motivo alheio
  ao código.
- **Assincronia desnecessária.** Subir, esperar ficar pronto, derrubar — cada passo é uma fonte de
  flakiness que não tem nada a ver com o que se quer verificar.
- **Paridade fica cara.** Go, Node.js e Python teriam três harnesses de servidor diferentes para
  testar o mesmo comportamento.

## Decision

Os handlers da API do `serve` são **funções sobre um diretório de governança**, não closures presas
ao servidor HTTP. Cada um recebe o caminho raiz e os parâmetros da requisição, e devolve a resposta
— sem tocar em socket.

O servidor vira uma casca fina: parseia a rota, chama o handler, serializa. O teste importa o
handler e o chama direto, com um `tmpdir` montado como fixture.

Em Node.js isso é `handleBoard`, `handleFile`, `handleMetrics` e `getAttention` exportados de
`npm/src/serve/`. Os outros dois runtimes seguem a mesma separação em `internal/serve/` e
`pypi/trackfw/serve/`.

Path traversal é testado como qualquer outro caso: chamar `handleFile` com `../` no caminho e
asseverar 403. Nenhum servidor envolvido.

## Consequences

**Positivas.** A suíte roda sem porta, sem espera e sem cleanup de processo — não há flakiness de
infraestrutura. Montar um caso degenerado é escrever um diretório: log ausente, roadmap sem REQ,
arquivo fora da raiz. E o mesmo desenho vale nos três runtimes, o que mantém a paridade barata.

**Negativas.** O roteamento em si fica descoberto: um handler certo pendurado na rota errada passa
nos testes. O mesmo vale para serialização, cabeçalhos e códigos de status definidos na camada HTTP.
Esses caminhos dependem de verificação manual ou de um teste de integração que não existe.

## Alternatives Considered

**Teste de integração subindo o servidor numa porta.** Cobriria roteamento e camada HTTP de verdade.
Descartada pelo custo: porta como estado global, assincronia de subida e três harnesses distintos
para o mesmo comportamento. O ganho — cobrir o wiring — não paga a flakiness importada.

**Servidor em porta efêmera (`:0`) com cleanup no teardown.** Resolve a colisão de porta e mantém a
cobertura de roteamento. Continua viável como camada adicional. Descartada por ora porque não elimina
a assincronia nem o custo de paridade, e o valor incremental sobre o teste de handler é pequeno
frente ao que já se cobre.
