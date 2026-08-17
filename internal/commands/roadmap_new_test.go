package commands

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kgsaran/trackfw/internal/config"
)

// chdirTmp muda para um tempdir e restaura ao fim do teste.
func chdirTmp(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	orig, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	if err := os.Chdir(dir); err != nil {
		t.Fatalf("chdir: %v", err)
	}
	t.Cleanup(func() { _ = os.Chdir(orig) })
	config.Reset()
	t.Cleanup(config.Reset)
	return dir
}

func backlogFiles(t *testing.T, dir string) []string {
	t.Helper()
	entries, err := os.ReadDir(filepath.Join(dir, "docs", "roadmaps", "backlog"))
	if err != nil {
		return nil
	}
	var out []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".md") {
			out = append(out, e.Name())
		}
	}
	return out
}

// TestRoadmapNew_SemREQCriaEAvisa cobre o bug em que o comando imprimia uma
// mensagem e fazia `return nil` — exit 0 sem criar nada, reportando sucesso a
// quem confia no código de saída.
// Ver REQ-2026-08-16-roadmap-new-paridade-contrato.
func TestRoadmapNew_SemREQCriaEAvisa(t *testing.T) {
	dir := chdirTmp(t)

	cmd := newRoadmapNewCmd()
	cmd.SetArgs([]string{"--title", "Feature Sem Req"})
	cmd.SetOut(os.Stderr)
	if err := cmd.Execute(); err != nil {
		t.Fatalf("Execute() erro: %v", err)
	}

	files := backlogFiles(t, dir)
	if len(files) != 1 {
		t.Fatalf("esperado 1 roadmap em backlog/, obtido %v", files)
	}
	if !strings.Contains(files[0], "feature-sem-req") {
		t.Errorf("nome inesperado: %s", files[0])
	}
}

// TestRoadmapNew_ComREQGravaOLink — o caminho com --req continua linkando.
func TestRoadmapNew_ComREQGravaOLink(t *testing.T) {
	dir := chdirTmp(t)

	reqDir := filepath.Join(dir, "docs", "req")
	if err := os.MkdirAll(reqDir, 0755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	reqPath := filepath.Join(reqDir, "REQ-x.md")
	if err := os.WriteFile(reqPath, []byte("# REQ: x\n"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	cmd := newRoadmapNewCmd()
	cmd.SetArgs([]string{"--title", "Com Req", "--req", "docs/req/REQ-x.md"})
	cmd.SetOut(os.Stderr)
	if err := cmd.Execute(); err != nil {
		t.Fatalf("Execute() erro: %v", err)
	}

	files := backlogFiles(t, dir)
	if len(files) != 1 {
		t.Fatalf("esperado 1 roadmap, obtido %v", files)
	}
	content, err := os.ReadFile(filepath.Join(dir, "docs", "roadmaps", "backlog", files[0]))
	if err != nil {
		t.Fatalf("lendo roadmap: %v", err)
	}
	if !strings.Contains(string(content), "REQ: docs/req/REQ-x.md") {
		t.Errorf("link da REQ ausente no roadmap:\n%s", content)
	}
}

// TestRoadmapNew_SemTituloESemREQFalha — sem nada de onde derivar um título, o
// comando precisa falhar de verdade, não criar um roadmap sem nome.
func TestRoadmapNew_SemTituloESemREQFalha(t *testing.T) {
	dir := chdirTmp(t)

	cmd := newRoadmapNewCmd()
	cmd.SetArgs([]string{})
	cmd.SetOut(os.Stderr)
	cmd.SilenceUsage = true
	cmd.SilenceErrors = true
	if err := cmd.Execute(); err == nil {
		t.Fatal("esperado erro quando não há título nem REQ")
	}

	if files := backlogFiles(t, dir); len(files) != 0 {
		t.Errorf("nenhum roadmap deveria ter sido criado, obtido %v", files)
	}
}
