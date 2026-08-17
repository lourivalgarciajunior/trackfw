"""
generators/adr.py — geração de ADR sequencial com numeração automática.
Espelha npm/src/generators/adr.js em Python puro (stdlib apenas).
"""

import os
import re
import unicodedata
from datetime import date


def next_adr_number(adr_dir: str) -> int:
    """
    Escaneia adr_dir por arquivos ADR-NNN-*.md e retorna max(NNN)+1.
    Retorna 1 se o diretório estiver vazio ou não existir.
    """
    if not os.path.isdir(adr_dir):
        return 1

    pattern = re.compile(r'^ADR-(\d+)-.*\.md$', re.IGNORECASE)
    max_num = 0

    for entry in os.listdir(adr_dir):
        m = pattern.match(entry)
        if m:
            num = int(m.group(1))
            if num > max_num:
                max_num = num

    return max_num + 1


def slugify(title: str) -> str:
    """
    Converte título em slug: lowercase, acentos removidos via NFKD,
    espaços → hifens, remove chars não-alfanuméricos exceto hífen.
    """
    # Normaliza para NFKD e descarta caracteres não-ASCII
    normalized = unicodedata.normalize('NFKD', title)
    ascii_str = normalized.encode('ascii', 'ignore').decode('ascii')

    # Lowercase e espaços → hifens
    slug = ascii_str.lower().replace(' ', '-')

    # Remove chars não-alfanuméricos exceto hífen
    slug = re.sub(r'[^a-z0-9-]', '', slug)

    # Colapsa hifens múltiplos
    slug = re.sub(r'-+', '-', slug)

    return slug.strip('-')


def _today() -> str:
    return date.today().isoformat()


def generate_adr(
    title: str,
    status: str = 'Draft',
    adr_dirs: list = None,
    cwd: str = None,
) -> str:
    """
    Gera arquivo ADR no primeiro diretório de adr_dirs (ou 'docs/adr' como default).
    Cria o diretório se não existir.
    Retorna o path absoluto do arquivo criado.
    """
    base = cwd or os.getcwd()

    if adr_dirs and len(adr_dirs) > 0:
        adr_dir = adr_dirs[0]
    else:
        adr_dir = 'docs/adr'

    # Tornar absoluto se relativo
    if not os.path.isabs(adr_dir):
        adr_dir = os.path.join(base, adr_dir)

    os.makedirs(adr_dir, exist_ok=True)

    num = next_adr_number(adr_dir)
    slug = slugify(title)
    num_str = str(num).zfill(3)
    name = f'ADR-{num_str}-{slug}'
    filename = f'{name}.md'
    filepath = os.path.join(adr_dir, filename)
    today = _today()

    body = f"""---
name: {name}
title: "{title}"
status: {status}
created: {today}
---

# ADR-{num_str}: {title}

## Status
{status}

## Context
<!-- Descreva o contexto e o problema que motivou esta decisão -->

## Decision
<!-- Descreva a decisão tomada -->

## Consequences
<!-- Descreva as consequências desta decisão -->
"""

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(body)

    return filepath


def parse_adr_status(path: str) -> str:
    """Extrai o status de uma ADR.

    O frontmatter e a fonte canonica — e o campo que o `adr new` grava e que o
    validator usa. Na ausencia dele, cai para a linha humana de cabecalho,
    parando no primeiro "## ".

    As versoes Go e Node.js discordavam entre si antes de
    REQ-2026-08-17-adr-list-python: o Go pegava a ultima ocorrencia de
    "| Status: " em qualquer lugar do arquivo, o npm pegava a primeira, e nenhum
    lia o frontmatter. Esta nasce ja com o contrato alinhado.
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


def list_adrs(adr_dir: str) -> None:
    """Lista as ADRs de adr_dir, com nome e status.

    Glob plano no diretorio recebido, igual ao Go e ao Node.js — os tres
    consomem apenas o PRIMEIRO adr_dirs, sem recursao, enquanto o validator
    percorre todos recursivamente. Limitacao herdada de proposito e registrada em
    REQ-2026-08-17-adr-list-python; unificar o resolvedor de ADR e trabalho
    proprio.
    """
    try:
        names = sorted(
            n for n in os.listdir(adr_dir)
            if n.endswith(".md") and os.path.isfile(os.path.join(adr_dir, n))
        )
    except OSError:
        names = []

    if not names:
        print(f"No ADRs found in {adr_dir}")
        return

    for name in names:
        status = parse_adr_status(os.path.join(adr_dir, name))
        print(f"{name:<60} {status}")
