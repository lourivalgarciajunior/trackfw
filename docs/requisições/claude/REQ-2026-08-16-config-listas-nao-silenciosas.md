---
id: REQ-2026-08-16-config-listas-nao-silenciosas
title: Parser de trackfw.yaml não pode descartar listas em silêncio
status: approved
priority: high
type: bug
created: 2026-08-16
author: claude
---

# REQ: Listas do `trackfw.yaml` descartadas em silêncio

Roadmap: config-listas-nao-silenciosas-2026-08-16.md

## Problema

O `trackfw.yaml` é lido por um parser caseiro em cada runtime. Ele entende **uma** das três formas
de lista que o YAML aceita, e descarta as outras duas sem dizer nada.

| forma | YAML válido | Go | npm | Python |
|---|---|---|---|---|
| bloco indentado — `  - claude` | sim | ✅ | ✅ | ✅ |
| bloco não indentado — `- claude` | sim | ❌ | ❌ | ✅ |
| inline — `[claude, gemini]` | sim | ❌ | ❌ | ❌ |

As duas formas de bloco são equivalentes para qualquer parser YAML de verdade — confirmado com
PyYAML: `yaml.safe_load` devolve o mesmo objeto para as duas.

### O exemplo do README não funciona

`README.md:199` documenta, na seção "Multi-agent namespacing":

```yaml
roadmap_namespacing: by_agent
agents: [claude, gemini, copilot]
```

Nos três runtimes isso resulta em `agents = []`. Quem segue a documentação escreve uma configuração
que é silenciosamente ignorada.

### Impacto medido, por bloco

**`agents` vazio é benigno.** Os três caem no fallback de varrer os subdiretórios de `roadmap_dir`
como agentes. É por isso que o sintoma não produzia diferença observável de comportamento.

**`adr_dirs` perdido é perda real.** O diretório declarado nunca é varrido, e toda ADR nele fica
invisível ao `validate` — sem erro e sem aviso. Isolado com uma ADR órfã em `docs/decisions`:

```
adr_dirs         go         npm        py
indentado        VE-a-ADR   VE-a-ADR   VE-a-ADR
NAO indentado    nao-ve     nao-ve     VE-a-ADR
```

### Por que ninguém tropeçou

Os três geradores do `init` emitem bloco indentado (`scaffold.go:550`, `init.js:57`,
`init_gen.py:126`). O caminho padrão é seguro. É atingido quem edita à mão — ou quem copia do
README.

## Decisão de rota

Duas rotas foram consideradas: cobrir todas as formas de YAML, ou recusar em voz alta o que não se
entende. **Escolhida a segunda**: o defeito é o silêncio, não a cobertura. Um parser de poucas
centenas de linhas nunca vai cobrir YAML inteiro, e cada forma não coberta reproduz o problema.

**Ressalva sobre o bloco não indentado.** Aplicar "recusar em voz alta" literalmente ali significaria
o Python avisar sobre input que ele já processa corretamente, ou passar a rejeitá-lo — as duas
pioram o estado atual. Nesse caso específico o alinhamento é **para cima**: Go e npm passam a
aceitar a forma que o Python já aceita. O aviso fica para a forma inline, que nenhum runtime
suporta.

## Requisitos

### R1 — Bloco não indentado aceito nos três
Go e npm passam a coletar itens `- x` mesmo sem indentação, como o Python já faz. Comportamento
idêntico nos três para as duas formas de bloco.

### R2 — Lista inline detectada e avisada, nunca descartada em silêncio
Quando uma chave de lista (`adr_dirs`, `agents`, `acceptance_markers`) vier com valor na mesma
linha, o parser emite aviso em stderr nomeando a chave, dizendo que a forma inline não é suportada
e mostrando a forma equivalente que funciona. O valor continua não sendo parseado — mas o usuário
fica sabendo.

### R3 — Aviso uma vez por processo
A config é um singleton nos três runtimes. O aviso sai no primeiro carregamento, não a cada
consulta.

### R4 — README corrigido
Trocar o exemplo inline pela forma de bloco em `README.md:199`.

## Critérios de Aceite

- [x] `agents:` e `adr_dirs:` em bloco não indentado funcionam nos três runtimes
- [x] `agents: [a, b]` emite aviso em stderr nos três, nomeando a chave
- [x] O aviso mostra a forma equivalente suportada
- [x] O aviso sai uma vez, não a cada `load()`
- [x] Nenhum aviso quando a config usa bloco (indentado ou não)
- [x] `README.md` não documenta mais a forma inline
- [x] `go test ./...` zero falhas, `pytest tests/` zero falhas, testes npm verdes
- [x] Os três gates de paridade passam
