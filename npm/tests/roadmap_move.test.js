'use strict'
const assert = require('assert')
const fs = require('fs')
const os = require('os')
const path = require('path')
const config = require('../src/config/index.js')
const { moveRoadmap } = require('../src/generators/roadmap')

// Prepara um repo temporário em modo flat com um roadmap em wip/, roda fn e limpa.
function withRoadmap(filename, content, fn) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'trackfw-move-'))
  const orig = process.cwd()
  try {
    fs.mkdirSync(path.join(tmp, 'docs', 'roadmaps', 'wip'), { recursive: true })
    fs.writeFileSync(path.join(tmp, 'docs', 'roadmaps', 'wip', filename), content, 'utf8')
    config.reset()
    process.chdir(tmp)
    fn(tmp)
  } finally {
    process.chdir(orig)
    config.reset()
    fs.rmSync(tmp, { recursive: true, force: true })
  }
}

function readMoved(tmp, state, filename) {
  return fs.readFileSync(path.join(tmp, 'docs', 'roadmaps', state, filename), 'utf8')
}

let passed = 0, failed = 0

function test(name, fn) {
  try { fn(); console.log(`✓ ${name}`); passed++ }
  catch (e) { console.error(`✗ ${name}: ${e.message}`); failed++ }
}

const NL = String.fromCharCode(10)

test('move sincroniza o status: do frontmatter', () => {
  const src = ['---', 'name: x', 'status: wip', 'date: 2026-08-16', '---', '', '# Roadmap: x', '', 'corpo', ''].join(NL)
  withRoadmap('x.md', src, (tmp) => {
    moveRoadmap('x.md', 'done')
    const want = ['---', 'name: x', 'status: done', 'date: 2026-08-16', '---', '', '# Roadmap: x', '', 'corpo', ''].join(NL)
    assert.strictEqual(readMoved(tmp, 'done', 'x.md'), want)
  })
})

test('roadmap sem frontmatter sai byte a byte identico', () => {
  const src = ['# Roadmap: y', '', '### ML-1', 'status: pendente', '', 'corpo', ''].join(NL)
  withRoadmap('y.md', src, (tmp) => {
    moveRoadmap('y.md', 'done')
    assert.strictEqual(readMoved(tmp, 'done', 'y.md'), src)
  })
})

test('frontmatter sem a chave status nao ganha o campo', () => {
  const src = ['---', 'name: z', 'date: 2026-08-16', '---', '', '# Roadmap: z', ''].join(NL)
  withRoadmap('z.md', src, (tmp) => {
    moveRoadmap('z.md', 'done')
    assert.strictEqual(readMoved(tmp, 'done', 'z.md'), src)
  })
})

test('status: no corpo, fora do frontmatter, nao e tocado', () => {
  const src = ['---', 'status: wip', '---', '', '# Roadmap: w', '', 'status: isto e corpo', ''].join(NL)
  withRoadmap('w.md', src, (tmp) => {
    moveRoadmap('w.md', 'blocked')
    const want = ['---', 'status: blocked', '---', '', '# Roadmap: w', '', 'status: isto e corpo', ''].join(NL)
    assert.strictEqual(readMoved(tmp, 'blocked', 'w.md'), want)
  })
})

console.log(`${NL}${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
