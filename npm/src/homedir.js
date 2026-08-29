'use strict';

// Resolve o diretório home do usuário de forma consistente entre plataformas.
//
// DIVERGÊNCIA LOCAL — não existe no upstream. Espelha internal/homedir/homedir.go
// (Go) e pypi/trackfw/homedir.py (Python). Ver
// REQ-2026-08-29-node-e-python-ignoram-home-no-windows.
//
// Por que existe: os.homedir() lê $HOME no Linux e no macOS, mas %USERPROFILE% no
// Windows. Teste e gate isolam a home com HOME=<tempdir>, o que no Windows não
// isola nada — o processo continua lendo e escrevendo a home real do
// desenvolvedor. Foi assim que uma rodada de teste nesta máquina criou artefato
// dentro de ~/.trackfw e tocou os seis arquivos de config global de agente.
//
// Dir() faz o Windows se comportar como as outras plataformas: $HOME primeiro,
// os.homedir() como fallback. Onde $HOME não está definido nada muda.
//
// A string vazia NÃO conta como definida: HOME="" resolveria para "" e todo
// caminho derivado viraria relativo em silêncio.

const os = require('os');

function homedir() {
  const fromEnv = process.env.HOME;
  if (fromEnv) return fromEnv;
  return os.homedir();
}

module.exports = { homedir };
