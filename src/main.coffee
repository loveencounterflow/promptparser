
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
{ U               }       = require './utilities'
{ trash           }       = require 'trash-sync'


#===========================================================================================================


#===========================================================================================================
module.exports = {
  Prompt_db, }


#===========================================================================================================
if module is require.main then await do =>

  cmd   = 'build'
  flags =
    match:      /(?:)/,
    trash_db:   true,
    sample:     0.01,
    max_count:  3,
    prompts:    '../to-be-merged-from-Atlas/prompts-consolidated.md'
    seed:       1,
    pre_match:  /^\[.*?\].*?\S+/,
    db:         '/dev/shm/promptparser.sqlite'

  lines = GUY.fs.walk_lines_with_positions flags.prompts

  prompt_db = new Prompt_db { cmd, flags, }
  debug 'Ω___6', name for { name, } from prompt_db.db SQL"""select name from sqlite_schema where type in ( 'table', 'view' );"""

  return null

  echo()
  echo ( GUY.trm.grey 'Ω___8' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
