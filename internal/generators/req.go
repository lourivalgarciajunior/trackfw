package generators

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/kgsaran/trackfw/internal/config"
)

// REQContent contém os campos de uma REQ a ser gerada.
type REQContent struct {
	Title         string
	Motivation    string
	Criteria      string
	LinkedADR     string
	LinkedRoadmap string
	DependsOnADRs []string // basenames de ADRs Draft vinculados
}

// NewREQ gera um arquivo REQ em docs/req/ com base no conteúdo fornecido.
// Campos preenchidos são inseridos diretamente; campos vazios mantêm o placeholder original.
func NewREQ(content REQContent) error {
	cfg := config.Load()
	reqDir := cfg.REQDir
	if err := os.MkdirAll(reqDir, 0755); err != nil {
		return err
	}

	slug := toSlug(content.Title)
	date := time.Now().Format("2006-01-02")
	filename := fmt.Sprintf("%s/REQ-%s-%s.md", reqDir, date, slug)

	motivationSection := "<!-- Why is this requirement needed? What problem does it solve? -->"
	if content.Motivation != "" {
		motivationSection = content.Motivation
	}

	criteriaSection := "- [ ]\n- [ ]"
	if content.Criteria != "" {
		criteriaSection = content.Criteria
	}

	linkedADRSection := ""
	if content.LinkedADR != "" {
		linkedADRSection = content.LinkedADR
	}

	linkedRoadmapSection := ""
	if content.LinkedRoadmap != "" {
		linkedRoadmapSection = content.LinkedRoadmap
	}

	// Linha de status — inclui contador de ADRs bloqueantes quando presente
	statusLine := fmt.Sprintf("> Date: %s | Status: Open\n| Linear Issue: \n| Jira Issue: ", date)
	if len(content.DependsOnADRs) > 0 {
		statusLine = fmt.Sprintf("> Date: %s | Status: Open | Blocked by ADRs: %d\n| Linear Issue: \n| Jira Issue: ", date, len(content.DependsOnADRs))
	}

	// Seção "Blocked by ADRs"
	var blockedSection string
	if len(content.DependsOnADRs) == 0 {
		blockedSection = "<!-- none -->"
	} else {
		var sb strings.Builder
		sb.WriteString("<!-- ADRs in Draft status that must be Accepted before a roadmap can be created -->")
		for _, adr := range content.DependsOnADRs {
			sb.WriteString("\n- ")
			sb.WriteString(adr)
			sb.WriteString(" (Draft)")
		}
		blockedSection = sb.String()
	}

	body := fmt.Sprintf(`---
status: Open
date: %s
author: ""
adr: ""
roadmap: ""
---

# REQ: %s

%s

## Motivation
%s

## Acceptance Criteria
%s

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: %s

## Blocked by ADRs
%s

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: %s
`, date, content.Title, statusLine, motivationSection, criteriaSection, linkedADRSection, blockedSection, linkedRoadmapSection)

	if err := os.WriteFile(filename, []byte(body), 0644); err != nil {
		return fmt.Errorf("writing REQ: %w", err)
	}

	fmt.Printf("created %s\n", filename)
	return nil
}

// ListREQs lista todos os REQs encontrados em dir, imprimindo filename e status.
// Retorna nil se o diretório estiver ausente ou sem arquivos .md.
func ListREQs(dir string) error {
	matches, err := filepath.Glob(filepath.Join(dir, "*.md"))
	if err != nil {
		return fmt.Errorf("listing REQs: %w", err)
	}
	if len(matches) == 0 {
		fmt.Printf("No REQs found in %s\n", dir)
		return nil
	}

	for _, path := range matches {
		filename := filepath.Base(path)
		title, status := parseREQMeta(path)
		if title == "" {
			title = filename
		}
		fmt.Printf("%-60s %s\n", filename, status)
		_ = title
	}
	return nil
}

// parseREQMeta extrai título e status de um arquivo REQ markdown.
func parseREQMeta(path string) (title, status string) {
	f, err := os.Open(path)
	if err != nil {
		return "", "unknown"
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	status = "unknown"
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "# REQ: ") {
			title = strings.TrimPrefix(line, "# REQ: ")
		}
		if strings.Contains(line, "| Status: ") {
			idx := strings.Index(line, "| Status: ")
			if idx >= 0 {
				rest := line[idx+len("| Status: "):]
				// O status termina no próximo " |" ou no final da linha
				if pipeIdx := strings.Index(rest, " |"); pipeIdx >= 0 {
					rest = rest[:pipeIdx]
				}
				rest = strings.TrimRight(rest, " >|")
				status = strings.TrimSpace(rest)
			}
		}
	}
	return title, status
}

// reqStates são os cinco estados que uma REQ pode ocupar — os mesmos que o
// validator já varre em resolveREQFiles.
var reqStates = []string{"backlog", "wip", "blocked", "done", "abandoned"}

