(async function() {
  'use strict';
  var $, DATOM, GUY, Interlex, Pipeline, Prompt_file_reader, Prompt_parser, Syntax, Transformer, U, alert, compose, debug, echo, end_of_line, get_types, help, hide, info, inspect, lets, log, new_datom, new_prompt_lexer, plain, praise, rpr, stamp, start_of_line, transforms, types, urge, warn, whisper,
    boundMethodCheck = function(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new Error('Bound instance method accessed before binding'); } },
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/production-registry'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  ({hide} = GUY.props);

  //...........................................................................................................
  ({DATOM} = require('datom'));

  //...........................................................................................................
  ({new_datom, lets, stamp} = DATOM);

  //...........................................................................................................
  ({Interlex, Syntax, compose} = require('intertext-lexer'));

  //...........................................................................................................
  ({Pipeline, $, Transformer, transforms} = require('moonriver'));

  ({U} = require('./utilities'));

  start_of_line = Symbol('start_of_line');

  end_of_line = Symbol('end_of_line');

  ({get_types} = require('./types'));

  types = get_types();

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
    /* TAINT use CFG pattern */
    constructor(match = null) {
      super();
      hide(this, 'types', get_types());
      this._lexer = new_prompt_lexer({
        state: 'reset'
      });
      this.cfg = {match};
      this.state = {
        counts: {
          prompts: 0,
          lexemes: 0,
          non_matches: 0
        }
      };
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    _cast_token(lnr, token) {
      if (!this.types.isa.symbol(token)) {
        token = lets(token, function(token) {
          return token.lnr1 = token.lnr2 = lnr;
        });
      }
      return token;
    }

    //---------------------------------------------------------------------------------------------------------
    $lex() {
      return (row, send) => {
        var ref, token;
        // urge 'Ω___2', GUY.trm.reverse GUY.trm.cyan GUY.trm.bold rpr row
        send({
          $key: 'row',
          $value: row,
          $stamped: true
        });
        ref = this._lexer.walk(row.line);
        for (token of ref) {
          send(this._cast_token(row.lnr, token));
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
    $filter_matching_prompts() {
      var parts;
      parts = null;
      return (d, send) => {
        var i, len, part;
        if (d.$stamped) {
          return send(d);
        }
        //.....................................................................................................
        if (d === start_of_line) {
          parts = [];
          return null;
        }
        //.....................................................................................................
        if (d === end_of_line) {
          if (parts != null) {
            send(start_of_line);
            for (i = 0, len = parts.length; i < len; i++) {
              part = parts[i];
              send(part);
            }
            send(end_of_line);
          }
          return null;
        }
        //.....................................................................................................
        if ((this.cfg.match != null) && d.$key === 'prompt') {
          this.cfg.match.lastIndex = 0/* TAINT ensure this becomes superfluous */
          if (!this.cfg.match.test(d.value)) {
            this.state.counts.non_matches++;
            parts = null;
            return null;
          }
        }
        //.....................................................................................................
        parts.push(d);
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
      var current_lnr, prerecord;
      prerecord = null;
      current_lnr = null;
      //.......................................................................................................
      return (d, send) => {
        var ref;
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
          if (prerecord.lnr == null) {
            prerecord.lnr = current_lnr;
          }
          if (prerecord.lnr == null) {
            prerecord.lnr = 1;
          }
          send(this.types.create.pp_prerecord_final(prerecord));
          prerecord = null;
          return send(d);
        }
        if ((ref = d.$key) !== 'prompt' && ref !== 'prompt_id' && ref !== 'generations' && ref !== 'comment' && ref !== 'promptnr' && ref !== 'rejected') {
          //.....................................................................................................
          return send(d);
        }
        //.....................................................................................................
        if (d.lnr != null) {
          current_lnr = d.lnr;
          prerecord.lnr = d.lnr;
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
            prompt_id,
            table: 'prd_generations',
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
          prompt_id: d.prompt_id,
          table: 'prd_prompts',
          fields
        });
        return null;
      };
    }

    //---------------------------------------------------------------------------------------------------------
    $show() {
      return (d) => {
        // urge 'Ω___3', rpr d # if d.$key is 'generation'
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
    class Prompt_file_reader {
      //---------------------------------------------------------------------------------------------------------
      constructor(cfg) {
        hide(this, 'types', get_types());
        this.cfg = this.types.create.pfr_constructor_cfg(cfg);
        hide(this, 'prompt_parser', new Prompt_parser(this.cfg.flags.match));
        hide(this, 'pipeline', new Pipeline());
        this.pipeline.push(this.prompt_parser);
        //.......................................................................................................
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      * [Symbol.iterator]() {
        var blank_line_count, line_count, nonmatching_line_count, read_prompt_count, record, ref, ref1, row, unsampled_line_count, written_prompt_count;
        whisper('Ω___8', "Prompt_file_reader::[Symbol.iterator]");
        // super()
        line_count = 0;
        blank_line_count = 0;
        read_prompt_count = 0;
        written_prompt_count = 0;
        // unique_row_ids          = new Set()
        nonmatching_line_count = 0;
        unsampled_line_count = 0;
        ref = this.cfg.lines;
        //.......................................................................................................
        for (row of ref) {
          line_count++;
          if (modulo(line_count, 1e3) === 0) {
            whisper('Ω___9', "Prompt_file_reader::_populate_db", GUY.trm.white(`line count: ${U.format_nr(line_count, 8)}`));
          }
          //.....................................................................................................
          /* EXCLUDE EMPTY LINES */
          if (/^\s*$/.test(row.line)) {
            blank_line_count++;
            continue;
          }
          //.....................................................................................................
          /* --SAMPLE */
          if (Math.random() > this.cfg.flags.sample) {
            unsampled_line_count++;
            continue;
          }
          //.....................................................................................................
          /* --MATCH */
          if (this.cfg.flags.pre_match != null) {
            this.cfg.flags.pre_match.lastIndex = 0/* TAINT ensure when constructing pre_match that lastIndex is never used */
            if (!this.cfg.flags.pre_match.test(row.line)) {
              nonmatching_line_count++;
              continue;
            }
          }
          //.....................................................................................................
          this.pipeline.send(row);
          ref1 = this.pipeline.walk();
          //.....................................................................................................
          for (record of ref1) {
            //...................................................................................................
            if (record.table === 'prd_prompts') {
              read_prompt_count++;
            }
            written_prompt_count++;
            yield record;
          }
          //...................................................................................................
          // { lastInsertRowid: row_id, } = @insert_into[ record.table ] record.fields
          // if record.table is 'prd_prompts'
          //   unique_row_ids.add row_id
          //   written_prompt_count = unique_row_ids.size
          //.....................................................................................................
          /* --MAX-COUNT */
          if (written_prompt_count >= this.cfg.flags.max_count) {
            whisper('Ω__10', "Prompt_file_reader::_populate_db", GUY.trm.white(`stopping because prompt count exceeds max prompt count of ${U.format_nr(this.cfg.flags.max_count)} prompts`));
            break;
          }
        }
        //.......................................................................................................
        whisper('Ω__11');
        whisper('Ω__12', "Prompt_file_reader::_populate_db", GUY.trm.white(`line count:                    +${U.format_nr(line_count, 12)}`));
        //.......................................................................................................
        whisper('Ω__13', "Prompt_file_reader::_populate_db", GUY.trm.white(`blank line count:              –${U.format_nr(blank_line_count, 12)}`));
        //.......................................................................................................
        whisper('Ω__14', "Prompt_file_reader::_populate_db", GUY.trm.white(`'unsampled' line count:        –${U.format_nr(unsampled_line_count, 12)}`));
        //.......................................................................................................
        whisper('Ω__15', "Prompt_file_reader::_populate_db", GUY.trm.white(`non-pre-matching line count:   –${U.format_nr(nonmatching_line_count, 12)}`));
        //.......................................................................................................
        whisper('Ω__16', "Prompt_file_reader::_populate_db", GUY.trm.white(`non-matching prompt count:     –${U.format_nr(this.prompt_parser.state.counts.non_matches, 12)}`));
        // #.......................................................................................................
        // whisper 'Ω__17', "Prompt_file_reader::_populate_db", GUY.trm.white \
        //   "inserted #{U.format_nr written_prompt_count} rows into DB at #{@cfg.db_path}"
        //.......................................................................................................
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    Prompt_file_reader.required_table_names = ['prd_prompts', 'prd_generations'];

    return Prompt_file_reader;

  }).call(this);

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
  module.exports = {new_prompt_lexer, Prompt_file_reader};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      var cmd, d, flags, lines, ref;
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
      lines = GUY.fs.walk_lines_with_positions(flags.prompts);
      ref = new Prompt_file_reader({cmd, flags, lines});
      for (d of ref) {
        debug('Ω__20', d);
      }
      return null;
      echo();
      echo(GUY.trm.grey('Ω__21'), GUY.trm.gold("run `node lib/cli.js help` instead of this file"));
      echo();
      return process.exit(111);
    })();
  }

}).call(this);

//# sourceMappingURL=production-registry.js.map