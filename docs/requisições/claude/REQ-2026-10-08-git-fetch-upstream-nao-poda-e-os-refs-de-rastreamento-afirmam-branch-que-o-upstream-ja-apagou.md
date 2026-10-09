---
status: Done
date: 2026-10-08
author: ""
adr: "docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md"
roadmap: "docs/roadmaps/claude/done/ROADMAP-2026-10-08-git-fetch-upstream-nao-poda-e-os-refs-de-rastreamento-afirmam-branch-que-o-upstream-ja-apagou.md"
---

# REQ: git fetch upstream nao poda e os refs de rastreamento afirmam branch que o upstream ja apagou

> Date: 2026-10-08 | Status: Done
| Linear Issue: 
| Jira Issue: 

## Motivation
"Branches do upstream por data" é **um dos quatro instrumentos** usados para responder *"o Kleber
evoluiu?"* — pergunta feita treze vezes em dois dias. O `git fetch` **não poda por padrão**, e o
mantenedor **apaga a branch ao mesclar**: então a leitura local ordena no topo refs de trabalho que
já terminou, e uma branch mesclada e apagada se apresenta como trabalho em curso.

## Acceptance Criteria

- [x] AC1 — A medição está escrita e o denominador reconcilia
      ✅ `135` refs locais de `refs/remotes/upstream` contra `4` branches reais na API, `131`
      podados; 4 + 131 = 135. E as **quatro mais novas** da leitura local — as que um relato citaria
      primeiro — deram **404** na API, uma a uma, conferidas por `gh api repos/.../branches/<nome>`.
- [x] AC2 — O `upstream-sync.sh` ganha um passo que **age**, sem rede, e nenhum caminho dele é mudo
      ✅ `poda_refs_de_rastreamento` liga `remote.<remote>.prune`; **5 `return 0`, 5 com `say`
      imediatamente antes**, conferido retorno-a-retorno por `awk` — não por `grep say`, que
      provaria só que a palavra existe.
- [x] AC3 — A sequência documentada leva `--prune`, para a passada corrente
      ✅ `CLAUDE.md`: `git fetch upstream --prune`. O passo conserta o **próximo** fetch; esta linha
      conserta o de agora.
- [x] AC4 — Falsificado nas duas direções, com o remoto REAL, sem contornar o hook
      ✅ ref sintética plantada por `git fetch upstream main:refs/remotes/upstream/<nome>` — o
      `git update-ref` é **bloqueado pelo hook**, e contornar continua vetado. Com a config vazia a
      ref **sobrevive** ao `fetch` normal; depois do passo, o **mesmo** `fetch` a **poda**.
- [x] AC5 — A diferença de causa contra a `REQ-2026-10-05` está escrita
      ✅ seção `## Por que isto NÃO é ML da REQ-2026-10-05`, abaixo, com o teste da Regra Dura
      aplicado nas duas direções.

- [x] AC6 — O segundo consumidor dos refs — o **produto** — está nomeado e medido
      ✅ `detectPendingSquashMerges` (`internal/commands/ship.go`) itera **todo** remote-tracking e
      só tira o prefixo `origin/`: `trackfw push` emite **4** avisos nomeando branch do **upstream**,
      em que temos **0** commits e que o `origin` não tem. Achado **no push deste trabalho**, não na
      análise — e a conclusão estreita do ML-0A ficou **datada e explicada**, não apagada.

- [x] AC7 — A poda cobre **todos** os remotes, não o que o `$REF` nomeia
      ✅ ML-1C: o passo passou a ligar `fetch.prune` e a enumerar por `git remote`. O `origin` estava
      **descoberto por construção** e já tinha ref velha (`origin/chore/sync-do-546…`, **404** na API);
      fechado por efeito com `git fetch origin` **sem flag**: `2 → 1` refs. Falsificado em **seis**
      direções, e a premissa de precedência (`remote.<r>.prune=false` ganha de `fetch.prune`) foi
      medida **por efeito com o remoto real**, nas duas direções — não lida na documentação.

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: docs/adr/ADR-2026-08-29-adotar-upstream-como-base.md

## Blocked by ADRs
<!-- none -->

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: docs/roadmaps/claude/done/ROADMAP-2026-10-08-git-fetch-upstream-nao-poda-e-os-refs-de-rastreamento-afirmam-branch-que-o-upstream-ja-apagou.md

## Medição — 2026-10-08

```
refs locais de refs/remotes/upstream     135
branches reais em kgsaran/trackfw          4
podados por `git remote prune upstream`  131
```

As quatro primeiras linhas do `for-each-ref` ordenado por `committerdate`, todas **404** na API:

| ref local (a leitura dizia) | na API |
|---|---|
| `upstream/feat/req-done-open-criteria-decompoe-herdadas` | 404 |
| `upstream/fix/credential-guard-nao-cobre-windsurf-e-amazon-q` | 404 |
| `upstream/chore/release-9.3.3` | 404 |
| `upstream/fix/hooks-de-guard-executam-no-windows-saida-nao-zero-no-powershell` | 404 |

🔴 **Não houve relato errado hoje, e isso não é o instrumento funcionando** — é redundância. O head
de `upstream/main` e a lista de PRs concordavam em "nada novo", então a leitura de branches não foi
o discriminante. Numa pergunta em que ela fosse, o relato teria afirmado trabalho em curso.

## Por que isto NÃO é ML da REQ-2026-10-05

A `REQ-2026-10-05-as-14-branches-upstream-pr-sao-todas-terminais-e-o-acervo-de-branches-mente-sobre-trabalho-vivo`
tem o **mesmo sintoma**, declarado no próprio título. Pela Regra Dura de Causa Raiz, sintoma igual
**investiga junto**, e separar exige a **medição escrita**. Ela está aqui, nas duas direções:

| correção | fecha o caso das 14? | fecha este? |
|---|---|---|
| apagar as branches (local + `origin`) | **sim** | não — ref de rastreamento não é branch nossa |
| ligar a poda do remote | não — as 14 **existiam** no `origin`, e poda não apaga o que existe | **sim** |

Nenhuma das duas fecha a outra, que é exatamente o teste que a regra manda aplicar: *"se eu corrigir
esta causa, exatamente estas falhas fecham — e nenhuma outra"*. Mecanismo de sobrevivência
diferente: lá **ninguém apagou**; aqui **o git não poda**.

## Context

🔴 **O passo é de CONFIGURAÇÃO, não de rede, e isso é desenho.** O `git fetch` roda **antes** do
`upstream-sync.sh`, de propósito — script que muda o estado que ele mede deixa de ser medição, a
mesma razão pela qual o `check-inherited-req.sh` não faz `fetch` sozinho. Ligar
`remote.<remote>.prune` faz o **próximo** fetch podar, inclusive o avulso digitado fora do sync, que
é onde o defeito morde.

**E ele age em vez de só avisar**, pela divisão de trabalho já escrita para a cópia do PATH: o passo
mantém a propriedade, o gate a torna verificável. Aviso que ninguém executa foi o que custou a
leitura de hoje.

**Limite declarado:** a chave é **config local do clone**, não arquivo versionado. Clone novo nasce
sem ela, e é por isso que o passo roda a cada sync em vez de ser instrução de instalação — e por
isso a sequência documentada leva `--prune`, que não depende de config nenhuma.
