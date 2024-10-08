(function() {
  'use strict';
  var CRYPTO, DBay, ExifReader, FS, GUY, SQL, Utilities, alert, debug, echo, format_nr, help, info, inspect, log, plain, praise, reverse, rpr, urge, warn, whisper,
    indexOf = [].indexOf;

  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/utilities'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  FS = require('node:fs');

  CRYPTO = require('node:crypto');

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  ExifReader = require('exifreader');

  format_nr = (new Intl.NumberFormat('en-GB')).format;

  Utilities = (function() {
    //===========================================================================================================
    class Utilities {
      //---------------------------------------------------------------------------------------------------------
      constructor() {
        this.nosuchprompt = "";
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      get_db_table_names(db) {
        return db.all_first_values(SQL`select name from sqlite_schema where type = 'table' order by name;`);
      }

      //---------------------------------------------------------------------------------------------------------
      db_has_all_table_names(db, ...must_have_table_names) {
        var must_have_table_name, table_names;
        table_names = this.get_db_table_names(db);
        for (must_have_table_name of must_have_table_names) {
          if (indexOf.call(table_names, must_have_table_name) < 0) {
            return false;
          }
        }
        return true;
      }

      //---------------------------------------------------------------------------------------------------------
      id_from_text(text, length = 16) {
        var hash;
        hash = CRYPTO.createHash('sha1');
        hash.update(text);
        return (hash.digest('hex')).slice(0, length);
      }

      //---------------------------------------------------------------------------------------------------------
      normalize_prompt(prompt) {
        var R;
        R = prompt;
        R = R.replace(/\s*\.\s*$/, '');
        R = R.trim();
        R = R.replace(/\s{2,}/g, ' ');
        return R;
      }

      //---------------------------------------------------------------------------------------------------------
      pluck(x, key, fallback = null) {
        var R;
        R = x[key];
        delete x[key];
        return R != null ? R : fallback;
      }

      //---------------------------------------------------------------------------------------------------------
      format_nr(x, width = null) {
        var R;
        R = format_nr(x);
        if (width == null) {
          return R;
        }
        return R.padStart(width, ' ');
      }

      //---------------------------------------------------------------------------------------------------------
      wrap_insert(insert_method) {
        return function(d) {
          var error, name, row;
          try {
            return insert_method(d);
          } catch (error1) {
            error = error1;
            name = GUY.trm.reverse(GUY.trm.bold(` ${rpr(insert_method.name)} `));
            row = GUY.trm.reverse(GUY.trm.bold(` ${rpr(d)} `));
            warn();
            warn('Ω___1', `error: ${error.message}`);
            warn('Ω___2', `error happened in insert method ${name} with this data:`);
            warn();
            warn('Ω___3', row);
            warn();
            throw error;
          }
        };
      }

      //---------------------------------------------------------------------------------------------------------
      shuffle_predictably(list) {
        return (GUY.rnd.get_shuffle(4, 62))(list);
      }

    };

    //---------------------------------------------------------------------------------------------------------
    Utilities.prototype.exif_from_path = (() => {
      var my_buffer;
      my_buffer = new Buffer.alloc(2 * 1024);
      return function(path) {
        var R, data, exif, fd, ref;
        fd = FS.openSync(path);
        FS.readSync(fd, my_buffer);
        exif = ExifReader.load(my_buffer);
        if ((data = (ref = exif != null ? exif.UserComment : void 0) != null ? ref : null) != null) {
          R = JSON.parse((Buffer.from(data.value)).toString('utf-8'));
        } else {
          R = {
            prompt: this.nosuchprompt,
            date: null
          };
        }
        //.....................................................................................................
        R.prompt = this.normalize_prompt(R.prompt);
        R.prompt_id = this.id_from_text(R.prompt);
        return R;
      };
    })();

    //---------------------------------------------------------------------------------------------------------
    Utilities.prototype.color = {
      cmd: function(...P) {
        return GUY.trm.white(GUY.trm.reverse(GUY.trm.bold(...P)));
      },
      flag: function(...P) {
        return GUY.trm.grey(GUY.trm.reverse(GUY.trm.bold(...P)));
      },
      description: function(...P) {
        return GUY.trm.lime(...P);
      },
      expect: function(...P) {
        return GUY.trm.blue(...P);
      },
      bad: function(...P) {
        return GUY.trm.red(GUY.trm.reverse(GUY.trm.bold(...P)));
      }
    };

    return Utilities;

  }).call(this);

  //===========================================================================================================
  module.exports = {
    Utilities: Utilities,
    U: new Utilities()
  };

}).call(this);

//# sourceMappingURL=utilities.js.map