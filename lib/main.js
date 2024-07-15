(async function() {
  'use strict';
  var $, DATOM, DBay, FS, File_mirror, GUY, Interlex, PATH, Pipeline, Prompt_file_reader, Prompt_parser, SQL, Syntax, Transformer, U, alert, build_file_db, compose, debug, demo_file_as_virtual_table, echo, help, info, inspect, lets, log, new_datom, new_prompt_lexer, plain, praise, rpr, stamp, transforms, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  //...........................................................................................................
  ({DATOM} = require('datom'));

  //...........................................................................................................
  ({new_datom, lets, stamp} = DATOM);

  //...........................................................................................................
  ({Interlex, Syntax, compose} = require('intertext-lexer'));

  //...........................................................................................................
  // { misfit
  //   get_base_types }        = require './types'
  // E                         = require './errors'
  //...........................................................................................................
  ({Pipeline, $, Transformer, transforms} = require('moonriver'));

  ({U} = require('./utilities'));

  ({build_file_db} = require('./file-cache-builder'));

  ({DBay} = require('dbay'));

  ({SQL} = DBay);

  PATH = require('node:path');

  FS = require('node:fs');

  //===========================================================================================================
  new_prompt_lexer = function(mode = 'plain') {
    var lexer;
    lexer = new Interlex({
      dotall: false
    });
    (() => {      //.........................................................................................................
      mode = 'plain';
      lexer.add_lexeme({
        mode,
        lxid: 'escchr',
        jump: null,
        pattern: /\\(?<chr>.)/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'marksleft',
        jump: '[marks',
        pattern: /\[/u
      });
      return lexer.add_lexeme({
        mode,
        lxid: 'prompt',
        jump: null,
        pattern: /[^\[\\]+/u
      });
    })();
    (() => {      //.........................................................................................................
      mode = 'marks';
      lexer.add_lexeme({
        mode,
        lxid: 'marksright',
        jump: '.]',
        pattern: /\]/u,
        reserved: ']'
      });
      lexer.add_lexeme({
        mode,
        lxid: 'format',
        jump: null,
        pattern: /[swh]/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'ws',
        jump: null,
        pattern: /\x20+/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'multiplier',
        jump: null,
        pattern: /x[0-9]{1,2}/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'promptnr',
        jump: null,
        pattern: /p#[0-9]+/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'generation',
        jump: null,
        pattern: /[U01234]/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'grade',
        jump: null,
        pattern: /[-+A-Fvnr]+/u
      });
      lexer.add_lexeme({
        mode,
        lxid: 'comment',
        jump: null,
        pattern: /(?:(?!(?:p#[0-9]|\])).)+/u
      });
      return lexer.add_reserved_lexeme({
        mode,
        lxid: 'forbidden',
        concat: true
      });
    })();
    //.........................................................................................................
    return lexer;
  };

  //===========================================================================================================
  Prompt_parser = class Prompt_parser extends Transformer {
    //---------------------------------------------------------------------------------------------------------
    constructor() {
      super();
      this._lexer = new_prompt_lexer({
        state: 'reset'
      });
      this.state = {
        counts: {
          prompts: 0,
          lexemes: 0
        }
      };
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    $lex() {
      return (source, send) => {
        var lexeme, ref;
        // urge 'Ω___1', rpr source
        send({
          $key: 'source',
          $value: source
        });
        ref = this._lexer.walk(source);
        for (lexeme of ref) {
          // help 'Ω___2', "#{lexeme.$key.padEnd 20} #{rpr lexeme.value}"
          send(lexeme);
        }
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $show() {
      return (d) => {
        urge('Ω___3', rpr(d));
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $normalize_prompt() {
      return (d, send) => {
        if (d.$key !== 'plain:prompt') {
          return send(d);
        }
        send(stamp(d));
        send(lets(d, function(d) {
          return d.value = U.normalize_prompt(d.value);
        }));
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $normalize_generation() {
      return (d, send) => {
        if (d.$key !== 'marks:generation') {
          return send(d);
        }
        send(stamp(d));
        send(lets(d, function(d) {
          return d.value = (/^\d$/.test(d.value)) ? parseInt(d.value, 10) : 0;
        }));
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $normalize_comment() {
      return (d, send) => {
        if (d.$key !== 'marks:comment') {
          return send(d);
        }
        send(stamp(d));
        send(lets(d, function(d) {
          return d.value = d.value.trim();
        }));
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $stamp_extraneous() {
      return (d, send) => {
        switch (true) {
          case d.$key === 'marks:marksleft':
            send(stamp(d));
            break;
          case d.$key === 'marks:marksright':
            send(stamp(d));
            break;
          case d.$key === 'marks:grade':
            send(stamp(d));
            break;
          case d.$key === 'marks:ws':
            send(stamp(d));
            break;
          default:
            send(d);
        }
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $count() {
      return (d) => {
        // urge 'Ω___4', d
        if (d.$key === 'source') {
          this.state.counts.prompts++;
        } else {
          this.state.counts.lexemes++;
        }
        return null;
      };
    }

  };

  File_mirror = (function() {
    //===========================================================================================================
    class File_mirror {
      //---------------------------------------------------------------------------------------------------------
      constructor(path) {
        this._db = new DBay({path});
        this._prepare();
        //.......................................................................................................
        if (U.db_has_all_table_names(this._db, this.constructor.required_table_names)) {
          help(`Ω___5 re-using DB at ${path}`);
        } else {
          warn(`Ω___6 initializing DB at ${path}`);
          this._initialize();
        }
        //.......................................................................................................
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      _prepare() {
        whisper("Ω___7 File_mirror._prepare");
        this._db(() => {
          return this._db.create_table_function({
            name: 'file_contents_t',
            columns: ['lnr', 'line', 'eol'],
            parameters: ['filename'],
            rows: function*(filename) {
              var eol, line, lnr, path, ref, x;
              path = PATH.resolve(process.cwd(), filename);
              ref = GUY.fs.walk_lines_with_positions(path);
              for (x of ref) {
                ({lnr, line, eol} = x);
                yield ({lnr, line, eol});
              }
              return null;
            }
          });
        });
        //.......................................................................................................
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _initialize() {
        whisper("Ω___8 File_mirror._initialize");
        // @_db =>
        //   @_db SQL"drop table if exists ...;"
        //   @_db SQL"""
        //     create table ...
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    File_mirror.required_table_names = [];

    return File_mirror;

  }).call(this);

  //===========================================================================================================
  Prompt_file_reader = class Prompt_file_reader extends File_mirror {
    //---------------------------------------------------------------------------------------------------------
    /* TAINT use CFG pattern, namespacing as in `file_mirror.path`, validation */
    constructor(file_mirror_path) {
      super(file_mirror_path);
      this._prompt_parser = new Prompt_parser();
      this._pipeline = new Pipeline();
      // @_pipeline.push $show = ( source ) -> whisper 'Ω___9', rpr source
      this._pipeline.push(this._prompt_parser);
      // @_pipeline.push $show = ( d ) -> whisper 'Ω__10', d
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(source) {
      var R;
      // debug 'Ω__11', rpr source
      this._pipeline.send(source);
      R = this._pipeline.run();
      info('Ω__12', GUY.trm.yellow(GUY.trm.reverse(this._prompt_parser.state)));
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _initialize() {
      super._initialize();
      whisper("Ω__13 Prompt_file_reader._initialize");
      // @_db =>
      //   @_db SQL"drop table if exists ...;"
      //   @_db SQL"""
      //     create table ...
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _prepare() {
      super._prepare();
      whisper("Ω__14 Prompt_file_reader._prepare");
      this._db.create_function({
        name: 'square',
        deterministic: true,
        varargs: false,
        call: function(n) {
          return n ** 2;
        }
      });
      //.......................................................................................................
      return null;
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  demo_file_as_virtual_table = function() {
    var db;
    db = new Prompt_file_reader('/dev/shm/demo_file_as_virtual_table.sqlite');
    (function() {
      var result;
      result = db._db.all_rows(SQL`select
    *,
    square( lnr ) as lnr2
  from file_contents_t( './README.md' ) order by lnr;`);
      return console.table(result);
    })();
    //.........................................................................................................
    return null;
  };

  //===========================================================================================================
  module.exports = {new_prompt_lexer, File_mirror, Prompt_file_reader};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      // build_file_db()
      return demo_file_as_virtual_table();
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map