

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
    # #.......................................................................................................
    # fm_table_name:          'nonempty.text'
    # fm_datasource_path:     'nonempty.text'
    # fm_table_fields:        'object'
    # #.......................................................................................................
    # fm_constructor_cfg:
    #   fields:
    #     db:                   'object'
    #     datasource_path:      'fm_datasource_path'
    #     table_name:           'fm_table_name'
    #   template:
    #     db:                   null
    #     datasource_path:      null
    #     table_name:           'fm_lines'
    #   create: ( cfg ) ->
    #     return { @declarations.fm_constructor_cfg.template..., cfg..., }
    # #.......................................................................................................
    # fm_insertion_record_object:
    #   fields:
    #     table:              'fm_table_name'
    #     fields:             'fm_table_fields'
    # fm_insertion_record_list: ( x ) ->
    #   return false unless @isa.list x
    #   return x.every ( e ) => @isa.fm_insertion_record_object e
    # fm_insertion_records:
    #   test:     ( x ) -> ( @isa.fm_insertion_record_object x ) or ( @isa.fm_insertion_record_list x )
    #   create:   ( x ) ->
    #     return x if @isa.fm_insertion_record_list x
    #     return [ x, ]
    #.......................................................................................................
    pfr_constructor_cfg:
      test:   'object'
      fields:
        ### inherited from fm_constructor_cfg ###
        db_path:              'nonempty.text'
        datasource_path:      ( x ) -> @isa.optional.nonempty.text x ### TAINT workaround due to missing feature ###
        has_db_path:          'boolean'
        has_datasource_path:  'boolean'
        has_db:               'boolean'
        ### own fields ###
        cmd:                  'nonempty.text'
        flags:                'object'
      create: ( cmd, flags, upstream_cfg = null ) ->
        db_path             = flags.db
        has_db_path         = db_path?
        has_db              = has_db_path
        datasource_path     = flags.prompts
        has_datasource_path = datasource_path?
        R = { upstream_cfg..., cmd, db_path, has_db_path, has_db, datasource_path, has_datasource_path, flags, }
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
        debug 'Ω__1', ( rpr x ), rpr @declarations.cli_pre_match.template
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
