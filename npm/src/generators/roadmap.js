'use strict'
const fs = require('fs')
const path = require('path')
const config = require('../config')

const STATE_ORDER = ['wip', 'backlog', 'blocked', 'done', 'abandoned']

// stateDir retorna o caminho do diretório para um estado válido no modo flat, ou null se inválido.
function stateDir(state) {
  const cfg = config.load()
  const valid = ['backlog', 'wip', 'blocked', 'done', 'abandoned']
  if (!valid.includes(state)) return null
  return cfg.roadmapDir + '/' + state
}

// agentStateDir retorna o diretório para um agente+estado em modo by_agent.
// agent=null usa o primeiro agente configurado (ou "default" se lista vazia).
function agentStateDir(agent, state) {
  const cfg = config.load()
  const valid = ['backlog', 'wip', 'blocked', 'done', 'abandoned']
  if (!valid.includes(state)) return null
  if (!agent) {
    agent = cfg.agents && cfg.agents.length > 0 ? cfg.agents[0] : 'default'
  }
  return cfg.roadmapDir + '/' + agent + '/' + state
}

// logPath retorna o caminho do arquivo de log de transições.
function logPath() {
  return config.load().roadmapDir + '/.trackfw-log'
}

/**
 * listRoadmaps — lista roadmaps agrupados por estado (e por agente em modo by_agent).
 * Se nenhum encontrado imprime mensagem orientando o usuário.
 */
function listRoadmaps() {
  const cfg = config.load()
  let found = false

  if (cfg.roadmapNamespacing === config.NAMESPACING_BY_AGENT) {
    let agents = cfg.agents || []
    if (agents.length === 0) {
      try {
        agents = fs.readdirSync(cfg.roadmapDir).filter(f => {
          try { return fs.statSync(path.join(cfg.roadmapDir, f)).isDirectory() } catch (_) { return false }
        })
      } catch (_) { agents = [] }
    }
    for (const agent of agents) {
      for (const state of STATE_ORDER) {
        const dir = cfg.roadmapDir + '/' + agent + '/' + state
        let files = []
        try {
          files = fs.readdirSync(dir).filter(f => {
            try { return !fs.statSync(path.join(dir, f)).isDirectory() && f.endsWith('.md') } catch (_) { return false }
          })
        } catch (_) { continue }
        if (files.length === 0) continue
        found = true
        console.log(`[${agent}/${state}]`)
        for (const f of files) console.log(`  ${f}`)
      }
    }
  } else {
    for (const state of STATE_ORDER) {
      const dir = cfg.roadmapDir + '/' + state
      let files = []
      try {
        files = fs.readdirSync(dir).filter(f => {
          try { return !fs.statSync(path.join(dir, f)).isDirectory() && f.endsWith('.md') } catch (_) { return false }
        })
      } catch (_) { continue }
      if (files.length === 0) continue
      found = true
      console.log(`[${state}]`)
      for (const f of files) console.log(`  ${f}`)
    }
  }

  if (!found) {
    console.log("Nenhum roadmap encontrado. Crie um com 'trackfw roadmap new'.")
  }
}

/**
 * showRoadmap — busca <roadmapDir>/ESTADO/NOME*.md (partial match, flat) ou
 * <roadmapDir>/AGENTE/ESTADO/NOME*.md (by_agent), imprime cabeçalho + conteúdo.
 */
function showRoadmap(name) {
  const matches = findRoadmapMatches(name)

  if (matches.length === 0) {
    console.error(`no roadmap found matching "${name}"`)
    process.exitCode = 1
    return
  }

  if (matches.length > 1) {
    console.log('Multiple roadmaps found — be more specific:')
    for (const m of matches) console.log(`  ${m}`)
    console.error(`ambiguous match for "${name}"`)
    process.exitCode = 1
    return
  }

  const filepath = matches[0]
  const basename = path.basename(filepath)
  const state = path.basename(path.dirname(filepath)).toUpperCase()
  const content = fs.readFileSync(filepath, 'utf8')

  console.log(`── ${basename} ── [${state}] ──────────────────────\n`)
  console.log(content)
  console.log(`Location: ${filepath}`)
}

/**
 * moveRoadmap — move arquivo para diretório do estado alvo.
 * Em modo by_agent, mantém o agente na hierarquia.
 */
