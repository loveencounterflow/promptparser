
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
  whisper }               = GUY.trm.get_loggers 'promptparser/prompt-db'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
#...........................................................................................................
{ hide }                  = GUY.props
{ get_types }             = require './types'
#...........................................................................................................
{ DATOM }                 = require 'datom'
{ new_datom
  lets
  stamp }                 = DATOM
#...........................................................................................................
{ Journal_walker  }       = require './journal-walker'
{ Image_walker    }       = require './image-walker'
{ DBay            }       = require 'dbay'
{ SQL             }       = DBay
{ U               }       = require './utilities'
{ trash           }       = require 'trash-sync'


#===========================================================================================================
class Prompt_db

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    hide @, 'types',  get_types()
    @cfg = @types.create.prompt_db_cfg cfg
    path = U.pluck @cfg.flags, 'db'
    trash path if @cfg.flags.trash_db
    hide @, 'db', new DBay { path, }
    @create_db_structure()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  create_db_structure: ->
    # super()
    whisper 'Ω___1', "Prompt_file_reader::create_db_structure"
    #.......................................................................................................
    @db SQL"""
      create table jnl_prompts (
          prompt_id text    unique not null primary key,
          lnr       integer unique not null,
          prompt    text    unique not null,
          comment   text               null,
          rejected  boolean        not null,
        unique( prompt ) );"""
    #.......................................................................................................
    @db SQL"""
      create table jnl_generations (
          prompt_id text    not null,
          nr        integer not null,
          count     integer not null,
        primary key ( prompt_id, nr ),
        foreign key ( prompt_id ) references jnl_prompts ( prompt_id ) );"""
    #.......................................................................................................
    @db SQL"""
      create view jnl_counts as select distinct
          g.prompt_id           as prompt_id,
          count(*)      over w  as generations,
          sum( count )  over w  as images
        from jnl_generations as g
        window w as ( partition by prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view jnl_densities as select
          c.prompt_id                                                                         as prompt_id,
          c.generations                                                                       as generations,
          c.images                                                                            as images,
          cast( ( ( cast( c.images as real ) / c.generations / 4 ) * 100 + 0.5 ) as integer ) as density
        from jnl_generations as g
        left join jnl_counts as c using ( prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view promptstats as select distinct
          d.prompt_id     as prompt_id,
          d.generations   as generations,
          d.images        as images,
          d.density       as density,
          p.lnr           as lnr,
          p.prompt        as prompt
        from jnl_prompts    as p
        join jnl_densities  as d using ( prompt_id );"""
    #-------------------------------------------------------------------------------------------------------
    @db SQL"""
      create table img_files (
          path_id   text unique not null primary key,
          prompt_id text        not null,
          path      text unique not null,
        foreign key ( prompt_id ) references img_prompts ( prompt_id ) );"""
    #.......................................................................................................
    @db SQL"""
      create table img_prompts (
          prompt_id text unique not null primary key,
          prompt    text unique not null );"""
    #.......................................................................................................
    @db SQL"""insert into img_prompts ( prompt_id, prompt ) values ( ?, ? );""", [
      ( U.id_from_text U.nosuchprompt ), U.nosuchprompt, ]
    #.......................................................................................................
    @db SQL"""
      create view img_files_and_img_prompts as select
          f.path_id     as path_id,
          p.prompt_id   as prompt_id,
          f.path        as path,
          p.prompt      as prompt
        from      img_prompts as p
        left join img_files   as f using ( prompt_id );"""
    #=======================================================================================================
    @db SQL"""
      create view img_files_with_empty_prompts as select
          i.path_id         as path_id,
          i.prompt_id       as prompt_id,
          i.path            as path,
          i.prompt          as prompt
        from img_files_and_img_prompts as i
        where i.prompt = '';"""
    #.......................................................................................................
    @db SQL"""
      create view img_files_with_jnl_prompts as select
          i.path_id         as path_id,
          j.prompt_id       as prompt_id,
          i.path            as path,
          j.prompt          as prompt
        from jnl_prompts                as j
        join img_files_and_img_prompts  as i using ( prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view img_files_without_jnl_prompts as select
          i.path_id         as path_id,
          i.prompt_id       as prompt_id,
          i.path            as path,
          i.prompt          as prompt
        from img_files_and_img_prompts  as i
        where true
          and prompt != ''
          and not exists ( select 1 from jnl_prompts as j where i.prompt_id = j.prompt_id );
        """
    #=======================================================================================================
    ### TAINT auto-generate? ###
    ### NOTE will contain counts for all relations ###
    @db SQL"""
      create view rowcounts as
        select            null as name,                 null as rowcount where false
        -- -------------------------------------------------------------------------------------------------
        union all select  'jnl_prompts',                count(*)  from jnl_prompts
        union all select  'jnl_generations',            count(*)  from jnl_generations
        union all select  'jnl_counts',                 count(*)  from jnl_counts
        union all select  'jnl_densities',              count(*)  from jnl_densities
        union all select  'promptstats',                count(*)  from promptstats
        -- -------------------------------------------------------------------------------------------------
        union all select  'img_files',                  count(*)  from img_files
        union all select  'img_prompts',                count(*)  from img_prompts
        union all select  'img_files_and_img_prompts',      count(*)  from img_files_and_img_prompts
        -- -------------------------------------------------------------------------------------------------
        union all select  'img_files_with_empty_prompts',  count(*)  from img_files_with_empty_prompts
        union all select  'img_files_with_jnl_prompts',  count(*)  from img_files_with_jnl_prompts
        union all select  'img_files_without_jnl_prompts',  count(*)  from img_files_without_jnl_prompts
        -- -------------------------------------------------------------------------------------------------
        ;"""
    #=======================================================================================================
    ### TAINT this should become a standard part of `DBay`; note that as with `@_required_table_names`,
    one should walk the prototype chain ###
    hide @, 'insert_into', insert_into = {}
    #.......................................................................................................
    insert_into.jnl_prompts = do =>
      insert_stmt = @db.create_insert { into: 'jnl_prompts',  on_conflict: { update: true, }, }
      return U.wrap_insert insert_into_jnl_prompts = ( d ) => @db insert_stmt, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0 ### TAINT should be auto-converted ###
    #.......................................................................................................
    insert_into.jnl_generations = do =>
      insert_stmt = @db.create_insert { into: 'jnl_generations', }
      return U.wrap_insert insert_into_jnl_generations = ( d ) => @db insert_stmt, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0 ### TAINT should be auto-converted ###
    #-------------------------------------------------------------------------------------------------------
    insert_into.img_prompts = do =>
      insert_stmt = @db.create_insert { into: 'img_prompts', on_conflict: 'do nothing', }
      return U.wrap_insert insert_into_img_prompts = ( d ) => @db insert_stmt, d
    #.......................................................................................................
    insert_into.img_files = do =>
      insert_stmt = @db.create_insert { into: 'img_files', }
      return U.wrap_insert insert_into_img_files = ( d ) => @db insert_stmt, d
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  img_get_known_path_ids: -> new Set @db.first_values SQL"select path_id from img_files;"

#===========================================================================================================
module.exports = {
  Prompt_db, }


#===========================================================================================================
if module is require.main then await do =>
  echo()
  echo ( GUY.trm.grey 'Ω___6' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
