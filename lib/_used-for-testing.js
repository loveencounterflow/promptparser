(function() {
  'use strict';
  var GUY, Journal_walker, _Journal_walker_for_testing;

  //###########################################################################################################
  GUY = require('guy');

  ({Journal_walker} = require('./journal-walker'));

  //===========================================================================================================
  _Journal_walker_for_testing = class _Journal_walker_for_testing extends Journal_walker {
    //---------------------------------------------------------------------------------------------------------
    constructor(cfg) {
      if (cfg.lines == null) {
        cfg.lines = [];
      }
      super(cfg);
      return void 0;
    }

    //=========================================================================================================
    parse_all_records(source) {
      var R, eol, line, lnr, ref, x;
      R = [];
      ref = GUY.str.walk_lines_with_positions(source);
      for (x of ref) {
        ({lnr, line, eol} = x);
        this.pipeline.send({lnr, line});
        R = R.concat(this.pipeline.run());
      }
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    parse_first_records(source) {
      var R, prompt_id, record, ref;
      prompt_id = null;
      R = [];
      ref = this.parse_all_records(source);
      for (record of ref) {
        if (prompt_id == null) {
          prompt_id = record.prompt_id;
        }
        if (prompt_id !== record.prompt_id) {
          break;
        }
        R.push(record);
      }
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    parse_all_tokens(source) {
      var R, eol, line, lnr, ref, ref1, token, x;
      R = [];
      ref = GUY.str.walk_lines_with_positions(source);
      for (x of ref) {
        ({lnr, line, eol} = x);
        ref1 = this.prompt_parser._lexer.walk(line);
        for (token of ref1) {
          if (this.types.isa.symbol(token)) {
            continue;
          }
          R.push(this.prompt_parser._cast_token(lnr, token));
        }
      }
      return R;
    }

    //---------------------------------------------------------------------------------------------------------
    parse_first_tokens(source) {
      var R, lnr1, ref, token;
      R = [];
      lnr1 = null;
      ref = this.parse_all_tokens(source);
      for (token of ref) {
        if (lnr1 == null) {
          lnr1 = token.lnr1;
        }
        if (lnr1 !== token.lnr1) {
          break;
        }
        R.push(token);
      }
      return R;
    }

  };

  //===========================================================================================================
  module.exports = {_Journal_walker_for_testing};

}).call(this);

//# sourceMappingURL=_used-for-testing.js.map