function moveRoadmap(name, state) {
  const cfg = config.load()
  const valid = ['backlog', 'wip', 'blocked', 'done', 'abandoned']
  if (!valid.includes(state)) {
    console.error(`invalid state "${state}" — valid states: backlog, wip, blocked, done, abandoned`)
    process.exitCode = 1
    return
  }

  const matches = findRoadmapMatches(name)
  if (matches.length === 0) {
    console.error(`roadmap "${name}" not found in any state directory`)
    process.exitCode = 1
    return
  }
  if (matches.length > 1) {
    console.log('Multiple roadmaps found — be more specific:')
    for (const m of matches) console.log(`  ${m}`)
    console.error(`ambiguous match for "${name}"`)
    process.exitCode = 1
    return
  }

  const src = matches[0]
  const basename = path.basename(src)
  let targetDir, fromState, logBasename

  if (cfg.roadmapNamespacing === config.NAMESPACING_BY_AGENT) {
    const agentDir = path.dirname(path.dirname(src))
    const agent = path.basename(agentDir)
    fromState = path.basename(path.dirname(src))
    targetDir = agentStateDir(agent, state)
    if (!targetDir) {
      console.error(`invalid state "${state}"`)
      process.exitCode = 1
      return
    }
    logBasename = agent + '/' + basename
  } else {
    fromState = path.basename(path.dirname(src))
    targetDir = stateDir(state)
    if (!targetDir) {
      console.error(`invalid state "${state}"`)
      process.exitCode = 1
      return
    }
    logBasename = basename
  }

  try { fs.mkdirSync(targetDir, { recursive: true }) } catch (_) {}

  const dst = path.join(targetDir, basename)
  fs.renameSync(src, dst)

  // A pasta é o estado, mas a regra folder_status do validator lê o status: do
  // frontmatter. Sem esta sincronização o próprio move produz a incoerência que
  // o validate reclama. Ver REQ-2026-08-16-roadmap-move-sincroniza-status.
  try {
    const content = fs.readFileSync(dst, 'utf8')
    const updated = setHeaderStatus(setFrontmatterStatus(content, state), state)
    if (updated !== content) fs.writeFileSync(dst, updated, 'utf8')
  } catch (_) {}

  appendTransitionLog(logBasename, fromState, state)
  console.log(`✓ moved ${basename} → ${targetDir}`)
}

/**
 * setFrontmatterStatus — devolve content com o campo status: do frontmatter
 * valendo state. Só mexe dentro do bloco delimitado pelos "---" do topo do
 * arquivo, e só se a chave status já existir ali.
 *
 * Devolve content intocado quando não há frontmatter ou quando o bloco não
 * declara status — mesmo contrato do validator, que ignora quem não declara.
 * Isso protege roadmaps sem frontmatter, cujo corpo pode conter uma linha
 * começando com "status:".
 */
function setFrontmatterStatus(content, state) {
  if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) return content

  const lines = content.split('\n')
  if (lines.length < 2) return content

  // Procura o "---" de fechamento; fora dele nada é reescrito.
  let end = -1
  for (let i = 1; i < lines.length; i++) {
    if (lines[i].replace(/\r+$/, '') === '---') { end = i; break }
  }
  if (end < 0) return content

  for (let i = 1; i < end; i++) {
    const line = lines[i]
    const trimmed = line.replace(/\r+$/, '')
    const idx = trimmed.indexOf(':')
    if (idx < 0) continue
    if (trimmed.slice(0, idx).trim() !== 'status') continue
    lines[i] = 'status: ' + state + (line.endsWith('\r') ? '\r' : '')
    return lines.join('\n')
  }

  return content
}

// headerStatusMarker — separa o rótulo do estado na linha humana logo abaixo do
// título, no formato "> Created: 2026-08-16 | Status: backlog".
const HEADER_STATUS_MARKER = '| Status: '

/**
 * setHeaderStatus — devolve content com o estado da linha humana valendo state.
 *
 * Age na primeira linha que comece com "> " e contenha o marcador; tudo depois
 * dele é substituído. Conteúdo intocado quando nenhuma linha casa — a linha nunca
 * é criada, mesmo contrato de setFrontmatterStatus.
 *
 * Tolera o formato herdado com emoji ("| Status: 🔄 WIP"), porque substitui o
 * trecho inteiro em vez de tentar casar o valor anterior.
 *
 * Ver REQ-2026-08-16-consistencias-template-saida-e-eol.
 */
