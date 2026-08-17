'use strict'

/**
 * reqs.js — resolve onde as REQs estão no disco.
 *
 * Antes deste módulo havia três implementações com alcances diferentes:
 *
 *   listREQs          varria reqDir/*.md                     → 0 das 36 REQs
 *   resolveReqFiles   varria reqDir/<agente>/<estado>/*.md    → 5
 *   findREQ           varria as três formas                   → 36
 *
 * O validate rodava sobre a segunda, e por isso nunca olhou 86% do corpus.
 * Ver REQ-2026-08-17-resolvedor-req-unificado.
 */

const fs = require('fs')
const path = require('path')

// Os cinco estados que uma REQ pode ocupar.
const STATES = ['backlog', 'wip', 'blocked', 'done', 'abandoned']

/**
 * dirs — devolve, em ordem de busca, os diretórios onde uma REQ pode estar,
 * com o agente e o estado que cada um representa.
 */
function dirs(cfg) {
  const reqDir = cfg.reqDir || cfg.req_dir || ''
  if (!reqDir) return []

  const namespacing = cfg.roadmapNamespacing || cfg.roadmap_namespacing || ''
  const out = []

  if (namespacing === 'by_agent') {
    let agents = cfg.agents || []
    if (!agents.length) {
      try {
        agents = fs.readdirSync(reqDir).filter(e => {
          try { return fs.statSync(path.join(reqDir, e)).isDirectory() } catch (_) { return false }
        })
      } catch (_) { agents = [] }
    }
    for (const agent of agents) {
      for (const state of STATES) {
        out.push({ dir: path.join(reqDir, agent, state), agent, state: state })
      }
      // REQ direto na pasta do agente, sem subpasta de estado. É a forma que
      // resolveReqFiles ignorava, e a maioria dos casos reais.
      out.push({ dir: path.join(reqDir, agent), agent, state: '' })
    }
  }
  out.push({ dir: reqDir, agent: '', state: '' })
  return out
}

/**
 * all — todas as REQs encontradas, com agente e estado de cada uma.
 * Ordem estável: agentes na ordem configurada, estados na ordem de STATES.
 */
function all(cfg) {
  const out = []
  const seen = new Set()

  for (const d of dirs(cfg)) {
    let entries = []
    try { entries = fs.readdirSync(d.dir) } catch (_) { continue }
    for (const name of entries) {
      if (!name.endsWith('.md')) continue
      const full = path.join(d.dir, name)
      if (seen.has(full)) continue
      try { if (fs.statSync(full).isDirectory()) continue } catch (_) { continue }
      seen.add(full)
      out.push({ path: full, agent: d.agent, state: d.state })
    }
  }
  return out
}

/** files — só os caminhos, para quem não precisa de agente nem estado. */
function files(cfg) {
  return all(cfg).map(e => e.path)
}

/**
 * find — localiza uma REQ por nome, match parcial case-insensitive.
 * Devolve { entry } ou { error }.
 */
function find(cfg, name) {
  const lower = name.toLowerCase()
  const matches = all(cfg).filter(e => path.basename(e.path).toLowerCase().includes(lower))

  if (matches.length === 0) {
    return { error: `req "${name}" não encontrada em ${cfg.reqDir || cfg.req_dir || ''}` }
  }
  if (matches.length > 1) {
    return {
      error: `nome "${name}" é ambíguo — casa com ${matches.length} REQs: ${matches.map(m => m.path).join(', ')}`,
    }
  }
  return { entry: matches[0] }
}

module.exports = { STATES, all, files, find }
