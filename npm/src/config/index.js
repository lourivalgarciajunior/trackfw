'use strict';

const fs = require('fs');
const path = require('path');

function defaults() {
  return {
    adrDirs: ['docs/adr'],
    reqDir: 'docs/req',
    roadmapDir: 'docs/roadmaps',
    roadmapNamespacing: 'flat',
    agents: [],
    governanceMode: '',
    lenientUntil: '',
    wipLimit: 1,
    wipBySquad: false,
    requireReqInCommit: false,
    traceIdField: '',
    // NOVOS campos:
    linkFields: {
      req:     ['REQ:'],
      adr:     ['ADR:'],
      roadmap: ['Roadmap:'],
    },
    acceptanceMarkers: ['## Acceptance Criteria', '## Critérios de Aceite'],
    rules: {
      wip_has_req:          'error',
      wip_acceptance:       'error',
      wip_limit:            'error',
      stale_wip:            'warning',
      adr_orphan:           'warning',
      ref_targets_exist:    'warning',
      folder_status:        'warning',
      filename_uniqueness:  'error',
      blocked_by_draft_adr: 'error',
    },
  };
}

let _instance = null;

function load(cwd) {
  if (_instance) return _instance;
  _instance = defaults();
  const yamlPath = path.join(cwd || process.cwd(), 'trackfw.yaml');
  if (!fs.existsSync(yamlPath)) return _instance;
  const content = fs.readFileSync(yamlPath, 'utf8');
  for (const w of parse(content, _instance)) console.error(w);
  return _instance;
}

function reset() {
  _instance = null;
}

