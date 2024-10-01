

'use strict'


############################################################################################################
GUY                       = require 'guy'
{ Journal_walker }        = require './journal-walker'


#===========================================================================================================
class _Journal_walker_for_testing extends Journal_walker

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    cfg.lines ?= []
    super cfg
    return undefined

  #=========================================================================================================
  parse_all_records: ( source ) ->
    R = []
    for { lnr, line, eol, } from GUY.str.walk_lines_with_positions source
      @pipeline.send { lnr, line, }
      R = R.concat @pipeline.run()
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
      for token from @prompt_parser._lexer.walk line
        continue if @types.isa.symbol token
        R.push @prompt_parser._cast_token lnr, token
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


#===========================================================================================================
module.exports = {
  _Journal_walker_for_testing, }


