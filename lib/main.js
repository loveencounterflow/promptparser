(async function() {
  'use strict';
  var DBay, GUY, Image_walker, Journal_walker, Prompt_db, SQL, alert, cmd, debug, echo, flags, get_types, help, hide, info, inspect, log, plain, pluck, praise, reverse, rpr, run_image_walker, run_journal_walker, urge, warn, whisper;

  //===========================================================================================================
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  //...........................................................................................................
  ({hide} = GUY.props);

  pluck = function(o, k) {
    var R;
    R = o[k];
    delete o[k];
    return R;
  };

  ({get_types} = require('./types'));

  //...........................................................................................................
  ({Journal_walker} = require('./journal-walker'));

  ({Image_walker} = require('./image-walker'));

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  // { U               }       = require './utilities'
  // { trash           }       = require 'trash-sync'
  ({Prompt_db} = require('./prompt-db'));

  //===========================================================================================================
  cmd = 'build';

  flags = {
    match: /(?:)/,
    trash_db: true,
    sample: 0.01,
    max_count: 3,
    prompts: '../to-be-merged-from-Atlas/prompts-consolidated.md',
    seed: 1,
    pre_match: /^\[.*?\].*?\S+/,
    db: '/dev/shm/promptparser.sqlite'
  };

  //===========================================================================================================
  run_journal_walker = function*() {
    var lines;
    lines = GUY.fs.walk_lines_with_positions(flags.prompts);
    yield* new Journal_walker({cmd, flags, lines});
    return null;
  };

  //===========================================================================================================
  run_image_walker = function*() {
    yield* new Image_walker();
    return null;
  };

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      var lines, name, prompt_db, ref, x;
      lines = GUY.fs.walk_lines_with_positions(flags.prompts);
      prompt_db = new Prompt_db({cmd, flags});
      ref = prompt_db.db(SQL`select name from sqlite_schema where type in ( 'table', 'view' );`);
      for (x of ref) {
        ({name} = x);
        debug('Ω___1', name);
      }
      (() => {
        var count, d, ref1;
        count = 0;
        ref1 = run_journal_walker();
        for (d of ref1) {
          count++;
          if (count > 10) {
            break;
          }
          info('Ω___2', d);
          info('Ω___2', prompt_db.insert_into[d.table]);
        }
        return null;
      })();
      (() => {
        var count, d, ref1;
        count = 0;
        ref1 = run_image_walker();
        for (d of ref1) {
          count++;
          if (count > 10) {
            break;
          }
          help('Ω___4', d);
        }
        return null;
      })();
      return null;
      echo();
      echo(GUY.trm.grey('Ω___5'), GUY.trm.gold("run `node lib/cli.js help` instead of this file"));
      echo();
      return process.exit(111);
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map