"""
reqs.py — resolve onde as REQs estão no disco.

Antes deste módulo havia três implementações com alcances diferentes:

    list de REQs        varria req_dir/*.md                     → 0 das 36 REQs
    resolve_req_files   varria req_dir/<agente>/<estado>/*.md    → 5
    find_req            varria as três formas                   → 36

O validate rodava sobre a segunda, e por isso nunca olhou 86% do corpus.
Ver REQ-2026-08-17-resolvedor-req-unificado.
"""

import os

# Os cinco estados que uma REQ pode ocupar.
STATES = ["backlog", "wip", "blocked", "done", "abandoned"]


def _dirs(cfg: dict) -> list:
    """Diretórios onde uma REQ pode estar, em ordem de busca, cada um com o
    agente e o estado que representa."""
    req_dir = cfg.get("req_dir")
    if not req_dir:
        return []

    out = []
    if cfg.get("roadmap_namespacing") == "by_agent":
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
            for state in STATES:
                out.append((os.path.join(req_dir, agent, state), agent, state))
            # REQ direto na pasta do agente, sem subpasta de estado. É a forma
            # que resolve_req_files ignorava, e a maioria dos casos reais.
            out.append((os.path.join(req_dir, agent), agent, ""))
    out.append((req_dir, "", ""))
    return out


def all_reqs(cfg: dict) -> list:
    """Todas as REQs encontradas, como lista de dicts {path, agent, state}.

    Ordem estável: agentes na ordem configurada, estados na ordem de STATES.
    """
    out = []
    seen = set()

    for d, agent, state in _dirs(cfg):
        try:
            entries = sorted(os.listdir(d))
        except OSError:
            continue
        for name in entries:
            if not name.endswith(".md"):
                continue
            full = os.path.join(d, name)
            if full in seen or os.path.isdir(full):
                continue
            seen.add(full)
            out.append({"path": full, "agent": agent, "state": state})
    return out


def files(cfg: dict) -> list:
    """Só os caminhos, para quem não precisa de agente nem estado."""
    return [e["path"] for e in all_reqs(cfg)]


def find(cfg: dict, name: str) -> dict:
    """Localiza uma REQ por nome, match parcial case-insensitive.

    Levanta FileNotFoundError se não achar e ValueError se for ambíguo.
    """
    lower = name.lower()
    matches = [e for e in all_reqs(cfg) if lower in os.path.basename(e["path"]).lower()]

    if not matches:
        raise FileNotFoundError(f'req "{name}" nao encontrada em {cfg.get("req_dir")}')
    if len(matches) > 1:
        paths = ", ".join(m["path"] for m in matches)
        raise ValueError(f'nome "{name}" e ambiguo — casa com {len(matches)} REQs: {paths}')
    return matches[0]
