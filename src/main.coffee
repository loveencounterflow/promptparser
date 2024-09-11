
'use strict'

#===========================================================================================================
GUY                       = require 'guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'promptparser'
{ rpr
  inspect
  echo
  reverse
  log     }               = GUY.trm

debug 'Ω___1', require './production-registry'
debug 'Ω___2', require './image-registry'

