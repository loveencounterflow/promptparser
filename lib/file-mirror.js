(function() {
  'use strict';
  var DBay, Dbay_autopop, FS, File_mirror, GUY, PATH, SQL, U, alert, debug, echo, get_types, help, hide, info, inspect, log, plain, praise, rpr, trash, types, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/db-bases'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  ({hide} = GUY.props);

  ({U} = require('./utilities'));

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  PATH = require('node:path');

  FS = require('node:fs');

  ({get_types} = require('./types'));

  types = get_types();

  ({trash} = require('trash-sync'));

  /*

  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
            8888888888          8888888888          8888888888          8888888888          8888888888
            8888888888          8888888888          8888888888          8888888888          8888888888
            8888888888          8888888888          8888888888          8888888888          8888888888
            8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888
  8888888888          8888888888          8888888888          8888888888          8888888888          8888888888

  */
  //===========================================================================================================
  /* TAINT should inherit from common base class together with File_mirror */
  Dbay_autopop = class Dbay_autopop {
    //---------------------------------------------------------------------------------------------------------
    // @required_table_names: [ 'fm_datasources', ]

      //---------------------------------------------------------------------------------------------------------
    /* TAINT use CFG pattern */
    constructor() {
      hide(this, 'types', get_types());
      //.......................................................................................................
      return void 0;
    }

  };

  File_mirror = (function() {
    /*

    8888888888 8888888 888      8888888888   888b     d888 8888888 8888888b.  8888888b.   .d88888b.  8888888b.
    888          888   888      888          8888b   d8888   888   888   Y88b 888   Y88b d88P" "Y88b 888   Y88b
    888          888   888      888          88888b.d88888   888   888    888 888    888 888     888 888    888
    8888888      888   888      8888888      888Y88888P888   888   888   d88P 888   d88P 888     888 888   d88P
    888          888   888      888          888 Y888P 888   888   8888888P"  8888888P"  888     888 8888888P"
    888          888   888      888          888  Y8P  888   888   888 T88b   888 T88b   888     888 888 T88b
    888          888   888      888          888   "   888   888   888  T88b  888  T88b  Y88b. .d88P 888  T88b
    888        8888888 88888888 8888888888   888       888 8888888 888   T88b 888   T88b  "Y88888P"  888   T88b

    */
    //===========================================================================================================
    class File_mirror extends Dbay_autopop {
      //---------------------------------------------------------------------------------------------------------
      /* TAINT use CFG pattern */
      constructor(db_path, datasource_path, trash_db = false) {
        super();
        hide(this, 'types', get_types());
        this.cfg = this.types.create.fm_constructor_cfg(db_path, datasource_path, trash_db);
        this._trash_db_if_necessary();
        //.......................................................................................................
        hide(this, '_db', new DBay({
          path: this.cfg.db_path
        }));
        //.......................................................................................................
        /* NOTE stuff like the below could go into a DBay utility class */
        this._prepare_db_connection();
        this._create_db_structure_if_necessary();
        if (new.target === File_mirror) {
          this._populate_db_if_necessary();
        }
        //.......................................................................................................
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      _trash_db_if_necessary() {
        if (!this.cfg.trash_db) {
          return 0;
        }
        return trash(this.cfg.db_path);
      }

      //---------------------------------------------------------------------------------------------------------
      _prepare_db_connection() {
        // whisper 'Ω___1', "File_mirror._prepare_db_connection"
        // @_db =>
        //   @_db.create_table_function
        //     name:         'file_contents_t'
        //     columns:      [ 'lnr', 'line', 'eol', ]
        //     parameters:   [ 'filename', ]
        //     rows: ( filename ) ->
        //       path  = PATH.resolve process.cwd(), filename
        //       for { lnr, line, eol, } from GUY.fs.walk_lines_with_positions path
        //         yield { lnr, line, eol, }
        //       return null
        //   return null
        // #.......................................................................................................
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _get_required_table_names() {
        var p;
        return new Set(((function() {
          var i, len, ref, ref1, results;
          ref = WG.props.get_prototype_chain(this.constructor);
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            p = ref[i];
            results.push((ref1 = p.required_table_names) != null ? ref1 : []);
          }
          return results;
        }).call(this)).flat());
      }

      //---------------------------------------------------------------------------------------------------------
      _create_db_structure_if_necessary() {
        if (U.db_has_all_table_names(this._db, this.constructor.required_table_names)) {
          whisper('Ω___2', `File_mirror::_create_db_structure_if_necessary: re-using DB at ${this.cfg.db_path}`);
        } else {
          whisper('Ω___3', `File_mirror::_create_db_structure_if_necessary: creating structure of DB at ${this.cfg.db_path}`);
          this._create_db_structure();
        }
        //.......................................................................................................
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _clear_db() {
        /* TAINT belongs to Prompt_file_reader */
        /* TAINT use `_required_table_names` */
        this._db(() => {
          return this._db(SQL`drop table if exists prompts;`);
        });
        //.......................................................................................................
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _create_db_structure() {
        whisper('Ω___4', "File_mirror::_create_db_structure");
        this._clear_db();
        this._db(() => {
          //.....................................................................................................
          /* TAINT a more general solution should accommodate more than a single source file */
          this._db(SQL`create table fm_datasources (
    lnr       integer not null primary key,
    line      text    not null );`);
          //.....................................................................................................
          /* TAINT auto-generate */
          hide(this, '_insert_into', {
            fm_datasources: this._db.create_insert({
              into: 'fm_datasources'
            })
          });
          //.....................................................................................................
          return null;
        });
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _populate_db_if_necessary() {
        whisper('Ω___5', "File_mirror::_populate_db_if_necessary");
        if (!this.cfg.auto_populate_db) {
          return 0;
        }
        this._populate_db();
        return 1;
      }

      //---------------------------------------------------------------------------------------------------------
      _populate_db() {
        var error, ref;
        try {
          /* TAINT throw error unless @cfg.auto_populate_db */
          this._db(() => {
            var eol, line, lnr, ref, x;
            ref = GUY.fs.walk_lines_with_positions(this.cfg.datasource_path);
            for (x of ref) {
              ({lnr, line, eol} = x);
              this._db(this._insert_into.fm_datasources, {lnr, line});
            }
            return null;
          });
        } catch (error1) {
          error = error1;
          if ((ref = error.code) === 'ENOENT' || ref === 'EACCES' || ref === 'EPERM') {
            whisper('Ω___6', "File_mirror::_populate_db", U.color.bad(error.message));
            process.exit(111);
          }
          throw error;
        }
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    File_mirror.required_table_names = ['fm_datasources'];

    return File_mirror;

  }).call(this);

  //===========================================================================================================
  module.exports = {File_mirror};

}).call(this);

//# sourceMappingURL=file-mirror.js.map