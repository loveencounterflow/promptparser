(function() {
  'use strict';
  var GUY, Intertype, alert, debug, echo, get_types, help, info, inspect, log, plain, praise, reverse, rpr, types, urge, warn, whisper;

  //===========================================================================================================
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/types'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  ({Intertype} = require('intertype'));

  //...........................................................................................................
  types = null;

  //===========================================================================================================
  get_types = function() {
    var create, isa, type_of, validate;
    if (types != null) {
      return types;
    }
    types = new Intertype();
    ({isa, type_of, validate, create} = types);
    //.........................................................................................................
    types.declare({
      //.......................................................................................................
      cardinal_or_infinity: function(x) {
        return (x === 2e308) || (this.isa.cardinal(x));
      },
      //.......................................................................................................
      pp_linenumber: 'positive.integer',
      pp_content_id: function(x) {
        return (this.isa.text(x)) && (/^[0-9a-f]{16}$/.test(x));
      },
      //.......................................................................................................
      pp_prerecord_initial: {
        fields: {
          $key: 'text',
          lnr: function(x) {
            return this.isa.optional.pp_linenumber(x);
          },
          /* TAINT workaround due to missing feature */promptnr: function(x) {
            return this.isa.optional.text(x);
          },
          /* TAINT workaround due to missing feature */prompt: function(x) {
            return this.isa.optional.text(x);
          },
          /* TAINT workaround due to missing feature */prompt_id: function(x) {
            return this.isa.optional.pp_content_id(x);
          },
          /* TAINT workaround due to missing feature */generations: function(x) {
            return this.isa.optional.list(x);
          },
          /* TAINT workaround due to missing feature */comment: function(x) {
            return this.isa.optional.text(x);
          },
          /* TAINT workaround due to missing feature */rejected: function(x) {
            return this.isa.optional.boolean(x);
          }
        },
        /* TAINT workaround due to missing feature */template: {
          $key: 'prerecord',
          lnr: null,
          promptnr: null,
          prompt: null,
          prompt_id: null,
          generations: null,
          comment: null,
          rejected: false
        }
      },
      //.......................................................................................................
      pp_prerecord_final: {
        fields: {
          $key: 'text',
          lnr: 'positive.integer',
          promptnr: function(x) {
            return this.isa.optional.text(x);
          },
          /* TAINT workaround due to missing feature */prompt: 'text',
          prompt_id: 'pp_content_id',
          generations: function(x) {
            return (this.isa.list(x)) && (x.every((e) => {
              return this.isa.cardinal(e);
            }));
          },
          /* TAINT workaround due to missing feature */comment: function(x) {
            return this.isa.optional.text(x);
          },
          /* TAINT workaround due to missing feature */rejected: 'boolean'
        },
        create: function(x) {
          if (!this.isa.object(x)) {
            return x;
          }
          return x;
        }
      },
      // #.......................................................................................................
      // fm_table_name:          'nonempty.text'
      // fm_datasource_path:     'nonempty.text'
      // fm_table_fields:        'object'
      // #.......................................................................................................
      // fm_constructor_cfg:
      //   fields:
      //     db:                   'object'
      //     datasource_path:      'fm_datasource_path'
      //     table_name:           'fm_table_name'
      //   template:
      //     db:                   null
      //     datasource_path:      null
      //     table_name:           'fm_lines'
      //   create: ( cfg ) ->
      //     return { @declarations.fm_constructor_cfg.template..., cfg..., }
      // #.......................................................................................................
      // fm_insertion_record_object:
      //   fields:
      //     table:              'fm_table_name'
      //     fields:             'fm_table_fields'
      // fm_insertion_record_list: ( x ) ->
      //   return false unless @isa.list x
      //   return x.every ( e ) => @isa.fm_insertion_record_object e
      // fm_insertion_records:
      //   test:     ( x ) -> ( @isa.fm_insertion_record_object x ) or ( @isa.fm_insertion_record_list x )
      //   create:   ( x ) ->
      //     return x if @isa.fm_insertion_record_list x
      //     return [ x, ]
      //.......................................................................................................
      list_or_iterator: function(x) {
        if (this.isa.list(x)) {
          return true;
        }
        if (this.isa.generator(x)) {
          return true;
        }
        return false;
      },
      //.......................................................................................................
      pfr_constructor_cfg: {
        test: 'object',
        fields: {
          cmd: 'nonempty.text',
          flags: 'object',
          lines: 'list_or_iterator'
        },
        create: function(cfg) {
          var R;
          R = {...this.declarations.pfr_constructor_cfg.template, ...cfg};
          return R;
        }
      },
      //.......................................................................................................
      cli_max_count: {
        test: 'cardinal_or_infinity',
        template: +2e308,
        create: function(x) {
          if (x == null) {
            return this.declarations.cli_max_count.template;
          }
          // return x unless /^\+?\d+$/.test x
          return Math.round(parseFloat(x));
        }
      },
      //.......................................................................................................
      normalfloat: function(x) {
        return (this.isa.float(x)) && (0 <= x && x <= 1);
      },
      //.......................................................................................................
      cli_sample: {
        test: 'normalfloat',
        template: 1,
        create: function(x) {
          var match;
          switch (true) {
            case x == null:
              return this.declarations.cli_sample.template;
            case x.endsWith('%'):
              return (parseFloat(x)) / 100;
            case (match = x.match(/^(?<numerator>[0-9.]+)\/(?<denominator>[0-9.]+)$/)) != null:
              return (parseFloat(match.groups.numerator)) / parseFloat(match.groups.denominator);
          }
          return parseFloat(x);
        }
      },
      //.......................................................................................................
      cli_seed: {
        test: 'float',
        template: null,
        create: function(x) {
          if (x == null) {
            return this.declarations.cli_sample.template;
          }
          return parseFloat(x);
        }
      },
      //.......................................................................................................
      cli_match: {
        test: function(x) {
          return this.isa.optional.regex(x);
        },
        /* TAINT workaround due to missing feature */template: null,
        create: function(x) {
          if (x == null) {
            return null;
          }
          return new RegExp(x);
        }
      },
      //.......................................................................................................
      cli_pre_match: {
        test: 'regex',
        template: /^\[.*?\].*?\S+/,
        create: function(x) {
          debug('Ω__1', rpr(x), rpr(this.declarations.cli_pre_match.template));
          if (x == null) {
            return this.declarations.cli_pre_match.template;
          }
          return new RegExp(x);
        }
      },
      //.......................................................................................................
      cli_trash_db: {
        test: 'boolean',
        template: false,
        create: function(x) {
          if (x == null) {
            return this.declarations.cli_trash_db.template;
          }
          if (x === 'true') {
            return true;
          }
          if (x === 'false') {
            return false;
          }
          return x;
        }
      },
      //.......................................................................................................
      cli_db: {
        test: 'nonempty.text',
        template: '/dev/shm/promptparser.sqlite',
        create: function(x) {
          return x != null ? x : this.declarations.cli_db.template;
        }
      },
      //.......................................................................................................
      cli_prompts: {
        test: 'nonempty.text',
        template: null,
        create: function(x) {
          return x;
        }
      }
    });
    //.........................................................................................................
    return types;
  };

  //===========================================================================================================
  module.exports = {get_types};

}).call(this);

//# sourceMappingURL=types.js.map