

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
  whisper }               = GUY.trm.get_loggers 'promptparser/image-walker'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
FS                        = require 'node:fs'
PATH                      = require 'node:path'
{ U }                     = require './utilities'
{ hide }                  = GUY.props
{ get_types }             = require './types'





#===========================================================================================================
class Image_walker

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    hide @, 'types',  get_types()
    @cfg            = @types.create.image_walker_cfg cfg
    hide @, 'known_path_ids', U.pluck @cfg, 'known_path_ids', new Set()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  [Symbol.iterator]: ->
    yield from @TMP_RENAME_build_file_db()

  #-----------------------------------------------------------------------------------------------------------
  TMP_RENAME_build_file_db: ->
    { glob
      globSync  }   = require 'glob'
    base_path       = PATH.resolve ( @cfg.flags.images ? process.cwd() )
    patterns        = [ '**/*.png', '**/*.jpg', '**/*.jpeg', ]
    glob_cfg        =
      dot:      true
      cwd:      base_path
    count           = 0
    #.........................................................................................................
    # DB.db ->
    console.time 'TMP_RENAME_build_file_db'
    counts    =
      skipped:          0
      added:            0
      deleted:          0
      unsampled_files:  0
    info 'Ω___1', GUY.trm.reverse "globbing files at #{glob_cfg.cwd} using #{rpr patterns}"
    rel_paths = globSync patterns, glob_cfg
    info 'Ω___2', GUY.trm.reverse "found #{rel_paths.length} matching files"
    for rel_path in rel_paths
      count++; whisper count if ( count %% 5e3 ) is 0
      path    = PATH.resolve base_path, rel_path
      path_id = U.id_from_text path
      #.....................................................................................................
      ### TAINT use method that honors `seed` ###
      ### --SAMPLE ###
      if Math.random() > @cfg.flags.sample
        counts.unsampled_files++
        continue
      #...................................................................................................
      if @known_path_ids.has path_id
        # help "Ω___3 skipping path ID #{rpr path_id}"
        counts.skipped++
        ### NOTE we know that in the present run we will not again have to test against the current
        `path_id`, so we also know we can safely delete it from the pool of known IDs (thereby making it
        smaller and potentially a tad faster); after having gone through all `path_ids` in the file
        system, we will then effectively have turned `@known_path_ids` into `extraneous_path_ids`, i.e.
        those that could be deleted from the DB if deemed necessary. ###
        @known_path_ids.delete path_id
      else
        counts.added++
        #.................................................................................................
        exif = U.exif_from_path abs_path
        fields = { id: exif.prompt_id, prompt: exif.prompt, }
        yield { $key: 'record', table: 'img_prompts', fields, }
        #.................................................................................................
        fields = { id: path_id, prompt_id: exif.prompt_id, path: abs_path, }
        yield { $key: 'record', table: 'img_files', fields, }
    #.....................................................................................................
    # info "Ω___8 changes to DB at #{DB.path}: #{rpr counts}"
    console.timeEnd 'TMP_RENAME_build_file_db'
    #.........................................................................................................
    return null

#===========================================================================================================
module.exports = { Image_walker, }


#===========================================================================================================
if module is require.main then await do =>
  echo()
  echo ( GUY.trm.grey 'Ω___5' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
