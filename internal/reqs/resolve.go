// Package reqs resolve onde as REQs estão no disco.
//
// Existe como pacote próprio porque `internal/generators` já importa
// `internal/validator` (via context.go), então um resolvedor compartilhado não
// pode morar em nenhum dos dois sem criar ciclo. Este importa apenas
// `internal/config`.
//
// Antes dele havia três implementações com alcances diferentes:
//
//	ListREQs          varria reqDir/*.md                     → 0 das 36 REQs deste repo
//	resolveREQFiles   varria reqDir/<agente>/<estado>/*.md    → 5
//	findREQ           varria as três formas                   → 36
//
// O validate rodava sobre a segunda, e por isso nunca olhou 86% do corpus.
// Ver REQ-2026-08-17-resolvedor-req-unificado.
package reqs

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/kgsaran/trackfw/internal/config"
)

// States são os cinco estados que uma REQ pode ocupar.
var States = []string{"backlog", "wip", "blocked", "done", "abandoned"}

// Entry é uma REQ localizada, com a posição que ocupa.
type Entry struct {
	Path  string // caminho completo
	Agent string // "" em modo flat ou quando a REQ está na raiz
	State string // "" quando a REQ não está em subpasta de estado
}

// dirs devolve, em ordem de busca, os diretórios onde uma REQ pode estar,
// junto com o agente e o estado que cada um representa.
func dirs(cfg config.ProjectConfig) []Entry {
	reqDir := cfg.REQDir
	if reqDir == "" {
		return nil
	}

	var out []Entry
	if cfg.RoadmapNamespacing == config.NamespacingByAgent {
		agents := cfg.Agents
		if len(agents) == 0 {
			entries, err := os.ReadDir(reqDir)
			if err == nil {
				for _, e := range entries {
					if e.IsDir() {
						agents = append(agents, e.Name())
					}
				}
			}
		}
		for _, agent := range agents {
			for _, state := range States {
				out = append(out, Entry{Path: filepath.Join(reqDir, agent, state), Agent: agent, State: state})
			}
			// REQ direto na pasta do agente, sem subpasta de estado. É a forma
			// que resolveREQFiles ignorava, e a maioria dos casos reais.
			out = append(out, Entry{Path: filepath.Join(reqDir, agent), Agent: agent})
		}
	}
	out = append(out, Entry{Path: reqDir})
	return out
}

// All devolve todas as REQs encontradas, com agente e estado de cada uma.
// A ordem é estável: agentes na ordem configurada, estados na ordem de States,
// e dentro de cada diretório em ordem alfabética.
func All(cfg config.ProjectConfig) []Entry {
	var out []Entry
	seen := map[string]bool{}

	for _, d := range dirs(cfg) {
		entries, err := os.ReadDir(d.Path)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") {
				continue
			}
			full := filepath.Join(d.Path, e.Name())
			if seen[full] {
				continue
			}
			seen[full] = true
			out = append(out, Entry{Path: full, Agent: d.Agent, State: d.State})
		}
	}
	return out
}

// Files devolve só os caminhos, para quem não precisa de agente nem estado.
func Files(cfg config.ProjectConfig) []string {
	all := All(cfg)
	paths := make([]string, 0, len(all))
	for _, e := range all {
		paths = append(paths, e.Path)
	}
	return paths
}

// Find localiza uma REQ por nome, com match parcial case-insensitive.
// Erro quando não encontra ou quando o nome casa com mais de uma.
func Find(cfg config.ProjectConfig, name string) (Entry, error) {
	lower := strings.ToLower(name)
	var matches []Entry
	for _, e := range All(cfg) {
		if strings.Contains(strings.ToLower(filepath.Base(e.Path)), lower) {
			matches = append(matches, e)
		}
	}

	switch len(matches) {
	case 0:
		return Entry{}, fmt.Errorf("req %q não encontrada em %s", name, cfg.REQDir)
	case 1:
		return matches[0], nil
	default:
		paths := make([]string, 0, len(matches))
		for _, m := range matches {
			paths = append(paths, m.Path)
		}
		return Entry{}, fmt.Errorf("nome %q é ambíguo — casa com %d REQs: %s",
			name, len(matches), strings.Join(paths, ", "))
	}
}
