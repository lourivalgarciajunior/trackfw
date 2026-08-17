package commands

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/huh"
	cbterm "github.com/charmbracelet/x/term"
	"github.com/kgsaran/trackfw/internal/config"
	"github.com/kgsaran/trackfw/internal/generators"
	"github.com/spf13/cobra"
)

func newRoadmapCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "roadmap",
		Short: "Manage Roadmaps",
	}
	cmd.AddCommand(newRoadmapNewCmd(), newRoadmapMoveCmd(), newRoadmapListCmd(), newRoadmapShowCmd())
	return cmd
}

func newRoadmapNewCmd() *cobra.Command {
	var title, reqPath, fromReq string
	cmd := &cobra.Command{
		Use:   "new",
		Short: "Create a new roadmap from a REQ",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			// --from-req: gera roadmap pré-preenchido com MLs extraídos da REQ
			if fromReq != "" {
				return generators.NewRoadmapFromREQ(fromReq)
			}

			// --req flag bypasses wizard entirely
			if reqPath != "" {
				if title == "" {
					title = strings.TrimSuffix(filepath.Base(reqPath), ".md")
					title = strings.TrimPrefix(title, "REQ-")
				}
				return generators.NewRoadmapFromContent(generators.RoadmapContent{
					Title:   title,
					REQPath: reqPath,
				})
			}

			reqFiles, _ := filepath.Glob(config.Load().REQDir + "/*.md")
			var selectedREQ string

			isTTY := cbterm.IsTerminal(uintptr(os.Stdin.Fd()))

			if isTTY && len(reqFiles) > 0 {
				options := make([]huh.Option[string], len(reqFiles))
				for i, f := range reqFiles {
					options[i] = huh.NewOption(filepath.Base(f), f)
				}
				form := huh.NewForm(
					huh.NewGroup(
						huh.NewSelect[string]().
							Title("Select a REQ to link this roadmap to:").
							Options(options...).
							Value(&selectedREQ),
					),
				)
				if err := form.Run(); err != nil {
					return fmt.Errorf("wizard: %w", err)
				}
			} else if len(args) > 0 {
				selectedREQ = args[0]
			} else if len(reqFiles) == 0 {
				// Antes daqui saía uma mensagem e um `return nil` — exit 0 sem
				// criar nada, reportando sucesso a quem confia no código de saída.
				// Agora cria e avisa: um roadmap em backlog/ sem REQ é estado
				// legítimo do modelo, e quem cobra o link é o validate, na hora
				// em que ele importa. Ver REQ-2026-08-16-roadmap-new-paridade-contrato.
				fmt.Fprintln(os.Stderr, "aviso: nenhuma REQ encontrada em "+config.Load().REQDir+" — o roadmap será criado sem link de REQ.")
				fmt.Fprintln(os.Stderr, "       isso vira violação de wip_has_req ao mover para wip/. Use --req ou --from-req para linkar.")
			}

			if title == "" && selectedREQ != "" {
				title = strings.TrimSuffix(filepath.Base(selectedREQ), ".md")
				title = strings.TrimPrefix(title, "REQ-")
			}
			if title == "" {
				return fmt.Errorf("informe o título com --title, ou uma REQ com --req/--from-req")
			}

			return generators.NewRoadmapFromContent(generators.RoadmapContent{
				Title:   title,
				REQPath: selectedREQ,
			})
		},
	}
	cmd.Flags().StringVarP(&title, "title", "t", "", "Roadmap title")
	cmd.Flags().StringVarP(&reqPath, "req", "r", "", "Path to the linked REQ file")
	cmd.Flags().StringVar(&fromReq, "from-req", "", "Generate roadmap with ML stubs from REQ acceptance criteria")
	return cmd
}

func newRoadmapListCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "List all roadmaps grouped by state",
		RunE: func(cmd *cobra.Command, args []string) error {
			return generators.ListRoadmaps()
		},
	}
}

func newRoadmapShowCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "show <name>",
		Short: "Show a roadmap by name (partial match)",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return generators.ShowRoadmap(args[0])
		},
	}
}

func newRoadmapMoveCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "move <name> <state>",
		Short: "Move a roadmap between states (backlog|wip|blocked|done|abandoned)",
		Args:  cobra.ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			return generators.MoveRoadmap(args[0], args[1])
		},
	}
}
