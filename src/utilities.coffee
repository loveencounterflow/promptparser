

'use strict'

GUY                       = require 'guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'promptparser/utilities'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
FS                        = require 'node:fs'
CRYPTO                    = require 'node:crypto'
{ DBay }                  = require 'dbay'
{ SQL  }                  = DBay
ExifReader                = require 'exifreader'
format_nr                 = ( new Intl.NumberFormat 'en-GB' ).format


#===========================================================================================================
class Utilities

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    @nosuchprompt = ""
    return undefined

  #---------------------------------------------------------------------------------------------------------
  get_db_table_names: ( db ) -> db.all_first_values SQL"""
    select name from sqlite_schema where type = 'table' order by name;"""

  #---------------------------------------------------------------------------------------------------------
  db_has_all_table_names: ( db, must_have_table_names... ) ->
    table_names = @get_db_table_names db
    for must_have_table_name from must_have_table_names
      return false unless must_have_table_name in table_names
    return true

  #---------------------------------------------------------------------------------------------------------
  id_from_text: ( text, length = 16 ) ->
    hash = CRYPTO.createHash 'sha1'
    hash.update text
    return ( hash.digest 'hex' )[ ... length ]

  #---------------------------------------------------------------------------------------------------------
  normalize_prompt: ( prompt ) ->
    R = prompt
    R = R.replace /\s*\.\s*$/, ''
    R = R.trim()
    R = R.replace /\s{2,}/g, ' '
    return R

  #---------------------------------------------------------------------------------------------------------
  exif_from_path: do =>
    my_buffer = new Buffer.alloc 2 * 1024
    return ( path ) ->
      fd          = FS.openSync path
      FS.readSync fd, my_buffer
      exif        = ExifReader.load my_buffer
      if ( data = exif?.UserComment ? null )?
        R = JSON.parse ( Buffer.from data.value ).toString 'utf-8'
      else
        R = { prompt: @nosuchprompt, date: null, }
      #.....................................................................................................
      R.prompt    = @normalize_prompt R.prompt
      R.prompt_id = @id_from_text R.prompt
      return R

  #---------------------------------------------------------------------------------------------------------
  color:
    cmd:          ( P... ) -> GUY.trm.white GUY.trm.reverse GUY.trm.bold P...
    flag:         ( P... ) -> GUY.trm.grey  GUY.trm.reverse GUY.trm.bold P...
    description:  ( P... ) -> GUY.trm.lime P...
    expect:       ( P... ) -> GUY.trm.blue P...
    bad:          ( P... ) -> GUY.trm.red   GUY.trm.reverse GUY.trm.bold P...

  #---------------------------------------------------------------------------------------------------------
  format_nr: ( x, width = null ) ->
    R = format_nr x
    return R unless width?
    return R.padStart width, ' '

  #---------------------------------------------------------------------------------------------------------
  wrap_insert: ( insert_method ) -> ( d ) ->
    try
      insert_method d
    catch error
      name  = GUY.trm.reverse GUY.trm.bold " #{rpr insert_method.name} "
      row   = GUY.trm.reverse GUY.trm.bold " #{rpr d} "
      warn()
      warn 'Ω___1', "error: #{error.message}"
      warn 'Ω___2', "error happened in insert method #{name} with this data:"
      warn()
      warn 'Ω___3', row
      warn()
      throw error

#===========================================================================================================
module.exports =
  Utilities:  Utilities
  U:          new Utilities()

