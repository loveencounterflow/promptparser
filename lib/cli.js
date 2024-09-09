(async function() {
  'use strict';
  var Failure, GUY, MIXA, Mixa, Promptparser_cli, U, WG, alert, debug, echo, get_types, help, hide, info, inspect, log, plain, praise, return_error, rpr, run, types, urge, warn, whisper;

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

  ({U} = require('./utilities'));

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
      this.flag_name = flag_name;
      this.value = value;
      this.message = `${rpr(value)} is not a valid setting for flag \`--${flag_name}\``;
      return void 0;
    }

  };

  //===========================================================================================================
  Mixa = class Mixa {
    //---------------------------------------------------------------------------------------------------------
    constructor(process_argv = null) {
      var base, base1, job, ref;
      /* TAINT monkeypatch so we can use new flag property */
      delete MIXA.types.specs.mixa_flagdef.tests["x has only keys 'type', 'alias', 'description', 'multiple', 'fallback', 'positional'"];
      /* TAINT do these steps in MIXA */
      this._compile_runners_and_cmds();
      this._use_hyphenated_names();
      this.process_argv = process_argv != null ? process_argv : process.argv;
      //.......................................................................................................
      job = MIXA.run(this.jobdef, this.process_argv);
      this.extra_flags = (ref = job.verdict.extra_flags) != null ? ref : [];
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
          throw new Error(`Ω___5 in declaration of cmd ${rpr(cmd)}, do not use property \`runner\`; ` + `instead, declare method ${rpr(runner_name)} in class ${this.constructor.name}`);
        }
        //.....................................................................................................
        /* validate that runner exists on instance */
        if ((runner = this[runner_name]) == null) {
          throw new Error(`Ω___6 in declaration of cmd ${rpr(cmd)}: ` + `missing method ${rpr(runner_name)} in class ${this.constructor.name}`);
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
        this.flags[flag_name] = flag_def.type(null);
      }
//.......................................................................................................
/* TAINT should call `create` */      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    _validate_flags() {
      var expect, failed_flag_names, failed_flags, failure, flag_def, flag_name, flag_value, ref;
      failed_flags = [];
      ref = this.flags;
      for (flag_name in ref) {
        flag_value = ref[flag_name];
        if (flag_value instanceof Failure) {
          failure = flag_value;
          failed_flags.push(`\`--${flag_name}\``);
          echo();
          echo('🔴', GUY.trm.bold(` ${failure.message} `));
          flag_def = this.jobdef.commands[this.cmd].flags[flag_name];
          if ((expect = flag_def.expect) != null) {
            echo(U.color.expect(`expected ${expect}`));
            echo(GUY.trm.bold(`got ${rpr(failure.value)}`));
          }
        }
      }
      //.......................................................................................................
      if (failed_flags.length > 0) {
        echo();
        failed_flag_names = failed_flags.join(', ');
        if (failed_flags.length === 1) {
          echo(GUY.trm.red(GUY.trm.reverse(GUY.trm.bold(` flag ${failed_flag_names} has an incorrect setting, see above `))));
        } else {
          echo(GUY.trm.red(GUY.trm.reverse(GUY.trm.bold(` flags ${failed_flag_names} have incorrect settings, see above `))));
        }
        process.exit(111);
      }
      //.......................................................................................................
      return null;
    }

    //---------------------------------------------------------------------------------------------------------
    /* TAINT the ordering stuff done here should be performed by a jobdef compilation step */
    _list_of_flags_for_cmd(cmd) {
      var flag;
      return ((function() {
        var results;
        results = [];
        for (flag in this.jobdef.commands[cmd].flags) {
          results.push(flag);
        }
        return results;
      }).call(this)).sort();
    }

    //---------------------------------------------------------------------------------------------------------
    cmd_help() {
      var cmd, cmd_def, cmds, description, expect, flag, flag_def, flags, i, j, k, len, len1, len2, ref, ref1, ref2, status;
      status = 0;
      if (this.error != null) {
        status = 1;
        warn('Ω___7', GUY.trm.reverse(` ${this.error.tag}: ${this.error.message} `));
        if (this.error.tag === 'EXTRA_FLAGS') {
          if (this.extra_flags.length > 0) {
            echo(GUY.trm.red(`found ${this.extra_flags.length} extraneous flag(s)`));
            ref = this.extra_flags;
            for (i = 0, len = ref.length; i < len; i++) {
              flag = ref[i];
              echo(GUY.trm.red(`  * extraneous flag ${U.color.bad(rpr(flag))}`));
            }
          }
        }
      }
      //.......................................................................................................
      /* TAINT the ordering stuff done here should be performed by a jobdef compilation step */
      help(GUY.trm.grey('Ω___9'));
      echo(GUY.trm.lime("The following sub-commands are available:"));
      cmds = ((function() {
        var results;
        results = [];
        for (cmd in this.jobdef.commands) {
          results.push(cmd);
        }
        return results;
      }).call(this)).sort();
      for (j = 0, len1 = cmds.length; j < len1; j++) {
        cmd = cmds[j];
        cmd_def = this.jobdef.commands[cmd];
        flags = this._list_of_flags_for_cmd(cmd);
        description = (ref1 = this.jobdef.commands[cmd].description) != null ? ref1 : (cmd === 'help' ? "show this message" : '?');
        echo(` ${U.color.cmd(cmd)} ${U.color.description(description)}`);
        for (k = 0, len2 = flags.length; k < len2; k++) {
          flag = flags[k];
          flag_def = cmd_def.flags[flag];
          description = (ref2 = flag_def.description) != null ? ref2 : '?';
          echo(`   ${U.color.flag('--' + flag)} ${U.color.description(description)}`);
          if ((expect = flag_def.expect) != null) {
            echo(`     ${U.color.expect('expects ' + expect)}`);
          }
        }
      }
      process.exit(status);
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
      //---------------------------------------------------------------------------------------------------------
      _new_prompt_file_reader(cmd = null, flags = null) {
        var Prompt_file_reader;
        ({Prompt_file_reader} = require('./main'));
        return new Prompt_file_reader(cmd != null ? cmd : this.cmd, flags != null ? flags : this.flags);
      }

      // #---------------------------------------------------------------------------------------------------------
      // cmd_nosuch: ->
      //   help 'Ω__10', "cmd_nosuch", @flags
      //   return null

        // #---------------------------------------------------------------------------------------------------------
      // cmd_refresh: ->
      //   help 'Ω__11', "cmd_refresh", @flags
      //   pfr = @_new_prompt_file_reader()
      //   return null

        //---------------------------------------------------------------------------------------------------------
      cmd_build() {
        var pfr;
        help('Ω__12', "cmd_build", this.flags);
        pfr = this._new_prompt_file_reader();
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
              description: "maximum number of unique prompts to add to the DB after filtering and matching",
              expect: "an integer number such as `1439`; may use exponential notation as in `1.5e3`",
              type: return_error('max_count', types.create.cli_max_count.bind(types.create))
            },
            sample: {
              description: "a ratio to indicate the approximate ratio of source lines to randomly accept; precedes `--match`es",
              expect: "a fraction as in `20/1000` or `0.02`, or a percentage as in `2%`",
              type: return_error('sample', types.create.cli_sample.bind(types.create))
            },
            seed: {
              description: "(when `--sample` is given) a seed to initialize the random number generator",
              expect: "any float, for example `-67.43` or `39382.1`",
              type: return_error('seed', types.create.cli_seed.bind(types.create))
            },
            pre_match: {
              description: "only keep raw lines that match this RegEx; defaults to selecting lines that start with square brackets, non-empty prompt text",
              expect: "a legal JavaScript literal to be used in `new RegExp()`; slashes will be interpreted literally",
              type: return_error('pre_match', types.create.cli_pre_match.bind(types.create))
            },
            match: {
              description: "only keep prompts that match this RegEx; applies after `--pre-match`, `--sample`",
              expect: "a legal JavaScript literal to be used in `new RegExp()`; slashes will be interpreted literally",
              type: return_error('match', types.create.cli_match.bind(types.create))
            },
            trash_db: {
              description: "whether to move existing DB file to trash",
              expect: "`true` or `false`; default is `false`",
              type: return_error('trash_db', types.create.cli_trash_db.bind(types.create))
            },
            db: {
              description: "path to DB",
              expect: "path that points to either an unused file name in an existing folder or a valid SQLite DB file",
              type: return_error('db', types.create.cli_db.bind(types.create))
            },
            prompts: {
              description: "prompts",
              expect: "file system path that points to a file containing the prompts to be processed",
              type: return_error('prompts', types.create.cli_prompts.bind(types.create)),
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
    info('Ω__13', `running command: ${GUY.trm.gold(cli.cmd)} ${GUY.trm.lime(rpr(cli.flags))}`);
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