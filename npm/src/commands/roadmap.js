'use strict'
const { Command } = require('commander')
const { listRoadmaps, showRoadmap, moveRoadmap, newRoadmap, newRoadmapFromReq } = require('../generators/roadmap')
const { t } = require('../i18n')

const cmd = new Command('roadmap')
cmd.description(t('roadmap.description'))

cmd.command('new')
  .description(t('roadmap.new.description'))
  .option('-t, --title <title>', 'Roadmap title')
  .option('-r, --req <path>', 'Path to the linked REQ')
  .option('--from-req <path>', 'Generate roadmap with ML stubs from REQ acceptance criteria')
  .action(async (opts) => {
    if (opts.fromReq) {
      newRoadmapFromReq(opts.fromReq)
      return
    }

    const reqPath = opts.req || ''

    // Sem título e sem REQ não há de onde derivar um nome. Antes daqui saía um
    // roadmap chamado "New Roadmap", criado em silêncio.
    // Ver REQ-2026-08-16-roadmap-new-paridade-contrato.
    if (!opts.title && !reqPath) {
      console.error('informe o título com --title, ou uma REQ com --req/--from-req')
      process.exitCode = 1
      return
    }

    // Roadmap em backlog/ sem REQ é estado legítimo — quem cobra o link é o
    // validate, quando o roadmap chega em wip/. Mas o usuário precisa saber.
    if (!reqPath) {
      const reqDir = require('../config').load().reqDir
      console.error(`aviso: nenhuma REQ linkada (req_dir: ${reqDir}) — o roadmap será criado sem link de REQ.`)
      console.error('       isso vira violação de wip_has_req ao mover para wip/. Use --req ou --from-req para linkar.')
    }

    // Sem --title mas com --req, o título vem do nome da REQ — mesmo que o Go faz.
    let title = opts.title || ''
    if (!title && reqPath) {
      title = require('path').basename(reqPath).replace(/\.md$/, '').replace(/^REQ-/, '')
    }

    newRoadmap(title, reqPath)
  })

cmd.command('list')
  .description(t('roadmap.list.description'))
  .action(async () => {
    listRoadmaps()
  })

cmd.command('show <name>')
  .description(t('roadmap.show.description'))
  .action(async (name) => {
    showRoadmap(name)
  })

cmd.command('move <name> <state>')
  .description(t('roadmap.move.description'))
  .action(async (name, state) => {
    moveRoadmap(name, state)
  })

module.exports = cmd
