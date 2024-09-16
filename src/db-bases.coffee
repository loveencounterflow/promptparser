
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
  whisper }               = GUY.trm.get_loggers 'promptparser/db-bases'
#...........................................................................................................
{ rpr
  inspect
  echo
  log     }               = GUY.trm
{ hide }                  = GUY.props
{ U }                     = require './utilities'
{ DBay }                  = require 'dbay'
{ SQL  }                  = DBay
PATH                      = require 'node:path'
FS                        = require 'node:fs'
{ get_types }             = require './types'
types                     = get_types()
{ trash }                 = require 'trash-sync'



###

8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888

###

#===========================================================================================================
### TAINT should inherit from common base class together with File_mirror ###
class Dbay_autopop

  #---------------------------------------------------------------------------------------------------------
  # @required_table_names: [ 'datasources', ]

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern ###
  constructor: () ->
    hide @, 'types', get_types()
    #.......................................................................................................
    return undefined



###

8888888888 8888888 888      8888888888   888b     d888 8888888 8888888b.  8888888b.   .d88888b.  8888888b.
888          888   888      888          8888b   d8888   888   888   Y88b 888   Y88b d88P" "Y88b 888   Y88b
888          888   888      888          88888b.d88888   888   888    888 888    888 888     888 888    888
8888888      888   888      8888888      888Y88888P888   888   888   d88P 888   d88P 888     888 888   d88P
888          888   888      888          888 Y888P 888   888   8888888P"  8888888P"  888     888 8888888P"
888          888   888      888          888  Y8P  888   888   888 T88b   888 T88b   888     888 888 T88b
888          888   888      888          888   "   888   888   888  T88b  888  T88b  Y88b. .d88P 888  T88b
888        8888888 88888888 8888888888   888       888 8888888 888   T88b 888   T88b  "Y88888P"  888   T88b

###

#===========================================================================================================
class File_mirror extends Dbay_autopop

  #---------------------------------------------------------------------------------------------------------
  @required_table_names: [ 'datasources', ]

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern ###
  constructor: ( db_path, datasource_path, trash_db = false ) ->
    super()
    hide @, 'types', get_types()
    @cfg  = @types.create.fm_constructor_cfg db_path, datasource_path, trash_db
    @_trash_db_if_necessary()
    #.......................................................................................................
    hide @, '_db', new DBay { path: @cfg.db_path, }
    #.......................................................................................................
    ### NOTE stuff like the below could go into a DBay utility class ###
    @_prepare_db_connection()
    @_create_db_structure_if_necessary()
    @_populate_db_if_necessary() if new.target is File_mirror
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _trash_db_if_necessary: ->
    return 0 unless @cfg.trash_db
    return trash @cfg.db_path

  #---------------------------------------------------------------------------------------------------------
  _prepare_db_connection: ->
    # whisper 'Ω___1', "File_mirror._prepare_db_connection"
    # @_db =>
    #   @_db.create_table_function
    #     name:         'file_contents_t'
    #     columns:      [ 'lnr', 'line', 'eol', ]
    #     parameters:   [ 'filename', ]
    #     rows: ( filename ) ->
    #       path  = PATH.resolve process.cwd(), filename
    #       for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions path
    #         yield { lnr, line, eol, }
    #       return null
    #   return null
    # #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _get_required_table_names: -> new Set (
    ( p.required_table_names ? [] ) for p in WG.props.get_prototype_chain @constructor ).flat()

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure_if_necessary: ->
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      whisper 'Ω___2', "File_mirror::_create_db_structure_if_necessary: re-using DB at #{@cfg.db_path}"
    else
      whisper 'Ω___3', "File_mirror::_create_db_structure_if_necessary: creating structure of DB at #{@cfg.db_path}"
      @_create_db_structure()
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _clear_db : ->
    ### TAINT belongs to Prompt_file_reader ###
    ### TAINT use `_required_table_names` ###
    @_db =>
      @_db SQL"drop table if exists prompts;"
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    whisper 'Ω___4', "File_mirror::_create_db_structure"
    @_clear_db()
    @_db =>
      ### TAINT a more general solution should accommodate more than a single source file ###
      @_db SQL"""
        create table datasources (
            lnr       integer not null primary key,
            line      text    not null );"""
      return null
    return null

  #---------------------------------------------------------------------------------------------------------
  _populate_db_if_necessary: ->
    whisper 'Ω___5', "File_mirror::_populate_db_if_necessary"
    return 0 unless @cfg.auto_populate_db
    @_populate_db()
    return 1

  #---------------------------------------------------------------------------------------------------------
  _populate_db: ->
    ### TAINT throw error unless @cfg.auto_populate_db ###
    try
      @_db =>
        for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions @cfg.datasource_path
          @_db @_insert_into.datasources, { lnr, line, }
        return null
    catch error
      if error.code in [ 'ENOENT', 'EACCES', 'EPERM', ]
        whisper 'Ω___6', "File_mirror::_populate_db", U.color.bad \
          error.message
        process.exit 111
      throw error
    return null


