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
    var Prompt_lexer, enter_marks, lexer, state;
    state = {
      marks_done: false
    };
    //.........................................................................................................
    /* TAINT consider to make `enter_marks()` an instance method */
    Prompt_lexer = class Prompt_lexer extends Interlex {
      constructor() {
        super({
          start_token: true,
          end_token: true,
          dotall: false,
          state: 'reset'
        });
      }

      _start(...P) {
        help('Ω___1', GUY.trm.reverse("start"));
        // @state.source = '\x00' + @state.source
        state.marks_done = false;
        return super._start(...P);
      }

    };
    //.........................................................................................................
    lexer = new Prompt_lexer();
    //.........................................................................................................
    enter_marks = function({token, match, lexer}) {
      if (state.marks_done) {
        return null;
      }
      state.marks_done = true;
      return {
        jump: '[marks'
      };
    };
    (() => {      // #.........................................................................................................
      // do =>
      //   mode = 'start'
      //   lexer.add_lexeme { mode, lxid: 'start',       jump: 'plain[',     pattern:  /^/u, empty_value: '\x00'          }
      //.........................................................................................................
      mode = 'plain';
      // lexer.add_lexeme { mode, lxid: 'escchr',     jump: null,     pattern:  /\\(?<chr>.)/u,           }
      // lexer.add_lexeme { mode, lxid: 'marksleft',  jump: '[marks', pattern:  /\[/u,                    }
      lexer.add_lexeme({
        mode,
        lxid: 'marksleft',
        jump: enter_marks,
        pattern: /\[/u
      });
      return lexer.add_lexeme({
        mode,
        lxid: 'prompt',
        jump: null,
        pattern: /[^\[]+/u
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
        urge('Ω___2', GUY.trm.reverse(GUY.trm.cyan(GUY.trm.bold(rpr(source)))));
        send({
          $key: 'source',
          $value: source,
          $stamped: true
        });
        ref = this._lexer.walk(source);
        for (lexeme of ref) {
          // help 'Ω___3', "#{lexeme.$key.padEnd 20} #{rpr lexeme.value}"
          send(lexeme);
        }
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $show() {
      return (d) => {
        urge('Ω___4', rpr(d));
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
    $consolidate_prompt() {
      var token;
      token = {};
      return (d, send) => {
        if (d.$key !== 'plain:prompt') {
          return send(d);
        }
        send(d);
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
          case d.$key === 'marks:$eof':
            send(stamp(d));
            break;
          case d.$key === 'plain:$eof':
            send(stamp(d));
            break;
          default:
            send(d);
        }
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $filter_stamped() {
      return (d, send) => {
        if (!d.$stamped) {
          return send(d);
        }
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $count() {
      return (d) => {
        // urge 'Ω___5', d
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
        this._prepare_db_connection();
        //.......................................................................................................
        if (U.db_has_all_table_names(this._db, this.constructor.required_table_names)) {
          help(`Ω___6 re-using DB at ${path}`);
        } else {
          warn(`Ω___7 creating structure of DB at ${path}`);
          this._create_db_structure();
        }
        //.......................................................................................................
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      _prepare_db_connection() {
        whisper("Ω___8 File_mirror._prepare_db_connection");
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
      _create_db_structure() {
        whisper("Ω___9 File_mirror._create_db_structure");
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
      // @_pipeline.push $show = ( source ) -> whisper 'Ω__10', rpr source
      this._pipeline.push(this._prompt_parser);
      // @_pipeline.push $show = ( d ) -> whisper 'Ω__11', d
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(source) {
      var R, t;
      // debug 'Ω__12', rpr source
      this._pipeline.send(source);
      R = this._pipeline.run();
      info('Ω__13', GUY.trm.yellow(GUY.trm.reverse(this._prompt_parser.state)));
      debug('Ω__14', ((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = R.length; i < len; i++) {
          t = R[i];
          results.push(`${t.$key}${rpr(t.value)}`);
        }
        return results;
      })()).join('|'));
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    _create_db_structure() {
      super._create_db_structure();
      whisper("Ω__15 Prompt_file_reader._create_db_structure");
      // @_db =>
      //   @_db SQL"drop table if exists ...;"
      //   @_db SQL"""
      //     create table ...
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _prepare_db_connection() {
      super._prepare_db_connection();
      whisper("Ω__16 Prompt_file_reader._prepare_db_connection");
      this._db.create_function({
        name: 'square',
        deterministic: true,
        varargs: false,
        call: function(n) {
          return n ** 2;
        }
      });
      this._db.create_function({
        name: 'parse',
        deterministic: true,
        varargs: false,
        call: (prompt) => {
          return JSON.stringify(this.parse(prompt));
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
      return result = db._db.all_rows(SQL`select
    *,
    square( lnr ) as lnr2,
    parse( line ) as prompt
  from file_contents_t( './data/short-prompts.md' ) order by lnr;`);
    })();
    // console.table result
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