function setHeaderStatus(content, state) {
  const lines = content.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    const trimmed = line.replace(/\r+$/, '')
    if (!trimmed.startsWith('> ')) continue
    const idx = trimmed.indexOf(HEADER_STATUS_MARKER)
    if (idx < 0) continue
    lines[i] =
      trimmed.slice(0, idx + HEADER_STATUS_MARKER.length) +
      state +
      (line.endsWith('\r') ? '\r' : '')
    return lines.join('\n')
  }
  return content
}

/**
 * appendTransitionLog — append em <roadmapDir>/.trackfw-log.
 */
function appendTransitionLog(basename, fromState, toState) {
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const hh = String(now.getHours()).padStart(2, '0')
  const min = String(now.getMinutes()).padStart(2, '0')
  const timestamp = `${yyyy}-${mm}-${dd} ${hh}:${min}`
  const line = `${timestamp}  ${basename.padEnd(50)}  ${fromState} → ${toState}\n`

  try {
    const lp = logPath()
    fs.mkdirSync(path.dirname(lp), { recursive: true })
    fs.appendFileSync(lp, line, 'utf8')
  } catch (_) {}
}

/**
 * newRoadmap — cria roadmap em <roadmapDir>/backlog/ROADMAP-YYYY-MM-DD-<slug>.md.
 * Em modo by_agent, usa o primeiro agente configurado.
 */
function newRoadmap(title, reqPath) {
  const cfg = config.load()
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const date = `${yyyy}-${mm}-${dd}`
  const slug = toSlug(title)

  let backlogDir
  if (cfg.roadmapNamespacing === config.NAMESPACING_BY_AGENT) {
    backlogDir = agentStateDir(null, 'backlog')
    if (!backlogDir) {
      console.error('cannot resolve backlog dir in by_agent mode')
      process.exitCode = 1
      return
    }
  } else {
    backlogDir = cfg.roadmapDir + '/backlog'
  }

  const filename = `${backlogDir}/ROADMAP-${date}-${slug}.md`
  fs.mkdirSync(backlogDir, { recursive: true })

  const body = `---
status: backlog
date: ${date}
req: ""
squad: ""
---

# Roadmap: ${title}

> Created: ${date} | Status: backlog

## Context
<!-- What problem does this roadmap solve? Link the REQ. -->
REQ: ${reqPath || ''}

## Wave 1 — <name> (parallel MLs)
> Dependencies: none

### ML-1A — ${title}
**Status:** pending
**Files affected:**
**Actions:**
**Acceptance criteria:**
- [ ] build passes
- [ ] tests green
- [ ] validate passes
`

  fs.writeFileSync(filename, body, 'utf8')
  console.log(`✓ created ${filename}`)
}

/**
 * newRoadmapFromReq — lê uma REQ e gera roadmap pré-preenchido com MLs extraídos
 * dos critérios de aceite.
 */
function newRoadmapFromReq(reqPath) {
  let data
  try {
    data = fs.readFileSync(reqPath, 'utf8')
  } catch (err) {
    console.error(`reading REQ: ${err.message}`)
    process.exitCode = 1
    return
  }

  const { title: parsedTitle, criteria, linkedADR } = parseReqForRoadmap(data)
  const basename = path.basename(reqPath)
  const title = parsedTitle || basename.replace(/\.md$/, '').replace(/^REQ-/, '')

  const cfg = config.load()
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const date = `${yyyy}-${mm}-${dd}`
  const slug = toSlug(title)

  let backlogDir
  if (cfg.roadmapNamespacing === config.NAMESPACING_BY_AGENT) {
    backlogDir = agentStateDir(null, 'backlog')
    if (!backlogDir) {
      console.error('cannot resolve backlog dir in by_agent mode')
      process.exitCode = 1
      return
    }
  } else {
    backlogDir = cfg.roadmapDir + '/backlog'
  }

  const filename = `${backlogDir}/ROADMAP-${date}-${slug}.md`
  try { fs.mkdirSync(backlogDir, { recursive: true }) } catch (_) {}

  // Gerar seção de MLs a partir dos critérios de aceite
  const mlLines = ['## Wave 1 — Implementation (derived from REQ criteria)', '> Dependencies: none']
  for (let i = 0; i < criteria.length; i++) {
    const mlLabel = `ML-1${String.fromCharCode(65 + i)}`
    const crit = criteria[i]
    mlLines.push(`\n### ${mlLabel} — ${crit}`)
    mlLines.push('**Status:** pending')
    mlLines.push('**Files affected:**')
    mlLines.push('**Actions:**')
    mlLines.push('**Acceptance criteria:**')
    mlLines.push(`- [ ] ${crit}`)
    mlLines.push('- [ ] build passes')
    mlLines.push('- [ ] tests green')
  }
  const mlSection = mlLines.join('\n')

  const adrRef = linkedADR ? `\nADR: ${linkedADR}` : ''

  const body = `---
status: backlog
date: ${date}
req: "${basename}"
squad: ""
---

# Roadmap: ${title}

> Created: ${date} | Status: backlog

## Context
<!-- Derived from REQ: ${basename} -->
REQ: ${reqPath}${adrRef}

${mlSection}
`

  fs.writeFileSync(filename, body, 'utf8')
  console.log(`✓ created ${filename}`)
}

