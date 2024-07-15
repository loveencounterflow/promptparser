(async function() {
  'use strict';
  var DBay, FS, GUY, SQL, U, alert, build_file_db, debug, echo, help, info, inspect, log, plain, praise, prepare_db, reverse, rpr, set_path, urge, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; },
    indexOf = [].indexOf;

  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/file-cache-builder'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  FS = require('node:fs');

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  ({U} = require('./utilities'));

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT this should become part of command line handling with [M.I.X.A.](https://github.com/loveencounterflow/mixa) */
  set_path = function() {
    var R, path, ref;
    if ((path = (ref = process.argv[2]) != null ? ref : null) != null) {
      process.chdir(path);
    }
    R = process.cwd();
    info(`Ω___1 CWD: ${R}`);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  build_file_db = function() {
    var DB, PATH, base_path, cfg, count, glob, globSync, patterns;
    PATH = require('node:path');
    ({glob, globSync} = require('glob'));
    patterns = ['**/*.png', '**/*.jpg'];
    cfg = {
      dot: true
    };
    base_path = set_path();
    count = 0;
    DB = prepare_db();
    (() => {      //.........................................................................................................
      DB.db(function() {
        var abs_path, counts, error, exif, i, len, path_id, rel_path, rel_paths;
        console.time('build_file_db');
        counts = {
          skipped: 0,
          added: 0,
          deleted: 0
        };
        rel_paths = globSync(patterns, cfg);
        info('Ω___2', `found ${rel_paths.length} matching files`);
        for (i = 0, len = rel_paths.length; i < len; i++) {
          rel_path = rel_paths[i];
          count++;
          if ((modulo(count, 1000)) === 0) {
            whisper(count);
          }
          // break if count > 10000 ### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ###
          abs_path = PATH.resolve(base_path, rel_path);
          path_id = U.id_from_text(abs_path);
          //...................................................................................................
          if (DB.known_path_ids.has(path_id)) {
            // help "Ω___3 skipping path ID #{rpr path_id}"
            counts.skipped++;
            /* NOTE we know that in the present run we will not again have to test against the current
                     `path_id`, so we also know we can safely delete it from the pool of known IDs (thereby making it
                     smaller and potentially a tad faster); after having gone through all `path_ids` in the file
                     system, we will then effectively have turned `DB.known_path_ids` into `extraneous_path_ids`, i.e.
                     those that could be deleted from the DB if deemed necessary. */
            DB.known_path_ids.delete(path_id);
          } else {
            //#################################################################################################
            //#################################################################################################
            /* TAINT factor this into method */
            // warn "Ω___4 inserting path ID #{rpr path_id}"
            counts.added++;
            //.................................................................................................
            exif = U.exif_from_path(abs_path);
            try {
              /* TAINT use prepared statement */
              DB.db(SQL`insert into prompts ( id, prompt ) values ( ?, ? )
  on conflict ( id ) do nothing;`, [exif.prompt_id, exif.prompt]);
            } catch (error1) {
              error = error1;
              warn('Ω___5', `error: ${error.message}`);
              warn('Ω___6', `error happened with this data: ${rpr(exif)}`);
            }
            try {
              //.................................................................................................
              /* TAINT use prepared statement */
              DB.db(SQL`insert into files ( id, prompt_id, path ) values ( ?, ?, ? );`, [path_id, exif.prompt_id, abs_path]);
            } catch (error1) {
              error = error1;
              warn('Ω___7', `error: ${error.message}`);
              warn('Ω___8', `error happened with this data: ${rpr({
                path_id,
                prompt_id: exif.prompt_id,
                abs_path
              })}`);
            }
          }
        }
        //#################################################################################################
        //#################################################################################################
        //.....................................................................................................
        info(`Ω___9 changes to DB at ${DB.path}: ${rpr(counts)}`);
        //.....................................................................................................
        return null;
      });
      console.timeEnd('build_file_db');
      return null;
    })();
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  prepare_db = function() {
    var db, get_must_initialize, initialize_db, known_path_ids, path;
    path = '/dev/shm/files-and-prompts.sqlite';
    db = new DBay({path});
    //.........................................................................................................
    get_must_initialize = function(db) {
      var R, tables;
      tables = db.first_values(SQL`select name from sqlite_schema where type = 'table' order by name;`);
      tables = [...tables];
      R = false;
      R || (R = indexOf.call(tables, 'files') < 0);
      R || (R = indexOf.call(tables, 'prompts') < 0);
      return R;
    };
    //.........................................................................................................
    initialize_db = function(db) {
      db(function() {
        db(SQL`drop table if exists files;`);
        db(SQL`drop table if exists prompts;`);
        db(SQL`create table files (
    id        text not null primary key,
    prompt_id text not null,
    path      text not null,
  foreign key ( prompt_id ) references prompts ( id ) );`);
        db(SQL`create table prompts (
  id      text not null primary key,
  prompt  text not null );`);
        db(SQL`insert into prompts ( id, prompt ) values ( ?, ? );`, [U.id_from_text(U.nosuchprompt), U.nosuchprompt]);
        return null;
      });
      return null;
    };
    //.........................................................................................................
    if (get_must_initialize(db)) {
      warn(`Ω__10 initializing DB at ${path}`);
      initialize_db(db);
    } else {
      help(`Ω__11 re-using DB at ${path}`);
    }
    //.........................................................................................................
    /* TAINT can we use an API call to get a set? */
    known_path_ids = (() => {
      var R, id, ref;
      R = new Set();
      ref = db.first_values(SQL`select * from files;`);
      for (id of ref) {
        R.add(id);
      }
      return R;
    })();
    //.........................................................................................................
    return {path, db, known_path_ids};
  };

  //===========================================================================================================
  module.exports = {build_file_db};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      // await demo_fast_glob()
      // await demo_node_glob()
      // await demo_exifr()
      // await demo_exiftool_vendored()
      // demo_dbay_with_exifdata()
      return build_file_db();
    })();
  }

  // debug 'Ω__12', U.id_from_text '/home/flow/Downloads/b-from-downloader/1707087663.6605954170/2024-02-04T0000+0100_0009_photo-sonnenlicht-seitenansicht-im-muskelpark-von-.jpg'
// debug 'Ω__13', U.id_from_text '/home/flow/Downloads/b-from-downloader/1714131794.2192695141/2024-04-26T1155+0200_0144_analoges-amateurphoto-unscharfe-kratzer-90s-vibe-s.jpg'

}).call(this);

//# sourceMappingURL=file-cache-builder.js.map