"""
Testes do `req list` no runtime Python.

Ver REQ-2026-08-17-req-list-python.
"""

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from trackfw.generators.req import parse_req_status

PYPI_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

YAML_BY_AGENT = (
    "req_dir: docs/req\n"
    "roadmap_dir: docs/roadmaps\n"
    "roadmap_namespacing: by_agent\n"
    "agents:\n"
    "  - claude\n"
)


class TestParseReqStatus(unittest.TestCase):
    """O frontmatter vence; o corpo nunca sobrescreve.

    As versões Go e Node.js desta função varriam o arquivo inteiro e deixavam
    qualquer tabela do corpo virar o status. Esta nasceu correta — o teste
    existe para que continue assim.
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _write(self, content):
        p = os.path.join(self.tmp, "REQ-x.md")
        with io.open(p, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        return p

    def test_frontmatter_vence(self):
        p = self._write(
            "---\nstatus: done\n---\n\n# REQ: x\n\n> Created: 2026-08-17 | Status: wip\n"
        )
        self.assertEqual(parse_req_status(p), "done")

    def test_cai_para_o_cabecalho_sem_frontmatter(self):
        p = self._write("# REQ: x\n\n> Created: 2026-08-17 | Status: wip\n")
        self.assertEqual(parse_req_status(p), "wip")

    def test_corpo_nao_sobrescreve(self):
        """Uma tabela mencionando '| Status: ' depois do primeiro '## ' é corpo."""
        p = self._write(
            "---\nstatus: approved\n---\n\n# REQ: x\n\n"
            "## Tabela\n\n| Runtime | Status: quebrado |\n"
        )
        self.assertEqual(parse_req_status(p), "approved")

    def test_corpo_nao_sobrescreve_sem_frontmatter(self):
        p = self._write(
            "# REQ: x\n\n> Created: 2026-08-17 | Status: backlog\n\n"
            "## Tabela\n\n> nota | Status: lixo\n"
        )
        self.assertEqual(parse_req_status(p), "backlog")

    def test_sem_nada_e_unknown(self):
        p = self._write("# REQ: x\n\ncorpo\n")
        self.assertEqual(parse_req_status(p), "unknown")


class TestReqListCLI(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _req(self, subdir, filename, content):
        full = os.path.join(self.tmp, *subdir.split("/"))
        os.makedirs(full, exist_ok=True)
        with io.open(os.path.join(full, filename), "w", encoding="utf-8", newline="") as f:
            f.write(content)

    def _yaml(self, text=YAML_BY_AGENT):
        with io.open(os.path.join(self.tmp, "trackfw.yaml"), "w", encoding="utf-8", newline="") as f:
            f.write(text)

    def _run(self):
        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        return subprocess.run(
            [sys.executable, "-m", "trackfw", "req", "list"],
            cwd=self.tmp, env=env, capture_output=True, text=True,
        )

    def test_agrupa_por_agente_e_estado(self):
        self._yaml()
        self._req("docs/req/claude/backlog", "REQ-a.md", "---\nstatus: backlog\n---\n\n# REQ: a\n")
        self._req("docs/req/claude", "REQ-b.md", "---\nstatus: approved\n---\n\n# REQ: b\n")

        r = self._run()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("[claude/backlog]", r.stdout)
        self.assertIn("[claude]", r.stdout)
        self.assertIn("REQ-a.md", r.stdout)
        self.assertIn("REQ-b.md", r.stdout)
        self.assertIn("backlog", r.stdout)
        self.assertIn("approved", r.stdout)

    def test_sem_reqs(self):
        self._yaml()
        os.makedirs(os.path.join(self.tmp, "docs", "req"), exist_ok=True)

        r = self._run()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("No REQs found in docs/req", r.stdout)

    def test_saida_usa_lf_e_nao_crlf(self):
        """Go e Node.js emitem LF. Sem isto as três saídas divergem byte a byte,
        o que quebra diff, pipe e comparação de paridade."""
        self._yaml()
        self._req("docs/req/claude", "REQ-a.md", "---\nstatus: approved\n---\n\n# REQ: a\n")

        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        r = subprocess.run(
            [sys.executable, "-m", "trackfw", "req", "list"],
            cwd=self.tmp, env=env, capture_output=True,
        )
        self.assertEqual(r.returncode, 0, r.stderr.decode("utf-8", "replace"))
        self.assertNotIn(b"\r\n", r.stdout, "saída do CLI Python não pode usar CRLF")


if __name__ == "__main__":
    unittest.main()
