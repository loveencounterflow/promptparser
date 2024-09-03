(async function() {
  'use strict';
  var Failure, GUY, MIXA, Mixa, Promptparser_cli, WG, alert, debug, echo, get_types, help, hide, info, inspect, log, plain, praise, return_error, rpr, run, types, urge, warn, whisper;

  //###########################################################################################################
  GUY = require('guy');

  ({alert, debug, help, info, plain, praise, urge, warn, whisper} = GUY.trm.get_loggers('promptparser/cli'));

  //...........................................................................................................
  ({rpr, inspect, echo, log} = GUY.trm);

  ({hide} = GUY.props);

  //...........................................................................................................
  // PATH                      = require 'node:path'
  // FS                        = require 'node:fs'
  ({get_types} = require('./types'));

  types = get_types();

  MIXA = require('mixa');

  WG = require('webguy');

  //===========================================================================================================
  return_error = function(flag_name, create) {
    return function(x) {
      var error;
      try {
        return create(x);
      } catch (error1) {
        error = error1;
        return new Failure(flag_name, x);
      }
    };
  };

  //===========================================================================================================
  Failure = class Failure {
    //---------------------------------------------------------------------------------------------------------
    constructor(flag_name, value) {
      this.message = `${rpr(value)} is not a valid ${rpr(flag_name)}`;
      return void 0;
    }

  };

  //===========================================================================================================
  Mixa = class Mixa {
    //---------------------------------------------------------------------------------------------------------
    constructor(process_argv = null) {
      var base, base1, job;
      /* TAINT do these steps in MIXA */
      this._compile_runners_and_cmds();
      this._use_hyphenated_names();
      this.process_argv = process_argv != null ? process_argv : process.argv;
      //.......................................................................................................
      job = MIXA.run(this.jobdef, this.process_argv);
      this.cmd = job.verdict.cmd;
      this.flags = (base = job.verdict).parameters != null ? base.parameters : base.parameters = {};
      this.error = (base1 = job.verdict).error != null ? base1.error : base1.error = null;
      this._supply_missing_flags();
      this._validate_flags();
      this._use_underscore_names();
      //.......................................................................................................
      return void 0;
    }

    //---------------------------------------------------------------------------------------------------------
    _compile_runners_and_cmds() {
      var base, base1, base2, cmd, cmd_def, ref, runner, runner_name;
      this._runners = {};
      if ((base = this.jobdef).commands == null) {
        base.commands = {};
      }
      if ((base1 = this.jobdef.commands).help == null) {
        base1.help = {};
      }
      ref = this.jobdef.commands;
      //.......................................................................................................
      for (cmd in ref) {
        cmd_def = ref[cmd];
        runner_name = `cmd_${cmd}`;
        //.....................................................................................................
        /* accept `null` in commands as a placeholder */
        if ((base2 = this.jobdef.commands)[cmd] == null) {
          base2[cmd] = (cmd_def = {});
        }
        //.....................................................................................................
        /* disallow previously allowed 'runners' in command definitions */
        if (cmd_def.runner != null) {
          throw new Error(`Ω___1 in declaration of cmd ${rpr(cmd)}, do not use property \`runner\`; ` + `instead, declare method ${rpr(runner_name)} in class ${this.constructor.name}`);
        }
        //.....................................................................................................
        /* validate that runner exists on instance */
        if ((runner = this[runner_name]) == null) {
          throw new Error(`Ω___2 in declaration of cmd ${rpr(cmd)}: ` + `missing method ${rpr(runner_name)} in class ${this.constructor.name}`);
        }
      }
      //.......................................................................................................
      /* supply command definitions for runners without entry in jobdef */
      // for runner_name, runner of @
      // GUY.props
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _use_hyphenated_names() {
      var cmd, cmd_def, flag_def, name, ref, ref1, ref2;
      ref = this.jobdef.commands;
      /* TAINT use separate object for these */
      for (cmd in ref) {
        cmd_def = ref[cmd];
        delete this.jobdef.commands[cmd];
        this.jobdef.commands[cmd.replace(/_/g, '-')] = cmd_def;
        ref2 = (ref1 = cmd_def != null ? cmd_def.flags : void 0) != null ? ref1 : [];
        for (name in ref2) {
          flag_def = ref2[name];
          delete cmd_def.flags[name];
          cmd_def.flags[name.replace(/_/g, '-')] = flag_def;
        }
      }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _use_underscore_names() {
      var name, ref, value;
      /* TAINT use separate object for these */
      this.cmd = this.cmd.replace(/-/g, '_');
      ref = this.flags;
      for (name in ref) {
        value = ref[name];
        delete this.flags[name];
        this.flags[name.replace(/-/g, '_')] = value;
      }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _supply_missing_flags() {
      var cmd_def, flag_def, flag_name, ref, ref1;
      cmd_def = this.jobdef.commands[this.cmd];
      ref1 = (ref = cmd_def.flags) != null ? ref : {};
      for (flag_name in ref1) {
        flag_def = ref1[flag_name];
        if (Reflect.has(this.flags, flag_name)) {
          continue;
        }
        this.flags[flag_name] = null;
      }
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _validate_flags() {
      var failure_count, flag_name, flag_value, ref;
      failure_count = 0;
      ref = this.flags;
      for (flag_name in ref) {
        flag_value = ref[flag_name];
        if (flag_value instanceof Failure) {
          failure_count++;
          warn('Ω___3', GUY.trm.reverse(` ${flag_value.message} `));
        }
      }
      //.......................................................................................................
      if (failure_count > 0) {
        warn('Ω___4', GUY.trm.reverse(" one or more flags have incorrect values, see above "));
        process.exit(111);
      }
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    cmd_help() {
      var cmd, cmds, description, flag, flags, i, j, len, len1, ref, ref1;
      debug('Ω___5', this.cmd, this.flags);
      if (this.error != null) {
        warn(GUY.trm.reverse(` ${this.error.tag}: ${this.error.message} `));
      }
      //.......................................................................................................
      /* TAINT the ordering stuff done here should be performed by a jobdef compilation step */
      help('Ω___6', "The following sub-commands are available:");
      cmds = ((function() {
        var results;
        results = [];
        for (cmd in this.jobdef.commands) {
          results.push(cmd);
        }
        return results;
      }).call(this)).sort();
      for (i = 0, len = cmds.length; i < len; i++) {
        cmd = cmds[i];
        flags = ((function() {
          var results;
          results = [];
          for (flag in this.jobdef.commands[cmd].flags) {
            results.push(flag);
          }
          return results;
        }).call(this)).sort();
        description = (ref = this.jobdef.commands[cmd].description) != null ? ref : '?';
        help(` ${cmd} ${GUY.trm.blue(description)}`);
        for (j = 0, len1 = flags.length; j < len1; j++) {
          flag = flags[j];
          description = (ref1 = this.jobdef.commands[cmd].flags[flag].description) != null ? ref1 : '?';
          urge(`   --${flag} ${GUY.trm.blue(description)}`);
        }
      }
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    run() {
      var runner_name;
      runner_name = `cmd_${this.cmd}`;
      this[runner_name].call(this);
      return null;
    }

  };

  Promptparser_cli = (function() {
    //===========================================================================================================
    class Promptparser_cli extends Mixa {
      // fallback:       null ### TAINT `fallback` repeated as `template` in types ###

        //---------------------------------------------------------------------------------------------------------
      _new_prompt_file_reader() {
        var Prompt_file_reader;
        ({Prompt_file_reader} = require('./main'));
        return new Prompt_file_reader(this.cmd, this.flags);
      }

      // #---------------------------------------------------------------------------------------------------------
      // cmd_nosuch: ->
      //   help 'Ω___7', "cmd_nosuch", @flags
      //   return null

        // #---------------------------------------------------------------------------------------------------------
      // cmd_refresh: ->
      //   help 'Ω___8', "cmd_refresh", @flags
      //   pfr = @_new_prompt_file_reader()
      //   return null

        //---------------------------------------------------------------------------------------------------------
      cmd_build() {
        help('Ω___9', "cmd_build", this.flags);
        // pfr = @_new_prompt_file_reader()
        return null;
      }

    };

    //---------------------------------------------------------------------------------------------------------
    Promptparser_cli.prototype.jobdef = {
      exit_on_error: false,
      commands: {
        // refresh:
        //   description:    "refresh database"
        //   allow_extra:    false
        //   flags:
        //     # $name:
        //     #   type:           function
        //     #   alias:          text
        //     #   description:    text
        //     #   multiple:       [ null, false, 'greedy', 'lazy', ]
        //     #   positional:     boolean
        //     #   fallback:       anything
        //     max_count:
        //       type:           return_error 'max_count', types.create.cli_max_count.bind types.create
        //       alias:          'x'
        //       description:    "processing will be short-cut after this many prompts"
        //       multiple:       false # [ null, false, 'greedy', 'lazy', ]
        //       positional:     false # boolean
        //       fallback:       Infinity ### TAINT `fallback` repeated as `template` in types ###
        build: {
          description: "build DB from prompts path given",
          flags: {
            max_count: {
              type: return_error('max_count', types.create.cli_max_count.bind(types.create)),
              description: "max_count",
              multiple: false,
              positional: false
            },
            // fallback:       Infinity ### TAINT `fallback` repeated as `template` in types ###
            sample: {
              type: return_error('sample', types.create.cli_sample.bind(types.create)),
              description: "when given as e.g. `4/1000` or `0.4%`, will randomly choose approx. 0.4% of all prompts",
              multiple: false,
              positional: false
            },
            // fallback:       1 ### TAINT `fallback` repeated as `template` in types ###
            match: {
              type: return_error('match', types.create.cli_match.bind(types.create)),
              description: "when given, will run this RegEx against prompts and only keep matching ones",
              multiple: false,
              positional: false
            },
            // fallback:       null ### TAINT `fallback` repeated as `template` in types ###
            overwrite: {
              type: return_error('overwrite', types.create.cli_overwrite.bind(types.create)),
              description: "whether to overwrite existing DB",
              multiple: false,
              positional: false
            },
            // fallback:       false ### TAINT `fallback` repeated as `template` in types ###
            db: {
              type: return_error('db', types.create.cli_db.bind(types.create)),
              description: "path to DB",
              multiple: false,
              positional: false
            },
            // fallback:       null ### TAINT `fallback` repeated as `template` in types ###
            prompts: {
              type: return_error('prompts', types.create.cli_prompts.bind(types.create)),
              description: "prompts",
              multiple: false,
              positional: true
            }
          }
        }
      }
    };

    return Promptparser_cli;

  }).call(this);

  //===========================================================================================================
  run = async function(process_argv = null) {
    var cli;
    cli = new Promptparser_cli(process_argv != null ? process_argv : process.argv);
    info('Ω__10', `running command: ${GUY.trm.gold(cli.cmd)} ${GUY.trm.lime(rpr(cli.flags))}`);
    await cli.run();
/* using `await` to demonstrate generally command execution may be async */    return null;
  };

  //===========================================================================================================
  if (module === require.main) {
    await run();
  } else {
    /* command line  use */    module.exports = {run, Promptparser_cli};
  }

  /* programmatic  use */

}).call(this);

//# sourceMappingURL=cli.js.map