'use strict'
const fs = require('fs')
const path = require('path')
const config = require('../config')
const reqs = require('../reqs')
const { setFrontmatterStatus, setHeaderStatus } = require('./roadmap')

/**
 * listREQs — lista arquivos .md em dir, imprimindo filename e status (coluna 60 chars).
 * Extrai status da linha `> Date: ... | Status: ...`.
 * Se dir não existe ou vazio: imprime "No REQs found in <dir>".
 */
function listREQs() {
  const cfg = config.load()
  const entries = reqs.all(cfg)

  if (entries.length === 0) {
    console.log(`No REQs found in ${cfg.reqDir}`)
    return
  }

  let lastGroup = ''
  for (const e of entries) {
    let group = ''
    if (e.agent && e.state) group = `${e.agent}/${e.state}`
    else if (e.agent) group = e.agent

    if (group !== lastGroup) {
      if (group) console.log(`${String.fromCharCode(10)}[${group}]`)
      lastGroup = group
    }

    const filename = path.basename(e.path)
    const status = parseREQStatus(e.path)
    console.log(`${filename.padEnd(60)} ${status}`)
  }
}

function parseREQStatus(filepath) {
  let content
  try {
    content = fs.readFileSync(filepath, 'utf8')
  } catch (_) {
    return 'unknown'
  }

  const lines = content.split(String.fromCharCode(10))

  // 1) Frontmatter e a fonte preferida. Antes esta funcao varria o arquivo
  // inteiro atras de "| Status: " e a PRIMEIRA ocorrencia vencia, entao qualquer
  // tabela ou trecho de corpo com esse texto virava o status.
  // Ver REQ-2026-08-17-resolvedor-req-unificado.
  if (lines[0] !== undefined && lines[0].replace(/\r+$/, '') === '---') {
    for (let k = 1; k < lines.length; k++) {
      const line = lines[k].replace(/\r+$/, '')
      if (line === '---') break
      const colon = line.indexOf(':')
      if (colon > 0 && line.slice(0, colon).trim() === 'status') {
        const v = line.slice(colon + 1).trim().replace(/^["']|["']$/g, '')
        if (v) return v
        break
      }
    }
  }

  // 2) Linha humana de cabecalho. A busca para no primeiro "## " — dai em
  // diante e corpo.
  for (const raw of lines) {
    const line = raw.replace(/\r+$/, '')
    if (line.startsWith('## ')) break
    if (!line.startsWith('> ')) continue
    const idx = line.indexOf('| Status: ')
    if (idx < 0) continue
    let rest = line.slice(idx + '| Status: '.length)
    const pipeIdx = rest.indexOf(' |')
    if (pipeIdx >= 0) rest = rest.slice(0, pipeIdx)
    rest = rest.replace(/[\s>|]+$/, '').trim()
    if (rest) return rest
  }

  return 'unknown'
}

/**
 * toSlug — converte string em slug kebab-case lowercase.
 * @param {string} s
 * @returns {string}
 */
function toSlug(s) {
  return s.toLowerCase().replace(/ /g, '-')
}

/**
 * newREQ — cria docs/req/REQ-YYYY-MM-DD-<slug>.md.
 * @param {{ title: string, motivation?: string, criteria?: string, dependsOnADRs?: string[] }} content
 * @returns {Promise<void>}
 */
async function newREQ(content) {
  const reqDir = require('../config').load().reqDir
  fs.mkdirSync(reqDir, { recursive: true })

  const slug = toSlug(content.title)
  const date = new Date().toISOString().slice(0, 10)
  const filename = `${reqDir}/REQ-${date}-${slug}.md`

  const motivationSection = content.motivation || '<!-- Why is this requirement needed? What problem does it solve? -->'
  const criteriaSection = content.criteria || '- [ ]\n- [ ]'
  const linkedADRSection = ''
  const linkedRoadmapSection = ''

  const dependsOnADRs = content.dependsOnADRs || []

  // Linha de status — inclui contador de ADRs bloqueantes quando presente
  let statusLine = `> Date: ${date} | Status: Open`
  if (dependsOnADRs.length > 0) {
    statusLine = `> Date: ${date} | Status: Open | Blocked by ADRs: ${dependsOnADRs.length}`
  }

  // Seção "Blocked by ADRs"
  let blockedSection
  if (dependsOnADRs.length === 0) {
    blockedSection = '<!-- none -->'
  } else {
    const lines = ['<!-- ADRs in Draft status that must be Accepted before a roadmap can be created -->']
    for (const adr of dependsOnADRs) {
      lines.push(`- ${adr} (Draft)`)
    }
    blockedSection = lines.join('\n')
  }

  const body = `---
status: Open
date: ${date}
author: ""
adr: ""
roadmap: ""
---

# REQ: ${content.title}

${statusLine}

## Motivation
${motivationSection}

## Acceptance Criteria
${criteriaSection}

## Linked ADR
<!-- Reference the ADR that governs this requirement -->
ADR: ${linkedADRSection}

## Blocked by ADRs
${blockedSection}

## Linked Roadmap
<!-- Reference the roadmap that implements this requirement -->
Roadmap: ${linkedRoadmapSection}
`

  fs.writeFileSync(filename, body, 'utf8')
  console.log(`created ${filename}`)
}

/**
 * PROBES_CATALOG — catálogo de domínios técnicos detectáveis (porte exato do Go).
 */
const PROBES_CATALOG = [
  {
    domain: 'authentication',
    keywords: ['login', 'auth', 'senha', 'password', 'sso', 'jwt', 'session', 'token', 'autenticação', 'autenticar'],
    questions: [
      {
        text: 'How will users authenticate?',
        options: [
          { label: 'Local login (email + password)', decided: true, adrSlug: '' },
          { label: 'SSO (Google, Azure AD, Okta...)', decided: false, adrSlug: 'sso-provider' },
          { label: 'Both (local + SSO)', decided: false, adrSlug: 'authentication-strategy' },
          { label: 'Not decided yet', decided: false, adrSlug: 'authentication-strategy' },
        ],
      },
      {
        text: 'How will sessions be managed?',
        options: [
          { label: 'JWT (stateless)', decided: true, adrSlug: '' },
          { label: 'Server-side sessions (cookies)', decided: true, adrSlug: '' },
          { label: 'Not decided yet', decided: false, adrSlug: 'session-management' },
        ],
      },
    ],
  },
  {
    domain: 'ui',
    keywords: ['tela', 'screen', 'ui', 'frontend', 'componente', 'component', 'design', 'layout', 'interface'],
    questions: [
      {
        text: 'Is there an existing UI framework or design system?',
        options: [
          { label: 'Yes, already chosen', decided: true, adrSlug: '' },
          { label: 'No, need to choose a UI framework', decided: false, adrSlug: 'ui-framework' },
          { label: 'Not relevant for this REQ', decided: true, adrSlug: '' },
        ],
      },
    ],
  },
  {
    domain: 'persistence',
    keywords: ['banco', 'database', 'db', 'tabela', 'table', 'migração', 'migration', 'modelo', 'model', 'persistência', 'persist'],
    questions: [
      {
        text: 'Which database engine will be used?',
        options: [
          { label: 'Already decided', decided: true, adrSlug: '' },
          { label: 'Not decided yet', decided: false, adrSlug: 'database-engine' },
        ],
      },
    ],
  },
  {
    domain: 'api',
    keywords: ['api', 'endpoint', 'rest', 'grpc', 'graphql', 'rota', 'route', 'http'],
    questions: [
      {
        text: 'Which API protocol will be used?',
        options: [
          { label: 'REST (already decided)', decided: true, adrSlug: '' },
          { label: 'gRPC (already decided)', decided: true, adrSlug: '' },
          { label: 'GraphQL (already decided)', decided: true, adrSlug: '' },
          { label: 'Not decided yet', decided: false, adrSlug: 'api-protocol' },
        ],
      },
    ],
  },
  {
    domain: 'deploy',
    keywords: ['deploy', 'cloud', 'container', 'kubernetes', 'k8s', 'docker', 'infra', 'aws', 'gcp', 'azure'],
    questions: [
      {
        text: 'Is the deployment infrastructure already defined?',
        options: [
          { label: 'Yes, fully defined', decided: true, adrSlug: '' },
          { label: 'Cloud provider not decided', decided: false, adrSlug: 'cloud-provider' },
          { label: 'Container strategy not decided', decided: false, adrSlug: 'container-strategy' },
        ],
      },
    ],
  },
  {
    domain: 'events',
    keywords: ['kafka', 'fila', 'queue', 'notificação', 'notification', 'evento', 'event', 'pubsub', 'pub/sub', 'broker', 'sqs', 'redis'],
    questions: [
      {
        text: 'Which event broker will be used?',
        options: [
          { label: 'Already decided', decided: true, adrSlug: '' },
          { label: 'Not decided yet', decided: false, adrSlug: 'event-broker' },
        ],
      },
    ],
  },
]

/**
 * detectDomains — retorna probes cujos keywords aparecem na intention (case-insensitive).
 * @param {string} intention
 * @returns {Array}
 */
function detectDomains(intention) {
  const lower = intention.toLowerCase()
  return PROBES_CATALOG.filter(probe =>
    probe.keywords.some(kw => lower.includes(kw.toLowerCase()))
  )
}


/**
 * findREQ — delega ao modulo reqs. Mantida para nao mexer nos chamadores;
 * a logica de caminho vive num lugar so.
 */
function findREQ(name) {
  const r = reqs.find(config.load(), name)
  if (r.error) return { error: r.error }
  return { path: r.entry.path }
}

/**
 * moveREQ — move uma REQ para o diretório de um estado, preservando o agente em
 * by_agent, e sincroniza o status: do frontmatter e a linha humana.
 *
 * Ver REQ-2026-08-17-req-move.
 */
function moveREQ(name, state) {
  if (!reqs.STATES.includes(state)) {
    console.error(`estado inválido "${state}" — válidos: ${reqs.STATES.join(', ')}`)
    process.exitCode = 1
    return
  }

  const found = findREQ(name)
  if (found.error) {
    console.error(found.error)
    process.exitCode = 1
    return
  }

  const cfg = config.load()
  const reqDir = path.normalize(cfg.reqDir)
  const src = found.path

  // O agente é a primeira pasta abaixo de req_dir, quando existe. Preservá-lo
  // evita que mover uma REQ a mude de dono.
  let targetDir
  let fromState = '—'
  const rel = path.relative(reqDir, path.dirname(src))
  if (rel && rel !== '.') {
    const parts = rel.split(path.sep)
    if (parts.length > 1) fromState = parts[1]
    targetDir = path.join(reqDir, parts[0], state)
  } else {
    targetDir = path.join(reqDir, state)
  }

  const dst = path.join(targetDir, path.basename(src))
  if (path.resolve(dst) === path.resolve(src)) {
    console.error(`req "${path.basename(src)}" já está em ${state}`)
    process.exitCode = 1
    return
  }

  try { fs.mkdirSync(targetDir, { recursive: true }) } catch (_) {}
  fs.renameSync(src, dst)

  try {
    const content = fs.readFileSync(dst, 'utf8')
    const updated = setHeaderStatus(setFrontmatterStatus(content, state), state)
    if (updated !== content) fs.writeFileSync(dst, updated, 'utf8')
  } catch (_) {}

  appendREQTransitionLog(path.basename(src), fromState, state)
  console.log(`✓ moved ${path.basename(src)} → ${targetDir}`)
}

/**
 * appendREQTransitionLog — grava em <req_dir>/.trackfw-log.
 *
 * Arquivo separado do log de roadmaps de propósito: `trackfw log` e
 * `trackfw metrics` tratam cada linha daquele arquivo como transição de roadmap,
 * e misturar REQs distorceria lead time e throughput em silêncio.
 */
function appendREQTransitionLog(basename, fromState, toState) {
  const now = new Date()
  const p2 = n => String(n).padStart(2, '0')
  const ts = `${now.getFullYear()}-${p2(now.getMonth() + 1)}-${p2(now.getDate())} ${p2(now.getHours())}:${p2(now.getMinutes())}`
  const line = `${ts}  ${basename.padEnd(50)}  ${fromState} → ${toState}\n`

  try {
    const lp = path.join(config.load().reqDir, '.trackfw-log')
    fs.mkdirSync(path.dirname(lp), { recursive: true })
    fs.appendFileSync(lp, line, 'utf8')
  } catch (_) {}
}

module.exports = { listREQs, parseREQStatus, newREQ, PROBES_CATALOG, detectDomains, moveREQ, findREQ }
