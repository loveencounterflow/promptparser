

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



#===========================================================================================================
{ Interlex
  compose  }        = require 'intertext-lexer'
first               = Symbol 'first'
last                = Symbol 'last'
#.........................................................................................................
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
    for d from ( new_prompt_lexer() ).walk prompt
      help 'Ω___3', "#{d.$key.padEnd 20} #{rpr d.value}"
  return null

# #===========================================================================================================
# module.exports = {
#   _TEMP_add_lexemes
#   Markdown_sx
#   Standard_sx
#   Hypedown_lexer }
