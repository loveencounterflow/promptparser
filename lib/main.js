(function() {
  'use strict';
  var $, DATOM, GUY, Interlex, Pipeline, Prompt_parser, Prompt_parsing_pipeline, Syntax, Transformer, alert, compose, debug, echo, f, help, info, inspect, lets, log, new_datom, new_prompt_lexer, plain, praise, rpr, stamp, transforms, urge, warn, whisper;

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

  // #===========================================================================================================
  // class Hypedown_parser

  //   #---------------------------------------------------------------------------------------------------------
  //   constructor: ( cfg ) ->
  //     @types        = get_base_types()
  //     @cfg          = Object.freeze @types.create.hd_parser_cfg cfg
  //     @lexer        = new Hypedown_lexer()
  //     # debug '^234^', @lexer
  //     @_build_pipeline()
  //     return undefined

  //   #---------------------------------------------------------------------------------------------------------
  //   _build_pipeline: ->
  //     tfs       = new XXX_Hypedown_transforms()
  //     @pipeline = new Pipeline()
  //     #.........................................................................................................
  //     @pipeline.push new XXX_TEMP.$001_prelude()
  //     @pipeline.push new XXX_TEMP.$002_tokenize_lines()
  //     @pipeline.push new XXX_TEMP.$010_prepare_paragraphs()
  //     @pipeline.push new XXX_TEMP.$020_priority_markup()
  //     @pipeline.push new XXX_TEMP.$030_htmlish_tags()
  //     @pipeline.push new XXX_TEMP.$040_stars()
  //     @pipeline.push new XXX_TEMP.$050_hash_headings()
  //     @pipeline.push tfs.$capture_text()
  //     @pipeline.push tfs.$generate_missing_p_tags()
  //     @pipeline.push tfs.$generate_html_nls { mode: 'plain', tid: 'nl', } ### NOTE removes virtual nl, should come late ###
  //     @pipeline.push tfs.$convert_escaped_chrs()
  //     @pipeline.push tfs.$stamp_borders()
  //     # @pipeline.push ( d ) -> urge '^_build_pipeline@5^', rpr d
  //     return null

  //   #---------------------------------------------------------------------------------------------------------
  //   send:       ( P... ) -> @pipeline.send P...
  //   run:        ( P... ) -> @pipeline.run  P...
  //   walk:       ( P... ) -> @pipeline.walk P...
  //   stop_walk:  ( P... ) -> @pipeline.stop_walk P...
  //   step:       ( P... ) -> @pipeline.step P...

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
  Prompt_parsing_pipeline = class Prompt_parsing_pipeline extends Transformer {
    //---------------------------------------------------------------------------------------------------------
    $show() {
      return function(d) {
        return urge('Ω___1', d);
      };
    }

  };

  //===========================================================================================================
  Prompt_parser = class Prompt_parser {
    //---------------------------------------------------------------------------------------------------------
    constructor(source) {
      // super()
      this._lexer = new_prompt_lexer({
        state: 'reset'
      });
      this._parser = Prompt_parsing_pipeline.as_pipeline();
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    parse(source) {
      var d, ref;
      ref = this._lexer.walk(source);
      for (d of ref) {
        help('Ω___6', `${d.$key.padEnd(20)} ${rpr(d.value)}`);
        this._parser.send(d);
      }
      return null;
    }

  };

  f = function() {
    var d, i, len, p, result, result_rpr;
    p = new Pipeline();
    p.push(function(d, send) {
      var e, ref, results;
      if (d.tid !== 'p') {
        return send(d);
      }
      ref = md_lexer.walk(d.value);
      results = [];
      for (e of ref) {
        results.push(send(e));
      }
      return results;
    });
    p.push($parse_md_stars());
    p.send(new_token('^æ19^', {
      start: 0,
      stop: probe.length
    }, 'plain', 'p', null, probe));
    result = p.run();
    result_rpr = ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = result.length; i < len; i++) {
        d = result[i];
        if (!d.$stamped) {
          results.push(d.value);
        }
      }
      return results;
    })()).join('');
    for (i = 0, len = result.length; i < len; i++) {
      d = result[i];
      urge('^08-1^', (Object.keys(d)).sort());
    }
    return H.tabulate(`${probe} -> ${result_rpr} (${matcher})`, result); // unless result_rpr is matcher
  };

  (() => {    
    //===========================================================================================================
    var i, len, parser, prompt, prompts;
    prompts = ["[s324w1 some remark] my prompt", "[A++v 212] other prompt", "[A++v 212 but no cigar] other prompt", "[B 2x3 p#3014] Altbau, Versuchsraum, Institut", "[WORDING p#4420]", "[UNSAFE p#38]", "[+++ + p#41]", "[meh p#53]", "[UU]", "[A+v U1UU]", "[A++v 22 but not following directions] \t foo bar   ", "[A++v 22 but not following directions p#7765] \t foo bar   ", "", "[]", "just a prompt", "     just a prompt", "     [324] a prompt"];
    parser = new Prompt_parser();
    for (i = 0, len = prompts.length; i < len; i++) {
      prompt = prompts[i];
      whisper('Ω___4', '————————————————————————');
      urge('Ω___5', rpr(prompt));
      info('Ω___5', parser.parse(prompt));
    }
    return null;
  })();

  //.........................................................................................................
// p = B.as_pipeline()
// debug 'Ω___3', p.run_and_stop()
// # T?.eq result, [ [ '*', 'a1', 'a2', 'a3', 'b1', '!b2!', 'b3' ] ]
// process.exit 111

  // #===========================================================================================================
// module.exports = {
//   _TEMP_add_lexemes
//   Markdown_sx
//   Standard_sx
//   Hypedown_lexer }

}).call(this);

//# sourceMappingURL=main.js.map