---
name: medir-pelo-caminho-do-cmd-nao-pela-fixture
description: Configuração de segurança só está ligada se o main/cmd a passa; a fixture de teste que preenche o campo à mão esconde a omissão e deixa a suíte verde
metadata:
  type: feedback
---

Quando um controle vem de configuração (teto, limite, timeout, chave), **leia o `cmd`/`main` que
monta o objeto em produção** e compare campo a campo com a struct. Não confie na suíte: a fixture
costuma preencher o campo que o `cmd` esquece.

**Why:** 2026-09-24, red team do runner do `trackfw-radar` (RT-6). `internal/config` lia
`RADAR_TAREFA_TETO_TURNOS/CUSTO/MINUTOS`, aplicava padrão e **recusava zero** — validação exemplar.
`cmd/api/runner.go:34` montava `&runner.Servico{DB, Client, Log, Clones, Areas}` e nunca passava
`Orcamento`. Os três tetos eram configuração morta. A suíte inteira de `internal/runner` passava
porque o helper `montar` escrevia
`Orcamento: tarefas.Orcamento{Turnos: 40, Centavos: 500, Duracao: 30 * time.Minute}` à mão. O
efeito real era nos dois sentidos: `Duracao == 0` faz `context.WithTimeout(ctx, 0)` nascer vencido
(toda tarefa morria no primeiro passo) e `Estourou` guarda com `> 0` (nenhum teto disparava).
Reproduzi construindo o `Servico` **exatamente como o `cmd` constrói**, com o controle ao lado
(mesmo cenário, com `Orcamento`): `falhou/0 chamadas` contra `aguardando_plano/1 chamada`.

**How to apply:** em qualquer auditoria de controle configurável, faça três leituras — (1) a struct
de config e sua validação, (2) o `cmd`/`main` que a consome, (3) a fixture de teste. Se (3)
preenche algo que (2) não preenche, é achado. E a sonda que prova é a que **replica o (2)**, não a
que reusa o helper da suíte. Relacionado: [[verde-sem-denominador-nao-e-evidencia]] — aqui o verde
existia porque o teste media outro objeto.
