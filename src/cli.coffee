

'use strict'


############################################################################################################
GUY                       = require 'guy'
{ alert
  debug
  help
  info
  plain
  praise
  urge
  warn
  whisper }               = GUY.trm.get_loggers 'promptparser/cli'
#...........................................................................................................
{ rpr
  inspect
  echo
  log     }               = GUY.trm
{ hide }                  = GUY.props
#...........................................................................................................
# PATH                      = require 'node:path'
# FS                        = require 'node:fs'
{ get_types }             = require './types'
types                     = get_types()
MIXA                      = require 'mixa'
WG                        = require 'webguy'


#===========================================================================================================
return_error = ( flag_name, create ) -> ( x ) -> try create x catch error then new Failure flag_name, x


#===========================================================================================================
class Failure

  #---------------------------------------------------------------------------------------------------------
  constructor: ( flag_name, value ) ->
    @message = "#{rpr value} is not a valid #{rpr flag_name}"
    return undefined


#===========================================================================================================
class Mixa

  #---------------------------------------------------------------------------------------------------------
  constructor: ( process_argv = null ) ->
    ### TAINT do these steps in MIXA ###
    @_compile_runners_and_cmds()
    @_use_hyphenated_names()
    @process_argv             = process_argv ? process.argv
    #.......................................................................................................
    job                       = MIXA.run @jobdef, @process_argv
    @cmd                      = job.verdict.cmd
    @flags                    = job.verdict.parameters  ?= {}
    @error                    = job.verdict.error       ?= null
    @_supply_missing_flags()
    @_validate_flags()
    @_use_underscore_names()
    #.......................................................................................................
    return undefined

  #---------------------------------------------------------------------------------------------------------
  _compile_runners_and_cmds: ->
    @_runners               = {}
    @jobdef.commands       ?= {}
    @jobdef.commands.help  ?= {}
    #.......................................................................................................
    for cmd, cmd_def of @jobdef.commands
      runner_name = "cmd_#{cmd}"
      #.....................................................................................................
      ### accept `null` in commands as a placeholder ###
      @jobdef.commands[ cmd ] ?= ( cmd_def = {} )
      #.....................................................................................................
      ### disallow previously allowed 'runners' in command definitions ###
      if cmd_def.runner?
        throw new Error "Ω___1 in declaration of cmd #{rpr cmd}, do not use property `runner`; " + \
          "instead, declare method #{rpr runner_name} in class #{@constructor.name}"
      #.....................................................................................................
      ### validate that runner exists on instance ###
      unless ( runner = @[ runner_name ] )?
        throw new Error "Ω___2 in declaration of cmd #{rpr cmd}: " + \
          "missing method #{rpr runner_name} in class #{@constructor.name}"
    #.......................................................................................................
    ### supply command definitions for runners without entry in jobdef ###
    # for runner_name, runner of @
    # GUY.props
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _use_hyphenated_names: ->
    ### TAINT use separate object for these ###
    for cmd, cmd_def of @jobdef.commands
      delete @jobdef.commands[ cmd ]
      @jobdef.commands[ cmd.replace /_/g, '-' ] = cmd_def
      for name, flag_def of cmd_def?.flags ? []
        delete cmd_def.flags[ name ]
        cmd_def.flags[ name.replace /_/g, '-' ] = flag_def
    return null

  #---------------------------------------------------------------------------------------------------------
  _use_underscore_names: ->
    ### TAINT use separate object for these ###
    @cmd = @cmd.replace /-/g, '_'
    for name, value of @flags
      delete @flags[ name ]
      @flags[ name.replace /-/g, '_' ] = value
    return null

  #---------------------------------------------------------------------------------------------------------
  _supply_missing_flags: ->
    cmd_def               = @jobdef.commands[ @cmd ]
    for flag_name, flag_def of cmd_def.flags ? {}
      continue if Reflect.has @flags, flag_name
      @flags[ flag_name ] = flag_def.type null ### TAINT should call `create` ###
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  _validate_flags: ->
    help 'Ω___3', @flags
    failure_count         = 0
    for flag_name, flag_value of @flags
      if flag_value instanceof Failure
        failure_count++
        warn 'Ω___4', GUY.trm.reverse " #{flag_value.message} "
    #.......................................................................................................
    if failure_count > 0
      warn 'Ω___5', GUY.trm.reverse " one or more flags have incorrect values, see above "
      process.exit 111
    #.......................................................................................................
    return null

  #---------------------------------------------------------------------------------------------------------
  cmd_help: ->
    debug 'Ω___6', @cmd, @flags
    if @error?
      warn 'Ω___7', GUY.trm.reverse " #{@error.tag}: #{@error.message} "
    debug 'Ω___8', rpr @cmd
    #.......................................................................................................
    ### TAINT the ordering stuff done here should be performed by a jobdef compilation step ###
    help 'Ω___9', "The following sub-commands are available:"
    cmds = ( cmd for cmd of @jobdef.commands ).sort()
    for cmd in cmds
      flags = ( flag for flag of @jobdef.commands[ cmd ].flags ).sort()
      description = @jobdef.commands[ cmd ].description ? '?'
      help " #{cmd} #{GUY.trm.blue description}"
      for flag in flags
        description = @jobdef.commands[ cmd ].flags[ flag ].description ? '?'
        urge "   --#{flag} #{GUY.trm.blue description}"
    return null

  #---------------------------------------------------------------------------------------------------------
  run: ->
    runner_name   = "cmd_#{@cmd}"
    @[ runner_name ].call @
    return null


