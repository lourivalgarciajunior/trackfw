package generators

import (
	"os"
	"path/filepath"
	"strings"
)

// userHomeDir resolve o diretório home do usuário. É uma variável, e não uma
// chamada direta a os.UserHomeDir, para que os testes possam apontá-la para um
// tempdir e ficarem contidos na própria sandbox.
//
// Por que um seam e não ler HOME direto: os.UserHomeDir lê USERPROFILE no
// Windows e HOME no resto. Trocar por leitura direta de HOME mudaria para onde o
// trackfw instala de verdade no Windows — sob Git Bash, HOME aponta para um
// lugar diferente de USERPROFILE. Produção segue idêntica; só o teste injeta.
//
// Ver REQ-2026-08-16-testes-go-portaveis-windows.
var userHomeDir = os.UserHomeDir

// displayPath devolve abs numa forma curta para exibição: com o home do usuário
// colapsado em "~" quando abs está sob ele, ou o próprio abs quando não está.
//
// Existe porque as mensagens dos instaladores traziam "~/.claude/…" como literal
// hardcoded na string de formato, sem relação com o caminho que a função tinha
// acabado de resolver. Quando o home não era o padrão, a saída afirmava um
// destino que não era o real — o que atrapalhou ativamente o diagnóstico em
// REQ-2026-08-16-testes-go-portaveis-windows, onde o instalador dizia
// "~/.claude/agents/…" enquanto escrevia num tempdir.
//
// No uso normal a saída fica idêntica à de antes.
//
// Ver REQ-2026-08-16-consistencias-template-saida-e-eol.
func displayPath(abs string) string {
	home, err := userHomeDir()
	if err != nil || home == "" {
		return filepath.ToSlash(abs)
	}

	rel, err := filepath.Rel(home, abs)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return filepath.ToSlash(abs)
	}

	return "~/" + filepath.ToSlash(rel)
}
