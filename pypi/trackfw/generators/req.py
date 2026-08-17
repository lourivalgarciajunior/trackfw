"""
generators/req.py — Gerador de REQs para trackfw.
Espelha npm/src/generators/req.js (funções newREQ, listREQs, parseREQStatus).
Stdlib apenas — sem dependências externas.
"""

import datetime
import os
import unicodedata
from datetime import date

from trackfw import config as cfg_module
from trackfw.generators.roadmap import _set_frontmatter_status, _set_header_status


def slugify(title: str) -> str:
    """
    Converte título em slug kebab-case lowercase.
    Remove acentos via NFKD + encode ascii ignore, substitui espaços por hífens.
    """
    normalized = unicodedata.normalize("NFKD", title)
    ascii_str = normalized.encode("ascii", "ignore").decode("ascii")
    return ascii_str.lower().replace(" ", "-")


def generate_req(title: str, req_dir: str = None, cwd: str = None) -> str:
    """
    Cria docs/requisições/<req_dir>/REQ-YYYY-MM-DD-<slug>.md.

    Args:
        title: Título da REQ.
        req_dir: Diretório destino (default: docs/requisicoes/claude).
        cwd: Diretório de trabalho base (default: os.getcwd()).

    Returns:
        Path absoluto do arquivo criado.
    """
    base = cwd or os.getcwd()

    if req_dir is None:
        req_dir = os.path.join(base, "docs", "requisicoes", "claude")
    elif not os.path.isabs(req_dir):
        req_dir = os.path.join(base, req_dir)

    os.makedirs(req_dir, exist_ok=True)

    slug = slugify(title)
    today = date.today().isoformat()
    filename = f"REQ-{today}-{slug}.md"
    filepath = os.path.join(req_dir, filename)

    content = f"""---
name: REQ-{today}-{slug}
title: "{title}"
status: Open
linked_adr: —
created: {today}
author:
---

# REQ: {title}

| Campo | Valor |
|---|---|
| Status | Open |
| Criado | {today} |

---

## Motivação

<!-- Descreva o problema ou oportunidade -->

---

## Critérios de Aceite

- [ ] critério 1

---

## Fora de Escopo

<!-- O que esta REQ NÃO cobre -->
"""

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    return filepath


# Os cinco estados que uma REQ pode ocupar — os mesmos que o validator ja varre.
REQ_STATES = ["backlog", "wip", "blocked", "done", "abandoned"]


def find_req(name: str, cfg: dict) -> str:
    """Procura uma REQ por nome (match parcial, case-insensitive) nas tres formas
    em que elas vivem: sob agente e estado, sob agente sem estado, e na raiz do
    req_dir.

    Devolve o caminho. Levanta FileNotFoundError se nao achar e ValueError se o
    nome for ambiguo.

    Ver ADR-2026-08-17-req-move-resolve-as-tres-formas.
    """
    req_dir = cfg.get("req_dir")
    if not req_dir:
        raise ValueError("req_dir nao configurado")

    dirs = []
    if cfg.get("roadmap_namespacing") == cfg_module.NAMESPACING_BY_AGENT:
        agents = list(cfg.get("agents") or [])
        if not agents:
            try:
                agents = [
                    e for e in os.listdir(req_dir)
                    if os.path.isdir(os.path.join(req_dir, e))
                ]
            except OSError:
                agents = []
        for agent in agents:
            for state in REQ_STATES:
                dirs.append(os.path.join(req_dir, agent, state))
            dirs.append(os.path.join(req_dir, agent))
    dirs.append(req_dir)

    lower = name.lower()
    matches = []
    seen = set()
    for d in dirs:
        try:
            entries = os.listdir(d)
        except OSError:
            continue
        for e in entries:
            if not e.endswith(".md"):
                continue
            full = os.path.join(d, e)
            if full in seen or os.path.isdir(full):
                continue
            if lower in e.lower():
                seen.add(full)
                matches.append(full)

    if not matches:
        raise FileNotFoundError(f'req "{name}" nao encontrada em {req_dir}')
    if len(matches) > 1:
        raise ValueError(
            f'nome "{name}" e ambiguo — casa com {len(matches)} REQs: {", ".join(matches)}'
        )
    return matches[0]


def move_req(name: str, state: str, cfg: dict) -> str:
    """Move uma REQ para o diretorio de um estado, preservando o agente em
    by_agent, e sincroniza o status: do frontmatter e a linha humana.

    Ver REQ-2026-08-17-req-move.
    """
    if state not in REQ_STATES:
        raise ValueError(
            f'estado invalido "{state}" — validos: {", ".join(REQ_STATES)}'
        )

    src = find_req(name, cfg)
    req_dir = os.path.normpath(cfg["req_dir"])

    # O agente e a primeira pasta abaixo de req_dir, quando existe. Preserva-lo
    # evita que mover uma REQ a mude de dono.
    from_state = "—"
    rel = os.path.relpath(os.path.dirname(src), req_dir)
    if rel and rel != ".":
        parts = rel.replace("\\", "/").split("/")
        if len(parts) > 1:
            from_state = parts[1]
        target_dir = os.path.join(req_dir, parts[0], state)
    else:
        target_dir = os.path.join(req_dir, state)

    dst = os.path.join(target_dir, os.path.basename(src))
    if os.path.abspath(dst) == os.path.abspath(src):
        raise ValueError(f'req "{os.path.basename(src)}" ja esta em {state}')

    os.makedirs(target_dir, exist_ok=True)
    os.replace(src, dst)

    try:
        with open(dst, "r", encoding="utf-8", newline="") as f:
            content = f.read()
        updated = _set_header_status(_set_frontmatter_status(content, state), state)
        if updated != content:
            with open(dst, "w", encoding="utf-8", newline="") as f:
                f.write(updated)
    except OSError:
        pass

    _append_req_transition_log(os.path.basename(src), from_state, state, cfg)
    return dst


def _append_req_transition_log(basename: str, from_state: str, to_state: str, cfg: dict) -> None:
    """Grava em <req_dir>/.trackfw-log.

    Arquivo separado do log de roadmaps de proposito: `trackfw log` e
    `trackfw metrics` tratam cada linha daquele arquivo como transicao de roadmap,
    e misturar REQs distorceria lead time e throughput em silencio.
    """
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    line = f"{timestamp}  {basename:<50}  {from_state} → {to_state}\n"
    log_path = os.path.join(cfg["req_dir"], ".trackfw-log")
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line)
    except OSError:
        pass
