
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
sqlite3pspg /dev/shm/promptparser.sqlite "select distinct
    prompt_id,
    sum( count ) over ( partition by prompt_id ) as sum,
    prompt
  from generations as g
left join prompts as p
  on ( g.prompt_id = p.id )
  order by sum desc;"
```

```bash
sqlite3pspg /dev/shm/promptparser.sqlite "
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

* **[–]** unify `prompt_file_path` and `datasource_path`, which mean the same thing
* **[–]** implement:
  * **[–]** make prompt file path optional
  * **[–]** make DB file path optional(?)
    * **[–]** if DB path is not given, should a temporary location be chosen? That would mean that all
      operations can be executed in both cases, the only difference being that the temporary location will
      be deleted when the process terminates
  * **[–]** allow to parse single prompts (or multiple lines, too?) and return the results w/out storing
    them in DB
  * **[–]** allow to either store results or return them (or both?); when no DB file path is given, only
    returning results is possible
* **[–]** find solution for line number issue
  * **[–]** look into lexer for solution
  * **[–]** otherwise, send line numbering datoms
* **[–]** add prompt with opening but missing closing bracket, test whether state is properly reset
* **[–]** statistics:
  * **[–]** raw words
  * **[–]** raw words normalized
  * **[–]** raw words normalized and translated
  * **[–]** 'generativity', 'density'
  * **[–]** 'acceptance' or 'appeal' i.e. absolute generativity in relation to how many pictures downloaded
  * **[–]** 'generational stability': measure for how much generation sizes vary (predictability)
* **[–]** add tests that the following are not recorded in DB:
  * **[–]** empty lines
  * **[–]** lines that do not contain a prompt
* **[–]** implement searching for similar queries
  * **[–]** https://unum-cloud.github.io/usearch/sqlite/
  * **[–]** https://github.com/schiffma/distlib
  * **[–]** https://sqlite.org/spellfix1.html
* **[–]** consider to use `git blame $filename` to detect changed lines, updated linenrs when doing
  `refresh`
  * **[–]** this may be simplified by only supporting refreshing everything from the first changed line
    onwards
* **[–]** commands:
  * **[–]** sooner:
    * **[–]** `build` DB with all prompts:
      * **[+]** (optional) up to `--max-count`
      * **[+]** (optional) `--sample` x out of y
      * **[+]** (optional) `--match` regex<ins>; this matches only the prompt, not the entire line; a `/^.../`
        RegEx start anchor will match the position before the first non-blank character of the prompt text
        (to the exclusion of the generational counts in square brackets)</ins>
        * **[+]** <del>consider to rename to `--match-line` and introduce additional `--match-prompt`</del>
      * **[–]** (optional) `--dont-match` regex
      * **[+]** (optional) `--pre-match` regex; this defaults to `/^\[.*?\].*?\S+/`, that is, prompts that
        start with a possibly empty pair of `[]` square brackets and a non-blank tail; this is intended to
        keep all commentaries and npn-rated prompts out of the DB.
      * **[+]** (optional) <del>`--overwrite`</del> <ins>`--trash-db`</ins>
      * **[+]** (optional) `--db` path
      * **[+]** (positional) prompts / datasource path
    * **[–]** `rebuild` DB; same as `build` but with `--overwrite` implied
  * **[–]** later:
    * **[–]** `refresh` DB with changed, added, deleted prompts
    * **[–]** `delete` DB
* **[–]** implement a way to add (some) RegEx flags to `--pre-match`, `--match`, `--dont-match`; maybe
  syntax could be changed to (optionally?) use `/.../` slashes with trailing flags, as in `--match
  '/[a-z]/i'`
* **[–]** use [`slevithan/regex`](https://github.com/slevithan/regex) to compile RegEx flags
* **[–]** Metrics:
  * **[–]** fulfillment rate: ratio of possible (4 per generation) to actually produced images
  * **[–]** correlation between prompt length and fulfillment rate
  * **[–]** acceptance rate: what proportion of produced images were downloaded
  * **[–]** success rate: what proportion of possible images (generation count times four) were downloaded
* **[–]** in jobdefs, forbid:
  * **[+]** `runner`
  * **[–]** `fallback`
* **[–]** in both the File Registry and the Production Registry, see to it that all prompts that equal the empty
  string are correctly assigned `Utilities::nosuchprompt`; this value is, ATM, the empty string, too, but
  that could change in the future
* **[–]** mention that file IDs are derived from *paths* (partial or absolute paths?), *not* from content
  hashes which would probably be the better and more correct (but also computationally more expensive) way
  to do it
* **[–]** introduce metric for 'strength of failure' (centrality?), i.e. `[s00000]` is 'more
  nope' than `[s0]`; this also holds true for any other fulfillment rate
* **[–]** future structure:
  * DB built from base `File_mirror`, table prefix `fm_`
  * two iterators over 'records' (i.e. objects with attributes `table` and `fields` ready to be used in
    suitable `insert` statements):
    * table prefix `prd_`: Production Registry (PRD): reads prompts and generation counts from prompts file;
      iterates over records for tables `prd_prompts`, `prd_generations`
    * table prefix `img_`: Image Registry (IMG): reads EXIF data from image files; iterates over records for
      tables `img_files`, `img_prompts`
  * overarching views and tables (MAIN):
    * table prefix `main_`
* **[–]** add CLI flag to specify globs for images

## Is Done

* **[+]** add `prompt_id` to all records so they have a common name for the central anchoring point of all
  data
* **[+]** make `parse_all_tokens()`, `parse_all_records()` return flat lists