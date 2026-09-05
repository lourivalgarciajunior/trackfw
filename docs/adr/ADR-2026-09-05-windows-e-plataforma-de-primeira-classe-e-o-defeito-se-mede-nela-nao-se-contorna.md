---
status: Accepted
date: 2026-09-05
author: "claude"
---

# ADR: Windows é plataforma de primeira classe — o defeito se mede nela, não se contorna

> Date: 2026-09-05 | Status: Accepted
> **ADR retroativa.** Registra decisão tomada e implementada entre 2026-08-16 e 2026-08-29. Escrita
> em 2026-09-05 para dar lastro às 5 REQs abaixo.

## Context

O trackfw nasceu e foi desenvolvido em POSIX. O primeiro uso real em ambiente Windows corporativo
revelou que a v7.3.0 **nunca tinha sido exercitada nessa plataforma** — não havia job de CI de
Windows, e o diagnóstico da época foi exatamente esse.

O que apareceu não foi uma lista de bugs, foi um **padrão**: predicados cujo nome promete uma
pergunta e cuja resposta muda com o sistema operacional. Medido neste acervo e no upstream:

| predicado | POSIX | Windows | consequência |
|---|---|---|---|
| `filepath.IsAbs("/opt/x")` | true | **false** | guard de segurança pulado sem aviso |
| `os.IsNotExist(err)` com `ENOTDIR` | false | **true** | diagnóstico de diretório ilegível engolido |
| `subprocess.run(["bash", …])` | bash real | stub do WSL, ou `FileNotFoundError` | ~50 testes sem executar o script |
| `os.Stat(...).Mode() & 0111` | bit real | **sempre 0** | bit de execução falsamente vermelho |
| `sys.stdout.isatty()` para `NUL` | False | **True** | saída interativa em pipe |

Em todos, o defeito é **silencioso na plataforma onde não existe**. Quem desenvolve em macOS não vê
nenhum deles, e a suíte verde local não é evidência.

A tentação, cada vez que um desses aparece, é a mesma: guardar o teste por plataforma e seguir. Isso
converte defeito em invisibilidade — e foi medido custando caro: 9 supressões silenciosas
pré-existentes passavam no Windows **sem nomear nada**, e um requisito que exigia nomear a garantia
não exercitada tinha **zero ocorrências** legíveis porque o `go test` sem `-v` descarta a saída de
pacote que passa.

## Decision

**Windows é plataforma de primeira classe. Um defeito que só aparece nela é defeito, e se mede nela.**

1. **Nenhum `skip` por plataforma.** Um teste pulado não mede mais que um que não executa. Onde a
   propriedade genuinamente não existe no SO — o bit de execução em NTFS é o caso —, o teste vira
   **supressão nomeada**: passa, e **imprime qual garantia deixou de ser exercitada**. A mensagem tem
   de ser legível na configuração real do CI, não só com flag de verbosidade.
2. **Não forçar a plataforma a mentir.** Não se escreve o bit de execução em NTFS para o teste passar;
   registra-se que NTFS não tem a propriedade.
3. **Classificação por consumidor, não por SO.** Onde o interpretador de um valor é o bash ou o CLI de
   agente — e não o sistema de arquivos —, o predicado não pode consultar o SO host. Onde há
   **travessia real de sistema de arquivos**, o SO é a autoridade certa e continua sendo consultado.
   A fronteira é explícita e verificável por leitura.
4. **CI de Windows executa as suítes de verdade**, não compilação cruzada. `GOOS=windows` compila e
   não executa; o defeito desta classe só existe em tempo de execução.

## Consequences

**Positivas**

- Cinco classes de defeito silencioso deixaram de ser silenciosas.
- A supressão nomeada preserva o vermelho legítimo (o bit em NTFS segue vermelho de propósito) sem
  esconder o ilegítimo.
- A fronteira "classificação vs travessia" impede o remédio de virar defeito novo: normalizar caminho
  antes de uma syscall quebraria UNC e caminho longo, com falha **intermitente**.

**Negativas, e assumidas**

- Um job de CI que não é da plataforma de desenvolvimento de ninguém. Enquanto ele roda com
  `continue-on-error`, não bloqueia nada e vira decoração — a regra só se sustenta quando ele passar
  a bloquear por ratchet.
- Supressão nomeada é mais cara de escrever que `skip`, e a mensagem precisa de canal que sobreviva à
  configuração do executor de testes.
- A verificação depende de alguém ter a plataforma. Esta é a assimetria que este fork explora: temos
  Windows real e o upstream não.

## Alternatives Considered

**Declarar Windows não suportado.** Recusada: o primeiro uso corporativo real do CLI foi em Windows,
e o `trackfw` é distribuído por npm e pip, que são exatamente os canais de quem está em Windows.

**`skip` por plataforma com justificativa em comentário.** Recusada por medição: comentário não é
sinal em tempo de execução. Contado neste acervo, o Go tem **41** `t.Skip` contra 1 do Node e 9 do
Python — a assimetria mostra que `skip` acumula sem revisão.

**Emular POSIX no Windows (WSL, Git Bash como pré-requisito).** Recusada: transfere o defeito para o
ambiente do usuário e não é verificável. O caso do stub do WSL prova o contrário — foi justamente o
`bash` do `System32` que quebrou ~50 testes.

## REQs governadas por esta decisão
- REQ-2026-08-16-cli-python-utf8-windows
- REQ-2026-08-16-testes-go-portaveis-windows
- REQ-2026-08-29-geradores-python-escrevem-crlf-no-windows
- REQ-2026-08-29-isatty-do-python-devolve-true-para-nul-no-windows
- REQ-2026-08-29-node-e-python-ignoram-home-no-windows
