'use strict'
const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { spawnSync } = require('child_process')

const BIN = path.join(__dirname, '..', 'bin', 'trackfw')
const NL = String.fromCharCode(10)

const REQ_SRC = [
  '---',
  'id: REQ-x',
  'status: backlog',
  '---',
  '',
  '# REQ: x',
  '',
  '> Created: 2026-08-17 | Status: backlog',
  '',
  'corpo',
  '',
].join(NL)

// Monta um repo temporario em by_agent e grava a REQ no subcaminho pedido.
function fixture(subdir, filename, content, yaml) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'trackfw-reqmove-'))
  fs.writeFileSync(
    path.join(tmp, 'trackfw.yaml'),
    yaml || 'req_dir: docs/req' + NL + 'roadmap_dir: docs/roadmaps' + NL +
      'roadmap_namespacing: by_agent' + NL + 'agents:' + NL + '  - claude' + NL,
    'utf8'
  )
  const full = path.join(tmp, ...subdir.split('/'))
  fs.mkdirSync(full, { recursive: true })
  fs.writeFileSync(path.join(full, filename), content, 'utf8')
  return tmp
}

function run(dir, ...args) {
  const r = spawnSync(process.execPath, [BIN, 'req', 'move', ...args], { cwd: dir, encoding: 'utf8' })
  return { status: r.status, stdout: r.stdout || '', stderr: r.stderr || '' }
}

function read(dir, rel) {
  return fs.readFileSync(path.join(dir, ...rel.split('/')), 'utf8')
}

function exists(dir, rel) {
  return fs.existsSync(path.join(dir, ...rel.split('/')))
}

let passed = 0, failed = 0

function test(name, fn) {
  let tmp
  try { tmp = fn(); console.log(`✓ ${name}`); passed++ }
  catch (e) { console.error(`✗ ${name}: ${e.message}`); failed++ }
  finally { if (tmp) fs.rmSync(tmp, { recursive: true, force: true }) }
}

test('move de subpasta de estado', () => {
  const tmp = fixture('docs/req/claude/backlog', 'REQ-x.md', REQ_SRC)
  const r = run(tmp, 'REQ-x', 'done')
  assert.strictEqual(r.status, 0, r.stderr)
  const got = read(tmp, 'docs/req/claude/done/REQ-x.md')
  assert.ok(got.includes('status: done'), 'frontmatter nao sincronizado')
  assert.ok(got.includes('| Status: done'), 'linha humana nao sincronizada')
  assert.ok(!exists(tmp, 'docs/req/claude/backlog/REQ-x.md'), 'origem deveria ter sumido')
  return tmp
})

test('move de dentro do agente sem subpasta de estado', () => {
  // Forma que o validator NAO enxerga e que e a maioria das REQs reais.
  const tmp = fixture('docs/req/claude', 'REQ-y.md', REQ_SRC)
  const r = run(tmp, 'REQ-y', 'abandoned')
  assert.strictEqual(r.status, 0, r.stderr)
  assert.ok(read(tmp, 'docs/req/claude/abandoned/REQ-y.md').includes('status: abandoned'))
  return tmp
})

test('move da raiz do req_dir em modo flat', () => {
  const tmp = fixture('docs/req', 'REQ-z.md', REQ_SRC,
    'req_dir: docs/req' + NL + 'roadmap_dir: docs/roadmaps' + NL)
  const r = run(tmp, 'REQ-z', 'wip')
  assert.strictEqual(r.status, 0, r.stderr)
  assert.ok(read(tmp, 'docs/req/wip/REQ-z.md').includes('status: wip'))
  return tmp
})

test('preserva o agente de origem', () => {
  const tmp = fixture('docs/req/apolo/done', 'REQ-w.md', REQ_SRC,
    'req_dir: docs/req' + NL + 'roadmap_dir: docs/roadmaps' + NL +
    'roadmap_namespacing: by_agent' + NL + 'agents:' + NL + '  - claude' + NL + '  - apolo' + NL)
  const r = run(tmp, 'REQ-w', 'abandoned')
  assert.strictEqual(r.status, 0, r.stderr)
  assert.ok(exists(tmp, 'docs/req/apolo/abandoned/REQ-w.md'), 'deveria estar em apolo/')
  assert.ok(!exists(tmp, 'docs/req/claude/abandoned/REQ-w.md'), 'mudou de dono')
  return tmp
})

test('arquivo sem frontmatter sai identico', () => {
  const src = ['# REQ: sem frontmatter', '', 'status: isto e corpo', ''].join(NL)
  const tmp = fixture('docs/req/claude', 'REQ-s.md', src)
  const r = run(tmp, 'REQ-s', 'done')
  assert.strictEqual(r.status, 0, r.stderr)
  assert.strictEqual(read(tmp, 'docs/req/claude/done/REQ-s.md'), src)
  return tmp
})

test('estado invalido: erro claro, exit != 0', () => {
  const tmp = fixture('docs/req/claude', 'REQ-x.md', REQ_SRC)
  const r = run(tmp, 'REQ-x', 'arquivado')
  assert.notStrictEqual(r.status, 0)
  assert.ok(/estado inv/.test(r.stderr), `mensagem nao orienta: ${r.stderr}`)
  return tmp
})

test('nome ambiguo: erro claro, nada movido', () => {
  const tmp = fixture('docs/req/claude', 'REQ-dup-a.md', REQ_SRC)
  fs.writeFileSync(path.join(tmp, 'docs', 'req', 'claude', 'REQ-dup-b.md'), REQ_SRC, 'utf8')
  const r = run(tmp, 'REQ-dup', 'done')
  assert.notStrictEqual(r.status, 0)
  assert.ok(/amb/.test(r.stderr), `mensagem nao menciona ambiguidade: ${r.stderr}`)
  return tmp
})

test('registra no log do req_dir, nao no de roadmaps', () => {
  const tmp = fixture('docs/req/claude/backlog', 'REQ-x.md', REQ_SRC)
  const r = run(tmp, 'REQ-x', 'done')
  assert.strictEqual(r.status, 0, r.stderr)
  const logged = read(tmp, 'docs/req/.trackfw-log')
  assert.ok(logged.includes('REQ-x.md'), 'REQ ausente do log')
  assert.ok(logged.includes('backlog'), 'estado de origem ausente')
  assert.ok(!exists(tmp, 'docs/roadmaps/.trackfw-log'), 'nao pode escrever no log de roadmaps')
  return tmp
})

console.log(`${NL}${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
