(function() {
  'use strict';
  var DATOM, E, GUY, Hypedown_lexer, Interlex, Markdown_sx, Standard_sx, Syntax, _TEMP_add_lexemes, alert, compose, debug, echo, get_base_types, help, info, inspect, lets, log, misfit, new_datom, new_escchr_descriptor, new_nl_descriptor, plain, praise, rpr, stamp, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('HYPEDOWN/HYPEDOWN-LEXER'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  //...........................................................................................................
  ({DATOM} = require('datom'));

  //...........................................................................................................
  ({new_datom, lets, stamp} = DATOM);

  //...........................................................................................................
  ({Interlex, Syntax, compose} = require('intertext-lexer'));

  //...........................................................................................................
  ({misfit, get_base_types} = require('./types'));

  E = require('./errors');

  Standard_sx = (function() {
    //===========================================================================================================
    class Standard_sx extends Syntax {};

    //---------------------------------------------------------------------------------------------------------
    Standard_sx.mode = 'plain';

    return Standard_sx;

  }).call(this);

  Markdown_sx = (function() {
    //---------------------------------------------------------------------------------------------------------
    // @lx_backslash_escape:  { tid: 'escchr', jump: null, pattern: /\\(?<chr>.)/u, reserved: '\\', }

      //===========================================================================================================
    class Markdown_sx extends Syntax {
      //---------------------------------------------------------------------------------------------------------
      constructor(cfg) {
        super({...cfg});
        return void 0;
      }

      //---------------------------------------------------------------------------------------------------------
      static lx_variable_codespan(cfg) {
        var backtick_count, entry_handler, exit_handler;
        backtick_count = null;
        //.......................................................................................................
        entry_handler = ({token, match, lexer}) => {
          backtick_count = token.value.length;
          return '[cspan';
        };
        //.......................................................................................................
        exit_handler = function({token, match, lexer}) {
          // debug '^534^', token
          // debug '^534^', match
          // debug '^534^', token.value.length, backtick_count
          if (token.value.length === backtick_count) {
            backtick_count = null;
            return '.]';
          }
          token = lets(token, function(token) {
            token.tid = 'text';
            return token.mk = `${token.mode}:text`;
          });
          return {token};
        };
        return [
          {
            //.......................................................................................................
            // info '^3531^', @cfg
            mode: 'plain',
            tid: 'start',
            jump: entry_handler,
            pattern: /(?<!`)`+(?!`)/u,
            reserved: '`'
          },
          {
            mode: 'cspan',
            tid: 'stop',
            jump: exit_handler,
            pattern: /(?<!`)`+(?!`)/u,
            reserved: '`'
          },
          new_nl_descriptor('cspan'),
          new_escchr_descriptor('cspan'),
          {
            /* NOTE this should be produced with `lexer.add_catchall_lexeme()` */
            // { mode: 'cspan', tid: 'text',      jump: null,           pattern:  /(?:\\`|[^`])+/u,  }
            mode: 'cspan',
            tid: 'text',
            jump: null,
            pattern: /[^`\\]+/u
          }
        ];
      }

    };

    //---------------------------------------------------------------------------------------------------------
    // @lx_nl:  /$/u

    //---------------------------------------------------------------------------------------------------------
    Markdown_sx.lx_star1 = {
      tid: 'star1',
      pattern: /(?<!\*)\*(?!\*)/u,
      reserved: '*'
    };

    Markdown_sx.lx_star2 = {
      tid: 'star2',
      pattern: /(?<!\*)\*\*(?!\*)/u,
      reserved: '*'
    };

    Markdown_sx.lx_star3 = {
      tid: 'star3',
      pattern: /(?<!\*)\*\*\*(?!\*)/u,
      reserved: '*'
    };

    //---------------------------------------------------------------------------------------------------------
    Markdown_sx.lx_hashes = /^(?<text>#{1,6})($|\s+)/u;

    return Markdown_sx;

  }).call(this);

  //===========================================================================================================
  Hypedown_lexer = class Hypedown_lexer extends Interlex {
    //---------------------------------------------------------------------------------------------------------
    constructor() {
      var i, len, lexeme, lexemes_lst, markdown_sx, standard_sx;
      super({
        linewise: true,
        border_tokens: true
      });
      _TEMP_add_lexemes(this);
      standard_sx = new Standard_sx();
      markdown_sx = new Markdown_sx();
      lexemes_lst = [];
      standard_sx.add_lexemes(lexemes_lst);
      markdown_sx.add_lexemes(lexemes_lst);
      for (i = 0, len = lexemes_lst.length; i < len; i++) {
        lexeme = lexemes_lst[i];
        this.add_lexeme(lexeme);
      }
      // @add_catchall_lexeme { mode: 'standard', }
      // @add_reserved_lexeme { mode: 'standard', }
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    step(...P) {
      return GUY.lft.lets(super.step(...P), function(tokens) {
        var i, len, token;
        for (i = 0, len = tokens.length; i < len; i++) {
          token = tokens[i];
          delete token.source;
        }
        return null;
      });
      return R;
    }

  };

  //-----------------------------------------------------------------------------------------------------------
  new_escchr_descriptor = function(mode) {
    var create;
    create = function(token) {
      var ref;
      if (((ref = token.data) != null ? ref.chr : void 0) == null) {
        token.data = {
          chr: '\n'
        };
      }
      return token;
    };
    return {
      mode,
      tid: 'escchr',
      pattern: /\\(?<chr>.|$)/u,
      reserved: '\\',
      create
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  new_nl_descriptor = function(mode) {
    /* TAINT consider to force value by setting it in descriptor (needs interlex update) */
    var create;
    create = function(token) {
      token.value = '\n';
      return token;
    };
    return {
      mode,
      tid: 'nl',
      pattern: /$/u,
      create
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  _TEMP_add_lexemes = function(lexer) {
    (() => {      // lexer.add_lexeme { mode, tid: 'eol',      pattern: ( /$/u  ), }
      //.........................................................................................................
      var mode;
      mode = 'plain';
      lexer.add_lexeme(new_escchr_descriptor(mode));
      lexer.add_lexeme(new_nl_descriptor(mode));
      lexer.add_lexeme({
        mode,
        tid: 'amp',
        jump: '[xncr',
        pattern: /&(?=[^\s\\]+;)/,
        reserved: '&' // only match if ahead of (no ws, no bslash) + semicolon
      });
      lexer.add_lexeme({
        mode,
        tid: 'c_s',
        jump: '[tag]',
        pattern: '/',
        reserved: '/'
      });
      lexer.add_lexeme({
        mode,
        tid: 'c_lsr',
        jump: '[tag]',
        pattern: '</>',
        reserved: '<'
      });
      lexer.add_lexeme({
        mode,
        tid: 'c_ls',
        jump: '[tag',
        pattern: /<\/(?!>)/,
        reserved: '<'
      });
      lexer.add_lexeme({
        mode,
        tid: 'ltbang',
        jump: '[comment',
        pattern: '<!--',
        reserved: '<'
      });
      lexer.add_lexeme({
        mode,
        tid: 'lt',
        jump: '[tag',
        pattern: '<',
        reserved: '<'
      });
      lexer.add_lexeme({
        mode,
        tid: 'ws',
        jump: null,
        pattern: /\s+/u
      });
      lexer.add_catchall_lexeme({
        mode,
        tid: 'other',
        concat: true
      });
      return lexer.add_reserved_lexeme({
        mode,
        tid: 'forbidden',
        concat: true
      });
    })();
    (() => {      //.........................................................................................................
      var mode;
      mode = 'tag';
      lexer.add_lexeme(new_escchr_descriptor(mode));
      lexer.add_lexeme(new_nl_descriptor(mode));
      // lexer.add_lexeme { mode,  tid: 'tagtext',   jump: null,       pattern: ( /[^\/>]+/u ), }
      lexer.add_lexeme({
        mode,
        tid: 'dq',
        jump: 'tag:dq[',
        pattern: '"',
        reserved: '"'
      });
      lexer.add_lexeme({
        mode,
        tid: 'sq',
        jump: 'tag:sq[',
        pattern: "'",
        reserved: "'"
      });
      lexer.add_lexeme({
        mode,
        tid: 'slashgt',
        jump: '.]',
        pattern: '/>',
        reserved: ['>', '/']
      });
      lexer.add_lexeme({
        mode,
        tid: 'slash',
        jump: '.]',
        pattern: '/',
        reserved: '/'
      });
      lexer.add_lexeme({
        mode,
        tid: 'gt',
        jump: '.]',
        pattern: '>',
        reserved: '>'
      });
      lexer.add_catchall_lexeme({
        mode,
        tid: 'text',
        concat: true
      });
      return lexer.add_reserved_lexeme({
        mode,
        tid: 'forbidden',
        concat: true
      });
    })();
    (() => {      //.........................................................................................................
      var mode;
      mode = 'xncr';
      // lexer.add_lexeme new_escchr_descriptor  mode
      // lexer.add_lexeme new_nl_descriptor      mode
      lexer.add_lexeme({
        mode,
        tid: 'csg',
        jump: null,
        pattern: /(?<=&)[^\s;#\\]+(?=#)/u // character set sigil (non-standard)
      });
      lexer.add_lexeme({
        mode,
        tid: 'name',
        jump: null,
        pattern: /(?<=&)[^\s;#\\]+(?=;)/u // name of named entity
      });
      lexer.add_lexeme({
        mode,
        tid: 'dec',
        jump: null,
        pattern: /#(?<nr>[0-9]+)(?=;)/u
      });
      lexer.add_lexeme({
        mode,
        tid: 'hex',
        jump: null,
        pattern: /#(?:x|X)(?<nr>[0-9a-fA-F]+)(?=;)/u
      });
      lexer.add_lexeme({
        mode,
        tid: 'sc',
        jump: '.]',
        pattern: /;/u
      });
      return lexer.add_lexeme({
        mode,
        tid: '$error',
        jump: '.]',
        pattern: /.|$/u
      });
    })();
    (() => {      //.........................................................................................................
      var mode;
      mode = 'tag:dq';
      lexer.add_lexeme(new_escchr_descriptor(mode));
      lexer.add_lexeme(new_nl_descriptor(mode));
      lexer.add_lexeme({
        mode,
        tid: 'dq',
        jump: '].',
        pattern: '"',
        reserved: '"'
      });
      return lexer.add_catchall_lexeme({
        mode,
        tid: 'text',
        concat: true
      });
    })();
    (() => {      //.........................................................................................................
      var mode;
      mode = 'tag:sq';
      lexer.add_lexeme(new_escchr_descriptor(mode));
      lexer.add_lexeme(new_nl_descriptor(mode));
      lexer.add_lexeme({
        mode,
        tid: 'sq',
        jump: '].',
        pattern: "'",
        reserved: "'"
      });
      return lexer.add_catchall_lexeme({
        mode,
        tid: 'text',
        concat: true
      });
    })();
    (() => {      //.........................................................................................................
      var mode;
      mode = 'comment';
      lexer.add_lexeme(new_escchr_descriptor(mode));
      lexer.add_lexeme(new_nl_descriptor(mode));
      lexer.add_lexeme({
        mode,
        tid: 'eoc',
        jump: '.]',
        pattern: '-->',
        reserved: '--'
      });
      lexer.add_catchall_lexeme({
        mode,
        tid: 'text',
        concat: true
      });
      return lexer.add_reserved_lexeme({
        mode,
        tid: 'forbidden',
        concat: true
      });
    })();
    return null;
  };

  //===========================================================================================================
  module.exports = {_TEMP_add_lexemes, Markdown_sx, Standard_sx, Hypedown_lexer};

}).call(this);

//# sourceMappingURL=promptlexer.js.map