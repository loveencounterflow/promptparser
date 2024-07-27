

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

###

8888888b.  8888888b.   .d88888b.  888b     d888 8888888b. 88888888888   888      8888888888 Y88b   d88P 8888888888 8888888b.
888   Y88b 888   Y88b d88P" "Y88b 8888b   d8888 888   Y88b    888       888      888         Y88b d88P  888        888   Y88b
888    888 888    888 888     888 88888b.d88888 888    888    888       888      888          Y88o88P   888        888    888
888   d88P 888   d88P 888     888 888Y88888P888 888   d88P    888       888      8888888       Y888P    8888888    888   d88P
8888888P"  8888888P"  888     888 888 Y888P 888 8888888P"     888       888      888           d888b    888        8888888P"
888        888 T88b   888     888 888  Y8P  888 888           888       888      888          d88888b   888        888 T88b
888        888  T88b  Y88b. .d88P 888   "   888 888           888       888      888         d88P Y88b  888        888  T88b
888        888   T88b  "Y88888P"  888       888 888           888       88888888 8888888888 d88P   Y88b 8888888888 888   T88b

###



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

###

8888888b.  8888888b.   .d88888b.  888b     d888 8888888b.  88888888888  8888888b.      d8888  8888888b.   .d8888b.  8888888888 8888888b.
888   Y88b 888   Y88b d88P" "Y88b 8888b   d8888 888   Y88b     888      888   Y88b    d88888  888   Y88b d88P  Y88b 888        888   Y88b
888    888 888    888 888     888 88888b.d88888 888    888     888      888    888   d88P888  888    888 Y88b.      888        888    888
888   d88P 888   d88P 888     888 888Y88888P888 888   d88P     888      888   d88P  d88P 888  888   d88P  "Y888b.   8888888    888   d88P
8888888P"  8888888P"  888     888 888 Y888P 888 8888888P"      888      8888888P"  d88P  888  8888888P"      "Y88b. 888        8888888P"
888        888 T88b   888     888 888  Y8P  888 888            888      888       d88P   888  888 T88b         "888 888        888 T88b
888        888  T88b  Y88b. .d88P 888   "   888 888            888      888      d8888888888  888  T88b  Y88b  d88P 888        888  T88b
888        888   T88b  "Y88888P"  888       888 888            888      888     d88P     888  888   T88b  "Y8888P"  8888888888 888   T88b

###


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
  $add_prompt_id: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'prompt'
    send d
    send lets d, ( d ) -> d.$key = 'prompt_id'; d.value = U.id_from_text d.value

  #---------------------------------------------------------------------------------------------------------
  $assemble_prerecords: ( d, send ) ->
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
      return send d unless d.$key in [ 'prompt', 'prompt_id', 'generations', 'comment', 'promptnr', 'rejected', ]
      #.....................................................................................................
      prerecord.lnr       ?= lnr
      prerecord[ d.$key ]  = d.value
      return send stamp d

  #---------------------------------------------------------------------------------------------------------
  $assemble_generation_records: ->
    prompt_id = null
    nrs       = new Map()
    #.......................................................................................................
    return ( d, send ) =>
      return send d if d.$stamped
      return send d unless d.$key is 'prerecord'
      send d
      #.....................................................................................................
      ### TAINT hide this in custom class ###
      prompt_id = d.prompt_id
      unless ( nr = nrs.get prompt_id )?
        nrs.set prompt_id, 0
        nr = 0
      #.....................................................................................................
      for count in d.generations
        nr++
        send { $key: 'record', table: 'generations', fields: { prompt_id, nr, count, }, }
      nrs.set prompt_id, nr
      return null

  #---------------------------------------------------------------------------------------------------------
  $assemble_prompt_records: -> ( d, send ) =>
    return send d if d.$stamped
    return send d unless d.$key is 'prerecord'
    send d
    fields =
      id:         d.prompt_id
      lnr:        d.lnr
      prompt:     d.prompt
      comment:    d.comment
      rejected:   d.rejected
    send { $key: 'record', table: 'prompts', fields, }
    return null

  #---------------------------------------------------------------------------------------------------------
  $show: -> ( d ) =>
    # urge 'Ω___4', rpr d # if d.$key is 'generation'
    return null

  #---------------------------------------------------------------------------------------------------------
  $stamp_extraneous: -> ( d, send ) =>
    switch true
      when d.$key isnt 'record'         then  send  stamp d
      else                                    send        d
    return null

  #---------------------------------------------------------------------------------------------------------
  $filter_stamped: -> ( d, send ) =>
    send d if ( d isnt start_of_line ) and ( d isnt end_of_line ) and ( not d.$stamped )
    return null

  #---------------------------------------------------------------------------------------------------------
  $count: -> ( d ) =>
    # urge 'Ω___5', d
    if d.$key is 'source' then  @state.counts.prompts++
    else                        @state.counts.lexemes++
    return null


###

8888888888 8888888 888      8888888888   888b     d888 8888888 8888888b.  8888888b.   .d88888b.  8888888b.
888          888   888      888          8888b   d8888   888   888   Y88b 888   Y88b d88P" "Y88b 888   Y88b
888          888   888      888          88888b.d88888   888   888    888 888    888 888     888 888    888
8888888      888   888      8888888      888Y88888P888   888   888   d88P 888   d88P 888     888 888   d88P
888          888   888      888          888 Y888P 888   888   8888888P"  8888888P"  888     888 8888888P"
888          888   888      888          888  Y8P  888   888   888 T88b   888 T88b   888     888 888 T88b
888          888   888      888          888   "   888   888   888  T88b  888  T88b  Y88b. .d88P 888  T88b
888        8888888 88888888 8888888888   888       888 8888888 888   T88b 888   T88b  "Y88888P"  888   T88b