#===========================================================================================================
class Promptparser_cli extends Mixa

  #---------------------------------------------------------------------------------------------------------
  jobdef:
    exit_on_error:  false
    commands:
      # refresh:
      #   description:    "refresh database"
      #   allow_extra:    false
      #   flags:
      #     # $name:
      #     #   type:           function
      #     #   alias:          text
      #     #   description:    text
      #     #   multiple:       [ null, false, 'greedy', 'lazy', ]
      #     #   positional:     boolean
      #     #   fallback:       anything
      #     max_count:
      #       type:           return_error 'max_count', types.create.cli_max_count.bind types.create
      #       alias:          'x'
      #       description:    "processing will be short-cut after this many prompts"
      #       multiple:       false # [ null, false, 'greedy', 'lazy', ]
      #       positional:     false # boolean
      #       fallback:       Infinity ### TAINT `fallback` repeated as `template` in types ###
      build:
        description: "build DB from prompts path given"
        flags:
          max_count:
            description:    "max_count"
            expect:         "an integer number such as `1439`; may use exponential notation as in `1.5e3`"
            type:           return_error 'max_count', types.create.cli_max_count.bind types.create
          sample:
            description:    "a ratio to indicate the approximate ratio of prompts to randomly accept"
            expect:         "a fraction as in `20/1000` or `0.02`, or a percentage as in `2%`"
            type:           return_error 'sample',    types.create.cli_sample.bind    types.create
          seed:
            description:    "(when `--sample` is given) a seed to initialize the random number generator"
            expect:         "any float, for example `-67.43` or `39382.1`"
            type:           return_error 'seed',      types.create.cli_seed.bind    types.create
          match:
            description:    "only keep prompts that match this RegEx"
            expect:         "a legal JavaScript literal to be used in `new RegExp()`; slashes will be interpreted literally"
            type:           return_error 'match',     types.create.cli_match.bind     types.create
          overwrite:
            description:    "whether to overwrite existing DB"
            expect:         "may be used without value or else with either `true` or `false`"
            type:           return_error 'overwrite', types.create.cli_overwrite.bind types.create
          db:
            description:    "path to DB"
            expect:         "file system path that points to either an unused name in an existing folder or a valid SQLite DB file"
            type:           return_error 'db',        types.create.cli_db.bind        types.create
          prompts:
            description:    "prompts"
            expect:         "file system path that points to a file containing the prompts to be processed"
            type:           return_error 'prompts',   types.create.cli_prompts.bind   types.create
            positional:     true

  #---------------------------------------------------------------------------------------------------------
  _new_prompt_file_reader: ->
    { Prompt_file_reader, } = require './main'
    return new Prompt_file_reader @cmd, @flags

  # #---------------------------------------------------------------------------------------------------------
  # cmd_nosuch: ->
  #   help 'Ω__10', "cmd_nosuch", @flags
  #   return null

  # #---------------------------------------------------------------------------------------------------------
  # cmd_refresh: ->
  #   help 'Ω__11', "cmd_refresh", @flags
  #   pfr = @_new_prompt_file_reader()
  #   return null

  #---------------------------------------------------------------------------------------------------------
  cmd_build: ->
    help 'Ω__12', "cmd_build", @flags
    # pfr = @_new_prompt_file_reader()
    return null


#===========================================================================================================
run = ( process_argv = null ) ->
  cli = new Promptparser_cli process_argv ? process.argv
  info 'Ω__13', "running command: #{GUY.trm.gold cli.cmd} #{GUY.trm.lime rpr cli.flags}"
  await cli.run() ### using `await` to demonstrate generally command execution may be async ###
  return null


#===========================================================================================================
if module is require.main then  await run()                                 ### command line  use ###
else                            module.exports = { run, Promptparser_cli, } ### programmatic  use ###


