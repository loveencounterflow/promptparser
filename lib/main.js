(async function() {
  'use strict';
  var $, DATOM, GUY, Interlex, Pipeline, Prompt_file_reader, Prompt_parser, Syntax, Transformer, U, alert, build_file_db, compose, debug, echo, help, info, inspect, lets, log, new_datom, new_prompt_lexer, plain, praise, rpr, stamp, transforms, urge, warn, whisper;

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

  //===========================================================================================================
  Prompt_file_reader = class Prompt_file_reader { // extends Dbay
    
      //---------------------------------------------------------------------------------------------------------
    constructor() {
      // super()
      this._prompt_parser = new Prompt_parser();
      this._pipeline = new Pipeline();
      // @_pipeline.push $show = ( source ) -> whisper 'Ω___5', rpr source
      this._pipeline.push(this._prompt_parser);
      // @_pipeline.push $show = ( d ) -> whisper 'Ω___6', d
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(source) {
      var R;
      // debug 'Ω___7', rpr source
      this._pipeline.send(source);
      R = this._pipeline.run();
      info('Ω___8', GUY.trm.yellow(GUY.trm.reverse(this._prompt_parser.state)));
      return R;
    }

  };

  //===========================================================================================================
  module.exports = {new_prompt_lexer, Prompt_file_reader};

  //===========================================================================================================
  if (module === require.main) {
    await (() => {
      return build_file_db();
    })();
  }

}).call(this);

//# sourceMappingURL=main.js.map