"""
Testes do sync de status: no frontmatter feito por move_roadmap.
Usa unittest (stdlib) — sem dependências externas.

Ver REQ-2026-08-16-roadmap-move-sincroniza-status.
"""

import os
import sys
import tempfile
import shutil
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from trackfw import config as cfg_module
from trackfw.generators.roadmap import move_roadmap


class TestMoveRoadmapStatus(unittest.TestCase):

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.cfg = dict(cfg_module.DEFAULTS) if hasattr(cfg_module, "DEFAULTS") else {}
        self.cfg["roadmap_dir"] = os.path.join(self.tmpdir, "docs", "roadmaps")
        self.cfg["roadmap_namespacing"] = "flat"
        os.makedirs(os.path.join(self.cfg["roadmap_dir"], "wip"), exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.tmpdir, ignore_errors=True)

    def _write(self, filename, content):
        path = os.path.join(self.cfg["roadmap_dir"], "wip", filename)
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        return path

    def _read(self, state, filename):
        path = os.path.join(self.cfg["roadmap_dir"], state, filename)
        with open(path, "r", encoding="utf-8", newline="") as f:
            return f.read()

    def test_sincroniza_status_do_frontmatter(self):
        src = "---\nname: x\nstatus: wip\ndate: 2026-08-16\n---\n\n# Roadmap: x\n\ncorpo\n"
        self._write("x.md", src)
        move_roadmap("x.md", "done", self.cfg)
        want = "---\nname: x\nstatus: done\ndate: 2026-08-16\n---\n\n# Roadmap: x\n\ncorpo\n"
        self.assertEqual(self._read("done", "x.md"), want)

    def test_sem_frontmatter_sai_identico(self):
        """A regex global anterior corromperia este arquivo, reescrevendo a
        linha 'status: pendente' do corpo."""
        src = "# Roadmap: y\n\n### ML-1\nstatus: pendente\n\ncorpo\n"
        self._write("y.md", src)
        move_roadmap("y.md", "done", self.cfg)
        self.assertEqual(self._read("done", "y.md"), src)

    def test_frontmatter_sem_status_nao_ganha_campo(self):
        src = "---\nname: z\ndate: 2026-08-16\n---\n\n# Roadmap: z\n"
        self._write("z.md", src)
        move_roadmap("z.md", "done", self.cfg)
        self.assertEqual(self._read("done", "z.md"), src)

    def test_status_no_corpo_nao_e_tocado(self):
        src = "---\nstatus: wip\n---\n\n# Roadmap: w\n\nstatus: isto e corpo\n"
        self._write("w.md", src)
        move_roadmap("w.md", "blocked", self.cfg)
        want = "---\nstatus: blocked\n---\n\n# Roadmap: w\n\nstatus: isto e corpo\n"
        self.assertEqual(self._read("blocked", "w.md"), want)

    def test_sincroniza_linha_humana(self):
        src = (
            "---\nstatus: wip\n---\n\n# Roadmap: h\n\n"
            "> Created: 2026-08-16 | Status: wip\n\ncorpo\n"
        )
        self._write("h.md", src)
        move_roadmap("h.md", "done", self.cfg)
        want = (
            "---\nstatus: done\n---\n\n# Roadmap: h\n\n"
            "> Created: 2026-08-16 | Status: done\n\ncorpo\n"
        )
        self.assertEqual(self._read("done", "h.md"), want)

    def test_linha_humana_com_emoji(self):
        """Formato herdado neste repositorio: o trecho inteiro apos o marcador
        e substituido, entao o emoji sai junto."""
        src = (
            "---\nstatus: wip\n---\n\n# Roadmap: e\n\n"
            "> Criado em: 2026-08-16 | Status: \U0001F504 WIP\n"
        )
        self._write("e.md", src)
        move_roadmap("e.md", "done", self.cfg)
        want = (
            "---\nstatus: done\n---\n\n# Roadmap: e\n\n"
            "> Criado em: 2026-08-16 | Status: done\n"
        )
        self.assertEqual(self._read("done", "e.md"), want)

    def test_sem_linha_humana_nao_cria(self):
        src = "---\nstatus: wip\n---\n\n# Roadmap: s\n\nsem linha de status aqui\n"
        self._write("s.md", src)
        move_roadmap("s.md", "done", self.cfg)
        want = "---\nstatus: done\n---\n\n# Roadmap: s\n\nsem linha de status aqui\n"
        self.assertEqual(self._read("done", "s.md"), want)


if __name__ == "__main__":
    unittest.main()
