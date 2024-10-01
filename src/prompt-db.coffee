
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
    hide @, 'db',     new DBay { path, }
    hide @, 'cache',  { known_path_ids: null, known_prompt_ids: null, }
    @create_db_structure()
    return undefined

  #---------------------------------------------------------------------------------------------------------
  create_db_structure: ->
    # super()
    whisper 'Ω___1', "Prompt_file_reader::create_db_structure"
    #.......................................................................................................
    @db SQL"""
      create table all_prompts (
          prompt_id text    unique not null primary key,
          prompt    text    unique not null );"""
    #.......................................................................................................
    @db SQL"""insert into all_prompts ( prompt_id, prompt ) values ( ?, ? );""", [
      ( U.id_from_text U.nosuchprompt ), U.nosuchprompt, ]
    #.......................................................................................................
    @db SQL"""
      create table jnl_prompts (
          prompt_id text    unique not null primary key,
          lnr       integer unique not null,
          comment   text               null,
          rejected  boolean        not null );"""
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
          sum( count )  over w  as production
        from jnl_generations as g
        window w as ( partition by prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view _jnl_productivities as select
          c.prompt_id                                                                             as prompt_id,
          c.generations                                                                           as generations,
          c.production                                                                            as production,
          cast( ( ( cast( c.production as real ) / c.generations / 4 ) * 100 + 0.5 ) as integer ) as productivity
        from jnl_generations as g
        left join jnl_counts as c using ( prompt_id );"""
    #-------------------------------------------------------------------------------------------------------
    @db SQL"""
      create table img_files (
          path_id   text unique not null primary key,
          prompt_id text        not null,
          path      text unique not null,
        foreign key ( prompt_id ) references all_prompts ( prompt_id ) );"""
    #.......................................................................................................
    @db SQL"""
      create view img_files_and_prompts as select
          f.path_id     as path_id,
          a.prompt_id   as prompt_id,
          f.path        as path,
          a.prompt      as prompt
        from img_files   as f
        join all_prompts as a using ( prompt_id );"""
    #=======================================================================================================
    @db SQL"""
      create view img_files_with_empty_prompts as select
          i.path_id         as path_id,
          i.prompt_id       as prompt_id,
          i.path            as path,
          i.prompt          as prompt
        from img_files_and_prompts as i
        where i.prompt = '';"""
    #.......................................................................................................
    @db SQL"""
      create view img_files_with_jnl_prompts as select
          i.path_id         as path_id,
          a.prompt_id       as prompt_id,
          i.path            as path,
          a.prompt          as prompt
        from img_files_and_prompts  as i
        join all_prompts            as a using ( prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view img_file_prompt_counts as select distinct
          äll.prompt_id       as prompt_id,
          count( img.path ) over w            as downloads
        from img_files_and_prompts  as img
        join all_prompts            as äll using ( prompt_id )
        window w as ( partition by prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view all_prompts_and_occurrences as select
          a.prompt_id         as prompt_id,
          jnl.prompt_id       as jnl_prompt_id,
          img.prompt_id       as img_prompt_id,
          a.prompt            as prompt
        from      all_prompts   as a
        left join jnl_prompts   as jnl using ( prompt_id )
        left join img_files     as img using ( prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view all_prompts_without_img_files as select
          *
        from all_prompts_and_occurrences  as o
        join all_prompts                  as a using ( prompt_id )
        where true
          and a.prompt != ''
          and img_prompt_id is null;"""
    #.......................................................................................................
    @db SQL"""
      create view all_prompts_without_jnl_entries as select
          *
        from all_prompts_and_occurrences  as o
        join all_prompts                  as a using ( prompt_id )
        where true
          and a.prompt != ''
          and jnl_prompt_id is null;"""
    #=======================================================================================================
    @db SQL"""
      create view _jnl_prodpoints as select distinct
          d.prompt_id                                                       as prompt_id,
          d.generations                                                     as generations,
          d.generations * 4                                                 as potential,
          d.production                                                      as production,
          d.productivity                                                    as productivity,
          d.productivity * d.production                                     as prodpoints,
          c.downloads                                                       as downloads,
          cast( cast( c.downloads as float ) / d.production * 100 + 0.5 as integer ) as acceptance,
          p.lnr                                                             as lnr,
          a.prompt                                                          as prompt
        from jnl_prompts            as p
        join _jnl_productivities    as d using ( prompt_id )
        join all_prompts            as a using ( prompt_id )
        join img_file_prompt_counts as c using ( prompt_id );"""
    #.......................................................................................................
    @db SQL"""
      create view jnl_promptstats as select
          p.prompt_id                       as prompt_id,
          p.generations                     as generations,
          p.potential                       as potential,
          p.production                      as production,
          p.downloads                       as downloads,
          p.acceptance                      as acceptance,
          p.productivity                    as productivity,
          p.prodpoints                      as prodpoints,
          p.lnr                             as lnr,
          p.prompt                          as prompt
        from _jnl_prodpoints as p
        order by
          p.prodpoints desc,
          p.acceptance desc,
          -- fooQQQ desc,
          p.productivity desc,
          p.lnr desc;"""
    #.......................................................................................................
    @db SQL"""
      create view faults_downloads_gt_production as select distinct
        s.production  as production,
        s.downloads   as downloads,
        s.prompt_id   as prompt_id,
        s.lnr         as lnr,
        s.prompt      as prompt
        -- f.path        as path
        from jnl_promptstats  as s
        -- join img_files        as f using ( prompt_id )
        where s.downloads > s.production
        order by ( s.downloads - s.production ) desc;"""
    #=======================================================================================================
    ### TAINT auto-generate? ###
    ### NOTE will contain counts for all relations ###
    @db SQL"""
      create view rowcounts as
        select            null as name,                 null as rowcount where false
        -- -------------------------------------------------------------------------------------------------
        union all select  'all_prompts',                      count(*)  from all_prompts
        -- -------------------------------------------------------------------------------------------------
        union all select  'jnl_prompts',                      count(*)  from jnl_prompts
        union all select  'jnl_generations',                  count(*)  from jnl_generations
        union all select  'jnl_counts',                       count(*)  from jnl_counts
        union all select  '_jnl_productivities',                    count(*)  from _jnl_productivities
        union all select  'jnl_promptstats',                  count(*)  from jnl_promptstats
        -- -------------------------------------------------------------------------------------------------
        union all select  'img_files',                        count(*)  from img_files
        union all select  'img_files_and_prompts',            count(*)  from img_files_and_prompts
        -- -------------------------------------------------------------------------------------------------
        union all select  'img_files_with_empty_prompts',     count(*)  from img_files_with_empty_prompts
        union all select  'img_files_with_jnl_prompts',       count(*)  from img_files_with_jnl_prompts
        union all select  'all_prompts_and_occurrences',      count(*)  from all_prompts_and_occurrences
        union all select  'all_prompts_without_img_files',    count(*)  from all_prompts_without_img_files
        union all select  'all_prompts_without_jnl_entries',  count(*)  from all_prompts_without_jnl_entries
        -- -------------------------------------------------------------------------------------------------
        union all select  'faults_downloads_gt_production',   count(*)  from faults_downloads_gt_production
        ;"""
    #=======================================================================================================
    @db SQL"""
      create view faultcounts as
        select * from rowcounts where name like 'faults_%';"""
    #=======================================================================================================
    ### TAINT this should become a standard part of `DBay`; note that as with `@_required_table_names`,
    one should walk the prototype chain ###
    hide @, 'insert_into', insert_into = {}
    #.......................................................................................................
    insert_into.all_prompts = do =>
      insert_stmt = @db.create_insert { into: 'all_prompts',  on_conflict: { update: true, }, }
      return U.wrap_insert insert_into_all_prompts = ( d ) => @db insert_stmt, d
    #.......................................................................................................
    insert_into.jnl_prompts = do =>
      insert_stmt = @db.create_insert { into: 'jnl_prompts',  on_conflict: { update: true, }, }
      return U.wrap_insert insert_into_jnl_prompts = ( d ) => @db insert_stmt, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0 ### TAINT should be auto-converted ###
    #.......................................................................................................
    insert_into.jnl_generations = do =>
      insert_stmt = @db.create_insert { into: 'jnl_generations', }
      return U.wrap_insert insert_into_jnl_generations = ( d ) => @db insert_stmt, d
    #.......................................................................................................
    insert_into.img_files = do =>
      insert_stmt = @db.create_insert { into: 'img_files', }
      return U.wrap_insert insert_into_img_files = ( d ) => @db insert_stmt, d
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  get_known_path_ids: ->
    return @cache.known_path_ids    if @cache.known_path_ids?
    return ( @cache.known_path_ids = new Set @db.first_values SQL"select path_id from img_files;"      )

  #---------------------------------------------------------------------------------------------------------
  get_known_prompt_ids:   ->
    return @cache.known_prompt_ids  if @cache.known_prompt_ids?
    return ( @cache.known_prompt_ids   = new Set @db.first_values SQL"select prompt_id from all_prompts;"  )

#===========================================================================================================
module.exports = {
  Prompt_db, }


#===========================================================================================================
if module is require.main then await do =>
  echo()
  echo ( GUY.trm.grey 'Ω___6' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
