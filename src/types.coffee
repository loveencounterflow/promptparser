

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
    #.......................................................................................................
    cardinal_or_infinity: ( x ) -> ( x is Infinity ) or ( @isa.cardinal x )
    #.......................................................................................................
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
    list_or_iterator:  ( x ) ->
      return true if @isa.list      x
      return true if @isa.generator x
      return false
    #.......................................................................................................
    pfr_constructor_cfg:
      test:   'object'
      fields:
        cmd:                  'nonempty.text'
        flags:                'object'
        lines:                'list_or_iterator'
      create: ( cfg ) ->
        R = { @declarations.pfr_constructor_cfg.template..., cfg..., }
        return R
    #.......................................................................................................
    prompt_db_cfg:
      test:   'object'
      fields:
        cmd:                  'nonempty.text'
        flags:                'object'
        # lines:                'list_or_iterator'
      template:
        cmd:                  null
        flags:                null
        # lines:                null
      create: ( cfg ) ->
        debug 'Ω___1', cfg
        R = { @declarations.prompt_db_cfg.template..., cfg..., }
        return R
    #.......................................................................................................
    cli_max_count:
      test:                 'cardinal_or_infinity'
      template:             +Infinity
      create:               ( x ) ->
        return @declarations.cli_max_count.template unless x?
        # return x unless /^\+?\d+$/.test x
        Math.round parseFloat x
    #.......................................................................................................
    normalfloat:            ( x ) -> ( @isa.float x ) and 0 <= x <= 1
    #.......................................................................................................
    cli_sample:
      test:                 'normalfloat'
      template:             1
      create: ( x ) ->
        switch true
          when not x?
            return @declarations.cli_sample.template
          when x.endsWith '%'
            return ( ( parseFloat x ) / 100 )
          when ( match = x.match /^(?<numerator>[0-9.]+)\/(?<denominator>[0-9.]+)$/ )?
            return ( ( parseFloat match.groups.numerator ) / parseFloat match.groups.denominator )
        return parseFloat x
    #.......................................................................................................
    cli_seed:
      test:                 'float'
      template:             null
      create: ( x ) ->
        return @declarations.cli_sample.template unless x?
        return parseFloat x
    #.......................................................................................................
    cli_match:
      test:                 ( x ) -> @isa.optional.regex x ### TAINT workaround due to missing feature ###
      template:             null
      create: ( x ) ->
        return null unless x?
        return new RegExp x
    #.......................................................................................................
    cli_pre_match:
      test:                 'regex'
      template:             /^\[.*?\].*?\S+/
      create: ( x ) ->
        debug 'Ω___2', ( rpr x ), rpr @declarations.cli_pre_match.template
        return @declarations.cli_pre_match.template unless x?
        return new RegExp x
    #.......................................................................................................
    cli_trash_db:
      test:                 'boolean'
      template:             false
      create: ( x ) ->
        return @declarations.cli_trash_db.template  unless x?
        return true                                 if x is 'true'
        return false                                if x is 'false'
        return x
    #.......................................................................................................
    cli_db:
      test:                 'nonempty.text'
      template:             '/dev/shm/promptparser.sqlite'
      create: ( x ) -> x ? @declarations.cli_db.template
    #.......................................................................................................
    cli_prompts:
      test:                 'nonempty.text'
      template:             null
      create: ( x ) -> x

  #.........................................................................................................
  return types


#===========================================================================================================
module.exports = { get_types, }
