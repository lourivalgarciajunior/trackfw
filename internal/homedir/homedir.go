// Package homedir resolve o diretório home do usuário de forma consistente
// entre plataformas.
//
// DIVERGÊNCIA LOCAL — não existe no upstream. Ver
// REQ-2026-08-29-migrar-para-upstream-7.3.0.
//
// Por que existe: os.UserHomeDir() lê $HOME no Linux e no macOS, mas
// %USERPROFILE% no Windows. Os testes do trackfw isolam a home com
// t.Setenv("HOME", t.TempDir()) — 97 call sites — o que no Windows não isola
// nada. O resultado é teste escrevendo em ~/.trackfw do desenvolvedor: uma
// execução de `go test ./...` nesta máquina criou ADR, integrations-manifest
// e dois scripts de guard dentro da home real.
//
// Dir() faz o Windows se comportar como as outras plataformas: $HOME primeiro,
// os.UserHomeDir() como fallback. Em produção no Windows a diferença é nula
// quando $HOME não está definido, e quando está (Git Bash o define) ele aponta
// para o mesmo lugar que %USERPROFILE%.
//
// A alternativa era editar os 97 call sites de teste, o que geraria conflito
// em todo merge futuro com o upstream. 21 call sites de produção é o custo
// menor.
package homedir

import "os"

// Dir retorna o diretório home do usuário, preferindo $HOME quando definido.
// Substitui os.UserHomeDir() em todo o código de produção do trackfw.
func Dir() (string, error) {
	if h := os.Getenv("HOME"); h != "" {
		return h, nil
	}
	return os.UserHomeDir()
}
