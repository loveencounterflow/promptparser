

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
{ DBay }                  = require 'dbay'
{ SQL  }                  = DBay
PATH                      = require 'node:path'
FS                        = require 'node:fs'



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
class File_mirror

  #---------------------------------------------------------------------------------------------------------
  @required_table_names: []

  #---------------------------------------------------------------------------------------------------------
  constructor: ( path ) ->
    @_db = new DBay { path, }
    @_prepare_file_mirror()
    #.......................................................................................................
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      help "Ω___5 re-using DB at #{path}"
    else
      warn "Ω___6 initializing DB at #{path}"
      @_initialize()
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _prepare_file_mirror: ->
    @_db =>
      @_db.create_table_function
        name:         'file_contents_t'
        columns:      [ 'lnr', 'line', 'eol', ]
        parameters:   [ 'filename', ]
        rows: ( filename ) ->
          path  = PATH.resolve process.cwd(), filename
          for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions path
            yield { lnr, line, eol, }
          return null
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _initialize: ->
    # @_db =>
    #   @_db SQL"drop table if exists ...;"
    #   @_db SQL"""
    #     create table ...
    return null

#===========================================================================================================
class Prompt_file_reader extends File_mirror

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern, namespacing as in `file_mirror.path`, validation ###
  constructor: ( file_mirror_path ) ->
    super file_mirror_path
    @_prompt_parser = new Prompt_parser()
    @_pipeline      = new Pipeline()
    # @_pipeline.push $show = ( source ) -> whisper 'Ω___9', rpr source
    @_pipeline.push @_prompt_parser
    # @_pipeline.push $show = ( d ) -> whisper 'Ω__10', d
    return undefined

  #---------------------------------------------------------------------------------------------------------
  parse: ( source ) ->
    # debug 'Ω__11', rpr source
    @_pipeline.send source
    R = @_pipeline.run()
    info 'Ω__12', GUY.trm.yellow GUY.trm.reverse @_prompt_parser.state
    return R


#-----------------------------------------------------------------------------------------------------------
demo_file_as_virtual_table = ->
  db = new Prompt_file_reader '/dev/shm/demo_file_as_virtual_table.sqlite'
  do ->
    result  = db._db.all_rows SQL"""select * from file_contents_t( './README.md' ) order by lnr;"""
    console.table result
  #.........................................................................................................
  return null



#===========================================================================================================
module.exports = {
  new_prompt_lexer,
  File_mirror,
  Prompt_file_reader, }

#===========================================================================================================
if module is require.main then await do =>
  # build_file_db()
  demo_file_as_virtual_table()
