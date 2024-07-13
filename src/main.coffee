

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
class Prompt_parsing_pipeline extends Transformer

  #---------------------------------------------------------------------------------------------------------
  $show: -> ( d ) -> urge 'Ω___1', d


#===========================================================================================================
class Prompt_parser

  #---------------------------------------------------------------------------------------------------------
  constructor: ( source ) ->
    # super()
    @_lexer   = new_prompt_lexer { state: 'reset', }
    @_parser  = Prompt_parsing_pipeline.as_pipeline()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  parse: ( source ) ->
    for d from @_lexer.walk source
      help 'Ω___6', "#{d.$key.padEnd 20} #{rpr d.value}"
      @_parser.send d
    return null


f = ->
      p = new Pipeline()
      p.push ( d, send ) ->
        return send d unless d.tid is 'p'
        send e for e from md_lexer.walk d.value
      p.push $parse_md_stars()
      p.send new_token '^æ19^', { start: 0, stop: probe.length, }, 'plain', 'p', null, probe
      result      = p.run()
      result_rpr  = ( d.value for d in result when not d.$stamped ).join ''
      urge '^08-1^', ( Object.keys d ).sort() for d in result
      H.tabulate "#{probe} -> #{result_rpr} (#{matcher})", result # unless result_rpr is matcher



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
  parser = new Prompt_parser()
  for prompt in prompts
    whisper 'Ω___4', '————————————————————————'
    urge 'Ω___5', rpr prompt
    info 'Ω___5', parser.parse prompt
  return null
  #.........................................................................................................
  # p = B.as_pipeline()
  # debug 'Ω___3', p.run_and_stop()
  # # T?.eq result, [ [ '*', 'a1', 'a2', 'a3', 'b1', '!b2!', 'b3' ] ]
  # process.exit 111

# #===========================================================================================================
# module.exports = {
#   _TEMP_add_lexemes
#   Markdown_sx
#   Standard_sx
#   Hypedown_lexer }
