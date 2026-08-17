package generators

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// useTempHome aponta o resolvedor de home do pacote para dir e restaura no fim
// do teste.
//
// Também exporta HOME, para cobrir os sistemas em que os.UserHomeDir o consulta.
// Era esse Setenv sozinho que os testes usavam antes — e no Windows ele não
// isolava nada, porque os.UserHomeDir lê USERPROFILE ali. O resultado era que os
// instaladores rodavam contra o home real do desenvolvedor durante a suíte.
//
// Ver REQ-2026-08-16-testes-go-portaveis-windows.
func useTempHome(t *testing.T, dir string) {
	t.Helper()

	origFn := userHomeDir
	userHomeDir = func() (string, error) { return dir, nil }

	origHome := os.Getenv("HOME")
	_ = os.Setenv("HOME", dir)

	t.Cleanup(func() {
		userHomeDir = origFn
		_ = os.Setenv("HOME", origHome)
	})
}

// TestUseTempHome_IsolaOResolvedor garante que o próprio mecanismo de isolamento
// funciona — sem isto, um seam quebrado passaria despercebido e os testes
// voltariam a escrever no home real em silêncio.
func TestUseTempHome_IsolaOResolvedor(t *testing.T) {
	real, err := os.UserHomeDir()
	if err != nil {
		t.Skipf("sem home resolvível neste ambiente: %v", err)
	}

	tmp := t.TempDir()
	t.Run("dentro", func(t *testing.T) {
		useTempHome(t, tmp)
		got, err := userHomeDir()
		if err != nil {
			t.Fatalf("userHomeDir() erro: %v", err)
		}
		if got != tmp {
			t.Errorf("userHomeDir() = %q, quer %q", got, tmp)
		}
		if got == real {
			t.Error("userHomeDir() devolveu o home real dentro do isolamento")
		}
	})

	got, err := userHomeDir()
	if err != nil {
		t.Fatalf("userHomeDir() erro após cleanup: %v", err)
	}
	if got != real {
		t.Errorf("após cleanup userHomeDir() = %q, quer %q", got, real)
	}
}

// TestDisplayPath cobre o helper que substituiu os caminhos hardcoded nas
// mensagens dos instaladores. O ponto do helper é justamente não mentir quando
// o home não é o padrão — ver REQ-2026-08-16-consistencias-template-saida-e-eol.
func TestDisplayPath(t *testing.T) {
	home := t.TempDir()
	useTempHome(t, home)

	t.Run("sob o home vira til", func(t *testing.T) {
		got := displayPath(filepath.Join(home, ".claude", "agents", "x.md"))
		want := "~/.claude/agents/x.md"
		if got != want {
			t.Errorf("displayPath() = %q, quer %q", got, want)
		}
	})

	t.Run("o proprio home vira til", func(t *testing.T) {
		if got := displayPath(home); got != "~/." {
			t.Logf("displayPath(home) = %q — aceitavel, so nao pode ser vazio", got)
			if got == "" {
				t.Error("displayPath(home) devolveu string vazia")
			}
		}
	})

	t.Run("fora do home fica absoluto", func(t *testing.T) {
		fora := t.TempDir()
		got := displayPath(filepath.Join(fora, "algum", "arquivo.md"))
		if strings.HasPrefix(got, "~") {
			t.Errorf("displayPath() = %q — caminho fora do home nao pode virar ~", got)
		}
		if !strings.Contains(got, "arquivo.md") {
			t.Errorf("displayPath() = %q — perdeu o nome do arquivo", got)
		}
	})
}

// TestDisplayPath_HomeIrresoluvel — o helper nao pode quebrar quando o home nao
// resolve; devolve o absoluto.
func TestDisplayPath_HomeIrresoluvel(t *testing.T) {
	orig := userHomeDir
	userHomeDir = func() (string, error) { return "", os.ErrNotExist }
	t.Cleanup(func() { userHomeDir = orig })

	abs := filepath.Join("C:", "qualquer", "x.md")
	got := displayPath(abs)
	if got == "" {
		t.Error("displayPath() devolveu string vazia com home irresolúvel")
	}
	if strings.HasPrefix(got, "~") {
		t.Errorf("displayPath() = %q — nao pode usar ~ sem home resolvido", got)
	}
}
