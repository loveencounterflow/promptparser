

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
  whisper }               = GUY.trm.get_loggers 'promptparser/image-registry'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
FS                        = require 'node:fs'
{ DBay }                  = require 'dbay'
{ SQL  }                  = DBay
{ U }                     = require './utilities'


#-----------------------------------------------------------------------------------------------------------
### TAINT this should become part of command line handling with [M.I.X.A.](https://github.com/loveencounterflow/mixa) ###
set_path = ->
  process.chdir path if ( path = process.argv[ 2 ] ? null )?
  R = process.cwd()
  info "Ω___1 CWD: #{R}"
  return R

#-----------------------------------------------------------------------------------------------------------
build_file_db = ->
  PATH            = require 'node:path'
  { glob
    globSync  }   = require 'glob'
  patterns        = [ '**/*.png', '**/*.jpg', '**/*.jpeg', ]
  cfg             = { dot: true }
  base_path       = set_path()
  count           = 0
  DB              = prepare_db()
  #.........................................................................................................
  # DB.db ->
  console.time 'build_file_db'
  counts    =
    skipped:  0
    added:    0
    deleted:  0
  rel_paths = globSync patterns, cfg
  info 'Ω___2', GUY.trm.reverse "found #{rel_paths.length} matching files"
  for rel_path in rel_paths
    count++; whisper count if ( count %% 1000 ) is 0
    # break if count > 10000 ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
    abs_path  = PATH.resolve base_path, rel_path
    path_id   = U.id_from_text abs_path
    #...................................................................................................
    if DB.known_path_ids.has path_id
      # help "Ω___3 skipping path ID #{rpr path_id}"
      counts.skipped++
      ### NOTE we know that in the present run we will not again have to test against the current
      `path_id`, so we also know we can safely delete it from the pool of known IDs (thereby making it
      smaller and potentially a tad faster); after having gone through all `path_ids` in the file
      system, we will then effectively have turned `DB.known_path_ids` into `extraneous_path_ids`, i.e.
      those that could be deleted from the DB if deemed necessary. ###
      DB.known_path_ids.delete path_id
    else
      ##################################################################################################
      ##################################################################################################
      ### TAINT factor this into method ###
      # warn "Ω___4 inserting path ID #{rpr path_id}"
      counts.added++
      #.................................................................................................
      exif = U.exif_from_path abs_path
      fields = { id: exif.prompt_id, prompt: exif.prompt, }
      yield { $key: 'record', table: 'img_prompts', fields, }
      #.................................................................................................
      fields = { id: path_id, prompt_id: exif.prompt_id, path: abs_path, }
      yield { $key: 'record', table: 'img_files', fields, }
      #.................................................................................................
      # ### TAINT use prepared statement ###
      # try
      #   DB.db SQL"""
      #     insert into img_prompts ( id, prompt ) values ( ?, ? )
      #       on conflict ( id ) do nothing;""", [
      #     exif.prompt_id, exif.prompt, ]
      # catch error
      #   warn 'Ω___5', "error: #{error.message}"
      #   warn 'Ω___6', "error happened with this data: #{rpr exif}"
      # #.................................................................................................
      # ### TAINT use prepared statement ###
      # try
      #   DB.db SQL"""insert into img_files ( id, prompt_id, path ) values ( ?, ?, ? );""", [
      #     path_id, exif.prompt_id, abs_path, ]
      # catch error
      #   warn 'Ω___7', "error: #{error.message}"
      #   warn 'Ω___8', "error happened with this data: #{rpr { path_id, prompt_id: exif.prompt_id, abs_path, }}"
      # ##################################################################################################
      # ##################################################################################################
  #.....................................................................................................
  info "Ω___9 changes to DB at #{DB.path}: #{rpr counts}"
  console.timeEnd 'build_file_db'
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
prepare_db = ->
  ### TAINT use `types`, template ###
  path                = '/dev/shm/promptparser.sqlite'
  db                  = new DBay { path, }
  #.........................................................................................................
  ### TAINT use `U.db_has_all_table_names()` ###
  get_must_initialize = ( db ) ->
    tables    = db.first_values SQL"select name from sqlite_schema where type = 'table' order by name;"
    tables    = [ tables..., ]
    R         = false
    R       or= 'img_files'   not in tables
    R       or= 'img_prompts' not in tables
    return R
  #.........................................................................................................
  initialize_db = ( db ) ->
    db ->
      db SQL"drop table if exists img_files;"
      db SQL"drop table if exists img_prompts;"
      db SQL"""
        create table img_files (
            id        text not null primary key,
            prompt_id text not null,
            path      text not null,
          foreign key ( prompt_id ) references img_prompts ( id ) );"""
      db SQL"""
        create table img_prompts (
            id        text not null primary key,
            prompt    text not null );"""
      db SQL"""insert into img_prompts ( id, prompt ) values ( ?, ? );""", [
        ( U.id_from_text U.nosuchprompt ), U.nosuchprompt, ]
      db SQL"""
        create view img_files_and_prompts as select
            f.id      as file_id,
            p.id      as prompt_id,
            f.path    as path,
            p.prompt  as prompt
          from      img_prompts as p
          left join img_files   as f on ( f.prompt_id = p.id );"""
      # #.....................................................................................................
      # ### TAINT auto-generate? ###
      # ### NOTE will contain counts for all relations ###
      # db SQL"""
      #   create view rowcounts as
      #     select            null as name,             null as rowcount where false
      #     union all select  'img_files',              count(*)          from img_files
      #     union all select  'img_prompts',            count(*)          from img_prompts
      #     union all select  'img_files_and_prompts',  count(*)          from img_files_and_prompts
      #     ;"""
      #.....................................................................................................
      return null
    return null
  #.........................................................................................................
  if get_must_initialize db
    warn "Ω__10 initializing DB at #{path}"
    initialize_db db
  else
    help "Ω__11 re-using DB at #{path}"
  #.........................................................................................................
  ### TAINT can we use an API call to get a set? ###
  known_path_ids = do =>
    R = new Set()
    R.add id for id from db.first_values SQL"select * from img_files;"
    return R
  #.........................................................................................................
  return { path, db, known_path_ids, }


#===========================================================================================================
class Image_walker

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cmd, flags ) ->
    return undefined

  #---------------------------------------------------------------------------------------------------------
  [Symbol.iterator]: ->
    yield from build_file_db()


#===========================================================================================================
module.exports = { Image_walker, }


#===========================================================================================================
if module is require.main then await do =>
  # await demo_fast_glob()
  # await demo_node_glob()
  # await demo_exifr()
  # await demo_exiftool_vendored()
  # demo_dbay_with_exifdata()
  iterator = new Image_walker()
  debug 'Ω__12', iterator[Symbol.iterator]
  debug 'Ω__13', d for d from iterator
  debug 'Ω__14', [ iterator..., ].length


