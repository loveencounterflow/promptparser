

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
        db_path:              'nonempty.text'
        datasource_path:      ( x ) -> @isa.optional.nonempty.text x ### TAINT workaround due to missing feature ###
        has_db_path:          'boolean'
        has_datasource_path:  'boolean'
        has_db:               'boolean'
      create: ( db_path, datasource_path ) ->
        has_db_path         = db_path?
        has_datasource_path = datasource_path?
        ### NOTE `has_db_path` could conceivably be used to optionally open a temporary DB; only when that
        DB actually exists would `has_db` be set to true; FTTB we don't do that so we here assume that in
        case there's a `db_path` there will be a (functional, writable &c) DB file to access, and otherwise,
        there will be no DB file. Observe that in any case, even if we did check for a file, we would still
        have to test its fitness for the purpose, so other than a given `db_path` pointing to an unsuitable
        location, there will remain failure modes that won't be captured by `has_db`. As such, `has_db` is
        more of an advisory, informative property: 'act as if there is / there is no DB file'. ###
        has_db              = has_db_path
        has_datasource      = has_datasource_path
        auto_populate_db    = has_db and has_datasource
        return {
          db_path,          has_db_path,          has_db,
          datasource_path,  has_datasource_path,  has_datasource,
          auto_populate_db, }
    #.......................................................................................................
    fm_table_name:          'nonempty.text'
    fm_table_fields:        'object'
    fm_insertion_record_object:
      fields:
        table:              'fm_table_name'
        fields:             'fm_table_fields'
    fm_insertion_record_list: ( x ) ->
      return false unless @isa.list x
      return x.every ( e ) => @isa.fm_insertion_record_object e
    fm_insertion_records:
      test:     ( x ) -> ( @isa.fm_insertion_record_object x ) or ( @isa.fm_insertion_record_list x )
      create:   ( x ) ->
        return x if @isa.fm_insertion_record_list x
        return [ x, ]


  #.........................................................................................................
  return types


#===========================================================================================================
module.exports = { get_types, }
