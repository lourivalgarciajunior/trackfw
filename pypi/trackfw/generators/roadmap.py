"""
roadmap.py — Gerador e movimentador de roadmaps.
Espelha npm/src/generators/roadmap.js em Python puro.
"""

import os
import re
import datetime

from trackfw import config as cfg_module

VALID_STATES = ["backlog", "wip", "blocked", "done", "abandoned"]
STATE_ORDER = ["wip", "backlog", "blocked", "done", "abandoned"]


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def slugify(title: str) -> str:
    """Converte string para slug lowercase com hífens."""
    slug = title.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = slug.strip("-")
    return slug


def _state_dir(state: str, cfg: dict) -> str | None:
    """Retorna diretório do estado em modo flat, ou None se estado inválido."""
    if state not in VALID_STATES:
        return None
    return os.path.join(cfg["roadmap_dir"], state)


def _agent_state_dir(agent: str | None, state: str, cfg: dict) -> str | None:
    """Retorna diretório agente/estado em modo by_agent."""
    if state not in VALID_STATES:
        return None
    if not agent:
        agents = cfg.get("agents") or []
        agent = agents[0] if agents else "default"
    return os.path.join(cfg["roadmap_dir"], agent, state)


def _find_roadmap_matches(name: str, cfg: dict) -> list[str]:
    """
    Retorna lista de paths que contêm `name` (case-insensitive) em qualquer estado.
    Suporta modo flat e by_agent.
    """
    matches = []
    name_lower = name.lower()

    if cfg.get("roadmap_namespacing") == cfg_module.NAMESPACING_BY_AGENT:
        agents = list(cfg.get("agents") or [])
        if not agents:
            roadmap_dir = cfg["roadmap_dir"]
            try:
                for entry in os.listdir(roadmap_dir):
                    full = os.path.join(roadmap_dir, entry)
                    if os.path.isdir(full):
                        agents.append(entry)
            except OSError:
                agents = ["default"]
        for agent in agents:
            for state in STATE_ORDER:
                d = os.path.join(cfg["roadmap_dir"], agent, state)
                try:
                    for f in os.listdir(d):
                        if name_lower in f.lower() and f.endswith(".md"):
                            matches.append(os.path.join(d, f))
                except OSError:
                    continue
    else:
        for state in STATE_ORDER:
            d = os.path.join(cfg["roadmap_dir"], state)
            try:
                for f in os.listdir(d):
                    if name_lower in f.lower() and f.endswith(".md"):
                        matches.append(os.path.join(d, f))
            except OSError:
                continue

    return matches


def _append_transition_log(basename: str, from_state: str, to_state: str, cfg: dict) -> None:
    """Grava linha no .trackfw-log dentro do roadmap_dir."""
    now = datetime.datetime.now()
    timestamp = now.strftime("%Y-%m-%d %H:%M")
    line = f"{timestamp}  {basename:<50}  {from_state} → {to_state}\n"
    log_path = os.path.join(cfg["roadmap_dir"], ".trackfw-log")
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass


def _roadmap_template(title: str, slug: str, date: str) -> str:
    """Retorna conteúdo do roadmap conforme o template do projeto."""
    return f"""---
name: {slug}
title: "{title}"
status: backlog
created: {date}
author:
---

# Roadmap: {title}

> Created: {date} | Status: backlog

## Diagnóstico / Contexto

<!-- Descreva o problema a resolver -->

## Wave 1 — <Nome>

### ML-1A — <Título>
**Status:** ⬜ Pendente
**Arquivos afetados:**
**Ações:**
**Critérios de aceite:**
- [ ]
"""


# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

def generate_roadmap(title: str, cfg: dict, agent: str = None) -> str:
    """
    Cria roadmap em backlog/.
    - Modo flat:     cfg["roadmap_dir"]/backlog/<slug>.md
    - Modo by_agent: cfg["roadmap_dir"]/<agent>/backlog/<slug>.md
    Retorna o path do arquivo criado.
    """
    today = datetime.date.today().isoformat()
    slug = slugify(title)
    filename = f"ROADMAP-{today}-{slug}.md"

    if cfg.get("roadmap_namespacing") == cfg_module.NAMESPACING_BY_AGENT:
        backlog_dir = _agent_state_dir(agent, "backlog", cfg)
    else:
        backlog_dir = os.path.join(cfg["roadmap_dir"], "backlog")

    os.makedirs(backlog_dir, exist_ok=True)
    filepath = os.path.join(backlog_dir, filename)

    body = _roadmap_template(title, slug, today)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(body)

    return filepath


