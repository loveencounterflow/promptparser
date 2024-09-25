(async function() {
  'use strict';
  var FS, GUY, Image_walker, PATH, U, alert, debug, echo, get_types, help, hide, info, inspect, log, plain, praise, reverse, rpr, urge, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //===========================================================================================================
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/image-walker'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  FS = require('node:fs');

  PATH = require('node:path');

  ({U} = require('./utilities'));

  ({hide} = GUY.props);

  ({get_types} = require('./types'));

  //===========================================================================================================
  Image_walker = class Image_walker {
    //---------------------------------------------------------------------------------------------------------
    constructor(cfg) {
      hide(this, 'types', get_types());
      this.cfg = this.types.create.image_walker_cfg(cfg);
      hide(this, 'known_path_ids', U.pluck(this.cfg, 'known_path_ids', new Set()));
      hide(this, 'known_prompt_ids', U.pluck(this.cfg, 'known_prompt_ids', new Set()));
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    * [Symbol.iterator]() {
      return (yield* this.TMP_RENAME_build_file_db());
    }

    //-----------------------------------------------------------------------------------------------------------
    * TMP_RENAME_build_file_db() {
      var base_path, count, counts, glob, globSync, glob_cfg, i, len, path, path_id, patterns, prompt, prompt_id, ref, rel_path, rel_paths;
      ({glob, globSync} = require('glob'));
      base_path = PATH.resolve((ref = this.cfg.flags.images) != null ? ref : process.cwd());
      patterns = ['**/*.png', '**/*.jpg', '**/*.jpeg'];
      glob_cfg = {
        dot: true,
        cwd: base_path
      };
      count = 0;
      //.........................................................................................................
      // DB.db ->
      console.time('TMP_RENAME_build_file_db');
      counts = {
        skipped: 0,
        added: 0,
        deleted: 0,
        unsampled_files: 0
      };
      info('Ω___1', GUY.trm.reverse(`globbing files at ${glob_cfg.cwd} using ${rpr(patterns)}`));
      rel_paths = globSync(patterns, glob_cfg);
      info('Ω___2', GUY.trm.reverse(`found ${rel_paths.length} matching files`));
      for (i = 0, len = rel_paths.length; i < len; i++) {
        rel_path = rel_paths[i];
        count++;
        if ((modulo(count, 5e3)) === 0) {
          whisper(count);
        }
        path = PATH.resolve(base_path, rel_path);
        path_id = U.id_from_text(path);
        //.....................................................................................................
        /* TAINT use method that honors `seed` */
        /* --SAMPLE */
        if (Math.random() > this.cfg.flags.sample) {
          counts.unsampled_files++;
          continue;
        }
        //.....................................................................................................
        if (this.known_path_ids.has(path_id)) {
          counts.skipped++;
          continue;
        }
        //.....................................................................................................
        this.known_path_ids.add(path_id);
        counts.added++;
        ({prompt_id, prompt} = U.exif_from_path(path));
        if (!this.known_prompt_ids.has(prompt_id)) {
          this.known_prompt_ids.add(prompt_id);
          yield ({
            $key: 'record',
            table: 'all_prompts',
            fields: {prompt_id, prompt}
          });
        }
        yield ({
          $key: 'record',
          table: 'img_files',
          fields: {path_id, prompt_id, path}
        });
      }
      //.....................................................................................................
      info('Ω___4', counts);
      console.timeEnd('TMP_RENAME_build_file_db');
      //.........................................................................................................
      return null;
    }

  };

  //===========================================================================================================
  module.exports = {Image_walker};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      echo();
      echo(GUY.trm.grey('Ω___5'), GUY.trm.gold("run `node lib/cli.js help` instead of this file"));
      echo();
      return process.exit(111);
    })();
  }

}).call(this);

//# sourceMappingURL=image-walker.js.map