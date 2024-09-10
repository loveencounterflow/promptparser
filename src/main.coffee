
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
WG                        = require 'webguy'
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
types                     = get_types()
{ trash }                 = require 'trash-sync'


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
  ### TAINT use CFG pattern ###
  constructor: ( match = null ) ->
    super()
    hide @, 'types', get_types()
    @_lexer   = new_prompt_lexer { state: 'reset', }
    @cfg      = { match, }
    @state    =
      counts: { prompts: 0, lexemes: 0, non_matches: 0, }
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _cast_token: ( lnr, token ) ->
    unless @types.isa.symbol token
      token = lets token, ( token ) -> token.lnr1 = token.lnr2 = lnr
    return token

  #---------------------------------------------------------------------------------------------------------
  $lex: -> ( row, send ) =>
    # urge 'Ω___2', GUY.trm.reverse GUY.trm.cyan GUY.trm.bold rpr row
    send { $key: 'row', $value: row, $stamped: true, }
    send @_cast_token row.lnr, token for token from @_lexer.walk row.line
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
  $filter_matching_prompts: ->
    parts = null
    return ( d, send ) =>
      return send d if d.$stamped
      #.....................................................................................................
      if d is start_of_line
        parts = []
        return null
      #.....................................................................................................
      if d is end_of_line
        if parts?
          send start_of_line
          send part for part in parts
          send end_of_line
        return null
      #.....................................................................................................
      if @cfg.match? and d.$key is 'prompt'
        @cfg.match.lastIndex = 0 ### TAINT ensure this becomes superfluous ###
        unless @cfg.match.test d.value
          @state.counts.non_matches++
          parts = null
          return null
      #.....................................................................................................
      parts.push d
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
    prerecord   = null
    current_lnr = null
    #.......................................................................................................
    return ( d, send ) =>
      return send d if d.$stamped
      #.....................................................................................................
      if d is start_of_line
        prerecord = @types.create.pp_prerecord_initial()
        return send d
      #.....................................................................................................
      if d is end_of_line
        ### TAINT use Datom API ###
        prerecord.lnr ?= current_lnr
        prerecord.lnr ?= 1
        send @types.create.pp_prerecord_final prerecord
        prerecord = null
        return send d
      #.....................................................................................................
      return send d unless d.$key in [ 'prompt', 'prompt_id', 'generations', 'comment', 'promptnr', 'rejected', ]
      #.....................................................................................................
      if d.lnr?
        current_lnr         = d.lnr
        prerecord.lnr       = d.lnr
      prerecord[ d.$key ] = d.value
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
        send { $key: 'record', prompt_id, table: 'generations', fields: { prompt_id, nr, count, }, }
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
    send { $key: 'record', prompt_id: d.prompt_id, table: 'prompts', fields, }
    return null

  #---------------------------------------------------------------------------------------------------------
  $show: -> ( d ) =>
    # urge 'Ω___3', rpr d # if d.$key is 'generation'
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
    # urge 'Ω___4', d
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
  @required_table_names: [ 'datasources', ]

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern ###
  constructor: ( db_path, datasource_path, trash_db = false ) ->
    hide @, 'types', get_types()
    @cfg  = @types.create.fm_constructor_cfg db_path, datasource_path, trash_db
    @_trash_db_if_necessary()
    #.......................................................................................................
    hide @, '_db', new DBay { path: @cfg.db_path, }
    #.......................................................................................................
    @_prepare_db_connection()
    @_create_db_structure_if_necessary()
    @_populate_db_if_necessary() if new.target is File_mirror
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _trash_db_if_necessary: ->
    return 0 unless @cfg.trash_db
    return trash @cfg.db_path

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    # whisper 'Ω___5', "File_mirror._prepare_db_connection"
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
  _get_required_table_names: -> new Set (
    ( p.required_table_names ? [] ) for p in WG.props.get_prototype_chain @constructor ).flat()

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure_if_necessary: ->
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      whisper 'Ω___6', "File_mirror::_create_db_structure_if_necessary: re-using DB at #{@cfg.db_path}"
    else
      whisper 'Ω___7', "File_mirror::_create_db_structure_if_necessary: creating structure of DB at #{@cfg.db_path}"
      @_create_db_structure()
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _clear_db : ->
    ### TAINT belongs to Prompt_file_reader ###
    ### TAINT use `_required_table_names` ###
    @_db =>
      @_db SQL"drop table if exists prompts;"
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    whisper 'Ω___8', "File_mirror::_create_db_structure"
    @_clear_db()
    @_db =>
      ### TAINT a more general solution should accommodate more than a single source file ###
      @_db SQL"""
        create table datasources (
            lnr       integer not null primary key,
            line      text    not null );"""
      return null
    return null

  #---------------------------------------------------------------------------------------------------------
  _populate_db_if_necessary: ->
    whisper 'Ω___9', "File_mirror::_populate_db_if_necessary"
    return 0 unless @cfg.auto_populate_db
    @_populate_db()
    return 1

  #---------------------------------------------------------------------------------------------------------
  _populate_db: ->
    ### TAINT throw error unless @cfg.auto_populate_db ###
    try
      @_db =>
        for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions @cfg.datasource_path
          @_db @_insert_into.datasources, { lnr, line, }
        return null
    catch error
      if error.code in [ 'ENOENT', 'EACCES', 'EPERM', ]
        whisper 'Ω__10', "File_mirror::_populate_db", U.color.bad \
          error.message
        process.exit 111
      throw error
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
  @required_table_names = [ 'prompts', 'generations', ]

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern, namespacing as in `file_mirror.path`, validation ###
  constructor: ( cmd, flags = null ) ->
    types           = get_types()
    cfg             = types.create.pfr_constructor_cfg cmd, flags, null
    super cfg.db_path, cfg.datasource_path, ( flags?.trash_db ? false )
    ### TAINT try to avoid constructing almost the same object twice ###
    @cfg            = @types.create.pfr_constructor_cfg cmd, flags, @cfg
    @_prompt_parser = new Prompt_parser @cfg.flags.match
    @_pipeline      = new Pipeline()
    @_pipeline.push @_prompt_parser
    #.......................................................................................................
    ### TAINT rather ad-hoc ###
    hide @, 'insert_into', insert_into = {}
    insert_into[ key ] = ( f.bind @ ) for key, f of @constructor.insert_into
    #.......................................................................................................
    @_populate_db_if_necessary() if new.target is Prompt_file_reader
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    super()
    whisper 'Ω__11', "Prompt_file_reader::_create_db_structure"
    @_db =>
      @_db SQL"""
        create table prompts (
            id        text    not null primary key,
            lnr       integer not null,
            prompt    text    not null,
            comment   text        null,
            rejected  boolean not null,
          unique( prompt ) );"""
      @_db SQL"""
        create table generations (
            prompt_id text    not null,
            nr        integer not null,
            count     integer not null,
          primary key ( prompt_id, nr ),
          foreign key ( prompt_id ) references prompts ( id ) );"""
      @_db SQL"""
        create view counts as select distinct
            prompt_id             as prompt_id,
            count(*)      over w  as generations,
            sum( count )  over w  as images
          from generations as g
          window w as ( partition by prompt_id );"""
      @_db SQL"""
        create view densities as select
            c.prompt_id                                                                         as prompt_id,
            c.generations                                                                       as generations,
            c.images                                                                            as images,
            cast( ( ( cast( c.images as real ) / c.generations / 4 ) * 100 + 0.5 ) as integer ) as density
          from generations as g
          left join counts as c on ( g.prompt_id = c.prompt_id );"""
      @_db SQL"""
        create view promptstats as select
            d.prompt_id     as prompt_id,
            d.generations   as generations,
            d.images        as images,
            d.density       as density
          from prompts    as p
          join densities  as d on ( p.id = d.prompt_id );"""
      @_db SQL"""
        create view rowcounts as
          select            null as name,         null as rowcount where false
          union all select  'prompts',            count(*)                from prompts
          union all select  'generations',        count(*)                from generations
          union all select  'counts',             count(*)                from counts
          union all select  'densities',          count(*)                from densities
          ;"""
      ### TAINT auto-generate ###
      hide @, '_insert_into',
        datasources:  @_db.create_insert { into: 'datasources',                                  }
        prompts:      @_db.create_insert { into: 'prompts',      on_conflict: { update: true, }, }
        generations:  @_db.create_insert { into: 'generations',                                  }
      return null
    return null

  #---------------------------------------------------------------------------------------------------------
  ### TAINT this should become a standard part of `DBay`; note that as with `@_required_table_names`,
  one should walk the prototype chain ###
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
  _populate_db: ->
    whisper 'Ω__12', "Prompt_file_reader::_populate_db"
    super()
    line_count              = 0
    blank_line_count        = 0
    read_prompt_count       = 0
    written_prompt_count    = 0
    unique_row_ids          = new Set()
    nonmatching_line_count  = 0
    unsampled_line_count    = 0
    #.......................................................................................................
    ### NOTE pre-caching source rows because it is fast, probably fits into available RAM, and results in
    much faster write performance. As such, concurrent writes are *still* a bit of a hurdle with SQLite. ###
    all_rows = @_db.all_rows SQL"""select * from datasources order by lnr;""" ### TAINT use API ###
    whisper 'Ω__13', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "read #{U.format_nr all_rows.length} lines from DB"
    #.......................................................................................................
    do =>
      ### NOTE this could / should be within a transaction but runs just as fast without one ###
      for row in all_rows
        line_count++
        whisper 'Ω__14', "Prompt_file_reader::_populate_db", GUY.trm.white \
          "line count: #{U.format_nr line_count, 8}" if line_count %% 1e3 is 0
        #...................................................................................................
        ### EXCLUDE EMPTY LINES ###
        if /^\s*$/.test row.line
          blank_line_count++
          continue
        #...................................................................................................
        ### --SAMPLE ###
        if Math.random() > @cfg.flags.sample
          unsampled_line_count++
          continue
        #...................................................................................................
        ### --MATCH ###
        if @cfg.flags.pre_match?
          @cfg.flags.pre_match.lastIndex = 0 ### TAINT ensure when constructing pre_match that lastIndex is never used ###
          unless @cfg.flags.pre_match.test row.line
            nonmatching_line_count++
            continue
        #...................................................................................................
        @_pipeline.send row
        #...................................................................................................
        for record from @_pipeline.walk()
          #.................................................................................................
          if record.table is 'prompts'
            read_prompt_count++
          #.................................................................................................
          { lastInsertRowid: row_id, } = @insert_into[ record.table ] record.fields
          if record.table is 'prompts'
            unique_row_ids.add row_id
            written_prompt_count = unique_row_ids.size
        #...................................................................................................
        ### --MAX-COUNT ###
        if written_prompt_count >= @cfg.flags.max_count
          whisper 'Ω__15', "Prompt_file_reader::_populate_db", GUY.trm.white \
            "stopping because prompt count exceeds max prompt count of #{U.format_nr @cfg.flags.max_count} prompts"
          break
      return null
    #.......................................................................................................
    written_prompt_count = @_db.single_value SQL"""select count(*) from prompts;""" ### TAINT use API ###
    #.......................................................................................................
    whisper 'Ω__16'
    whisper 'Ω__17', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "line count:                    +#{U.format_nr line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__18', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "blank line count:              –#{U.format_nr blank_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__19', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "'unsampled' line count:        –#{U.format_nr unsampled_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__20', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "non-pre-matching line count:   –#{U.format_nr nonmatching_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__21', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "non-matching prompt count:     –#{U.format_nr @_prompt_parser.state.counts.non_matches, 12}"
    #.......................................................................................................
    whisper 'Ω__22', "Prompt_file_reader::_populate_db", GUY.trm.white \
      "inserted #{U.format_nr written_prompt_count} rows into DB at #{@cfg.db_path}"
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  parse_all_records: ( source ) ->
    R = []
    for { lnr, line, eol, } from GUY.str.walk_lines_with_positions source
      @_pipeline.send { lnr, line, }
      R = R.concat @_pipeline.run()
    return R

  #---------------------------------------------------------------------------------------------------------
  parse_first_records: ( source ) ->
    prompt_id = null
    R         = []
    for record from @parse_all_records source
      prompt_id ?= record.prompt_id
      break unless prompt_id is record.prompt_id
      R.push record
    return R

  #---------------------------------------------------------------------------------------------------------
  parse_all_tokens: ( source ) ->
    R = []
    for { lnr, line, eol, } from GUY.str.walk_lines_with_positions source
      for token from @_prompt_parser._lexer.walk line
        continue if @types.isa.symbol token
        R.push @_prompt_parser._cast_token lnr, token
    return R

  #---------------------------------------------------------------------------------------------------------
  parse_first_tokens: ( source ) ->
    R     = []
    lnr1  = null
    for token from @parse_all_tokens source
      lnr1 ?= token.lnr1
      break if lnr1 isnt token.lnr1
      R.push token
    return R

  #---------------------------------------------------------------------------------------------------------
  insert: ( insertion_records ) ->
    insertion_records = @types.create.fm_insertion_records insertion_records
    R = 0
    for insertion_record in insertion_records
       change_record = @insert_into[ insertion_record.table ] insertion_record.fields
       R += change_record.changes
    return R

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
  echo()
  echo ( GUY.trm.grey 'Ω__23' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()