function parse(content, cfg) {
  const inlineWarnings = [];
  const lines = content.split('\n');

  // estados existentes
  let inAdrDirs = false;
  let inAgents = false;
  let adrDirs = [];
  let agents = [];

  // NOVOS estados
  let inLinkFields = false;
  let inLinkFieldsReq = false;
  let inLinkFieldsAdr = false;
  let inLinkFieldsRoadmap = false;
  let linkFieldsReq = [];
  let linkFieldsAdr = [];
  let linkFieldsRoadmap = [];

  let inAcceptanceMarkers = false;
  let acceptanceMarkers = [];

  let inRules = false;
  let rules = {};

  function flushBlocks() {
    if (inAdrDirs && adrDirs.length) cfg.adrDirs = adrDirs;
    if (inAgents && agents.length) cfg.agents = agents;
    if (inLinkFields) {
      if (inLinkFieldsReq && linkFieldsReq.length) cfg.linkFields.req = linkFieldsReq;
      if (inLinkFieldsAdr && linkFieldsAdr.length) cfg.linkFields.adr = linkFieldsAdr;
      if (inLinkFieldsRoadmap && linkFieldsRoadmap.length) cfg.linkFields.roadmap = linkFieldsRoadmap;
    }
    if (inAcceptanceMarkers && acceptanceMarkers.length) cfg.acceptanceMarkers = acceptanceMarkers;
    if (inRules && Object.keys(rules).length) Object.assign(cfg.rules, rules);
    // reset
    inAdrDirs = false; adrDirs = [];
    inAgents = false; agents = [];
    inLinkFields = false;
    inLinkFieldsReq = false; inLinkFieldsAdr = false; inLinkFieldsRoadmap = false;
    linkFieldsReq = []; linkFieldsAdr = []; linkFieldsRoadmap = [];
    inAcceptanceMarkers = false; acceptanceMarkers = [];
    inRules = false; rules = {};
  }

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line) continue;
    let hasIndent = rawLine.length > 0 && (rawLine[0] === ' ' || rawLine[0] === '\t');

    // YAML aceita o bloco de lista na mesma coluna da chave:
    //
    //   agents:
    //   - claude
    //
    // Sem isto o '- claude' seria tratado como top-level, dispararia o flush
    // abaixo e o item sumiria em silencio. Ver
    // REQ-2026-08-16-config-listas-nao-silenciosas.
    if (line.startsWith('- ')) hasIndent = true;

    if (!hasIndent) {
      flushBlocks();
    }

    if (hasIndent) {
      if (inAdrDirs) {
        if (line.startsWith('- ')) adrDirs.push(line.slice(2).trim().replace(/^["']|["']$/g, ''));
        continue;
      }
      if (inAgents) {
        if (line.startsWith('- ')) agents.push(line.slice(2).trim().replace(/^["']|["']$/g, ''));
        continue;
      }
      if (inAcceptanceMarkers) {
        if (line.startsWith('- ')) {
          let val = line.slice(2).trim();
          val = val.replace(/^["']|["']$/g, '');
          acceptanceMarkers.push(val);
        }
        continue;
      }
      if (inRules) {
        const colonIdx = line.indexOf(':');
        if (colonIdx > 0) {
          const k = line.slice(0, colonIdx).trim();
          const v = line.slice(colonIdx + 1).trim().replace(/^["']|["']$/g, '');
          if (k) rules[k] = v;
        }
        continue;
      }
      if (inLinkFields) {
        if (line.startsWith('- ')) {
          let val = line.slice(2).trim();
          val = val.replace(/^["']|["']$/g, '');
          if (inLinkFieldsReq) linkFieldsReq.push(val);
          else if (inLinkFieldsAdr) linkFieldsAdr.push(val);
          else if (inLinkFieldsRoadmap) linkFieldsRoadmap.push(val);
        } else {
          // sub-chave dentro de link_fields
          const colonIdx = line.indexOf(':');
          const subKey = colonIdx > 0 ? line.slice(0, colonIdx).trim() : line.replace(':', '').trim();
          // flush sub-campo anterior
          if (inLinkFieldsReq && linkFieldsReq.length) { cfg.linkFields.req = linkFieldsReq; linkFieldsReq = []; }
          if (inLinkFieldsAdr && linkFieldsAdr.length) { cfg.linkFields.adr = linkFieldsAdr; linkFieldsAdr = []; }
          if (inLinkFieldsRoadmap && linkFieldsRoadmap.length) { cfg.linkFields.roadmap = linkFieldsRoadmap; linkFieldsRoadmap = []; }
          inLinkFieldsReq = false; inLinkFieldsAdr = false; inLinkFieldsRoadmap = false;
          if (subKey === 'req') inLinkFieldsReq = true;
          else if (subKey === 'adr') inLinkFieldsAdr = true;
          else if (subKey === 'roadmap') inLinkFieldsRoadmap = true;
        }
        continue;
      }
      continue;
    }

    // linha top-level
    const colonIdx = line.indexOf(':');
    if (colonIdx < 0) continue;
    const key = line.slice(0, colonIdx).trim();
    const val = line.slice(colonIdx + 1).trim();
    if (!key) continue;

    switch (key) {
      case 'adr_dirs':
        if (val) inlineWarnings.push(inlineListWarning('adr_dirs', val));
        inAdrDirs = true; adrDirs = []; break;
      case 'req_dir':               cfg.reqDir = val.replace(/^["']|["']$/g, ''); break;
      case 'roadmap_dir':           cfg.roadmapDir = val.replace(/^["']|["']$/g, ''); break;
      case 'roadmap_namespacing':   cfg.roadmapNamespacing = val; break;
      case 'agents':
        if (val) inlineWarnings.push(inlineListWarning('agents', val));
        inAgents = true; agents = []; break;
      case 'governance_mode':       cfg.governanceMode = val; break;
      case 'lenient_until':         cfg.lenientUntil = val; break;
      case 'wip_limit':             { const n = parseInt(val, 10); if (n > 0) cfg.wipLimit = n; break; }
      case 'wip_by_squad':          cfg.wipBySquad = val === 'true'; break;
      case 'require_req_in_commit': cfg.requireReqInCommit = val === 'true'; break;
      case 'trace_id_field':        cfg.traceIdField = val.replace(/^["']|["']$/g, ''); break;
      case 'link_fields':           inLinkFields = true; break;
      case 'acceptance_markers':
        if (val) inlineWarnings.push(inlineListWarning('acceptance_markers', val));
        inAcceptanceMarkers = true; acceptanceMarkers = []; break;
      case 'rules':                 inRules = true; rules = {}; break;
    }
  }

  // flush final (EOF)
  flushBlocks();

  return inlineWarnings;
}

const NAMESPACING_FLAT = 'flat';
const NAMESPACING_BY_AGENT = 'by_agent';

module.exports = { load, reset, defaults, NAMESPACING_FLAT, NAMESPACING_BY_AGENT };

/**
 * inlineListWarning — monta o aviso para uma lista escrita na forma inline.
 *
 * O parser do trackfw entende lista só na forma de bloco. A forma inline é YAML
 * válido, mas cai fora do que ele cobre — e antes disto era descartada em
 * silêncio, deixando a chave vazia sem nenhum sinal ao usuário. O exemplo de
 * `agents:` no próprio README usava essa forma.
 *
 * Ver REQ-2026-08-16-config-listas-nao-silenciosas.
 */
function inlineListWarning(key, val) {
  return 'aviso: trackfw.yaml — `' + key + ': ' + val + '` usa lista inline, que o trackfw não lê. ' +
    'A chave ficou vazia. Escreva em bloco:\n' +
    '       ' + key + ':\n' +
    '         - primeiro\n' +
    '         - segundo'
}
