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
      pp_linenumber: 'positive.integer',
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
      }
    });
    //.........................................................................................................
    return types;
  };

  //===========================================================================================================
  module.exports = {get_types};

}).call(this);

//# sourceMappingURL=types.js.map