

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
  whisper }               = GUY.trm.get_loggers 'promptparser/file-cache-builder'
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


#===========================================================================================================
class Utilities

  #---------------------------------------------------------------------------------------------------------
  constructor: ->
    @nosuchprompt = ""
    return undefined

  #---------------------------------------------------------------------------------------------------------
  id_from_text: ( text, length = 16 ) ->
    hash = CRYPTO.createHash 'sha1'
    hash.update text
    return ( hash.digest 'hex' )[ ... length ]

  #---------------------------------------------------------------------------------------------------------
  normalize_prompt: ( prompt ) -> prompt.trim().replace /\.$/, ''

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


#===========================================================================================================
module.exports =
  Utilities:  Utilities
  U:          new Utilities()

