(async function() {
  'use strict';
  var DBay, FS, GUY, SQL, U, alert, debug, demo_exifreader, echo, help, info, inspect, log, plain, praise, prepare_db, reverse, rpr, set_path, urge, warn, whisper,
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
  demo_exifreader = function() {
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
        var abs_path, counts, exif, i, len, path_id, rel_path, rel_paths;
        console.time('demo_exifreader');
        counts = {
          skipped: 0,
          added: 0,
          deleted: 0
        };
        rel_paths = globSync(patterns, cfg);
        info('Ω__17', `found ${rel_paths.length} matching files`);
        for (i = 0, len = rel_paths.length; i < len; i++) {
          rel_path = rel_paths[i];
          count++;
          if ((modulo(count, 1000)) === 0) {
            whisper(count);
          }
          if (count > 10000/* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */) {
            break;
          }
          abs_path = PATH.resolve(base_path, rel_path);
          path_id = U.id_from_text(abs_path);
          //...................................................................................................
          if (DB.known_path_ids.has(path_id)) {
            // help "Ω__18 skipping path ID #{rpr path_id}"
            counts.skipped++;
            /* NOTE we know that in the present run we will not again have to test against the current
                     `path_id`, so we also know we can safely delete it from the pool of known IDs (thereby making it
                     smaller and potentially a tad faster); after having gone through all `path_ids` in the file
                     system, we will then effectively have turned `DB.known_path_ids` into `extraneous_path_ids`, i.e.
                     those that could be deleted from the DB if deemed necessary. */
            DB.known_path_ids.delete(path_id);
          } else {
            // warn "Ω__19 inserting path ID #{rpr path_id}"
            counts.added++;
            //.................................................................................................
            exif = U.exif_from_path(abs_path);
            /* TAINT use prepared statement */
            DB.db(SQL`insert into prompts ( id, prompt ) values ( ?, ? )
  on conflict ( id ) do nothing;`, [exif.prompt_id, exif.prompt]);
            /* TAINT use prepared statement */
            DB.db(SQL`insert into files ( id, prompt_id, path ) values ( ?, ?, ? );`, [path_id, exif.prompt_id, abs_path]);
          }
        }
        //.....................................................................................................
        info(`Ω__21 changes to DB at ${DB.path}: ${rpr(counts)}`);
        //.....................................................................................................
        return null;
      });
      console.timeEnd('demo_exifreader');
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
      warn(`Ω__22 initializing DB at ${path}`);
      initialize_db(db);
    } else {
      help(`Ω__23 re-using DB at ${path}`);
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
  if (module === require.main) {
    await (async() => {
      // await demo_fast_glob()
      // await demo_node_glob()
      // await demo_exifr()
      // await demo_exiftool_vendored()
      return (await demo_exifreader());
    })();
  }

  // demo_dbay_with_exifdata()

}).call(this);

//# sourceMappingURL=file-cache-builder.js.map