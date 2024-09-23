
'use strict'

#===========================================================================================================
GUY                       = require 'guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'promptparser'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
#...........................................................................................................
{ hide }                  = GUY.props
pluck                     = ( o, k ) -> R = o[ k ]; delete o[ k ]; R
{ get_types }             = require './types'
#...........................................................................................................
{ Journal_walker  }       = require './journal-walker'
{ Image_walker    }       = require './image-walker'
{ DBay            }       = require 'dbay'
{ SQL             }       = DBay
# { U               }       = require './utilities'
# { trash           }       = require 'trash-sync'
{ Prompt_db       }       = require './prompt-db'


#===========================================================================================================
cmd   = 'build'
flags =
  match:      /(?:)/,
  trash_db:   true,
  sample:     0.01,
  max_count:  3,
  prompts:    '../../jzr/to-be-merged-from-Atlas/prompts-consolidated.md'
  seed:       1,
  pre_match:  /^\[.*?\].*?\S+/,
  db:         '/dev/shm/promptparser.sqlite'

#===========================================================================================================
run_journal_walker = ->
  lines = GUY.fs.walk_lines_with_positions flags.prompts
  yield from new Journal_walker { cmd, flags, lines, }
  return null

#===========================================================================================================
run_image_walker = ->
  yield from new Image_walker()
  return null

#===========================================================================================================
if module is require.main then await do =>




  lines = GUY.fs.walk_lines_with_positions flags.prompts
  prompt_db = new Prompt_db { cmd, flags, }
  debug 'Ω___1', name for { name, } from prompt_db.db SQL"""select name from sqlite_schema where type in ( 'table', 'view' );"""
  do =>
    count = 0
    for d from run_journal_walker()
      count++; break if count > 10
      info 'Ω___2', d
      info 'Ω___2', prompt_db.insert_into[ d.table ]
    return null
  do =>
    count = 0
    for d from run_image_walker()
      count++; break if count > 10
      help 'Ω___4', d
    return null


  return null

  echo()
  echo ( GUY.trm.grey 'Ω___5' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
