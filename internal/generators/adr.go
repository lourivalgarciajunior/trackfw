package generators

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/kgsaran/trackfw/internal/config"
)

// ADRContent contém os campos de um ADR a ser gerado.
type ADRContent struct {
	Title        string
	Context      string
	Decision     string
	Consequences string
	Alternatives string
}

// NewADR gera um arquivo ADR em docs/adr/ com base no conteúdo fornecido.
// Campos preenchidos são inseridos diretamente; campos vazios mantêm o placeholder HTML.
func NewADR(content ADRContent) error {
	cfg := config.Load()
	adrDir := cfg.ADRDirs[0]
	if err := os.MkdirAll(adrDir, 0755); err != nil {
		return err
	}

	slug := toSlug(content.Title)
	date := time.Now().Format("2006-01-02")
	filename := fmt.Sprintf("%s/ADR-%s-%s.md", adrDir, date, slug)

	contextSection := "<!-- What is the situation that motivates this decision? -->"
	if content.Context != "" {
		contextSection = content.Context
	}

	decisionSection := "<!-- What was decided? -->"
	if content.Decision != "" {
		decisionSection = content.Decision
	}

	consequencesSection := "<!-- What are the positive and negative consequences of this decision? -->"
	if content.Consequences != "" {
		consequencesSection = content.Consequences
	}

	alternativesSection := "<!-- What other options were evaluated and why were they rejected? -->"
	if content.Alternatives != "" {
		alternativesSection = content.Alternatives
	}

	body := fmt.Sprintf(`---
status: Proposed
date: %s
author: ""
---

# ADR: %s

> Date: %s | Status: Proposed

## Context
%s

## Decision
%s

## Consequences
%s

## Alternatives Considered
%s
`, date, content.Title, date, contextSection, decisionSection, consequencesSection, alternativesSection)

	if err := os.WriteFile(filename, []byte(body), 0644); err != nil {
		return fmt.Errorf("writing ADR: %w", err)
	}

	fmt.Printf("created %s\n", filename)
	return nil
}

// ListADRs lista todos os ADRs encontrados em dir, imprimindo filename e status.
// Retorna nil se o diretório estiver ausente ou sem arquivos .md.
func ListADRs(dir string) error {
	matches, err := filepath.Glob(filepath.Join(dir, "*.md"))
	if err != nil {
		return fmt.Errorf("listing ADRs: %w", err)
	}
	if len(matches) == 0 {
		fmt.Printf("No ADRs found in %s\n", dir)
		return nil
	}

	for _, path := range matches {
		filename := filepath.Base(path)
		title, status := parseADRMeta(path)
		if title == "" {
			title = filename
		}
		fmt.Printf("%-60s %s\n", filename, status)
		_ = title
	}
	return nil
}

// parseADRMeta extrai título e status de um arquivo ADR markdown.
func parseADRMeta(path string) (title, status string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", "unknown"
	}
	content := string(data)
	status = "unknown"

	lines := strings.Split(content, "\n")

	// 1) Frontmatter e a fonte canonica — e o campo que o `adr new` grava e que o
	// validator usa. Antes desta reescrita a funcao varria o arquivo inteiro atras
	// de "| Status: " e a ULTIMA ocorrencia vencia, enquanto o Node.js pegava a
	// PRIMEIRA: os dois runtimes davam respostas diferentes para a mesma ADR.
	// Ver REQ-2026-08-17-adr-list-python.
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

	// 2) Titulo e, se o frontmatter nao disse nada, a linha humana de cabecalho.
	// A busca para no primeiro "## " — dai em diante e corpo.
	for _, raw := range lines {
		line := strings.TrimRight(raw, "\r")
		if strings.HasPrefix(line, "## ") {
			break
		}
		if strings.HasPrefix(line, "# ADR: ") {
			title = strings.TrimPrefix(line, "# ADR: ")
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

func toSlug(s string) string {
	s = strings.ToLower(s)
	s = strings.ReplaceAll(s, " ", "-")
	return s
}

// slugToTitle converte um slug com hífens em título com title case.
// Ex: "authentication-strategy" → "Authentication Strategy"
func slugToTitle(slug string) string {
	words := strings.Split(slug, "-")
	for i, w := range words {
		if len(w) > 0 {
			words[i] = strings.ToUpper(w[:1]) + w[1:]
		}
	}
	return strings.Join(words, " ")
}

// NewADRDraft cria um ADR com Status: Draft a partir de um slug.
// Usado pelo wizard req new para registrar decisões pendentes.
// Retorna o basename do arquivo criado.
// Se o arquivo já existir, não sobrescreve (idempotente) e retorna o basename sem erro.
func NewADRDraft(slug string) (string, error) {
	cfg := config.Load()
	adrDir := cfg.ADRDirs[0]
	if err := os.MkdirAll(adrDir, 0755); err != nil {
		return "", fmt.Errorf("creating %s: %w", adrDir, err)
	}

	// Verificar idempotência: glob por slug
	pattern := filepath.Join(adrDir, "ADR-*-"+slug+".md")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return "", fmt.Errorf("glob: %w", err)
	}
	if len(matches) > 0 {
		basename := filepath.Base(matches[0])
		fmt.Printf("skipped %s (already exists)\n", basename)
		return basename, nil
	}

	date := time.Now().Format("2006-01-02")
	filename := fmt.Sprintf("ADR-%s-%s.md", date, slug)
	path := filepath.Join(adrDir, filename)
	title := slugToTitle(slug)

	body := fmt.Sprintf(`---
status: Draft
date: %s
author: ""
---

# ADR: %s

> Date: %s | Status: Draft

## Context
<!-- What is the situation that motivates this decision? -->

## Decision
<!-- What was decided? -->

## Consequences
<!-- What are the positive and negative consequences of this decision? -->

## Alternatives Considered
<!-- What other options were evaluated and why were they rejected? -->
`, date, title, date)

	if err := os.WriteFile(path, []byte(body), 0644); err != nil {
		return "", fmt.Errorf("writing ADR draft: %w", err)
	}

	fmt.Printf("created %s\n", filename)
	return filename, nil
}
