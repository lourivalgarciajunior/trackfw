#!/usr/bin/env bash
# Wave 0 gate — a superficie de slug de artefato esta fechada.
# Falha se aparecer implementacao nova, ou sumir uma das declaradas.
set -euo pipefail

expected=$(printf '%s\n' \
  'internal/generators/adr.go:toSlug' \
  'npm/src/generators/adr.js:toSlug' \
  'npm/src/generators/init.js:pom-inline' \
  'npm/src/generators/note.js:toSlug' \
  'npm/src/generators/req.js:toSlug' \
  'npm/src/generators/roadmap.js:toSlug' \
  'pypi/trackfw/generators/adr.py:slugify' \
  'pypi/trackfw/generators/note.py:slugify' \
  'pypi/trackfw/generators/req.py:slugify' \
  'pypi/trackfw/generators/roadmap.py:slugify' | sort)

actual=$(
  { grep -rlE '^func toSlug' internal/generators --include='*.go' | sed 's/$/:toSlug/'
    grep -rlE '^function toSlug' npm/src/generators --include='*.js' | sed 's/$/:toSlug/'
    grep -rlE 'function generatePomXml' npm/src/generators --include='*.js' | sed 's/$/:pom-inline/'
    grep -rlE '^def slugify' pypi/trackfw/generators --include='*.py' | sed 's/$/:slugify/'
  } | sort -u)

if [ "$actual" != "$expected" ]; then
  echo "Wave 0: inventario de slug mudou."
  diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true
  exit 1
fi
echo "Wave 0: inventario de slug fechado — 10 implementacoes declaradas."
