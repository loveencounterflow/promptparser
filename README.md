
# Prompt Parser

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Prompt Parser](#prompt-parser)
  - [Parsing Individual Prompts](#parsing-individual-prompts)
  - [Inserting Individual Prompts](#inserting-individual-prompts)
  - [To Do](#to-do)

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
* **[–]** implement test
* **[–]** find solution for line number issue
  * **[–]** look into lexer for solution
  * **[–]** otherwise, send line numbering datoms
* **[–]** add prompt with opening but missing closing bracket, test whether state is properly reset when
* **[–]** add `prompt_id` to all records so they have a common name for the central anchoring point of all
  data
* **[–]** make `parse_all_tokens()`, `parse_all_records()` return flat lists


