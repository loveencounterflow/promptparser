

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


# #===========================================================================================================
# class Hypedown_parser

#   #---------------------------------------------------------------------------------------------------------
#   constructor: ( cfg ) ->
#     @types        = get_base_types()
#     @cfg          = Object.freeze @types.create.hd_parser_cfg cfg
#     @lexer        = new Hypedown_lexer()
#     # debug '^234^', @lexer
#     @_build_pipeline()
#     return undefined

#   #---------------------------------------------------------------------------------------------------------
#   _build_pipeline: ->
#     tfs       = new XXX_Hypedown_transforms()
#     @pipeline = new Pipeline()
#     #.........................................................................................................
#     @pipeline.push new XXX_TEMP.$001_prelude()
#     @pipeline.push new XXX_TEMP.$002_tokenize_lines()
#     @pipeline.push new XXX_TEMP.$010_prepare_paragraphs()
#     @pipeline.push new XXX_TEMP.$020_priority_markup()
#     @pipeline.push new XXX_TEMP.$030_htmlish_tags()
#     @pipeline.push new XXX_TEMP.$040_stars()
#     @pipeline.push new XXX_TEMP.$050_hash_headings()
#     @pipeline.push tfs.$capture_text()
#     @pipeline.push tfs.$generate_missing_p_tags()
#     @pipeline.push tfs.$generate_html_nls { mode: 'plain', tid: 'nl', } ### NOTE removes virtual nl, should come late ###
#     @pipeline.push tfs.$convert_escaped_chrs()
#     @pipeline.push tfs.$stamp_borders()
#     # @pipeline.push ( d ) -> urge '^_build_pipeline@5^', rpr d
#     return null

#   #---------------------------------------------------------------------------------------------------------
#   send:       ( P... ) -> @pipeline.send P...
#   run:        ( P... ) -> @pipeline.run  P...
#   walk:       ( P... ) -> @pipeline.walk P...
#   stop_walk:  ( P... ) -> @pipeline.stop_walk P...
#   step:       ( P... ) -> @pipeline.step P...

# f = ->
#   p = new Pipeline()
#   p.push ( d, send ) ->
#     return send d unless d.tid is 'p'
#     send e for e from md_lexer.walk d.value
#   p.push $parse_md_stars()
#   p.send new_token '^æ19^', { start: 0, stop: probe.length, }, 'plain', 'p', null, probe
#   result      = p.run()
#   result_rpr  = ( d.value for d in result when not d.$stamped ).join ''
#   urge '^08-1^', ( Object.keys d ).sort() for d in result
#   H.tabulate "#{probe} -> #{result_rpr} (#{matcher})", result # unless result_rpr is matcher


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
    send lets d, ( d ) -> d.value = d.value.trim()

  #---------------------------------------------------------------------------------------------------------
  $count: -> ( d ) =>
    # urge 'Ω___4', d
    if d.$key is 'source' then  @state.counts.prompts++
    else                        @state.counts.lexemes++
    return null


#===========================================================================================================
class Wwwww # extends Dbay

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




#===========================================================================================================
do =>
  prompts = [
    "[s324w1 some remark] my prompt"
    "[A++v 212] other prompt"
    "[A++v 212 but no cigar] other prompt"
    "[B 2x3 p#3014] Altbau, Versuchsraum, Institut"
    "[WORDING p#4420]"
    "[UNSAFE p#38]"
    "[+++ + p#41]"
    "[meh p#53]"
    "[UU]"
    "[A+v U1UU]"
    "[A++v 22 but not following directions] \t foo bar   "
    "[A++v 22 but not following directions p#7765] \t foo bar   "
    ""
    "[]"
    "just a prompt"
    "     just a prompt"
    "     [324] a prompt"
    ]
  parser = new Wwwww()
  whisper 'Ω___9', '————————————————————————'
  for prompt in prompts
    whisper 'Ω__10', '————————————————————————'
    for d in parser.parse prompt
      try
        switch true
          when d.$key is 'source' then  urge    'Ω__11', GUY.trm.reverse rpr d.$value
          when d.$stamped         then  whisper 'Ω__12', "#{d.$key.padEnd 20} #{rpr d.value}"
          else                          info    'Ω__13', "#{d.$key.padEnd 20} #{rpr d.value}"
      catch error
        warn 'Ω__14', error.message
        whisper 'Ω__15', d
  return null
  #.........................................................................................................
  # p = B.as_pipeline()
  # debug 'Ω__16', p.run_and_stop()
  # # T?.eq result, [ [ '*', 'a1', 'a2', 'a3', 'b1', '!b2!', 'b3' ] ]
  # process.exit 111

# #===========================================================================================================
# module.exports = {
#   _TEMP_add_lexemes
#   Markdown_sx
#   Standard_sx
#   Hypedown_lexer }
