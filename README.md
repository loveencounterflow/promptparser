
# Prompt Parser

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Prompt Parser](#prompt-parser)
  - [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Prompt Parser


## To Do

* **[–]** unify `prompt_file_path` and `datasource_path`, which mean the same thing
* **[–]** implement:
  * **[–]** make prompt file path optional
  * **[–]** make DB file path optional(?)
  * **[–]** allow to parse single prompts (or multiple lines, too?) and return the results w/out storing
    them in DB
  * **[–]** allow to either store results or return them (or both?); when no DB file path is given, only
    returning results is possible
* **[–]** implement test
* **[–]** find solution for line number issue
  * **[–]** look into lexer for solution
  * **[–]** otherwise, send line numbering datoms
* **[–]** add prompt with opening but missing closing bracket, test whether state is properly reset when
  prompt ends


