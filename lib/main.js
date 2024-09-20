(function() {
  'use strict';
  var GUY, alert, debug, echo, help, info, inspect, log, plain, praise, reverse, rpr, urge, warn, whisper;

  //===========================================================================================================
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  debug('Ω___1', require('./production-registry'));

  debug('Ω___2', require('./image-registry'));

  // #---------------------------------------------------------------------------------------------------------
// _create_db_structure: ->
//   super()
//   whisper 'Ω___6', "Prompt_file_reader::_create_db_structure"
//   @_db =>
//     @_db SQL"""
//       create table prd_prompts (
//           id        text    not null primary key,
//           lnr       integer not null,
//           prompt    text    not null,
//           comment   text        null,
//           rejected  boolean not null,
//         unique( prompt ) );"""
//     @_db SQL"""
//       create table prd_generations (
//           prompt_id text    not null,
//           nr        integer not null,
//           count     integer not null,
//         primary key ( prompt_id, nr ),
//         foreign key ( prompt_id ) references prd_prompts ( id ) );"""
//     @_db SQL"""
//       create view prd_counts as select distinct
//           prompt_id             as prompt_id,
//           count(*)      over w  as generations,
//           sum( count )  over w  as images
//         from prd_generations as g
//         window w as ( partition by prompt_id );"""
//     @_db SQL"""
//       create view prd_densities as select
//           c.prompt_id                                                                         as prompt_id,
//           c.generations                                                                       as generations,
//           c.images                                                                            as images,
//           cast( ( ( cast( c.images as real ) / c.generations / 4 ) * 100 + 0.5 ) as integer ) as density
//         from prd_generations as g
//         left join prd_counts as c on ( g.prompt_id = c.prompt_id );"""
//     @_db SQL"""
//       create view promptstats as select distinct
//           d.prompt_id     as prompt_id,
//           d.generations   as generations,
//           d.images        as images,
//           d.density       as density,
//           p.lnr           as lnr,
//           p.prompt        as prompt
//         from prd_prompts    as p
//         join prd_densities  as d on ( p.id = d.prompt_id );"""
//     #.....................................................................................................
//     ### TAINT auto-generate? ###
//     ### NOTE will contain counts for all relations ###
//     @_db SQL"""
//       create view rowcounts as
//         select            null as name,         null as rowcount where false
//         union all select  'prd_prompts',        count(*)          from prd_prompts
//         union all select  'prd_generations',    count(*)          from prd_generations
//         union all select  'prd_counts',         count(*)          from prd_counts
//         union all select  'prd_densities',      count(*)          from prd_densities
//         ;"""
//     #.....................................................................................................
//     ### TAINT auto-generate ###
//     hide @, '_insert_into',
//       fm_datasources:   @_db.create_insert { into: 'fm_datasources',                               }
//       prd_prompts:      @_db.create_insert { into: 'prd_prompts',  on_conflict: { update: true, }, }
//       prd_generations:  @_db.create_insert { into: 'prd_generations',                              }
//     return null
//   return null

  // #---------------------------------------------------------------------------------------------------------
// ### TAINT this should become a standard part of `DBay`; note that as with `@_required_table_names`,
// one should walk the prototype chain ###
// @insert_into:
//   #.......................................................................................................
//   fm_datasources: ( d ) ->
//     ### TAINT validate? ###
//     return @_db.alt @_insert_into.fm_datasources, d
//   #.......................................................................................................
//   prd_prompts: ( d ) ->
//     ### TAINT validate? ###
//     return @_db.alt @_insert_into.prd_prompts, lets d, ( d ) ->
//       d.rejected = if d.rejected is true then 1 else 0
//   #.......................................................................................................
//   prd_generations: ( d ) ->
//     ### TAINT validate? ###
//     return @_db.alt @_insert_into.prd_generations, d

  // #---------------------------------------------------------------------------------------------------------
// _populate_db: ->
//   whisper 'Ω___7', "Prompt_file_reader::_populate_db"

}).call(this);

//# sourceMappingURL=main.js.map