
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
  whisper }               = GUY.trm.get_loggers 'promptparser/file-mirror'
#...........................................................................................................
{ rpr
  inspect
  echo
  log     }               = GUY.trm
{ hide }                  = GUY.props
{ U }                     = require './utilities'
{ SQL  }                  = DBay
PATH                      = require 'node:path'
FS                        = require 'node:fs'
{ get_types }             = require './types'
types                     = get_types()


#===========================================================================================================
class File_mirror

  #---------------------------------------------------------------------------------------------------------
  ### TAINT use CFG pattern ###
  constructor: ( cfg ) ->
    hide @, 'types', get_types()
    @cfg  = @types.create.fm_constructor_cfg cfg
    @_create_db_structure()
    @_populate_db()
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _create_db_structure: ->
    whisper 'Ω___1', "File_mirror::_create_db_structure"
    @_clear_db()
    @cfg.db =>
      #.....................................................................................................
      ### TAINT a more general solution should accommodate more than a single source file ###
      @cfg.db SQL"""
        create table if not exists fm_datasources (
            lnr       integer not null primary key,
            line      text    not null );"""
      #.....................................................................................................
      return null
    #.......................................................................................................
    @insert_into =
      lines_table: do =>
        insert_statement = @cfg.db.create_insert { into: @cfg.table_name, }
        ( d ) -> @cfg.db.alt insert_statement, d
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _populate_db: ->
    try
      @cfg.db =>
        for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions @cfg.datasource_path
          @insert_into.lines_table { lnr, line, }
        return null
    catch error
      if error.code in [ 'ENOENT', 'EACCES', 'EPERM', ]
        whisper 'Ω___2', "File_mirror::_populate_db", U.color.bad \
          error.message
        process.exit 111
      throw error
    return null


#===========================================================================================================
module.exports = { File_mirror, }

