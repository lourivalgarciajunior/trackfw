package generators

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kgsaran/trackfw/internal/config"
)

const reqSrc = "---\nid: REQ-x\nstatus: backlog\n---\n\n# REQ: x\n\n> Created: 2026-08-17 | Status: backlog\n\ncorpo\n"

// setupREQ prepara um repo temporário em by_agent e grava a REQ no subcaminho
// pedido, relativo a docs/req. Devolve a raiz.
func setupREQ(t *testing.T, subdir, filename, content string) string {
	t.Helper()
	dir := t.TempDir()
	chdirADR(t, dir)
	config.Reset()
	t.Cleanup(config.Reset)

	yaml := "req_dir: docs/req\nroadmap_dir: docs/roadmaps\nroadmap_namespacing: by_agent\nagents:\n  - claude\n"
	if err := os.WriteFile(filepath.Join(dir, "trackfw.yaml"), []byte(yaml), 0644); err != nil {
		t.Fatalf("write yaml: %v", err)
	}

	full := filepath.Join(dir, filepath.FromSlash(subdir))
	if err := os.MkdirAll(full, 0755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(full, filename), []byte(content), 0644); err != nil {
		t.Fatalf("write req: %v", err)
	}
	return dir
}

func readAt(t *testing.T, dir, rel string) string {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(dir, filepath.FromSlash(rel)))
	if err != nil {
		t.Fatalf("lendo %s: %v", rel, err)
	}
	return string(data)
}

