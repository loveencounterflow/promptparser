(function() {
  'use strict';
  var GUY, alert, debug, echo, help, info, inspect, log, plain, praise, reverse, rpr, urge, warn, whisper;

  //===========================================================================================================
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser'));

  ({rpr, inspect, echo, reverse, log} = GUY.trm);

  debug('Ω___1', require('./production-registry'));

  debug('Ω___2', require('./image-registry'));

}).call(this);

//# sourceMappingURL=main.js.map