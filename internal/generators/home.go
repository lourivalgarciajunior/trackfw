package generators

import "os"

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
