

'use strict'


############################################################################################################
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
#...........................................................................................................
{ rpr
  inspect
  echo
  log     }               = GUY.trm
#...........................................................................................................
{ DATOM }                 = require 'datom'
#...........................................................................................................
{ new_datom
  lets
  stamp }                = DATOM
#...........................................................................................................
{ Interlex
  Syntax
  compose  }              = require 'intertext-lexer'
#...........................................................................................................
# { misfit
#   get_base_types }        = require './types'
# E                         = require './errors'
#...........................................................................................................
{ Pipeline
  $
  Transformer
  transforms }            = require 'moonriver'
{ U }                     = require './utilities'
{ build_file_db }         = require './file-cache-builder'



#===========================================================================================================
new_prompt_lexer = ( mode = 'plain' ) ->
  lexer   = new Interlex { dotall: false, }
  #.........................................................................................................
  do =>
    mode = 'plain'
    lexer.add_lexeme { mode, lxid: 'escchr',     jump: null,     pattern:  /\\(?<chr>.)/u,           }
    lexer.add_lexeme { mode, lxid: 'marksleft',  jump: '[marks', pattern:  /\[/u,                    }
    lexer.add_lexeme { mode, lxid: 'prompt',     jump: null,     pattern:  /[^\[\\]+/u,              }
  #.........................................................................................................
  do =>
    mode = 'marks'
    lexer.add_lexeme { mode, lxid: 'marksright', jump: '.]',     pattern:  /\]/u, reserved: ']',          }
    lexer.add_lexeme { mode, lxid: 'format',     jump: null,     pattern:  /[swh]/u,                      }
    lexer.add_lexeme { mode, lxid: 'ws',         jump: null,     pattern:  /\x20+/u,                      }
    lexer.add_lexeme { mode, lxid: 'multiplier', jump: null,     pattern:  /x[0-9]{1,2}/u,                }
    lexer.add_lexeme { mode, lxid: 'promptnr',   jump: null,     pattern:  /p#[0-9]+/u,                   }
    lexer.add_lexeme { mode, lxid: 'generation', jump: null,     pattern:  /[U01234]/u,                   }
    lexer.add_lexeme { mode, lxid: 'grade',      jump: null,     pattern:  /[-+A-Fvnr]+/u,                }
    lexer.add_lexeme { mode, lxid: 'comment',    jump: null,     pattern:  /(?:(?!(?:p#[0-9]|\])).)+/u,   }
    lexer.add_reserved_lexeme { mode, lxid: 'forbidden', concat: true, }
  #.........................................................................................................
  return lexer

#===========================================================================================================
class Prompt_parser extends Transformer

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    super()
    @_lexer   = new_prompt_lexer { state: 'reset', }
    @state =
      counts: { prompts: 0, lexemes: 0, }
    return undefined

  #---------------------------------------------------------------------------------------------------------
  $lex: -> ( source, send ) =>
    # urge 'Ω___1', rpr source
    send { $key: 'source', $value: source, }
    for lexeme from @_lexer.walk source
      # help 'Ω___2', "#{lexeme.$key.padEnd 20} #{rpr lexeme.value}"
      send lexeme
    return null

  #---------------------------------------------------------------------------------------------------------
  $show: -> ( d ) =>
    urge 'Ω___3', rpr d
    return null

  #---------------------------------------------------------------------------------------------------------
  $normalize_prompt: -> ( d, send ) =>
    return send d unless d.$key is 'plain:prompt'
    send stamp d
    send lets d, ( d ) -> d.value = U.normalize_prompt d.value
    return null

  #---------------------------------------------------------------------------------------------------------
  $normalize_generation: -> ( d, send ) =>
    return send d unless d.$key is 'marks:generation'
    send stamp d
    send lets d, ( d ) -> d.value = if ( /^\d$/.test d.value ) then parseInt d.value, 10 else 0
    return null

  #---------------------------------------------------------------------------------------------------------
  $normalize_comment: -> ( d, send ) =>
    return send d unless d.$key is 'marks:comment'
    send stamp d
    send lets d, ( d ) -> d.value = d.value.trim()
    return null

  #---------------------------------------------------------------------------------------------------------
  $stamp_extraneous: -> ( d, send ) =>
    switch true
      when d.$key is 'marks:marksleft'  then  send stamp  d
      when d.$key is 'marks:marksright' then  send stamp  d
      when d.$key is 'marks:grade'      then  send stamp  d
      when d.$key is 'marks:ws'         then  send stamp  d
      else                                    send        d
    return null

  #---------------------------------------------------------------------------------------------------------
  $count: -> ( d ) =>
    # urge 'Ω___4', d
    if d.$key is 'source' then  @state.counts.prompts++
    else                        @state.counts.lexemes++
    return null


#===========================================================================================================
class Prompt_file_reader # extends Dbay

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    # super()
    @_prompt_parser = new Prompt_parser()
    @_pipeline      = new Pipeline()
    # @_pipeline.push $show = ( source ) -> whisper 'Ω___5', rpr source
    @_pipeline.push @_prompt_parser
    # @_pipeline.push $show = ( d ) -> whisper 'Ω___6', d
    return undefined

  #---------------------------------------------------------------------------------------------------------
  parse: ( source ) ->
    # debug 'Ω___7', rpr source
    @_pipeline.send source
    R = @_pipeline.run()
    info 'Ω___8', GUY.trm.yellow GUY.trm.reverse @_prompt_parser.state
    return R

#-----------------------------------------------------------------------------------------------------------
demo_file_as_virtual_table = ->
  PATH                      = require 'node:path'
  FS                        = require 'node:fs'
  { DBay }                  = require 'dbay'
  { SQL  }                  = DBay
  #.........................................................................................................
  path                      = '/dev/shm/demo_file_as_virtual_table.sqlite'
  db                        = new DBay { path, }
  #.........................................................................................................
  initialize_db = ( db ) ->
    db ->
      # db SQL"drop table if exists myfile;"
      db.create_virtual_table
        name:   'file_contents'
        create: ( filename, P... ) ->
          urge 'Ω___9', { filename, P, }
          R =
            columns: [ 'lnr', 'line', ],
            rows: ->
              path  = PATH.resolve process.cwd(), filename
              ### TAINT read line-by-line ###
              lines = ( FS.readFileSync path, { encoding: 'utf-8', } ).split '\n'
              for line, line_idx in lines
                yield { lnr: line_idx + 1, line, }
              return null
          return R
      db SQL"""
        create virtual table contents_of_readme
          using file_contents( README.md, any stuff goes here, and more here );"""
    return null
  #.........................................................................................................
  debug 'Ω__10', U.get_db_table_names db
  debug 'Ω__11', U.db_has_all_table_names db, 'contents_of_readme'
  if U.db_has_all_table_names db, 'contents_of_readme'
    help "Ω__12 re-using DB at #{path}"
  else
    warn "Ω__13 initializing DB at #{path}"
    initialize_db db
  #.........................................................................................................
  result  = db.all_rows SQL"""select * from contents_of_readme where line != '' order by lnr;"""
  console.table result
  #.........................................................................................................
  return null



#===========================================================================================================
module.exports = {
  new_prompt_lexer,
  Prompt_file_reader, }

#===========================================================================================================
if module is require.main then await do =>
  # build_file_db()
  demo_file_as_virtual_table()
