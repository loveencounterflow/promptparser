(async function() {
  'use strict';
  var $, DATOM, DBay, FS, File_mirror, GUY, Interlex, PATH, Pipeline, Prompt_file_reader, Prompt_parser, SQL, Syntax, Transformer, U, WG, alert, build_file_db, compose, debug, demo_file_as_virtual_table, echo, end_of_line, get_types, help, hide, info, inspect, lets, log, new_datom, new_prompt_lexer, plain, praise, rpr, stamp, start_of_line, transforms, urge, warn, whisper,
    boundMethodCheck = function(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new Error('Bound instance method accessed before binding'); } };

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  ({hide} = GUY.props);

  //...........................................................................................................
  ({DATOM} = require('datom'));

  WG = require('webguy');

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

  start_of_line = Symbol('start_of_line');

  end_of_line = Symbol('end_of_line');

  ({get_types} = require('./types'));

  /*

  8888888b.  8888888b.   .d88888b.  888b     d888 8888888b. 88888888888   888      8888888888 Y88b   d88P 8888888888 8888888b.
  888   Y88b 888   Y88b d88P" "Y88b 8888b   d8888 888   Y88b    888       888      888         Y88b d88P  888        888   Y88b
  888    888 888    888 888     888 88888b.d88888 888    888    888       888      888          Y88o88P   888        888    888
  888   d88P 888   d88P 888     888 888Y88888P888 888   d88P    888       888      8888888       Y888P    8888888    888   d88P
  8888888P"  8888888P"  888     888 888 Y888P 888 8888888P"     888       888      888           d888b    888        8888888P"
  888        888 T88b   888     888 888  Y8P  888 888           888       888      888          d88888b   888        888 T88b
  888        888  T88b  Y88b. .d88P 888   "   888 888           888       888      888         d88P Y88b  888        888  T88b
  888        888   T88b  "Y88888P"  888       888 888           888       88888888 8888888888 d88P   Y88b 8888888888 888   T88b

  */
  //===========================================================================================================
  new_prompt_lexer = function(mode = 'plain') {
    var Prompt_lexer, lexer;
    //.........................................................................................................
    /* TAINT consider to make `enter_marks()` an instance method */
    Prompt_lexer = class Prompt_lexer extends Interlex {
      //-------------------------------------------------------------------------------------------------------
      constructor() {
        super({
          end_of_line,
          start_of_line,
          dotall: false,
          state: 'reset'
        });
        // return super P...
        //-------------------------------------------------------------------------------------------------------
        this.enter_marks = this.enter_marks.bind(this);
        this.user_state = {
          marks_done: false
        };
        return void 0;
      }

      //-------------------------------------------------------------------------------------------------------
      reset() {
        // help 'Ω___1', GUY.trm.reverse "reset", @user_state
        return this.user_state.marks_done = false;
      }

      enter_marks({token, match, lexer}) {
        boundMethodCheck(this, Prompt_lexer);
        if (this.user_state.marks_done) {
          return null;
        }
        this.user_state.marks_done = true;
        return {
          jump: '[marks'
        };
      }

    };
    //.........................................................................................................
    lexer = new Prompt_lexer();
    (() => {      //.........................................................................................................
      mode = 'plain';
      // lexer.add_lexeme { mode, lxid: 'escchr',     jump: null,     pattern:  /\\(?<chr>.)/u,           }
      // lexer.add_lexeme { mode, lxid: 'marksleft',  jump: '[marks', pattern:  /\[/u,                    }
      lexer.add_lexeme({
        mode,
        lxid: 'marksleft',
        jump: (function(...P) {
          return lexer.enter_marks(...P);
        }),
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
        lxid: 'wording',
        jump: null,
        pattern: /WORDING/u
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
        pattern: /UNSAFE|[U01234]/u
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

  /*

  8888888b.  8888888b.   .d88888b.  888b     d888 8888888b.  88888888888  8888888b.      d8888  8888888b.   .d8888b.  8888888888 8888888b.
  888   Y88b 888   Y88b d88P" "Y88b 8888b   d8888 888   Y88b     888      888   Y88b    d88888  888   Y88b d88P  Y88b 888        888   Y88b
  888    888 888    888 888     888 88888b.d88888 888    888     888      888    888   d88P888  888    888 Y88b.      888        888    888
  888   d88P 888   d88P 888     888 888Y88888P888 888   d88P     888      888   d88P  d88P 888  888   d88P  "Y888b.   8888888    888   d88P
  8888888P"  8888888P"  888     888 888 Y888P 888 8888888P"      888      8888888P"  d88P  888  8888888P"      "Y88b. 888        8888888P"
  888        888 T88b   888     888 888  Y8P  888 888            888      888       d88P   888  888 T88b         "888 888        888 T88b
  888        888  T88b  Y88b. .d88P 888   "   888 888            888      888      d8888888888  888  T88b  Y88b  d88P 888        888  T88b
  888        888   T88b  "Y88888P"  888       888 888            888      888     d88P     888  888   T88b  "Y8888P"  8888888888 888   T88b

  */
  //===========================================================================================================
  Prompt_parser = class Prompt_parser extends Transformer {
    //---------------------------------------------------------------------------------------------------------
    constructor() {
      super();
      hide(this, 'types', get_types());
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
    $normalize_generation() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
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
        if (d.$stamped) {
          return send(d);
        }
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
      var lnr, parts;
      parts = null;
      lnr = null;
      //.......................................................................................................
      return (d, send) => {
        /* TAINT use Datom API */
        var ref, token;
        if (d.$stamped) {
          return send(d);
        }
        //.....................................................................................................
        if (d === start_of_line) {
          parts = [];
          return send(d);
        }
        //.....................................................................................................
        if (d === end_of_line) {
          token = {
            $key: 'prompt',
            value: parts.join([]),
            lnr
          };
          parts = lnr = null;
          send(token);
          return send(d);
        }
        if (!((ref = d.$key) != null ? ref.startsWith('plain:') : void 0)) {
          //.....................................................................................................
          return send(d);
        }
        //.....................................................................................................
        if (lnr == null) {
          lnr = d.lnr1;
        }
        parts.push(d.value);
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $normalize_prompt() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'prompt') {
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
    $consolidate_generations() {
      /* TAINT code duplication */
      var lnr, parts;
      parts = null;
      lnr = null;
      //.......................................................................................................
      return (d, send) => {
        /* TAINT use Datom API */
        var ref, token;
        if (d.$stamped) {
          return send(d);
        }
        //.....................................................................................................
        if (d === start_of_line) {
          parts = [];
          return send(d);
        }
        //.....................................................................................................
        if (d === end_of_line) {
          token = {
            $key: 'generations',
            value: parts,
            lnr
          };
          parts = lnr = null;
          send(token);
          return send(d);
        }
        if ((ref = d.$key) !== 'marks:generation') {
          //.....................................................................................................
          // return send d unless d.$key in [ 'marks:format', 'marks:generation', ]
          return send(d);
        }
        //.....................................................................................................
        if (lnr == null) {
          lnr = d.lnr1;
        }
        parts.push(d.value);
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $consolidate_comments() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'marks:comment') {
          return send(d);
        }
        send(lets(d, function(d) {
          return d.$key = 'comment';
        }));
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $consolidate_rejected() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'marks:wording') {
          return send(d);
        }
        send(lets(d, function(d) {
          d.$key = 'rejected';
          return d.value = true;
        }));
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $consolidate_promptnr() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'marks:promptnr') {
          return send(d);
        }
        send(lets(d, function(d) {
          return d.$key = 'promptnr';
        }));
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $add_prompt_id() {
      return (d, send) => {
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'prompt') {
          return send(d);
        }
        send(d);
        return send(lets(d, function(d) {
          d.$key = 'prompt_id';
          return d.value = U.id_from_text(d.value);
        }));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $assemble_prerecords(d, send) {
      /* TAINT code duplication */
      var lnr, prerecord;
      prerecord = null;
      lnr = null;
      //.......................................................................................................
      return (d, send) => {
        var ref, ref1;
        if (lnr == null) {
          lnr = (ref = d.lnr1) != null ? ref : d.lnr;
        }
        if (d.$stamped) {
          return send(d);
        }
        //.....................................................................................................
        if (d === start_of_line) {
          prerecord = this.types.create.pp_prerecord_initial();
          return send(d);
        }
        //.....................................................................................................
        if (d === end_of_line) {
          /* TAINT use Datom API */
          send(this.types.create.pp_prerecord_final(prerecord));
          prerecord = null;
          return send(d);
        }
        if ((ref1 = d.$key) !== 'prompt' && ref1 !== 'prompt_id' && ref1 !== 'generations' && ref1 !== 'comment' && ref1 !== 'promptnr' && ref1 !== 'rejected') {
          //.....................................................................................................
          return send(d);
        }
        //.....................................................................................................
        if (prerecord.lnr == null) {
          prerecord.lnr = lnr;
        }
        prerecord[d.$key] = d.value;
        return send(stamp(d));
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $assemble_generation_records() {
      var nrs, prompt_id;
      prompt_id = null;
      nrs = new Map();
      //.......................................................................................................
      return (d, send) => {
        var count, i, len, nr, ref;
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'prerecord') {
          return send(d);
        }
        send(d);
        //.....................................................................................................
        /* TAINT hide this in custom class */
        prompt_id = d.prompt_id;
        if ((nr = nrs.get(prompt_id)) == null) {
          nrs.set(prompt_id, 0);
          nr = 0;
        }
        ref = d.generations;
        //.....................................................................................................
        for (i = 0, len = ref.length; i < len; i++) {
          count = ref[i];
          nr++;
          send({
            $key: 'record',
            table: 'generations',
            fields: {prompt_id, nr, count}
          });
        }
        nrs.set(prompt_id, nr);
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $assemble_prompt_records() {
      return (d, send) => {
        var fields;
        if (d.$stamped) {
          return send(d);
        }
        if (d.$key !== 'prerecord') {
          return send(d);
        }
        send(d);
        fields = {
          id: d.prompt_id,
          lnr: d.lnr,
          prompt: d.prompt,
          comment: d.comment,
          rejected: d.rejected
        };
        send({
          $key: 'record',
          table: 'prompts',
          fields
        });
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $show() {
      return (d) => {
        // urge 'Ω___4', rpr d # if d.$key is 'generation'
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $stamp_extraneous() {
      return (d, send) => {
        switch (true) {
          case d.$key !== 'record':
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
        if ((d !== start_of_line) && (d !== end_of_line) && (!d.$stamped)) {
          send(d);
        }
        return null;
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
    class File_mirror {
      //---------------------------------------------------------------------------------------------------------
      constructor(path) {
        var f, insert_into, key, ref;
        hide(this, 'types', get_types());
        this.cfg = this.types.create.fm_constructor_cfg(path);
        hide(this, '_db', new DBay({path}));
        //.......................................................................................................
        /* TAINT rather ad-hoc */
        hide(this, 'insert_into', insert_into = {});
        ref = this.constructor.insert_into;
        for (key in ref) {
          f = ref[key];
          insert_into[key] = f.bind(this);
        }
        //.......................................................................................................
        this._prepare_db_connection();
        this._create_db_structure_if_necessary();
        this._acquire_datasources_if_necessary();
        //.......................................................................................................
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      _prepare_db_connection() {
        // whisper "Ω___6 File_mirror._prepare_db_connection"
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
          help(`Ω___8 re-using DB at ${this.cfg.path}`);
        } else {
          warn(`Ω___9 creating structure of DB at ${this.cfg.path}`);
          this._create_db_structure();
        }
        //.......................................................................................................
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _create_db_structure() {
        whisper("Ω__10 File_mirror._create_db_structure");
        this._db(() => {
          this._db(SQL`drop table if exists prompts;`);
          /* TAINT a more general solution should accommodate more than a single source file */
          this._db(SQL`create table datasources (
    lnr       integer not null primary key,
    line      text    not null );`);
          this._db(SQL`create table prompts (
    id        text    not null primary key,
    lnr       integer not null,
    prompt    text    not null,
    comment   text        null,
    rejected  boolean not null );`);
          this._db(SQL`create table generations (
    prompt_id text    not null,
    nr        integer not null,
    count     integer not null,
  primary key ( prompt_id, nr ),
  foreign key ( prompt_id ) references prompts ( id ) );`);
          hide(this, '_insert_into', {
            datasources: this._db.create_insert({
              into: 'datasources'
            }),
            prompts: this._db.create_insert({
              into: 'prompts',
              on_conflict: {
                update: true
              }
            }),
            generations: this._db.create_insert({
              into: 'generations'
            })
          });
          return null;
        });
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _acquire_datasources_if_necessary() {
        this._acquire_datasources();
        return null;
      }

      //---------------------------------------------------------------------------------------------------------
      _acquire_datasources() {
        /* TAINT replace hardcoded datasource path */
        this._db(() => {
          var eol, line, lnr, ref, results, x;
          ref = GUY.fs.walk_lines_with_positions('./data/short-prompts.md');
          results = [];
          for (x of ref) {
            ({lnr, line, eol} = x);
            results.push(this._db(this._insert_into.datasources, {lnr, line}));
          }
          return results;
        });
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    File_mirror.required_table_names = ['datasources'];

    //---------------------------------------------------------------------------------------------------------
    File_mirror.insert_into = {
      //.......................................................................................................
      datasources: function(d) {
        /* TAINT validate? */
        return this._db.alt(this._insert_into.datasources, d);
      },
      //.......................................................................................................
      prompts: function(d) {
        /* TAINT validate? */
        return this._db.alt(this._insert_into.prompts, lets(d, function(d) {
          return d.rejected = d.rejected === true ? 1 : 0;
        }));
      },
      //.......................................................................................................
      generations: function(d) {
        /* TAINT validate? */
        return this._db.alt(this._insert_into.generations, d);
      }
    };

    return File_mirror;

  }).call(this);

  Prompt_file_reader = (function() {
    /*

    8888888888 8888888 888      8888888888   8888888b.  8888888888        d8888  8888888b.  8888888888 8888888b.
    888          888   888      888          888   Y88b 888              d88888  888  "Y88b 888        888   Y88b
    888          888   888      888          888    888 888             d88P888  888    888 888        888    888
    8888888      888   888      8888888      888   d88P 8888888        d88P 888  888    888 8888888    888   d88P
    888          888   888      888          8888888P"  888           d88P  888  888    888 888        8888888P"
    888          888   888      888          888 T88b   888          d88P   888  888    888 888        888 T88b
    888          888   888      888          888  T88b  888         d8888888888  888  .d88P 888        888  T88b
    888        8888888 88888888 8888888888   888   T88b 8888888888 d88P     888  8888888P"  8888888888 888   T88b

    */
    //===========================================================================================================
    class Prompt_file_reader extends File_mirror {
      //---------------------------------------------------------------------------------------------------------
      /* TAINT use CFG pattern, namespacing as in `file_mirror.path`, validation */
      constructor(file_mirror_path) {
        super(file_mirror_path);
        this._prompt_parser = new Prompt_parser();
        this._pipeline = new Pipeline();
        this._pipeline.push(this._prompt_parser);
        return void 0;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    Prompt_file_reader.required_table_names = ['prompts', 'generations'];

    return Prompt_file_reader;

  }).call(this);

  //-----------------------------------------------------------------------------------------------------------
  demo_file_as_virtual_table = function() {
    var db;
    db = new Prompt_file_reader('/dev/shm/prompts-and-generations.sqlite');
    db._db(() => {
      var record, ref, results, row;
      ref = db._db(SQL`select * from datasources order by lnr;`);
      results = [];
      for (row of ref) {
        debug('Ω__11', row);
        help('Ω__12', db._pipeline.send(row.line));
        results.push((function() {
          var ref1, results1;
          ref1 = db._pipeline.walk();
          results1 = [];
          for (record of ref1) {
            info('Ω__13', record);
            results1.push(db.insert_into[record.table](record.fields));
          }
          return results1;
        })());
      }
      return results;
    });
    //.........................................................................................................
    return null;
  };

  /*

  8888888888  .d88888b.  8888888888
  888        d88P" "Y88b 888
  888        888     888 888
  8888888    888     888 8888888
  888        888     888 888
  888        888     888 888
  888        Y88b. .d88P 888
  8888888888  "Y88888P"  888

  */
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