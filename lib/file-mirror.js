(function() {
  'use strict';
  var FS, File_mirror, GUY, PATH, SQL, U, alert, debug, echo, get_types, help, hide, info, inspect, log, plain, praise, rpr, types, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/file-mirror'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  ({hide} = GUY.props);

  ({U} = require('./utilities'));

  ({SQL} = DBay);

  PATH = require('node:path');

  FS = require('node:fs');

  ({get_types} = require('./types'));

  types = get_types();

  //===========================================================================================================
  File_mirror = class File_mirror {
    //---------------------------------------------------------------------------------------------------------
    /* TAINT use CFG pattern */
    constructor(cfg) {
      hide(this, 'types', get_types());
      this.cfg = this.types.create.fm_constructor_cfg(cfg);
      this._create_db_structure();
      this._populate_db();
      //.......................................................................................................
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    _create_db_structure() {
      whisper('Ω___1', "File_mirror::_create_db_structure");
      this._clear_db();
      this.cfg.db(() => {
        //.....................................................................................................
        /* TAINT a more general solution should accommodate more than a single source file */
        this.cfg.db(SQL`create table if not exists fm_datasources (
    lnr       integer not null primary key,
    line      text    not null );`);
        //.....................................................................................................
        return null;
      });
      //.......................................................................................................
      this.insert_into = {
        lines_table: (() => {
          var insert_statement;
          insert_statement = this.cfg.db.create_insert({
            into: this.cfg.table_name
          });
          return function(d) {
            return this.cfg.db.alt(insert_statement, d);
          };
        })()
      };
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _populate_db() {
      var error, ref;
      try {
        this.cfg.db(() => {
          var eol, line, lnr, ref, x;
          ref = GUY.fs.walk_lines_with_positions(this.cfg.datasource_path);
          for (x of ref) {
            ({lnr, line, eol} = x);
            this.insert_into.lines_table({lnr, line});
          }
          return null;
        });
      } catch (error1) {
        error = error1;
        if ((ref = error.code) === 'ENOENT' || ref === 'EACCES' || ref === 'EPERM') {
          whisper('Ω___2', "File_mirror::_populate_db", U.color.bad(error.message));
          process.exit(111);
        }
        throw error;
      }
      return null;
    }

  };

  //===========================================================================================================
  module.exports = {File_mirror};

}).call(this);

//# sourceMappingURL=file-mirror.js.map