// findREQ procura uma REQ por nome (match parcial, case-insensitive) nas três
// formas em que elas vivem: sob agente e estado, sob agente sem estado, e na
// raiz do req_dir.
//
// Devolve o caminho encontrado. Erro quando não acha, ou quando o nome casa com
// mais de um arquivo — nesse caso lista os candidatos.
//
// Ver ADR-2026-08-17-req-move-resolve-as-tres-formas.
func findREQ(name string) (string, error) {
	cfg := config.Load()
	reqDir := cfg.REQDir
	if reqDir == "" {
		return "", fmt.Errorf("req_dir não configurado")
	}

	var patterns []string
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
			for _, state := range reqStates {
				patterns = append(patterns, filepath.Join(reqDir, agent, state, "*.md"))
			}
			patterns = append(patterns, filepath.Join(reqDir, agent, "*.md"))
		}
	}
	patterns = append(patterns, filepath.Join(reqDir, "*.md"))

	lower := strings.ToLower(name)
	var matches []string
	seen := map[string]bool{}
	for _, p := range patterns {
		found, err := filepath.Glob(p)
		if err != nil {
			continue
		}
		for _, f := range found {
			if seen[f] {
				continue
			}
			if strings.Contains(strings.ToLower(filepath.Base(f)), lower) {
				seen[f] = true
				matches = append(matches, f)
			}
		}
	}

	switch len(matches) {
	case 0:
		return "", fmt.Errorf("req %q não encontrada em %s", name, reqDir)
	case 1:
		return matches[0], nil
	default:
		return "", fmt.Errorf("nome %q é ambíguo — casa com %d REQs: %s",
			name, len(matches), strings.Join(matches, ", "))
	}
}

// MoveREQ move uma REQ para o diretório de um estado, preservando o agente em
// modo by_agent, e sincroniza o status: do frontmatter e a linha humana.
//
// Ver REQ-2026-08-17-req-move.
func MoveREQ(name, state string) error {
	valid := false
	for _, s := range reqStates {
		if s == state {
			valid = true
			break
		}
	}
	if !valid {
		return fmt.Errorf("estado inválido %q — válidos: %s", state, strings.Join(reqStates, ", "))
	}

	src, err := findREQ(name)
	if err != nil {
		return err
	}

	cfg := config.Load()
	reqDir := filepath.Clean(cfg.REQDir)

	// O agente é a primeira pasta abaixo de req_dir, quando existe. Preservá-lo
	// evita que mover uma REQ a mude de dono.
	var targetDir string
	fromState := "—"
	rel, relErr := filepath.Rel(reqDir, filepath.Dir(src))
	if relErr == nil && rel != "." {
		parts := strings.Split(filepath.ToSlash(rel), "/")
		agent := parts[0]
		if len(parts) > 1 {
			fromState = parts[1]
		}
		targetDir = filepath.Join(reqDir, agent, state)
	} else {
		targetDir = filepath.Join(reqDir, state)
	}

	if err := os.MkdirAll(targetDir, 0755); err != nil {
		return fmt.Errorf("criando %s: %w", targetDir, err)
	}

	dst := filepath.Join(targetDir, filepath.Base(src))
	if dst == src {
		return fmt.Errorf("req %q já está em %s", filepath.Base(src), state)
	}
	if err := os.Rename(src, dst); err != nil {
		return fmt.Errorf("movendo req: %w", err)
	}

	if content, err := os.ReadFile(dst); err == nil {
		updated := setHeaderStatus(setFrontmatterStatus(string(content), state), state)
		if updated != string(content) {
			_ = os.WriteFile(dst, []byte(updated), 0644)
		}
	}

	appendREQTransitionLog(filepath.Base(src), fromState, state)

	fmt.Printf("✓ moved %s → %s\n", filepath.Base(src), targetDir)
	return nil
}

// appendREQTransitionLog grava a transição em <req_dir>/.trackfw-log.
//
// Arquivo separado do log de roadmaps de propósito: `trackfw log` e
// `trackfw metrics` leem <roadmap_dir>/.trackfw-log e tratam cada linha como
// transição de roadmap. Misturar REQs ali distorceria lead time e throughput sem
// nenhum sinal. Ver ADR-2026-08-17-req-move-resolve-as-tres-formas.
func appendREQTransitionLog(basename, fromState, toState string) {
	line := fmt.Sprintf("%s  %-50s  %s → %s\n",
		time.Now().Format("2006-01-02 15:04"), basename, fromState, toState)

	logPath := filepath.Join(config.Load().REQDir, ".trackfw-log")
	if err := os.MkdirAll(filepath.Dir(logPath), 0755); err != nil {
		return
	}
	f, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer func() { _ = f.Close() }()
	_, _ = f.WriteString(line)
}
