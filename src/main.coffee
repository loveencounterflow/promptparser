
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
  whisper }               = GUY.trm.get_loggers 'promptparser'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm
#...........................................................................................................
pluck                     = ( o, k ) -> R = o[ k ]; delete o[ k ]; R
#...........................................................................................................
{ Journal_walker  }       = require './journal-walker'
{ Image_walker    }       = require './image-walker'

#===========================================================================================================
class Prompt_db

  #---------------------------------------------------------------------------------------------------------
  constructor: ( cfg ) ->
    hide @, 'types',  get_types()
    @cfg = @types.create.prompt_db.cfg cfg
    @trash_db_if_necessary()
    hide @, 'db',     pluck @cfg, 'db'
    @create_db_structure()
    # @_populate_db() ???
    return undefined

  #---------------------------------------------------------------------------------------------------------
  trash_db_if_necessary: ->
    return 0 unless @cfg.trash_db
    return trash @cfg.db_path

  #---------------------------------------------------------------------------------------------------------
  create_db_structure: ->
    # super()
    whisper 'Ω___1', "Prompt_file_reader::create_db_structure"
    #.......................................................................................................
    @db SQL"""
      create table jnl_prompts (
          id        text    not null primary key,
          lnr       integer not null,
          prompt    text    not null,
          comment   text        null,
          rejected  boolean not null,
        unique( prompt ) );"""
    #.......................................................................................................
    @db SQL"""
      create table jnl_generations (
          prompt_id text    not null,
          nr        integer not null,
          count     integer not null,
        primary key ( prompt_id, nr ),
        foreign key ( prompt_id ) references jnl_prompts ( id ) );"""
    #.......................................................................................................
    @db SQL"""
      create view jnl_counts as select distinct
          prompt_id             as prompt_id,
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
        left join jnl_counts as c on ( g.prompt_id = c.prompt_id );"""
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
        join jnl_densities  as d on ( p.id = d.prompt_id );"""
    #.......................................................................................................
    ### TAINT auto-generate? ###
    ### NOTE will contain counts for all relations ###
    @db SQL"""
      create view rowcounts as
        select            null as name,         null as rowcount where false
        union all select  'jnl_prompts',        count(*)          from jnl_prompts
        union all select  'jnl_generations',    count(*)          from jnl_generations
        union all select  'jnl_counts',         count(*)          from jnl_counts
        union all select  'jnl_densities',      count(*)          from jnl_densities
        ;"""
    #.......................................................................................................
    ### TAINT this should become a standard part of `DBay`; note that as with `@_required_table_names`,
    one should walk the prototype chain ###
    hide @, 'insert_into', insert_into = {}
    #.......................................................................................................
    insert_into.jnl_prompts = do =>
      insert_stmt = @db.create_insert { into: 'jnl_prompts',  on_conflict: { update: true, }, }
      return ( d ) -> @db insert_stmt, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0 ### TAINT should be auto-converted ###
    #.......................................................................................................
    insert_into.jnl_generations = do =>
      insert_stmt = @db.create_insert { into: 'jnl_generations', }
      return ( d ) => @db insert_stmt, lets d, ( d ) ->
        d.rejected = if d.rejected is true then 1 else 0 ### TAINT should be auto-converted ###
    return null


#===========================================================================================================
module.exports = {
  Prompt_db, }


#===========================================================================================================
if module is require.main then await do =>

  cmd   = 'build'
  flags =
    match:      /(?:)/,
    trash_db:   true,
    sample:     0.01,
    max_count:  3,
    prompts:    '../to-be-merged-from-Atlas/prompts-consolidated.md'
    seed:       1,
    pre_match:  /^\[.*?\].*?\S+/,
    db:         '/dev/shm/promptparser.sqlite'

  lines = GUY.fs.walk_lines_with_positions flags.prompts

  debug 'Ω___3', new Prompt_db { cmd, flags, }

  return null

  echo()
  echo ( GUY.trm.grey 'Ω___4' ), ( GUY.trm.gold "run `node lib/cli.js help` instead of this file" )
  echo()
  process.exit 111
