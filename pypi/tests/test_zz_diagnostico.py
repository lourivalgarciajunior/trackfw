"""DIAGNOSTICO TEMPORARIO — nao faz parte da suite. Remover depois de ler o log.

Reproduz a chamada que as 8 falhas fazem e imprime o estado que decide se
validate_agent_namespace_undeclared dispara (a unica regra do validator.py que
devolve string em vez de dict, e portanto a unica que explica o
`TypeError: string indices must be integers` no helper _messages dos testes).

Nome com zz para rodar no fim, vendo a contaminacao maxima da $HOME de sessao.
"""

import os
import tempfile

from trackfw import config, validator


def test_zz_diagnostico_do_typeerror():
    tmp = tempfile.mkdtemp()
    os.makedirs(os.path.join(tmp, "scripts"), exist_ok=True)
    with open(os.path.join(tmp, "scripts", "trackfw-credential-guard.sh"), "w") as fh:
        fh.write("#!/usr/bin/env bash" + chr(10) + "exit 0" + chr(10))

    config.reset()
    cfg = config.load(tmp)
    resultado = validator.validate_unfiltered(tmp)

    linhas = []
    linhas.append("HOME                 = %r" % os.environ.get("HOME"))
    linhas.append("expanduser(~)        = %r" % os.path.expanduser("~"))
    linhas.append("cwd                  = %r" % os.getcwd())
    linhas.append("cfg roadmap_namespacing = %r" % cfg.get("roadmap_namespacing"))
    linhas.append("cfg agents           = %r" % cfg.get("agents"))
    linhas.append("cfg roadmap_dir      = %r" % cfg.get("roadmap_dir"))
    linhas.append("cfg req_dir          = %r" % cfg.get("req_dir"))
    glob_cfg = os.path.join(os.path.expanduser("~"), ".trackfw", "trackfw.yaml")
    linhas.append("global trackfw.yaml existe = %r" % os.path.exists(glob_cfg))
    if os.path.exists(glob_cfg):
        with open(glob_cfg, encoding="utf-8") as fh:
            linhas.append("global trackfw.yaml:" + chr(10) + fh.read()[:400])
    for chave in ("violations", "warnings"):
        itens = resultado[chave]
        strs = [x for x in itens if not isinstance(x, dict)]
        linhas.append("%s total=%d strings=%d" % (chave, len(itens), len(strs)))
        for x in strs[:5]:
            linhas.append("   STRING: %r" % (x,))
    saida = chr(10).join(linhas)
    print(chr(10) + "===== DIAGNOSTICO =====" + chr(10) + saida + chr(10) + "===== FIM =====")
    # falha de proposito: pytest so mostra a saida de teste que falha,
    # e o objetivo deste arquivo temporario e LER o diagnostico no log da CI.
    assert False, saida
