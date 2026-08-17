"""
Testes do `adr list` no runtime Python.

Ver REQ-2026-08-17-adr-list-python.
"""

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from trackfw.generators.adr import parse_adr_status

PYPI_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


class TestParseAdrStatus(unittest.TestCase):
    """O frontmatter vence; o corpo nunca decide.

    Antes desta REQ, Go pegava a última ocorrência de "| Status: " em qualquer
    lugar do arquivo e npm pegava a primeira — os dois davam respostas
    diferentes para a mesma ADR. Estes testes travam o contrato alinhado.
    """

    def setUp(self):
        self.tmp = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _write(self, content):
        p = os.path.join(self.tmp, "ADR-x.md")
        with io.open(p, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        return p

    def test_frontmatter_vence(self):
        p = self._write(
            "---\nstatus: Accepted\n---\n\n# ADR: x\n\n> Date: 2026-08-17 | Status: Proposed\n"
        )
        self.assertEqual(parse_adr_status(p), "Accepted")

    def test_cai_para_o_cabecalho_sem_frontmatter(self):
        p = self._write("# ADR: x\n\n> Date: 2026-08-17 | Status: Proposed\n")
        self.assertEqual(parse_adr_status(p), "Proposed")

    def test_tabela_no_corpo_nao_decide(self):
        """Este é o caso que distinguia Go de npm."""
        p = self._write(
            "---\nstatus: Accepted\n---\n\n# ADR: x\n\n"
            "> Date: 2026-08-17 | Status: Accepted\n\n"
            "## Tabela\n\n| Runtime | Status: quebrado |\n"
        )
        self.assertEqual(parse_adr_status(p), "Accepted")

    def test_tabela_no_corpo_sem_frontmatter(self):
        p = self._write(
            "# ADR: x\n\n> Date: 2026-08-17 | Status: Draft\n\n"
            "## Tabela\n\n| Runtime | Status: quebrado |\n"
        )
        self.assertEqual(parse_adr_status(p), "Draft")

    def test_sem_nada_e_unknown(self):
        p = self._write("# ADR: x\n\ncorpo\n")
        self.assertEqual(parse_adr_status(p), "unknown")


class TestAdrListCLI(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        with io.open(os.path.join(self.tmp, "trackfw.yaml"), "w",
                     encoding="utf-8", newline="") as f:
            f.write("adr_dirs:\n  - docs/adr\n")
        os.makedirs(os.path.join(self.tmp, "docs", "adr"), exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _adr(self, filename, content):
        with io.open(os.path.join(self.tmp, "docs", "adr", filename), "w",
                     encoding="utf-8", newline="") as f:
            f.write(content)

    def _run(self):
        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        return subprocess.run(
            [sys.executable, "-m", "trackfw", "adr", "list"],
            cwd=self.tmp, env=env, capture_output=True, text=True,
        )

    def test_lista_com_status(self):
        self._adr("ADR-a.md", "---\nstatus: Accepted\n---\n\n# ADR: a\n")
        self._adr("ADR-b.md", "---\nstatus: Proposed\n---\n\n# ADR: b\n")

        r = self._run()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("ADR-a.md", r.stdout)
        self.assertIn("Accepted", r.stdout)
        self.assertIn("ADR-b.md", r.stdout)
        self.assertIn("Proposed", r.stdout)

    def test_diretorio_vazio(self):
        r = self._run()
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("No ADRs found in docs/adr", r.stdout)

    def test_saida_usa_lf(self):
        self._adr("ADR-a.md", "---\nstatus: Accepted\n---\n\n# ADR: a\n")

        env = dict(os.environ)
        env["PYTHONPATH"] = PYPI_ROOT
        env["PYTHONUTF8"] = "1"
        r = subprocess.run(
            [sys.executable, "-m", "trackfw", "adr", "list"],
            cwd=self.tmp, env=env, capture_output=True,
        )
        self.assertEqual(r.returncode, 0, r.stderr.decode("utf-8", "replace"))
        self.assertNotIn(b"\r\n", r.stdout)


if __name__ == "__main__":
    unittest.main()