/**
 * parseReqForRoadmap — extrai título, critérios de aceite e ADR linkada de conteúdo REQ.
 */
function parseReqForRoadmap(content) {
  const lines = content.split('\n')
  let title = ''
  let linkedADR = ''
  const criteria = []
  let inCriteria = false

  for (const line of lines) {
    if (line.startsWith('# REQ: ')) {
      title = line.replace('# REQ: ', '').trim()
      continue
    }
    if (line.startsWith('# REQ — ')) {
      title = line.replace('# REQ — ', '').trim()
      continue
    }
    if (line.startsWith('# REQ - ')) {
      title = line.replace('# REQ - ', '').trim()
      continue
    }
    if (line.startsWith('**ADR:**')) {
      linkedADR = line.replace('**ADR:**', '').trim()
      continue
    }

    const lower = line.trim().toLowerCase()
    if (lower === '## critérios de aceite' || lower === '## acceptance criteria') {
      inCriteria = true
      continue
    }
    if (inCriteria && line.startsWith('## ')) {
      inCriteria = false
      continue
    }
    if (inCriteria) {
      const trimmed = line.trim()
      const checkboxPrefixes = ['- [ ]', '- [x]', '- [X]']
      for (const prefix of checkboxPrefixes) {
        if (trimmed.startsWith(prefix)) {
          const item = trimmed.slice(prefix.length).trim().replace(/`/g, '')
          if (item) criteria.push(item)
          break
        }
      }
    }
  }
  return { title, criteria, linkedADR }
}

// --- helpers ---

/**
 * findRoadmapMatches — retorna array de paths que contêm `name` (case-insensitive) em qualquer estado.
 * Suporta modo flat (1 nível) e by_agent (2 níveis).
 */
function findRoadmapMatches(name) {
  const cfg = config.load()
  const matches = []
  const nameLower = name.toLowerCase()

  if (cfg.roadmapNamespacing === config.NAMESPACING_BY_AGENT) {
    let agents = cfg.agents || []
    if (agents.length === 0) {
      try {
        agents = fs.readdirSync(cfg.roadmapDir).filter(f => {
          try { return fs.statSync(path.join(cfg.roadmapDir, f)).isDirectory() } catch (_) { return false }
        })
      } catch (_) { agents = ['default'] }
    }
    for (const agent of agents) {
      for (const state of STATE_ORDER) {
        const dir = cfg.roadmapDir + '/' + agent + '/' + state
        let files = []
        try { files = fs.readdirSync(dir) } catch (_) { continue }
        for (const f of files) {
          if (f.toLowerCase().includes(nameLower) && f.endsWith('.md')) {
            matches.push(path.join(dir, f))
          }
        }
      }
    }
  } else {
    for (const state of STATE_ORDER) {
      const dir = cfg.roadmapDir + '/' + state
      let files = []
      try { files = fs.readdirSync(dir) } catch (_) { continue }
      for (const f of files) {
        if (f.toLowerCase().includes(nameLower) && f.endsWith('.md')) {
          matches.push(path.join(dir, f))
        }
      }
    }
  }
  return matches
}

/**
 * toSlug — converte string para slug lowercase com hífens.
 */
function toSlug(s) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

module.exports = {
  listRoadmaps,
  showRoadmap,
  moveRoadmap,
  appendTransitionLog,
  newRoadmap,
  newRoadmapFromReq,
  stateDir,
  agentStateDir,
}