###

8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
8888888888          8888888888          8888888888          8888888888          8888888888          8888888888

###

#===========================================================================================================
### TAINT should inherit from common base class together with File_mirror ###
### TAINT should get its own submodule ###
class Promptparser_main extends Dbay_autopop

  #---------------------------------------------------------------------------------------------------------
  # @required_table_names: [ 'datasources', ]

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cmd, flags = null ) ->
    super()
    hide @, 'types', get_types()
    @cfg  = @types.create.ppm_constructor_cfg cmd, flags, null
    #.......................................................................................................
    @cfg.db_path = '/tmp/nosuch.sqlite'
    #.......................................................................................................
    @_trash_db_if_necessary()
    #.......................................................................................................
    hide @, '_db', new DBay { path: '/dev/shm/promptparser.sqlite', }
    # hide @, '_db', new DBay { path: @cfg.db_path, }
    #.......................................................................................................
    ### NOTE stuff like the below could go into a DBay utility class ###
    # @_prepare_db_connection()
    @_create_db_structure_if_necessary()
    # @_populate_db_if_necessary() if new.target is File_mirror
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _trash_db_if_necessary: ->
    return 0 unless @cfg.trash_db
    return trash @cfg.db_path

  # #---------------------------------------------------------------------------------------------------------
  # _prepare_db_connection: ->
  #   return null

  #---------------------------------------------------------------------------------------------------------
  _get_required_table_names: -> new Set (
    ( p.required_table_names ? [] ) for p in WG.props.get_prototype_chain @constructor ).flat()

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure_if_necessary: ->
    if U.db_has_all_table_names @_db, @constructor.required_table_names
      whisper 'Ω___7', "Promptparser_main::_create_db_structure_if_necessary: re-using DB at #{@cfg.db_path}"
    else
      whisper 'Ω___8', "Promptparser_main::_create_db_structure_if_necessary: creating structure of DB at #{@cfg.db_path}"
      @_create_db_structure()
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _clear_db : ->
    return null

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    whisper 'Ω___9', "Promptparser_main::_create_db_structure"
    @_clear_db()
    # @_db =>
    #   @_db SQL"""
    #     create table datasources (
    #         lnr       integer not null primary key,
    #         line      text    not null );"""
    #   return null
    return null

  #---------------------------------------------------------------------------------------------------------
  _populate_db_if_necessary: ->
    whisper 'Ω__10', "Promptparser_main::_populate_db_if_necessary"
    return 0 unless @cfg.auto_populate_db
    @_populate_db()
    return 1

  #---------------------------------------------------------------------------------------------------------
  _populate_db: ->
    ### TAINT throw error unless @cfg.auto_populate_db ###
    try
      @_db =>
        for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions @cfg.datasource_path
          @_db @_insert_into.datasources, { lnr, line, }
        return null
    catch error
      if error.code in [ 'ENOENT', 'EACCES', 'EPERM', ]
        whisper 'Ω__11', "Promptparser_main::_populate_db", U.color.bad \
          error.message
        process.exit 111
      throw error
    return null


#===========================================================================================================
module.exports = { File_mirror, Promptparser_main, }


if module is require.main then do =>
  debug 'Ω__12', new Promptparser_main()
