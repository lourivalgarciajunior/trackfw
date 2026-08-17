package generators

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/kgsaran/trackfw/internal/config"
	"github.com/kgsaran/trackfw/internal/reqs"
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
// ListREQs lista todas as REQs, agrupadas por agente e estado em modo by_agent.
//
// Antes usava glob em reqDir/*.md e por isso respondia "No REQs found" em
// qualquer repositório com namespacing por agente — 0 das 36 REQs deste aqui.
// Ver REQ-2026-08-17-resolvedor-req-unificado.
func ListREQs() error {
	cfg := config.Load()
	entries := reqs.All(cfg)

	if len(entries) == 0 {
		fmt.Printf("No REQs found in %s\n", cfg.REQDir)
		return nil
	}

	lastGroup := ""
	for _, e := range entries {
		group := ""
		switch {
		case e.Agent != "" && e.State != "":
			group = e.Agent + "/" + e.State
		case e.Agent != "":
			group = e.Agent
		}
		if group != lastGroup {
			if group != "" {
				fmt.Printf("\n[%s]\n", group)
			}
			lastGroup = group
		}

		filename := filepath.Base(e.Path)
		_, status := parseREQMeta(e.Path)
		fmt.Printf("%-60s %s\n", filename, status)
	}
	return nil
}

// parseREQMeta extrai título e status de um arquivo REQ markdown.
func parseREQMeta(path string) (title, status string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", "unknown"
	}
	content := string(data)
	status = "unknown"

	lines := strings.Split(content, "\n")

	// 1) Frontmatter é a fonte preferida. Antes desta função varrer o arquivo
	// inteiro atrás de "| Status: ", qualquer tabela ou trecho de corpo com esse
	// texto sobrescrevia o status — e a última ocorrência vencia. Ver
	// REQ-2026-08-17-resolvedor-req-unificado.
	if strings.HasPrefix(content, "---\n") || strings.HasPrefix(content, "---\r\n") {
		for idx := 1; idx < len(lines); idx++ {
			line := strings.TrimRight(lines[idx], "\r")
			if line == "---" {
				break
			}
			if k, v, ok := strings.Cut(line, ":"); ok && strings.TrimSpace(k) == "status" {
				if v = strings.TrimSpace(strings.Trim(strings.TrimSpace(v), `"'`)); v != "" {
					status = v
				}
				break
			}
		}
	}

	// 2) Título e, se o frontmatter não disse nada, a linha humana de cabeçalho.
	// A busca para no primeiro "## " — daí em diante é corpo.
	for _, raw := range lines {
		line := strings.TrimRight(raw, "\r")
		if strings.HasPrefix(line, "## ") {
			break
		}
		if strings.HasPrefix(line, "# REQ: ") {
			title = strings.TrimPrefix(line, "# REQ: ")
		}
		if status == "unknown" && strings.HasPrefix(line, "> ") {
			if idx := strings.Index(line, "| Status: "); idx >= 0 {
				rest := line[idx+len("| Status: "):]
				if pipeIdx := strings.Index(rest, " |"); pipeIdx >= 0 {
					rest = rest[:pipeIdx]
				}
				if rest = strings.TrimSpace(strings.TrimRight(rest, " >|")); rest != "" {
					status = rest
				}
			}
		}
	}

	return title, status
}

// findREQ delega ao pacote reqs. Mantida como função para não mexer nos
// chamadores; a lógica de caminho vive num lugar só.
func findREQ(name string) (string, error) {
	e, err := reqs.Find(config.Load(), name)
	if err != nil {
		return "", err
	}
	return e.Path, nil
}

// MoveREQ move uma REQ para o diretório de um estado, preservando o agente em
// modo by_agent, e sincroniza o status: do frontmatter e a linha humana.
//
// Ver REQ-2026-08-17-req-move.
func MoveREQ(name, state string) error {
	valid := false
	for _, s := range reqs.States {
		if s == state {
			valid = true
			break
		}
	}
	if !valid {
		return fmt.Errorf("estado inválido %q — válidos: %s", state, strings.Join(reqs.States, ", "))
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
