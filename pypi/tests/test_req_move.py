"""
Testes do contrato de `req move` no runtime Python.

Rodam o CLI por subprocesso para cobrir flags, exit code e conteúdo gerado, em
vez de só o generator.

Ver REQ-2026-08-17-req-move.
"""

import os
import shutil
import subprocess
import sys
import tempfile
import unittest

PYPI_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

REQ_SRC = (
    "---\n"
    "id: REQ-x\n"
    "status: backlog\n"
    "---\n"
    "\n"
    "# REQ: x\n"
    "\n"
    "> Created: 2026-08-17 | Status: backlog\n"
    "\n"
    "corpo\n"
)

YAML_BY_AGENT = (
    "req_dir: docs/req\n"
    "roadmap_dir: docs/roadmaps\n"
    "roadmap_namespacing: by_agent\n"
    "agents:\n"
    "  - claude\n"
)


class TestReqMove(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _fixture(self, subdir, filename, content=REQ_SRC, yaml=YAML_BY_AGENT):
        with open(os.path.join(self.tmp, "trackfw.yaml"), "w", encoding="utf-8") as f:
            f.write(yaml)
        full = os.path.join(self.tmp, *subdir.split("/"))
        os.makedirs(full, exist_ok=True)
        with open(os.path.join(full, filename), "w", encoding="utf-8", newline="") as f:
            f.write(content)

    def _run(self, *args):
        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        return subprocess.run(
            [sys.executable, "-m", "trackfw", "req", "move", *args],
            cwd=self.tmp, env=env, capture_output=True, text=True,
        )

    def _read(self, rel):
        with open(os.path.join(self.tmp, *rel.split("/")), encoding="utf-8", newline="") as f:
            return f.read()

    def _exists(self, rel):
        return os.path.exists(os.path.join(self.tmp, *rel.split("/")))

    def test_move_de_subpasta_de_estado(self):
        self._fixture("docs/req/claude/backlog", "REQ-x.md")
        r = self._run("REQ-x", "done")
        self.assertEqual(r.returncode, 0, r.stderr)
        got = self._read("docs/req/claude/done/REQ-x.md")
        self.assertIn("status: done", got)
        self.assertIn("| Status: done", got)
        self.assertFalse(self._exists("docs/req/claude/backlog/REQ-x.md"))

    def test_move_de_dentro_do_agente_sem_estado(self):
        """Forma que o validator não enxerga e que é a maioria das REQs reais."""
        self._fixture("docs/req/claude", "REQ-y.md")
        r = self._run("REQ-y", "abandoned")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("status: abandoned", self._read("docs/req/claude/abandoned/REQ-y.md"))

    def test_move_da_raiz_em_modo_flat(self):
        self._fixture("docs/req", "REQ-z.md",
                      yaml="req_dir: docs/req\nroadmap_dir: docs/roadmaps\n")
        r = self._run("REQ-z", "wip")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("status: wip", self._read("docs/req/wip/REQ-z.md"))

    def test_preserva_o_agente_de_origem(self):
        yaml = YAML_BY_AGENT.replace("  - claude\n", "  - claude\n  - apolo\n")
        self._fixture("docs/req/apolo/done", "REQ-w.md", yaml=yaml)
        r = self._run("REQ-w", "abandoned")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(self._exists("docs/req/apolo/abandoned/REQ-w.md"))
        self.assertFalse(self._exists("docs/req/claude/abandoned/REQ-w.md"),
                         "REQ mudou de dono")

    def test_sem_frontmatter_sai_identico(self):
        src = "# REQ: sem frontmatter\n\nstatus: isto e corpo\n"
        self._fixture("docs/req/claude", "REQ-s.md", content=src)
        r = self._run("REQ-s", "done")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self._read("docs/req/claude/done/REQ-s.md"), src)

    def test_estado_invalido(self):
        self._fixture("docs/req/claude", "REQ-x.md")
        r = self._run("REQ-x", "arquivado")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("estado inv", r.stderr)

    def test_nome_ambiguo(self):
        self._fixture("docs/req/claude", "REQ-dup-a.md")
        with open(os.path.join(self.tmp, "docs", "req", "claude", "REQ-dup-b.md"),
                  "w", encoding="utf-8") as f:
            f.write(REQ_SRC)
        r = self._run("REQ-dup", "done")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("ambiguo", r.stderr)

    def test_registra_no_log_do_req_dir(self):
        self._fixture("docs/req/claude/backlog", "REQ-x.md")
        r = self._run("REQ-x", "done")
        self.assertEqual(r.returncode, 0, r.stderr)
        logged = self._read("docs/req/.trackfw-log")
        self.assertIn("REQ-x.md", logged)
        self.assertIn("backlog", logged)
        self.assertFalse(self._exists("docs/roadmaps/.trackfw-log"),
                         "não pode escrever no log de roadmaps")


if __name__ == "__main__":
    unittest.main()
