"""
Testes do contrato de `roadmap new` no runtime Python.

Rodam o CLI por subprocesso para cobrir o contrato de verdade — flags, exit code
e conteúdo gerado — em vez de só o generator.

Ver REQ-2026-08-16-roadmap-new-paridade-contrato.
"""

import os
import shutil
import subprocess
import sys
import tempfile
import unittest

PYPI_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

REQ_CONTENT = (
    "# REQ: Minha Feature\n"
    "\n"
    "## Critérios de Aceite\n"
    "\n"
    "- [ ] critério um\n"
    "- [ ] critério dois\n"
)


class TestRoadmapNewContrato(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        with open(os.path.join(self.tmp, "trackfw.yaml"), "w", encoding="utf-8") as f:
            f.write("roadmap_namespacing: flat\n")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _write_req(self):
        req_dir = os.path.join(self.tmp, "docs", "req")
        os.makedirs(req_dir, exist_ok=True)
        path = os.path.join(req_dir, "REQ-x.md")
        with open(path, "w", encoding="utf-8") as f:
            f.write(REQ_CONTENT)
        return "docs/req/REQ-x.md"

    def _run(self, *args):
        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        return subprocess.run(
            [sys.executable, "-m", "trackfw", "roadmap", "new", *args],
            cwd=self.tmp, env=env, capture_output=True, text=True,
        )

    def _backlog(self):
        d = os.path.join(self.tmp, "docs", "roadmaps", "backlog")
        try:
            return sorted(f for f in os.listdir(d) if f.endswith(".md"))
        except OSError:
            return []

    def _read(self, name):
        with open(os.path.join(self.tmp, "docs", "roadmaps", "backlog", name),
                  encoding="utf-8") as f:
            return f.read()

    def test_sem_req_cria_e_avisa(self):
        r = self._run("--title", "Feature Sem Req")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("aviso: nenhuma REQ linkada", r.stderr)
        self.assertIn("wip_has_req", r.stderr)
        files = self._backlog()
        self.assertEqual(len(files), 1, files)
        self.assertIn("feature-sem-req", files[0])

    def test_titulo_posicional_continua_aceito(self):
        """Retrocompatibilidade: era a única forma antes desta REQ."""
        r = self._run("Titulo", "Posicional")
        self.assertEqual(r.returncode, 0, r.stderr)
        files = self._backlog()
        self.assertEqual(len(files), 1, files)
        self.assertIn("titulo-posicional", files[0])

    def test_com_req_grava_o_link(self):
        req = self._write_req()
        r = self._run("--title", "Com Req", "--req", req)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn("aviso: nenhuma REQ", r.stderr)
        files = self._backlog()
        self.assertEqual(len(files), 1, files)
        self.assertIn(f"REQ: {req}", self._read(files[0]))

    def test_from_req_gera_mls_dos_criterios(self):
        req = self._write_req()
        r = self._run("--from-req", req)
        self.assertEqual(r.returncode, 0, r.stderr)
        files = self._backlog()
        self.assertEqual(len(files), 1, files)
        content = self._read(files[0])
        self.assertIn("# Roadmap: Minha Feature", content)
        self.assertIn(f"REQ: {req}", content)
        self.assertIn("### ML-1A — critério um", content)
        self.assertIn("### ML-1B — critério dois", content)

    def test_sem_titulo_e_sem_req_falha(self):
        r = self._run()
        self.assertNotEqual(r.returncode, 0, "deveria falhar")
        self.assertIn("--title", r.stderr)
        self.assertEqual(self._backlog(), [])


if __name__ == "__main__":
    unittest.main()
