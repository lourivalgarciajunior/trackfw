package reqs

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kgsaran/trackfw/internal/config"
)

// fixture monta um repo temporário e grava REQs nos subcaminhos pedidos,
// relativos à raiz. Devolve a config carregada de lá.
func fixture(t *testing.T, yaml string, paths ...string) config.ProjectConfig {
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

	if err := os.WriteFile(filepath.Join(dir, "trackfw.yaml"), []byte(yaml), 0644); err != nil {
		t.Fatalf("write yaml: %v", err)
	}
	for _, p := range paths {
		full := filepath.Join(dir, filepath.FromSlash(p))
		if err := os.MkdirAll(filepath.Dir(full), 0755); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		if err := os.WriteFile(full, []byte("---\nid: x\n---\n\n# REQ: x\n"), 0644); err != nil {
			t.Fatalf("write req: %v", err)
		}
	}

	config.Reset()
	t.Cleanup(config.Reset)
	return config.Load()
}

const yamlByAgent = "req_dir: docs/req\nroadmap_dir: docs/roadmaps\nroadmap_namespacing: by_agent\nagents:\n  - claude\n"

// TestAll_CobreAsTresFormas é o teste central deste pacote: antes dele o
// validator só enxergava a primeira forma, e por isso ignorava 31 das 36 REQs
// deste repositório. Ver REQ-2026-08-17-resolvedor-req-unificado.
func TestAll_CobreAsTresFormas(t *testing.T) {
	cfg := fixture(t, yamlByAgent,
		"docs/req/claude/backlog/REQ-com-estado.md",
		"docs/req/claude/REQ-sem-estado.md",
		"docs/req/REQ-na-raiz.md",
	)

	got := All(cfg)
	if len(got) != 3 {
		var names []string
		for _, e := range got {
			names = append(names, filepath.Base(e.Path))
		}
		t.Fatalf("esperado 3 REQs, obtido %d: %v", len(got), names)
	}

	byName := map[string]Entry{}
	for _, e := range got {
		byName[filepath.Base(e.Path)] = e
	}

	if e := byName["REQ-com-estado.md"]; e.Agent != "claude" || e.State != "backlog" {
		t.Errorf("com-estado: agent=%q state=%q, quer claude/backlog", e.Agent, e.State)
	}
	if e := byName["REQ-sem-estado.md"]; e.Agent != "claude" || e.State != "" {
		t.Errorf("sem-estado: agent=%q state=%q, quer claude e estado vazio", e.Agent, e.State)
	}
	if e := byName["REQ-na-raiz.md"]; e.Agent != "" || e.State != "" {
		t.Errorf("na-raiz: agent=%q state=%q, quer ambos vazios", e.Agent, e.State)
	}
}

// TestAll_NaoDuplica — a REQ na raiz não pode aparecer também como se fosse de
// um agente, nem vice-versa.
func TestAll_NaoDuplica(t *testing.T) {
	cfg := fixture(t, yamlByAgent,
		"docs/req/claude/REQ-a.md",
		"docs/req/REQ-b.md",
	)

	got := All(cfg)
	seen := map[string]int{}
	for _, e := range got {
		seen[e.Path]++
	}
	for p, n := range seen {
		if n > 1 {
			t.Errorf("%s apareceu %d vezes", p, n)
		}
	}
	if len(got) != 2 {
		t.Errorf("esperado 2 REQs, obtido %d", len(got))
	}
}

// TestAll_Flat — em modo flat só a raiz é varrida.
func TestAll_Flat(t *testing.T) {
	cfg := fixture(t, "req_dir: docs/req\nroadmap_dir: docs/roadmaps\n",
		"docs/req/REQ-a.md",
		"docs/req/claude/REQ-ignorada.md",
	)

	got := All(cfg)
	if len(got) != 1 || filepath.Base(got[0].Path) != "REQ-a.md" {
		t.Errorf("modo flat deveria ver só a raiz, obtido %v", got)
	}
}

// TestAll_AgentesInferidos — sem `agents:` no yaml, os subdiretórios viram agentes.
func TestAll_AgentesInferidos(t *testing.T) {
	cfg := fixture(t, "req_dir: docs/req\nroadmap_dir: docs/roadmaps\nroadmap_namespacing: by_agent\n",
		"docs/req/apolo/done/REQ-a.md",
		"docs/req/artemis/REQ-b.md",
	)

	if got := All(cfg); len(got) != 2 {
		t.Errorf("esperado 2 REQs com agentes inferidos, obtido %d", len(got))
	}
}

func TestFind_Encontra(t *testing.T) {
	cfg := fixture(t, yamlByAgent, "docs/req/claude/REQ-alvo.md")

	e, err := Find(cfg, "alvo")
	if err != nil {
		t.Fatalf("Find: %v", err)
	}
	if filepath.Base(e.Path) != "REQ-alvo.md" {
		t.Errorf("achou %q", e.Path)
	}
}

func TestFind_NaoEncontrada(t *testing.T) {
	cfg := fixture(t, yamlByAgent, "docs/req/claude/REQ-a.md")

	if _, err := Find(cfg, "inexistente"); err == nil {
		t.Fatal("esperado erro")
	}
}

func TestFind_Ambigua(t *testing.T) {
	cfg := fixture(t, yamlByAgent,
		"docs/req/claude/REQ-dup-a.md",
		"docs/req/claude/backlog/REQ-dup-b.md",
	)

	_, err := Find(cfg, "dup")
	if err == nil {
		t.Fatal("esperado erro de ambiguidade")
	}
	if !strings.Contains(err.Error(), "ambíguo") {
		t.Errorf("mensagem não menciona ambiguidade: %v", err)
	}
}
