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
from trackfw import reqs as _reqs
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


def find_req(name: str, cfg: dict) -> str:
    """Delega ao modulo reqs. Mantida para nao mexer nos chamadores; a logica de
    caminho vive num lugar so."""
    return _reqs.find(cfg, name)["path"]


def move_req(name: str, state: str, cfg: dict) -> str:
    """Move uma REQ para o diretorio de um estado, preservando o agente em
    by_agent, e sincroniza o status: do frontmatter e a linha humana.

    Ver REQ-2026-08-17-req-move.
    """
    if state not in _reqs.STATES:
        raise ValueError(
            f'estado invalido "{state}" — validos: {", ".join(_reqs.STATES)}'
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


def parse_req_status(path: str) -> str:
    """Extrai o status de uma REQ.

    O frontmatter e a fonte preferida. Na ausencia dele, cai para a linha humana
    de cabecalho, parando no primeiro "## " — dai em diante e corpo.

    As versoes Go e Node.js desta funcao varriam o arquivo inteiro atras de
    "| Status: " e deixavam qualquer tabela do corpo sobrescrever o valor; foram
    corrigidas em REQ-2026-08-17-resolvedor-req-unificado. Esta nasce ja correta.
    """
    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return "unknown"

    lines = content.split("\n")

    # 1) Frontmatter.
    if lines and lines[0].rstrip("\r") == "---":
        for line in lines[1:]:
            line = line.rstrip("\r")
            if line == "---":
                break
            idx = line.find(":")
            if idx > 0 and line[:idx].strip() == "status":
                val = line[idx + 1:].strip().strip("\"'")
                if val:
                    return val
                break

    # 2) Linha humana de cabecalho.
    for raw in lines:
        line = raw.rstrip("\r")
        if line.startswith("## "):
            break
        if not line.startswith("> "):
            continue
        idx = line.find("| Status: ")
        if idx < 0:
            continue
        rest = line[idx + len("| Status: "):]
        pipe = rest.find(" |")
        if pipe >= 0:
            rest = rest[:pipe]
        rest = rest.rstrip(" >|").strip()
        if rest:
            return rest

    return "unknown"


def list_reqs(cfg: dict) -> None:
    """Lista todas as REQs, agrupadas por agente e estado em modo by_agent.

    Usa o resolvedor unificado — mesmo alcance do validate e do move.
    Ver REQ-2026-08-17-req-list-python.
    """
    entries = _reqs.all_reqs(cfg)

    if not entries:
        print(f'No REQs found in {cfg.get("req_dir")}')
        return

    last_group = ""
    for e in entries:
        agent, state = e["agent"], e["state"]
        if agent and state:
            group = f"{agent}/{state}"
        elif agent:
            group = agent
        else:
            group = ""

        if group != last_group:
            if group:
                print(f"\n[{group}]")
            last_group = group

        filename = os.path.basename(e["path"])
        status = parse_req_status(e["path"])
        print(f"{filename:<60} {status}")
