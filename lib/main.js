(async function() {
  'use strict';
  var DATOM, DBay, GUY, Image_walker, Journal_walker, Prompt_db, SQL, alert, cmd, debug, echo, flags, get_types, help, hide, info, inspect, lets, lines, log, new_datom, plain, pluck, praise, reverse, rpr, run_image_walker, run_journal_walker, stamp, urge, warn, whisper;

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
  ({DATOM} = require('datom'));

  ({new_datom, lets, stamp} = DATOM);

  //...........................................................................................................
  ({Journal_walker} = require('./journal-walker'));

  ({Image_walker} = require('./image-walker'));

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  // { U               }       = require './utilities'
  // { trash           }       = require 'trash-sync'
  ({Prompt_db} = require('./prompt-db'));

  //===========================================================================================================
  lines = null;

  cmd = 'build';

  flags = {
    match: /(?:)/,
    trash_db: true,
    // sample:     0.05,
    // sample:     0.1,
    sample: 1,
    // max_count:  20,
    max_count: 2e308,
    prompts: '../../jzr/to-be-merged-from-Atlas/prompts-consolidated.md',
    images: '../../Downloads/b-from-downloader',
    seed: 1,
    pre_match: /^\[.*?\].*?\S+/,
    db: '/dev/shm/promptparser.sqlite'
  };

  //===========================================================================================================
  run_journal_walker = function*({prompt_db, known_prompt_ids}) {
    lines = GUY.fs.walk_lines_with_positions(flags.prompts);
    yield* new Journal_walker({cmd, flags, lines, known_prompt_ids});
    return null;
  };

  //===========================================================================================================
  run_image_walker = function*({prompt_db, known_path_ids, known_prompt_ids}) {
    yield* new Image_walker({cmd, flags, known_path_ids, known_prompt_ids});
    return null;
  };

  //===========================================================================================================
  module.exports = {Journal_walker, Image_walker, Prompt_db};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      var known_path_ids, known_prompt_ids, prompt_db;
      prompt_db = new Prompt_db({cmd, flags});
      known_path_ids = prompt_db.get_known_path_ids();
      known_prompt_ids = prompt_db.get_known_prompt_ids();
      (() => {        //---------------------------------------------------------------------------------------------------------
        var count, d, ref;
        count = 0;
        ref = run_image_walker({prompt_db, known_path_ids, known_prompt_ids});
        for (d of ref) {
          count++;
          if (count > flags.max_count) {
            break;
          }
          prompt_db.insert_into[d.table](d.fields);
        }
        return null;
      })();
      (() => {        //---------------------------------------------------------------------------------------------------------
        var d, ref;
        ref = run_journal_walker({prompt_db, known_prompt_ids});
        for (d of ref) {
          prompt_db.insert_into[d.table](d.fields);
        }
        return null;
      })();
      //---------------------------------------------------------------------------------------------------------
      return null;
      echo();
      echo(GUY.trm.grey('Ω___3'), GUY.trm.gold("run `node lib/cli.js help` instead of this file"));
      echo();
      return process.exit(111);
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map