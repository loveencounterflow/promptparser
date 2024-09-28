
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
  * **[–]** **potential**: number of generations times maximum number of images per generation (always 4 in
    Dall-E)
  * **[–]** **production**: number of produced images (in each generation or over a number of generations, e.g.
    all generations from a given prompt)
  * **[–]** **productivity**: ratio of potential to production, expressed in per cent
  * **[–]** **prodpoints**: arithmetic product of productivity (given in per cent) and production; this
    measure will be proportionally grow with both the number of generations and the productivity; example:
    * prompt A: journal entry `[4444444]`, ran for 7 generations (a potential of 28 images), actually
      produced 28 images, i.e. a productivity of 100%;
    * prompt B: journal entry `[44344442312]`, ran for 11 generations (a potential of 44 images), produced
      35 images, i.e. a productivity of 80%;
    * both prompts get 28 * 100 = 35 * 80 = 2800 `prodpoints`, so although it's true that prompt A gets (in
      all likelyhood, and could change any time) more images per generation, since prompt B was run more
      often, both get the same `prodpoints` indicating that—presumably for the high quality of the
      images—prompt B made up for somewhat worse productivity with more generations
    * Like the result of any multiplication, `prodpoints` can be visualized as the area of a rectangle whose
      sides are proportional to the two multiplicands—in this case, `productivity` and `production`.
    * Since we should expect that in real life the number of images per prompt is small (< 10), we can
      easily see that for these—many—cases, `prodpoints` will be more or less proportional to `productivity`
      (which can be a number like 50 or 100 even though only a single generation was run with a given
      prompt). Still, it can happen that a prompt with only, say, 3 generations and high productivity gets
      roughly as many `prodpoints` as one with 11 generations but low productivity, indicating that both
      prompts were deemed of being of similar interest
  * **[–]** correlation between prompt length and productivity
  * **[–]** **acceptance** rate: what proportion of images were downloaded, expressed in per cent; two
    flavors:
    * **[–]** ratio of downloaded to potential
    * **[–]** ratio of downloaded to production
* **[–]** in jobdefs, forbid:
  * **[+]** `runner`
  * **[–]** `fallback`
* **[–]** in both the File Registry and the Production Registry, see to it that all prompts that equal the
  empty string are correctly assigned `Utilities::nosuchprompt`; this value is, ATM, the empty string, too,
  but that could change in the future
* **[–]** mention that file IDs are derived from *paths* (partial or absolute paths?), *not* from content
  hashes which would probably be the better and more correct (but also computationally more expensive) way
  to do it
* **[–]** introduce metric for 'strength of failure' (centrality?), i.e. `[s00000]` is 'more
  nope' than `[s0]`; this also holds true for any other productivity
* **[–]** future structure:
  * <ins>no more `File_mirror`, instead iterator over file lines<ins> <del>`File_mirror` becomes a 'DB
    shaper' (for lack of a better word); given a `DBay` instance (as `db`), a table prefix (default `fm_`)
    and source file path (`datasource_path`), it augments the DB by adding tables containing the file
    contents</del>
    * alternative solution: just iterate over file lines and cutting out `File_mirror` altogether
      * **pro**: one less module, (at least) one less table
      * **con**: now the source file paths and the verbatim raw lines live outside the DB; relational access
        is not possible without specialized means such as table-valued functions
  * two iterators over 'records' (i.e. objects with attributes `table` and `fields` ready to be used in
    suitable `insert` statements):
    * table prefix `prd_`: Production Registry (PRD): reads prompts and generation counts from prompts file;
      iterates over records for tables `prd_prompts`, `prd_generations`
      * the production registry does not get to see a `DBay` instance (a DB); instead, it is initialized
        with a list of / an iterator over prompts (we choose to use a list to circumvent concurrent writes
        concerns)
    * table prefix `img_`: Image Registry (IMG): reads EXIF data from image files; iterates over records for
      tables `img_files`, `img_prompts`
  * overarching views and tables (MAIN):
    * table prefix `main_`
* **[–]** add CLI flag to specify globs for images
* **[–]** instead of *production* (**PRD**): <del>*ledger* (**LGR**, **LED**), *journal* (**JNL**,
  **JRN**)</del> <ins>*journal* (**JNL**)</ins>
* **[–]** in the CLI, if DB path and / or prompts journal are not indicated, try to resolve standard names
  and extensions by globbing the current working directory
* **[–]** instead of passing around mutable data structures `known_path_ids`, `known_prompt_ids`, pass
  around methods to check and update these as that entails better guarantees against misuse
* **[–]** invariants for error / fault detection:
  * **[–]** more actual images with a prompt than in journal; this is actually the case for no less than 950
    prompts at this time; consider to treat this by adding theoretical / assumed generations
    * **[–]** implement parsing of expressions like `[A++v 1x3, 10x4]` the lack of which is responsible for
      some of these faults; since we must give generations an ordering, randomize

## Is Done

* **[+]** add `prompt_id` to all records so they have a common name for the central anchoring point of all
  data
* **[+]** make `parse_all_tokens()`, `parse_all_records()` return flat lists
* **[+]** keeep in-memory set of `known_prompt_ids` to avoid unnecessary `insert`s; `known_prompt_ids` could
  be used to block the construction of extraneous records in `$assemble_prompt_records()` and in
  `Image_walker`
* **[+]** modify DB schema: use only one table for `prompt`s and `prompt_id`s, other tables only refer to
  `prompt_id`s


