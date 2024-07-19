

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
{ hide }                  = GUY.props
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
start_of_line             = Symbol 'start_of_line'
end_of_line               = Symbol 'end_of_line'
{ get_types }             = require './types'


#===========================================================================================================
new_prompt_lexer = ( mode = 'plain' ) ->
  #.........................................................................................................
  ### TAINT consider to make `enter_marks()` an instance method ###
  class Prompt_lexer extends Interlex
    #-------------------------------------------------------------------------------------------------------
    constructor: ->
      super { end_of_line, start_of_line, dotall: false, state: 'reset', }
      @user_state = { marks_done: false, }
      return undefined
    #-------------------------------------------------------------------------------------------------------
    reset: ->
      # help 'Ω___1', GUY.trm.reverse "reset", @user_state
      @user_state.marks_done = false
      # return super P...
    #-------------------------------------------------------------------------------------------------------
    enter_marks: ({ token, match, lexer, }) =>
      return null if @user_state.marks_done
      @user_state.marks_done = true
      return { jump: '[marks', }
  #.........................................................................................................
  lexer       = new Prompt_lexer()
  #.........................................................................................................
  do =>
    mode = 'plain'
    # lexer.add_lexeme { mode, lxid: 'escchr',     jump: null,     pattern:  /\\(?<chr>.)/u,           }
    # lexer.add_lexeme { mode, lxid: 'marksleft',  jump: '[marks', pattern:  /\[/u,                    }
    lexer.add_lexeme { mode, lxid: 'marksleft',  jump: ( ( P... ) -> lexer.enter_marks P... ), pattern:  /\[/u,                      }
    lexer.add_lexeme { mode, lxid: 'prompt',     jump: null,     pattern:  /[^\[]+/u,                     }
  #.........................................................................................................
  do =>
    mode = 'marks'
    lexer.add_lexeme { mode, lxid: 'marksright', jump: '.]',     pattern:  /\]/u, reserved: ']',          }
    lexer.add_lexeme { mode, lxid: 'wording',    jump: null,     pattern:  /WORDING/u,                    }
    lexer.add_lexeme { mode, lxid: 'format',     jump: null,     pattern:  /[swh]/u,                      }
    lexer.add_lexeme { mode, lxid: 'ws',         jump: null,     pattern:  /\x20+/u,                      }
    lexer.add_lexeme { mode, lxid: 'multiplier', jump: null,     pattern:  /x[0-9]{1,2}/u,                }
    lexer.add_lexeme { mode, lxid: 'promptnr',   jump: null,     pattern:  /p#[0-9]+/u,                   }
    lexer.add_lexeme { mode, lxid: 'generation', jump: null,     pattern:  /UNSAFE|[U01234]/u,            }
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
    hide @, 'types', get_types()
    @_lexer   = new_prompt_lexer { state: 'reset', }
    @state =
      counts: { prompts: 0, lexemes: 0, }
    return undefined

  #---------------------------------------------------------------------------------------------------------
  $lex: -> ( source, send ) =>
    urge 'Ω___2', GUY.trm.reverse GUY.trm.cyan GUY.trm.bold rpr source
    send { $key: 'source', $value: source, $stamped: true, }
    for lexeme from @_lexer.walk source
      # help 'Ω___3', "#{lexeme.$key.padEnd 20} #{rpr lexeme.value}"
      send lexeme
    return null

  #---------------------------------------------------------------------------------------------------------
  $normalize_generation: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'marks:generation'
    send stamp d
    send lets d, ( d ) -> d.value = if ( /^\d$/.test d.value ) then parseInt d.value, 10 else 0
    return null

  #---------------------------------------------------------------------------------------------------------
  $normalize_comment: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'marks:comment'
    send stamp d
    send lets d, ( d ) -> d.value = d.value.trim()
    return null

  #---------------------------------------------------------------------------------------------------------
  $consolidate_prompt: ->
    parts = null
    lnr   = null
    #.......................................................................................................
    return ( d, send ) =>
      return send d if d.$stamped
      #.....................................................................................................
      if d is start_of_line
        parts = []
        return send d
      #.....................................................................................................
      if d is end_of_line
        ### TAINT use Datom API ###
        token = { $key: 'prompt', value: ( parts.join [] ), lnr, }
        parts = lnr = null
        send token
        return send d
      #.....................................................................................................
      return send d unless d.$key?.startsWith 'plain:'
      #.....................................................................................................
      lnr ?= d.lnr1
      parts.push d.value
      return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $normalize_prompt: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'prompt'
    send stamp d
    send lets d, ( d ) -> d.value = U.normalize_prompt d.value
    return null

  #---------------------------------------------------------------------------------------------------------
  $consolidate_generations: ->
    ### TAINT code duplication ###
    parts = null
    lnr   = null
    #.......................................................................................................
    return ( d, send ) =>
      return send d if d.$stamped
      #.....................................................................................................
      if d is start_of_line
        parts = []
        return send d
      #.....................................................................................................
      if d is end_of_line
        ### TAINT use Datom API ###
        token = { $key: 'generations', value: parts, lnr, }
        parts = lnr = null
        send token
        return send d
      #.....................................................................................................
      # return send d unless d.$key in [ 'marks:format', 'marks:generation', ]
      return send d unless d.$key in [ 'marks:generation', ]
      #.....................................................................................................
      lnr ?= d.lnr1
      parts.push d.value
      return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $consolidate_comments: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'marks:comment'
    send lets d, ( d ) -> d.$key = 'comment'
    return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $consolidate_rejected: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'marks:wording'
    send lets d, ( d ) -> d.$key = 'rejected'; d.value = true
    return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $consolidate_promptnr: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'marks:promptnr'
    send lets d, ( d ) -> d.$key = 'promptnr'
    return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $assemble_records: ->
    ### TAINT code duplication ###
    prerecord = null
    lnr       = null
    #.......................................................................................................
    return ( d, send ) =>
      lnr ?= d.lnr1 ? d.lnr
      return send d if d.$stamped
      #.....................................................................................................
      if d is start_of_line
        prerecord = @types.create.pp_prerecord_initial()
        return send d
      #.....................................................................................................
      if d is end_of_line
        ### TAINT use Datom API ###
        send @types.create.pp_prerecord_final prerecord
        prerecord = null
        return send d
      #.....................................................................................................
      return send d unless d.$key in [ 'prompt', 'generations', 'comment', 'promptnr', 'rejected', ]
      #.....................................................................................................
      prerecord.lnr       ?= lnr
      prerecord[ d.$key ]  = d.value
      return send stamp d

  # #---------------------------------------------------------------------------------------------------------
  # $show: -> ( d ) =>
  #   urge 'Ω___5', rpr d
  #   return null

  #---------------------------------------------------------------------------------------------------------
  $stamp_extraneous: -> ( d, send ) =>
    switch true
      when d.$key is 'marks:marksleft'  then  send stamp  d
      when d.$key is 'marks:marksright' then  send stamp  d
      when d.$key is 'marks:grade'      then  send stamp  d
      when d.$key is 'marks:ws'         then  send stamp  d
      when d.$key is 'marks:$eof'       then  send stamp  d
      when d.$key is 'plain:$eof'       then  send stamp  d
      else                                    send        d
    return null

  #---------------------------------------------------------------------------------------------------------
  $filter_stamped: -> ( d, send ) =>
    send d if ( d isnt start_of_line ) and ( d isnt end_of_line ) and ( not d.$stamped )
    return null

  #---------------------------------------------------------------------------------------------------------
  $count: -> ( d ) =>
    # urge 'Ω___6', d
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
    @_prepare_db_connection()
    #.......................................................................................................
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      help "Ω___7 re-using DB at #{path}"
    else
      warn "Ω___8 creating structure of DB at #{path}"
      @_create_db_structure()
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    whisper "Ω___9 File_mirror._prepare_db_connection"
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
  _create_db_structure: ->
    whisper "Ω__10 File_mirror._create_db_structure"
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
    # @_pipeline.push $show = ( source ) -> whisper 'Ω__11', rpr source
    @_pipeline.push @_prompt_parser
    # @_pipeline.push $show = ( d ) -> whisper 'Ω__12', d
    return undefined

  #---------------------------------------------------------------------------------------------------------
  parse: ( source ) ->
    # debug 'Ω__13', rpr source
    @_pipeline.send source
    R = @_pipeline.run()
    # info 'Ω__14', GUY.trm.yellow GUY.trm.reverse @_prompt_parser.state
    info 'Ω__15', GUY.trm.reverse GUY.trm.bold GUY.trm.gold R.at -1
    # debug 'Ω__16', ( "#{t.$key}#{rpr t.value}" for t in R ).join '|'
    return R

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    super()
    whisper "Ω__17 Prompt_file_reader._create_db_structure"
    # @_db =>
    #   @_db SQL"drop table if exists ...;"
    #   @_db SQL"""
    #     create table ...
    return null

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    super()
    whisper "Ω__18 Prompt_file_reader._prepare_db_connection"
    @_db.create_function name: 'square', deterministic: true, varargs: false, call: ( n ) -> n ** 2
    @_db.create_function
      name:           'parse'
      deterministic:  true
      varargs:        false
      call:           ( prompt ) => JSON.stringify @parse prompt
    #.......................................................................................................
    return null


#-----------------------------------------------------------------------------------------------------------
demo_file_as_virtual_table = ->
  db = new Prompt_file_reader '/dev/shm/demo_file_as_virtual_table.sqlite'
  do ->
    result  = db._db.all_rows SQL"""
      select
          *,
          square( lnr ) as lnr2,
          parse( line ) as prompt
        from file_contents_t( './data/short-prompts.md' ) order by lnr;"""
    # console.table result
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