// TestMoveREQ_DeSubpastaDeEstado — a forma que o validator já enxerga.
func TestMoveREQ_DeSubpastaDeEstado(t *testing.T) {
	dir := setupREQ(t, "docs/req/claude/backlog", "REQ-x.md", reqSrc)

	if err := MoveREQ("REQ-x", "done"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	got := readAt(t, dir, "docs/req/claude/done/REQ-x.md")
	if !strings.Contains(got, "status: done") {
		t.Errorf("frontmatter não sincronizado:\n%s", got)
	}
	if !strings.Contains(got, "| Status: done") {
		t.Errorf("linha humana não sincronizada:\n%s", got)
	}
	if _, err := os.Stat(filepath.Join(dir, "docs", "req", "claude", "backlog", "REQ-x.md")); !os.IsNotExist(err) {
		t.Error("origem deveria ter sumido")
	}
}

// TestMoveREQ_DeDentroDoAgenteSemEstado — a forma que o validator NÃO enxerga e
// que representa 31 das 36 REQs deste repositório. Era o caso que quebraria se o
// comando reusasse resolveREQFiles. Ver ADR-2026-08-17-req-move-resolve-as-tres-formas.
func TestMoveREQ_DeDentroDoAgenteSemEstado(t *testing.T) {
	dir := setupREQ(t, "docs/req/claude", "REQ-y.md", reqSrc)

	if err := MoveREQ("REQ-y", "abandoned"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	got := readAt(t, dir, "docs/req/claude/abandoned/REQ-y.md")
	if !strings.Contains(got, "status: abandoned") {
		t.Errorf("frontmatter não sincronizado:\n%s", got)
	}
}

// TestMoveREQ_DaRaizDoReqDir — forma flat.
func TestMoveREQ_DaRaizDoReqDir(t *testing.T) {
	dir := t.TempDir()
	chdirADR(t, dir)
	config.Reset()
	t.Cleanup(config.Reset)

	yaml := "req_dir: docs/req\nroadmap_dir: docs/roadmaps\n"
	if err := os.WriteFile(filepath.Join(dir, "trackfw.yaml"), []byte(yaml), 0644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(dir, "docs", "req"), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "docs", "req", "REQ-z.md"), []byte(reqSrc), 0644); err != nil {
		t.Fatal(err)
	}

	if err := MoveREQ("REQ-z", "wip"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	if !strings.Contains(readAt(t, dir, "docs/req/wip/REQ-z.md"), "status: wip") {
		t.Error("frontmatter não sincronizado")
	}
}

// TestMoveREQ_PreservaOAgente — mover não pode trocar o dono da REQ.
func TestMoveREQ_PreservaOAgente(t *testing.T) {
	dir := t.TempDir()
	chdirADR(t, dir)
	config.Reset()
	t.Cleanup(config.Reset)

	// claude é o primeiro agente; a REQ é da apolo.
	yaml := "req_dir: docs/req\nroadmap_dir: docs/roadmaps\nroadmap_namespacing: by_agent\nagents:\n  - claude\n  - apolo\n"
	if err := os.WriteFile(filepath.Join(dir, "trackfw.yaml"), []byte(yaml), 0644); err != nil {
		t.Fatal(err)
	}
	src := filepath.Join(dir, "docs", "req", "apolo", "done")
	if err := os.MkdirAll(src, 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(src, "REQ-w.md"), []byte(reqSrc), 0644); err != nil {
		t.Fatal(err)
	}

	if err := MoveREQ("REQ-w", "abandoned"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	if _, err := os.Stat(filepath.Join(dir, "docs", "req", "apolo", "abandoned", "REQ-w.md")); err != nil {
		t.Errorf("REQ deveria estar em apolo/abandoned: %v", err)
	}
	if _, err := os.Stat(filepath.Join(dir, "docs", "req", "claude", "abandoned", "REQ-w.md")); err == nil {
		t.Error("REQ foi parar no primeiro agente da lista — mudou de dono")
	}
}

// TestMoveREQ_SemFrontmatterNaoModifica — mesmo contrato do roadmap move.
func TestMoveREQ_SemFrontmatterNaoModifica(t *testing.T) {
	src := "# REQ: sem frontmatter\n\nstatus: isto é corpo\n"
	dir := setupREQ(t, "docs/req/claude", "REQ-s.md", src)

	if err := MoveREQ("REQ-s", "done"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	if got := readAt(t, dir, "docs/req/claude/done/REQ-s.md"); got != src {
		t.Errorf("arquivo sem frontmatter foi modificado:\n got: %q\nwant: %q", got, src)
	}
}

// TestMoveREQ_EstadoInvalido e _NaoEncontrada — erros claros, nada movido.
func TestMoveREQ_EstadoInvalido(t *testing.T) {
	setupREQ(t, "docs/req/claude", "REQ-x.md", reqSrc)

	err := MoveREQ("REQ-x", "arquivado")
	if err == nil {
		t.Fatal("esperado erro para estado inválido")
	}
	if !strings.Contains(err.Error(), "estado inválido") {
		t.Errorf("mensagem não orienta: %v", err)
	}
}

func TestMoveREQ_NaoEncontrada(t *testing.T) {
	setupREQ(t, "docs/req/claude", "REQ-x.md", reqSrc)

	if err := MoveREQ("REQ-inexistente", "done"); err == nil {
		t.Fatal("esperado erro para REQ inexistente")
	}
}

// TestMoveREQ_Ambigua — dois arquivos casando o nome param o comando.
func TestMoveREQ_Ambigua(t *testing.T) {
	dir := setupREQ(t, "docs/req/claude", "REQ-dup-a.md", reqSrc)
	if err := os.WriteFile(filepath.Join(dir, "docs", "req", "claude", "REQ-dup-b.md"), []byte(reqSrc), 0644); err != nil {
		t.Fatal(err)
	}

	err := MoveREQ("REQ-dup", "done")
	if err == nil {
		t.Fatal("esperado erro de ambiguidade")
	}
	if !strings.Contains(err.Error(), "ambíguo") {
		t.Errorf("mensagem não menciona ambiguidade: %v", err)
	}
}

// TestMoveREQ_RegistraNoLogDoReqDir — o log é o do req_dir, não o de roadmaps.
func TestMoveREQ_RegistraNoLogDoReqDir(t *testing.T) {
	dir := setupREQ(t, "docs/req/claude/backlog", "REQ-x.md", reqSrc)

	if err := MoveREQ("REQ-x", "done"); err != nil {
		t.Fatalf("MoveREQ: %v", err)
	}

	logged := readAt(t, dir, "docs/req/.trackfw-log")
	if !strings.Contains(logged, "REQ-x.md") || !strings.Contains(logged, "backlog → done") {
		t.Errorf("transição não registrada corretamente:\n%s", logged)
	}
	if _, err := os.Stat(filepath.Join(dir, "docs", "roadmaps", ".trackfw-log")); err == nil {
		t.Error("REQ não pode escrever no log de roadmaps — corromperia as métricas")
	}
}
