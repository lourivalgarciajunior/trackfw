'use strict'
const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const { execFileSync, spawnSync } = require('child_process')

const BIN = path.join(__dirname, '..', 'bin', 'trackfw')

// Roda o CLI num tempdir isolado e devolve {status, stdout, stderr, dir}.
function runIn(dir, args) {
  const r = spawnSync(process.execPath, [BIN, ...args], {
    cwd: dir,
    encoding: 'utf8',
  })
  return { status: r.status, stdout: r.stdout || '', stderr: r.stderr || '', dir }
}

function fixture() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'trackfw-new-'))
  fs.writeFileSync(path.join(tmp, 'trackfw.yaml'), 'roadmap_namespacing: flat\n', 'utf8')
  return tmp
}

function backlogFiles(dir) {
  try {
    return fs.readdirSync(path.join(dir, 'docs', 'roadmaps', 'backlog')).filter(f => f.endsWith('.md'))
  } catch (_) {
    return []
  }
}

let passed = 0, failed = 0

function test(name, fn) {
  const tmp = fixture()
  try { fn(tmp); console.log(`✓ ${name}`); passed++ }
  catch (e) { console.error(`✗ ${name}: ${e.message}`); failed++ }
  finally { fs.rmSync(tmp, { recursive: true, force: true }) }
}

test('sem REQ: cria, avisa em stderr e sai 0', (tmp) => {
  const r = runIn(tmp, ['roadmap', 'new', '--title', 'Feature Sem Req'])
  assert.strictEqual(r.status, 0, `exit ${r.status}; stderr: ${r.stderr}`)
  assert.ok(/aviso: nenhuma REQ linkada/.test(r.stderr), `stderr sem aviso: ${r.stderr}`)
  assert.ok(/wip_has_req/.test(r.stderr), 'aviso nao explica a consequencia')
  const files = backlogFiles(tmp)
  assert.strictEqual(files.length, 1, `esperado 1 roadmap, obtido ${JSON.stringify(files)}`)
  assert.ok(files[0].includes('feature-sem-req'), `nome inesperado: ${files[0]}`)
})

test('com --req: grava a linha REQ', (tmp) => {
  fs.mkdirSync(path.join(tmp, 'docs', 'req'), { recursive: true })
  fs.writeFileSync(path.join(tmp, 'docs', 'req', 'REQ-x.md'), '# REQ: x\n', 'utf8')

  const r = runIn(tmp, ['roadmap', 'new', '--title', 'Com Req', '--req', 'docs/req/REQ-x.md'])
  assert.strictEqual(r.status, 0, `exit ${r.status}; stderr: ${r.stderr}`)
  const files = backlogFiles(tmp)
  assert.strictEqual(files.length, 1, `esperado 1 roadmap, obtido ${JSON.stringify(files)}`)
  const content = fs.readFileSync(path.join(tmp, 'docs', 'roadmaps', 'backlog', files[0]), 'utf8')
  assert.ok(content.includes('REQ: docs/req/REQ-x.md'), `link ausente:\n${content}`)
})

test('sem titulo e sem REQ: erro claro, nada criado', (tmp) => {
  const r = runIn(tmp, ['roadmap', 'new'])
  assert.notStrictEqual(r.status, 0, 'deveria falhar')
  assert.ok(/--title/.test(r.stderr), `mensagem nao orienta: ${r.stderr}`)
  assert.strictEqual(backlogFiles(tmp).length, 0, 'nao deveria ter criado roadmap')
})

console.log(`${String.fromCharCode(10)}${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
