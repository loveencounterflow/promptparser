(function() {
  'use strict';
  var CRYPTO, DBay, ExifReader, FS, GUY, SQL, Utilities, alert, debug, echo, help, info, inspect, log, plain, praise, reverse, rpr, urge, warn, whisper,
    indexOf = [].indexOf;

  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/file-cache-builder'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  FS = require('node:fs');

  CRYPTO = require('node:crypto');

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  ExifReader = require('exifreader');

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
        var i, len, must_have_table_name, table_names;
        table_names = this.get_db_table_names(db);
        for (i = 0, len = must_have_table_names.length; i < len; i++) {
          must_have_table_name = must_have_table_names[i];
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
        return prompt.trim().replace(/\.$/, '');
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

    return Utilities;

  }).call(this);

  //===========================================================================================================
  module.exports = {
    Utilities: Utilities,
    U: new Utilities()
  };

}).call(this);

//# sourceMappingURL=utilities.js.map