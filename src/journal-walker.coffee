
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
  whisper }               = GUY.trm.get_loggers 'promptparser/production-registry'
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
{ Pipeline
  $
  Transformer
  transforms }            = require 'moonriver'
{ U }                     = require './utilities'
start_of_line             = Symbol 'start_of_line'
end_of_line               = Symbol 'end_of_line'
{ get_types }             = require './types'
types                     = get_types()


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
        send { $key: 'record', prompt_id, table: 'prd_generations', fields: { prompt_id, nr, count, }, }
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
    send { $key: 'record', prompt_id: d.prompt_id, table: 'prd_prompts', fields, }
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
class Journal_walker

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    hide @, 'types',          get_types()
    @cfg                      = @types.create.pfr_constructor_cfg cfg
    hide @, 'prompt_parser',  new Prompt_parser @cfg.flags.match
    hide @, 'pipeline',       new Pipeline()
    @pipeline.push @prompt_parser
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  [Symbol.iterator]: ->
    whisper 'Ω___5', "Journal_walker::[Symbol.iterator]"
    line_count              = 0
    blank_line_count        = 0
    read_prompt_count       = 0
    written_prompt_count    = 0
    nonmatching_line_count  = 0
    unsampled_line_count    = 0
    #.......................................................................................................
    for row from @cfg.lines
      line_count++
      whisper 'Ω___6', "Journal_walker::_populate_db", GUY.trm.white \
        "line count: #{U.format_nr line_count, 8}" if line_count %% 1e3 is 0
      #.....................................................................................................
      ### EXCLUDE EMPTY LINES ###
      if /^\s*$/.test row.line
        blank_line_count++
        continue
      #.....................................................................................................
      ### --SAMPLE ###
      if Math.random() > @cfg.flags.sample
        unsampled_line_count++
        continue
      #.....................................................................................................
      ### --MATCH ###
      if @cfg.flags.pre_match?
        @cfg.flags.pre_match.lastIndex = 0 ### TAINT ensure when constructing pre_match that lastIndex is never used ###
        unless @cfg.flags.pre_match.test row.line
          nonmatching_line_count++
          continue
      #.....................................................................................................
      @pipeline.send row
      #.....................................................................................................
      for record from @pipeline.walk()
        #...................................................................................................
        if record.table is 'prd_prompts'
          read_prompt_count++
        written_prompt_count++
        yield record
      #.....................................................................................................
      ### --MAX-COUNT ###
      if written_prompt_count >= @cfg.flags.max_count
        whisper 'Ω___7', "Journal_walker::_populate_db", GUY.trm.white \
          "stopping because prompt count exceeds max prompt count of #{U.format_nr @cfg.flags.max_count} prompts"
        break
    #.......................................................................................................
    whisper 'Ω___8'
    whisper 'Ω___9', "Journal_walker::_populate_db", GUY.trm.white \
      "line count:                    +#{U.format_nr line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__10', "Journal_walker::_populate_db", GUY.trm.white \
      "blank line count:              –#{U.format_nr blank_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__11', "Journal_walker::_populate_db", GUY.trm.white \
      "'unsampled' line count:        –#{U.format_nr unsampled_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__12', "Journal_walker::_populate_db", GUY.trm.white \
      "non-pre-matching line count:   –#{U.format_nr nonmatching_line_count, 12}"
    #.......................................................................................................
    whisper 'Ω__13', "Journal_walker::_populate_db", GUY.trm.white \
      "non-matching prompt count:     –#{U.format_nr @prompt_parser.state.counts.non_matches, 12}"
    #.......................................................................................................
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
  Journal_walker, }


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

  for d from new Journal_walker { cmd, flags, lines, }
    debug 'Ω__14', d

  return null


  echo()
  echo ( GUY.trm.grey 'Ω__15' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
