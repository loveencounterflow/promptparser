

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
  whisper }               = GUY.trm.get_loggers 'HYPEDOWN/HYPEDOWN-LEXER'
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


#===========================================================================================================
class Standard_sx extends Syntax

  #---------------------------------------------------------------------------------------------------------
  @mode: 'plain'

  #---------------------------------------------------------------------------------------------------------
  # @lx_backslash_escape:  { tid: 'escchr', jump: null, pattern: /\\(?<chr>.)/u, reserved: '\\', }



#===========================================================================================================
class Markdown_sx extends Syntax

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    super { cfg..., }
    return undefined

  #---------------------------------------------------------------------------------------------------------
  @lx_variable_codespan: ( cfg ) ->
    backtick_count  = null
    #.......................................................................................................
    entry_handler = ({ token, match, lexer, }) =>
      backtick_count = token.value.length
      return '[cspan'
    #.......................................................................................................
    exit_handler = ({ token, match, lexer, }) ->
      # debug '^534^', token
      # debug '^534^', match
      # debug '^534^', token.value.length, backtick_count
      if token.value.length is backtick_count
        backtick_count = null
        return '.]'
      ### TAINT setting `token.mk` should not have to be done manually ###
      token = lets token, ( token ) -> token.tid = 'text'; token.mk = "#{token.mode}:text"
      return { token, }
    #.......................................................................................................
    # info '^3531^', @cfg
    return [
      { mode: 'plain',    tid: 'start',  jump: entry_handler,  pattern:  /(?<!`)`+(?!`)/u, reserved: '`', }
      { mode: 'cspan',    tid: 'stop',   jump: exit_handler,   pattern:  /(?<!`)`+(?!`)/u, reserved: '`', }
      ( new_nl_descriptor     'cspan' )
      ( new_escchr_descriptor 'cspan' )
      ### NOTE this should be produced with `lexer.add_catchall_lexeme()` ###
      # { mode: 'cspan', tid: 'text',      jump: null,           pattern:  /(?:\\`|[^`])+/u,  }
      { mode: 'cspan', tid: 'text',      jump: null,           pattern:  /[^`\\]+/u,  }
      ]

  #---------------------------------------------------------------------------------------------------------
  # @lx_nl:  /$/u

  #---------------------------------------------------------------------------------------------------------
  @lx_star1:  { tid: 'star1', pattern: /(?<!\*)\*(?!\*)/u,      reserved: '*', }
  @lx_star2:  { tid: 'star2', pattern: /(?<!\*)\*\*(?!\*)/u,    reserved: '*', }
  @lx_star3:  { tid: 'star3', pattern: /(?<!\*)\*\*\*(?!\*)/u,  reserved: '*', }

  #---------------------------------------------------------------------------------------------------------
  @lx_hashes:  /^(?<text>#{1,6})($|\s+)/u


#===========================================================================================================
class Hypedown_lexer extends Interlex

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    super { linewise: true, border_tokens: true, }
    _TEMP_add_lexemes @
    standard_sx       = new Standard_sx()
    markdown_sx       = new Markdown_sx()
    lexemes_lst       = []
    standard_sx.add_lexemes lexemes_lst
    markdown_sx.add_lexemes lexemes_lst
    @add_lexeme lexeme for lexeme in lexemes_lst
    # @add_catchall_lexeme { mode: 'standard', }
    # @add_reserved_lexeme { mode: 'standard', }
    return undefined

  #---------------------------------------------------------------------------------------------------------
  step: ( P... ) ->
    return GUY.lft.lets ( super P... ), ( tokens ) ->
      delete token.source for token in tokens
      return null
    return R

#-----------------------------------------------------------------------------------------------------------
new_escchr_descriptor = ( mode ) ->
  create = ( token ) ->
    token.data = { chr: '\n', } unless ( token.data?.chr )?
    return token
  return { mode, tid: 'escchr', pattern: /\\(?<chr>.|$)/u, reserved: '\\', create, }

#-----------------------------------------------------------------------------------------------------------
new_nl_descriptor = ( mode ) ->
  ### TAINT consider to force value by setting it in descriptor (needs interlex update) ###
  create = ( token ) ->
    token.value = '\n'
    return token
  return { mode, tid: 'nl', pattern: /$/u, create, }

#-----------------------------------------------------------------------------------------------------------
_TEMP_add_lexemes = ( lexer ) ->
  # lexer.add_lexeme { mode, tid: 'eol',      pattern: ( /$/u  ), }
  #.........................................................................................................
  do =>
    mode = 'plain'
    lexer.add_lexeme new_escchr_descriptor  mode
    lexer.add_lexeme new_nl_descriptor      mode
    lexer.add_lexeme { mode,  tid: 'amp',       jump: '[xncr',    pattern: /&(?=[^\s\\]+;)/, reserved: '&', } # only match if ahead of (no ws, no bslash) + semicolon
    lexer.add_lexeme { mode,  tid: 'c_s',       jump: '[tag]',    pattern: '/',              reserved: '/', }
    lexer.add_lexeme { mode,  tid: 'c_lsr',     jump: '[tag]',    pattern: '</>',            reserved: '<', }
    lexer.add_lexeme { mode,  tid: 'c_ls',      jump: '[tag',     pattern: /<\/(?!>)/,       reserved: '<', }
    lexer.add_lexeme { mode,  tid: 'ltbang',    jump: '[comment', pattern: '<!--',           reserved: '<', }
    lexer.add_lexeme { mode,  tid: 'lt',        jump: '[tag',     pattern: '<',              reserved: '<', }
    lexer.add_lexeme { mode,  tid: 'ws',        jump: null,       pattern: /\s+/u, }
    lexer.add_catchall_lexeme { mode, tid: 'other', concat: true, }
    lexer.add_reserved_lexeme { mode, tid: 'forbidden', concat: true, }
  #.........................................................................................................
  do =>
    mode = 'tag'
    lexer.add_lexeme new_escchr_descriptor  mode
    lexer.add_lexeme new_nl_descriptor      mode
    # lexer.add_lexeme { mode,  tid: 'tagtext',   jump: null,       pattern: ( /[^\/>]+/u ), }
    lexer.add_lexeme { mode,  tid: 'dq',        jump: 'tag:dq[',  pattern: '"',       reserved: '"' }
    lexer.add_lexeme { mode,  tid: 'sq',        jump: 'tag:sq[',  pattern: "'",       reserved: "'" }
    lexer.add_lexeme { mode,  tid: 'slashgt',   jump: '.]',       pattern: '/>',      reserved: [ '>', '/', ] }
    lexer.add_lexeme { mode,  tid: 'slash',     jump: '.]',       pattern: '/',       reserved: '/', }
    lexer.add_lexeme { mode,  tid: 'gt',        jump: '.]',       pattern: '>',       reserved: '>', }
    lexer.add_catchall_lexeme { mode, tid: 'text', concat: true, }
    lexer.add_reserved_lexeme { mode, tid: 'forbidden', concat: true, }
  #.........................................................................................................
  do =>
    mode = 'xncr'
    # lexer.add_lexeme new_escchr_descriptor  mode
    # lexer.add_lexeme new_nl_descriptor      mode
    lexer.add_lexeme { mode,  tid: 'csg',       jump: null,     pattern: /(?<=&)[^\s;#\\]+(?=#)/u, } # character set sigil (non-standard)
    lexer.add_lexeme { mode,  tid: 'name',      jump: null,     pattern: /(?<=&)[^\s;#\\]+(?=;)/u, } # name of named entity
    lexer.add_lexeme { mode,  tid: 'dec',       jump: null,     pattern: /#(?<nr>[0-9]+)(?=;)/u, }
    lexer.add_lexeme { mode,  tid: 'hex',       jump: null,     pattern: /#(?:x|X)(?<nr>[0-9a-fA-F]+)(?=;)/u, }
    lexer.add_lexeme { mode,  tid: 'sc',        jump: '.]',      pattern: /;/u, }
    lexer.add_lexeme { mode,  tid: '$error',    jump: '.]',      pattern: /.|$/u, }
  #.........................................................................................................
  do =>
    mode = 'tag:dq'
    lexer.add_lexeme new_escchr_descriptor  mode
    lexer.add_lexeme new_nl_descriptor      mode
    lexer.add_lexeme { mode,  tid: 'dq',        jump: '].',        pattern: '"',       reserved: '"', }
    lexer.add_catchall_lexeme { mode, tid: 'text', concat: true, }
  #.........................................................................................................
  do =>
    mode = 'tag:sq'
    lexer.add_lexeme new_escchr_descriptor  mode
    lexer.add_lexeme new_nl_descriptor      mode
    lexer.add_lexeme { mode,  tid: 'sq',        jump: '].',        pattern: "'",       reserved: "'", }
    lexer.add_catchall_lexeme { mode, tid: 'text', concat: true, }
  #.........................................................................................................
  do =>
    mode = 'comment'
    lexer.add_lexeme new_escchr_descriptor  mode
    lexer.add_lexeme new_nl_descriptor      mode
    lexer.add_lexeme { mode, tid: 'eoc',       jump: '.]',         pattern:  '-->',    reserved: '--',  }
    lexer.add_catchall_lexeme { mode, tid: 'text', concat: true, }
    lexer.add_reserved_lexeme { mode, tid: 'forbidden', concat: true, }
  return null


#===========================================================================================================
{ Interlex
  compose  }        = require 'intertext-lexer'
first               = Symbol 'first'
last                = Symbol 'last'
#.........................................................................................................
new_toy_md_lexer = ( mode = 'plain' ) ->
  lexer   = new Interlex { dotall: false, }
  #.........................................................................................................
  lexer.add_lexeme { mode: 'plain', lxid: 'escchr',     jump: null,     pattern:  /\\(?<chr>.)/u,           }
  lexer.add_lexeme { mode: 'plain', lxid: 'marksleft',  jump: '[marks', pattern:  /\[/u,                    }
  lexer.add_lexeme { mode: 'plain', lxid: 'other',      jump: null,     pattern:  /[^\[\\]+/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'marksright', jump: '.]',     pattern:  /\]\s*/u, reserved: ']',     }
  lexer.add_lexeme { mode: 'marks', lxid: 'format',     jump: null,     pattern:  /[swh]/u,                 }
  lexer.add_lexeme { mode: 'marks', lxid: 'ws',         jump: null,     pattern:  /\x20+/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'multiplier', jump: null,     pattern:  /x[0-9]{1,2}/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'promptnr',   jump: null,     pattern:  /p#[0-9]+/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'generation', jump: null,     pattern:  /[U01234]/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'grade',      jump: null,     pattern:  /[-+A-Fvnr]+/u,              }
  lexer.add_lexeme { mode: 'marks', lxid: 'comment',    jump: null,     pattern:  /(?:(?!p#[0-9]|\]).)+/u,              }
  # lexer.add_lexeme { mode: 'marks', lxid: 'comment',    jump: null,     pattern:  /.+(?!(?:p#[0-9]|\]))/u,              }
  # lexer.add_catchall_lexeme { mode: 'marks', lxid: 'comment', concat: true, }
  lexer.add_reserved_lexeme { mode, lxid: 'forbidden', concat: true, }
  #.........................................................................................................
  return lexer

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
    ]
  for prompt in prompts
    whisper 'Ω___1', '————————————————————————'
    urge 'Ω___2', rpr prompt
    for d from ( new_toy_md_lexer() ).walk prompt
      help 'Ω___3', "#{d.$key.padEnd 20} #{rpr d.value}"
  return null

#===========================================================================================================
module.exports = {
  _TEMP_add_lexemes
  Markdown_sx
  Standard_sx
  Hypedown_lexer }
