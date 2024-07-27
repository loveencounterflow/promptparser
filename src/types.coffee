

'use strict'

#===========================================================================================================
GUY                       = require 'guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'promptparser/types'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
{ Intertype }             = require 'intertype'
#...........................................................................................................
types                     = null

#===========================================================================================================
get_types = ->
  return types if types?
  types                     = new Intertype
  { isa
    type_of
    validate
    create                } = types
  #.........................................................................................................
  types.declare
    pp_linenumber:    'positive.integer'
    pp_content_id:    ( x ) -> ( @isa.text x ) and ( /^[0-9a-f]{16}$/.test x )
    #.......................................................................................................
    pp_prerecord_initial:
      fields:
        $key:         'text'
        lnr:          ( x ) -> @isa.optional.pp_linenumber  x ### TAINT workaround due to missing feature ###
        promptnr:     ( x ) -> @isa.optional.text           x ### TAINT workaround due to missing feature ###
        prompt:       ( x ) -> @isa.optional.text           x ### TAINT workaround due to missing feature ###
        prompt_id:    ( x ) -> @isa.optional.pp_content_id  x ### TAINT workaround due to missing feature ###
        generations:  ( x ) -> @isa.optional.list           x ### TAINT workaround due to missing feature ###
        comment:      ( x ) -> @isa.optional.text           x ### TAINT workaround due to missing feature ###
        rejected:     ( x ) -> @isa.optional.boolean        x ### TAINT workaround due to missing feature ###
      template:
        $key:         'prerecord'
        lnr:          null
        promptnr:     null
        prompt:       null
        prompt_id:    null
        generations:  null
        comment:      null
        rejected:     false
    #.......................................................................................................
    pp_prerecord_final:
      fields:
        $key:         'text'
        lnr:          'positive.integer'
        promptnr:     ( x ) -> @isa.optional.text x ### TAINT workaround due to missing feature ###
        prompt:       'text'
        prompt_id:    'pp_content_id'
        generations:  ( x ) -> ( @isa.list x ) and ( x.every ( e ) => @isa.cardinal e ) ### TAINT workaround due to missing feature ###
        comment:      ( x ) -> @isa.optional.text x ### TAINT workaround due to missing feature ###
        rejected:     'boolean'
      create: ( x ) ->
        return x unless @isa.object x
        return x
    #.......................................................................................................
    fm_constructor_cfg:
      fields:
        db_path:          'nonempty.text'
        datasource_path:  'nonempty.text'
      create: ( db_path, datasource_path ) -> { db_path, datasource_path, }
  #.........................................................................................................
  return types


#===========================================================================================================
module.exports = { get_types, }
