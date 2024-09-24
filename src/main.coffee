
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
{ DATOM }                 = require 'datom'
{ new_datom
  lets
  stamp }                 = DATOM
#...........................................................................................................
{ Journal_walker  }       = require './journal-walker'
{ Image_walker    }       = require './image-walker'
{ DBay            }       = require 'dbay'
{ SQL             }       = DBay
# { U               }       = require './utilities'
# { trash           }       = require 'trash-sync'
{ Prompt_db       }       = require './prompt-db'


#===========================================================================================================
known_path_ids  = null
lines           = null
cmd             = 'build'
flags           =
  match:      /(?:)/,
  trash_db:   true,
  # sample:     0.01,
  # max_count:  20,
  sample:     0.01,
  max_count:  Infinity,
  prompts:    '../../jzr/to-be-merged-from-Atlas/prompts-consolidated.md'
  images:     '../../Downloads/b-from-downloader'
  seed:       1,
  pre_match:  /^\[.*?\].*?\S+/,
  db:         '/dev/shm/promptparser.sqlite'

#===========================================================================================================
run_journal_walker = ( prompt_db ) ->
  lines = GUY.fs.walk_lines_with_positions flags.prompts
  yield from new Journal_walker { cmd, flags, lines, }
  return null

#===========================================================================================================
run_image_walker = ( prompt_db ) ->
  known_path_ids  = prompt_db.img_get_known_path_ids()
  yield from new Image_walker { known_path_ids, }
  return null

#===========================================================================================================
if module is require.main then await do =>
  prompt_db = new Prompt_db { cmd, flags, }
  do =>
    count = 0
    for d from run_image_walker prompt_db
      count++; break if count > flags.max_count
      prompt_db.insert_into[ d.table ] d.fields
    return null
  do =>
    for d from run_journal_walker prompt_db
      prompt_db.insert_into[ d.table ] d.fields
    return null


  return null

  echo()
  echo ( GUY.trm.grey 'Ω___4' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