###

#===========================================================================================================
class File_mirror

  #---------------------------------------------------------------------------------------------------------
  @required_table_names: [ 'prompts', ]

  #---------------------------------------------------------------------------------------------------------
  constructor: ( path ) ->
    hide @, 'types', get_types()
    @cfg  = @types.create.fm_constructor_cfg path
    hide @, '_db', new DBay { path, }
    #.......................................................................................................
    ### TAINT rather ad-hoc ###
    hide @, 'insert_into', insert_into = {}
    insert_into[ key ] = ( f.bind @ ) for key, f of @constructor.insert_into
    #.......................................................................................................
    @_prepare_db_connection()
    @_create_db_structure_if_necessary()
    @_acquire_datasources_if_necessary()
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    # whisper "Ω___6 File_mirror._prepare_db_connection"
    # @_db =>
    #   @_db.create_table_function
    #     name:         'file_contents_t'
    #     columns:      [ 'lnr', 'line', 'eol', ]
    #     parameters:   [ 'filename', ]
    #     rows: ( filename ) ->
    #       path  = PATH.resolve process.cwd(), filename
    #       for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions path
    #         yield { lnr, line, eol, }
    #       return null
    #   return null
    # #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure_if_necessary: ->
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      help "Ω___7 re-using DB at #{@cfg.path}"
    else
      warn "Ω___8 creating structure of DB at #{@cfg.path}"
      @_create_db_structure()
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    whisper "Ω___9 File_mirror._create_db_structure"
    @_db =>
      @_db SQL"drop table if exists prompts;"
      ### TAINT a more general solution should accommodate more than a single source file ###
      @_db SQL"""
        create table datasources (
            lnr       integer not null primary key,
            line      text    not null );"""
      @_db SQL"""
        create table prompts (
            id        text    not null primary key,
            lnr       integer not null,
            prompt    text    not null,
            comment   text        null,
            rejected  boolean not null );"""
      @_db SQL"""
        create table generations (
            prompt_id text    not null,
            nr        integer not null,
            count     integer not null,
          primary key ( prompt_id, nr ),
          foreign key ( prompt_id ) references prompts ( id ) );"""
      hide @, '_insert_into',
        datasources:  @_db.create_insert { into: 'datasources',                                  }
        prompts:      @_db.create_insert { into: 'prompts',      on_conflict: { update: true, }, }
        generations:  @_db.create_insert { into: 'generations',                                  }
      return null
    return null

  #---------------------------------------------------------------------------------------------------------
  @insert_into:
    #.......................................................................................................
    datasources: ( d ) ->
      ### TAINT validate? ###
      return @_db.alt @_insert_into.datasources, d
    #.......................................................................................................
    prompts: ( d ) ->
      ### TAINT validate? ###
      return @_db.alt @_insert_into.prompts, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0
    #.......................................................................................................
    generations: ( d ) ->
      ### TAINT validate? ###
      return @_db.alt @_insert_into.generations, d

  #---------------------------------------------------------------------------------------------------------
  _acquire_datasources_if_necessary: ->
    @_acquire_datasources()
    return null

  #---------------------------------------------------------------------------------------------------------
  _acquire_datasources: ->
    ### TAINT replace hardcoded datasource path ###
    @_db =>
      for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions './data/short-prompts.md'
        @_db @_insert_into.datasources, { lnr, line, }
    return null

###

8888888888 8888888 888      8888888888   8888888b.  8888888888        d8888  8888888b.  8888888888 8888888b.
888          888   888      888          888   Y88b 888              d88888  888  "Y88b 888        888   Y88b
888          888   888      888          888    888 888             d88P888  888    888 888        888    888
8888888      888   888      8888888      888   d88P 8888888        d88P 888  888    888 8888888    888   d88P
888          888   888      888          8888888P"  888           d88P  888  888    888 888        8888888P"
888          888   888      888          888 T88b   888          d88P   888  888    888 888        888 T88b
888          888   888      888          888  T88b  888         d8888888888  888  .d88P 888        888  T88b
888        8888888 88888888 8888888888   888   T88b 8888888888 d88P     888  8888888P"  8888888888 888   T88b

###

#===========================================================================================================
class Prompt_file_reader extends File_mirror

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern, namespacing as in `file_mirror.path`, validation ###
  constructor: ( file_mirror_path ) ->
    super file_mirror_path
    @_prompt_parser = new Prompt_parser()
    @_pipeline      = new Pipeline()
    @_pipeline.push @_prompt_parser
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    super()
    whisper "Ω__16 Prompt_file_reader._prepare_db_connection"
    #.......................................................................................................
    return null


#-----------------------------------------------------------------------------------------------------------
demo_file_as_virtual_table = ->
  db = new Prompt_file_reader '/dev/shm/prompts-and-generations.sqlite'
  db._db =>
    for row from db._db SQL"""select * from datasources order by lnr;"""
      debug 'Ω__10', row
      help 'Ω__11', db._pipeline.send row.line
      for record from db._pipeline.walk()
        info 'Ω__12', record
        db.insert_into[ record.table ] record.fields
  #.........................................................................................................
  return null

###

8888888888  .d88888b.  8888888888
888        d88P" "Y88b 888
888        888     888 888
8888888    888     888 8888888
888        888     888 888
888        888     888 888
888        Y88b. .d88P 888
8888888888  "Y88888P"  888

###


#===========================================================================================================
module.exports = {
  new_prompt_lexer,
  File_mirror,
  Prompt_file_reader, }

#===========================================================================================================
if module is require.main then await do =>
  # build_file_db()
  demo_file_as_virtual_table()

