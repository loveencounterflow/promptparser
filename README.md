
# Prompt Parser

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Prompt Parser](#prompt-parser)
  - [Parsing Individual Prompts](#parsing-individual-prompts)
  - [Inserting Individual Prompts](#inserting-individual-prompts)
  - [Queries](#queries)
  - [To Do](#to-do)
  - [Is Done](#is-done)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Prompt Parser

## Parsing Individual Prompts

* **`parse_first_tokens: ( source ) ->`**
* **`parse_all_tokens: ( source ) ->`**
* **`parse_first_records: ( source ) ->`**
* **`parse_all_records: ( source ) ->`**

## Inserting Individual Prompts

* **`insert: ( insertion_record ) ->`**: insert one or more records
  * **`insertion_record`**: either
    * an object with fields:
      * `table`: name of the targetted DB table
      * `fields`: object with name / value pairs for each relevant field in the named table
      * and possibly other properties
    * or a list of insertion records

## Queries


```bash
sqlite3pspg /dev/shm/promptparser-production-registry.sqlite "select distinct
    prompt_id,
    sum( count ) over ( partition by prompt_id ) as sum,
    prompt
  from generations as g
left join prompts as p
  on ( g.prompt_id = p.id )
  order by sum desc;"
```

```bash
sqlite3pspg /dev/shm/promptparser-production-registry.sqlite "
select distinct
    c.prompt_id                   as prompt_id,
    c.g                           as g,
    c.s                           as s,
    cast( ( ( cast( c.s as real ) / c.g / 4 ) * 100 + 0.5 ) as integer )   as avg,
    prompt                        as prompt
  from generations as g
left join counts as c
  on ( g.prompt_id = c.prompt_id )
left join prompts as p
  on ( g.prompt_id = p.id )
  order by avg desc, g desc, s desc;"
```


## To Do

* **[–]** `TD/Ω___1` unify `prompt_file_path` and `datasource_path`, which mean the same thing
* **[–]** `TD/Ω___2` implement:
  * **[–]** `TD/Ω___3` make prompt file path optional
  * **[–]** `TD/Ω___4` make DB file path optional(?)
    * **[–]** `TD/Ω___5` if DB path is not given, should a temporary location be chosen? That would mean that all
      operations can be executed in both cases, the only difference being that the temporary location will
      be deleted when the process terminates
  * **[–]** `TD/Ω___6` allow to parse single prompts (or multiple lines, too?) and return the results w/out storing
    them in DB
  * **[–]** `TD/Ω___7` allow to either store results or return them (or both?); when no DB file path is given, only
    returning results is possible
* **[–]** `TD/Ω___8` find solution for line number issue
  * **[–]** `TD/Ω___9` look into lexer for solution
  * **[–]** `TD/Ω__10` otherwise, send line numbering datoms
* **[–]** `TD/Ω__11` add prompt with opening but missing closing bracket, test whether state is properly reset
* **[–]** `TD/Ω__12` statistics:
  * **[–]** `TD/Ω__13` raw words
  * **[–]** `TD/Ω__14` raw words normalized
  * **[–]** `TD/Ω__15` raw words normalized and translated
  * **[–]** `TD/Ω__16` 'generativity', 'density'
  * **[–]** `TD/Ω__17` 'acceptance' or 'appeal' i.e. absolute generativity in relation to how many pictures downloaded
  * **[–]** `TD/Ω__18` 'generational stability': measure for how much generation sizes vary (predictability)
* **[–]** `TD/Ω__19` add tests that the following are not recorded in DB:
  * **[–]** `TD/Ω__20` empty lines
  * **[–]** `TD/Ω__21` lines that do not contain a prompt
* **[–]** `TD/Ω__22` implement searching for similar queries
  * **[–]** `TD/Ω__23` https://unum-cloud.github.io/usearch/sqlite/
  * **[–]** `TD/Ω__24` https://github.com/schiffma/distlib
  * **[–]** `TD/Ω__25` https://sqlite.org/spellfix1.html
* **[–]** `TD/Ω__26` consider to use `git blame $filename` to detect changed lines, updated linenrs when doing
  `refresh`
  * **[–]** `TD/Ω__27` this may be simplified by only supporting refreshing everything from the first changed line
    onwards
* **[–]** `TD/Ω__28` commands:
  * **[–]** `TD/Ω__29` sooner:
    * **[–]** `TD/Ω__30` `build` DB with all prompts:
      * **[+]** `TD/Ω__31` (optional) up to `--max-count`
      * **[+]** `TD/Ω__32` (optional) `--sample` x out of y
      * **[+]** `TD/Ω__33` (optional) `--match` regex<ins>; this matches only the prompt, not the entire line; a `/^.../`
        RegEx start anchor will match the position before the first non-blank character of the prompt text
        (to the exclusion of the generational counts in square brackets)</ins>
        * **[+]** `TD/Ω__34` <del>consider to rename to `--match-line` and introduce additional `--match-prompt`</del>
      * **[–]** `TD/Ω__35` (optional) `--dont-match` regex
      * **[+]** `TD/Ω__36` (optional) `--pre-match` regex; this defaults to `/^\[.*?\].*?\S+/`, that is, prompts that
        start with a possibly empty pair of `[]` square brackets and a non-blank tail; this is intended to
        keep all commentaries and npn-rated prompts out of the DB.
      * **[+]** `TD/Ω__37` (optional) <del>`--overwrite`</del> <ins>`--trash-db`</ins>
      * **[+]** `TD/Ω__38` (optional) `--db` path
      * **[+]** `TD/Ω__39` (positional) prompts / datasource path
    * **[–]** `TD/Ω__40` `rebuild` DB; same as `build` but with `--overwrite` implied
  * **[–]** `TD/Ω__41` later:
    * **[–]** `TD/Ω__42` `refresh` DB with changed, added, deleted prompts
    * **[–]** `TD/Ω__43` `delete` DB
* **[–]** `TD/Ω__44` implement a way to add (some) RegEx flags to `--pre-match`, `--match`, `--dont-match`; maybe
  syntax could be changed to (optionally?) use `/.../` slashes with trailing flags, as in `--match
  '/[a-z]/i'`
* **[–]** `TD/Ω__45` use [`slevithan/regex`](https://github.com/slevithan/regex) to compile RegEx flags
* **[–]** `TD/Ω__46` Metrics:
  * **[–]** `TD/Ω__47` fulfillment rate: ratio of possible (4 per generation) to actually produced images
  * **[–]** `TD/Ω__48` correlation between prompt length and fulfillment rate
  * **[–]** `TD/Ω__49` acceptance rate: what proportion of produced images were downloaded
  * **[–]** `TD/Ω__50` success rate: what proportion of possible images (generation count times four) were downloaded
* **[–]** `TD/Ω__51` in jobdefs, forbid:
  * **[+]** `TD/Ω__52` `runner`
  * **[–]** `TD/Ω__53` `fallback`
* **[–]** `TD/Ω__54` in both the File Registry and the Production Registry, see to it that all prompts that equal the empty
  string are correctly assigned `Utilities::nosuchprompt`; this value is, ATM, the empty string, too, but
  that could change in the future
* **[–]** `TD/Ω__55` mention that file IDs are derived from *paths* (partial or absolute paths?), *not* from content
  hashes which would probably be the better and more correct (but also computationally more expensive) way
  to do it
* **[–]** `TD/Ω__56` future structure:
  * Production Registry (PRD)
    * module now called `main` -> `production-registry`
    * DB now called `prompts-and-generations.sqlite` -> `promptparser-production-registry.sqlite`
  * Image Registry (IMG)
    * module now called `file-cache-builder` -> `image-registry`
    * DB now called `files-and-prompts.sqlite` -> `promptparser-image-registry.sqlite`
  * one DB to bind them all:
    * module called `main`
    * DB called `promptparser-main.sqlite`
    * has `promptparser-production-registry.sqlite` attached as `prd`
    * has `promptparser-image-registry.sqlite` attached as `img`

## Is Done

* **[+]** `TD/Ω__57` add `prompt_id` to all records so they have a common name for the central anchoring point of all
  data
* **[+]** `TD/Ω__58` make `parse_all_tokens()`, `parse_all_records()` return flat lists