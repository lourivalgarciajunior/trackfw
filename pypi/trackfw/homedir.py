"""Resolve o diretório home do usuário de forma consistente entre plataformas.

DIVERGÊNCIA LOCAL — não existe no upstream. Espelha internal/homedir/homedir.go
(Go) e npm/src/homedir.js (Node). Ver
REQ-2026-08-29-node-e-python-ignoram-home-no-windows.

Por que existe: os.path.expanduser("~") lê $HOME no Linux e no macOS, mas
%USERPROFILE% no Windows. Teste e gate isolam a home com HOME=<tempdir>, o que no
Windows não isola nada — o processo continua lendo e escrevendo a home real do
desenvolvedor.

home_dir() faz o Windows se comportar como as outras plataformas: $HOME primeiro,
expanduser("~") como fallback. Onde $HOME não está definido, nada muda.

A string vazia NÃO conta como definida: HOME="" resolveria para "" e todo caminho
derivado viraria relativo em silêncio.

São duas famílias, e as duas importam:
  home_dir()      "me dê a home"
  expand_path(p)  "expanda o ~ deste caminho" — usado em adr_dirs do trackfw.yaml,
                  que também resolvia pelo USERPROFILE antes desta correção.
"""

import os


def home_dir() -> str:
    """Diretório home do usuário, preferindo $HOME quando definido e não vazio."""
    from_env = os.environ.get("HOME")
    if from_env:
        return from_env
    return os.path.expanduser("~")


def expand_path(path):
    """Expande um `~` inicial usando home_dir(). Espelha config.ExpandPath (Go).

    Devolve o valor intacto quando não começa com `~`, ou quando não é string.
    """
    if not path or not isinstance(path, str):
        return path
    if path == "~":
        return home_dir()
    if path.startswith("~/") or path.startswith("~" + chr(92)):
        return os.path.join(home_dir(), path[2:])
    return path