def move_roadmap(filename: str, to_state: str, cfg: dict) -> str:
    """
    Move um roadmap de um estado para outro, atualizando status: no frontmatter.
    Busca o arquivo em todos os estados (e em todos os agentes em modo by_agent).
    Retorna o novo path.
    Levanta ValueError em estado inválido ou arquivo não encontrado.
    """
    if to_state not in VALID_STATES:
        raise ValueError(
            f'Estado inválido "{to_state}" — válidos: {", ".join(VALID_STATES)}'
        )

    # Encontra o arquivo em qualquer estado
    matches = _find_roadmap_matches(filename, cfg)

    # Filtra apenas o arquivo com basename exato (sem partial match por default)
    exact = [m for m in matches if os.path.basename(m) == filename]
    if not exact:
        # Tenta partial match se não houver exato
        exact = matches

    if not exact:
        raise FileNotFoundError(f'Roadmap "{filename}" não encontrado em nenhum estado.')

    if len(exact) > 1:
        raise ValueError(
            f'Múltiplos roadmaps encontrados para "{filename}": {exact}'
        )

    src = exact[0]
    basename = os.path.basename(src)
    from_state = os.path.basename(os.path.dirname(src))

    # Determina diretório de destino preservando agente em by_agent
    if cfg.get("roadmap_namespacing") == cfg_module.NAMESPACING_BY_AGENT:
        agent_dir = os.path.dirname(os.path.dirname(src))
        agent = os.path.basename(agent_dir)
        target_dir = _agent_state_dir(agent, to_state, cfg)
    else:
        target_dir = _state_dir(to_state, cfg)

    os.makedirs(target_dir, exist_ok=True)
    dst = os.path.join(target_dir, basename)

    # Move primeiro, depois reescreve só se o frontmatter mudar — mesmo fluxo do
    # Go e do Node.js. newline="" nos dois lados desliga a tradução automática de
    # quebra de linha: sem isso o Windows converteria LF em CRLF no arquivo
    # inteiro, mesmo quando não há nada a alterar.
    os.replace(src, dst)

    try:
        with open(dst, "r", encoding="utf-8", newline="") as f:
            content = f.read()
        updated = _set_header_status(
            _set_frontmatter_status(content, to_state), to_state
        )
        if updated != content:
            with open(dst, "w", encoding="utf-8", newline="") as f:
                f.write(updated)
    except OSError:
        pass

    _append_transition_log(basename, from_state, to_state, cfg)

    return dst


def _set_frontmatter_status(content: str, state: str) -> str:
    """Devolve content com o campo status: do frontmatter valendo state.

    So mexe dentro do bloco delimitado pelos "---" do topo do arquivo, e so se a
    chave status ja existir ali.

    Devolve content intocado quando nao ha frontmatter ou quando o bloco nao
    declara status - mesmo contrato do validator, que ignora quem nao declara.
    Isso protege roadmaps sem frontmatter, cujo corpo pode conter uma linha
    comecando com "status:". Ver REQ-2026-08-16-roadmap-move-sincroniza-status.
    """
    if not (content.startswith("---\n") or content.startswith("---\r\n")):
        return content

    lines = content.split("\n")
    if len(lines) < 2:
        return content

    # Procura o "---" de fechamento; fora dele nada e reescrito.
    end = -1
    for i in range(1, len(lines)):
        if lines[i].rstrip("\r") == "---":
            end = i
            break
    if end < 0:
        return content

    for i in range(1, end):
        line = lines[i]
        trimmed = line.rstrip("\r")
        idx = trimmed.find(":")
        if idx < 0:
            continue
        if trimmed[:idx].strip() != "status":
            continue
        lines[i] = "status: " + state + ("\r" if line.endswith("\r") else "")
        return "\n".join(lines)

    return content


# Separa o rotulo do estado na linha humana logo abaixo do titulo, no formato
# "> Created: 2026-08-16 | Status: backlog".
_HEADER_STATUS_MARKER = "| Status: "


def _set_header_status(content: str, state: str) -> str:
    """Devolve content com o estado da linha humana valendo state.

    Age na primeira linha que comece com "> " e contenha o marcador; tudo depois
    dele e substituido. Conteudo intocado quando nenhuma linha casa - a linha
    nunca e criada, mesmo contrato de _set_frontmatter_status.

    Tolera o formato herdado com emoji ("| Status: WIP" precedido de emoji),
    porque substitui o trecho inteiro em vez de tentar casar o valor anterior.

    Ver REQ-2026-08-16-consistencias-template-saida-e-eol.
    """
    lines = content.split("\n")
    for i, line in enumerate(lines):
        trimmed = line.rstrip("\r")
        if not trimmed.startswith("> "):
            continue
        idx = trimmed.find(_HEADER_STATUS_MARKER)
        if idx < 0:
            continue
        novo = trimmed[: idx + len(_HEADER_STATUS_MARKER)] + state
        lines[i] = novo + ("\r" if line.endswith("\r") else "")
        return "\n".join(lines)
    return content
