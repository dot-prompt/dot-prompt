; Keywords
[
  "init"
  "do"
  "end"
  "if"
  "elif"
  "else"
  "case"
  "vary"
  "def"
  "params"
  "fragments"
  "docs"
  "select"
  "from"
  "match"
  "matchRe"
  "limit"
  "order"
  "ascending"
  "descending"
  "all"
] @keyword

; Comments
(comment) @comment

; Parameters
(param_name) @variable

; Types
[
  "str"
  "int"
  "bool"
  "enum"
  "list"
] @type.builtin

; Fragment identifiers
(fragment_static
  name: (identifier) @function)

(fragment_dynamic
  name: (identifier) @function)

(fragment_static_decl
  name: (identifier) @function)

(fragment_dynamic_decl
  name: (identifier) @function)

; Punctuation
["{" "}" "{{" "}}"] @punctuation.bracket
["[" "]"] @punctuation.bracket
[":" "=" "->"] @operator

; Strings and values
(string_value) @string
(param_declaration
  default: _ @string)

; Case labels
(case_label
  label: (identifier) @label)

; Version directive
(version_directive) @constant
