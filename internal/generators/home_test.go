package generators

import (
	"os"
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
