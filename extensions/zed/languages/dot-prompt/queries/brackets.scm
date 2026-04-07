; Brackets
["{" "}"] @open @close
["[" "]"] @open @close

; Fragment delimiters
(fragment_static
  "{" @open
  "}" @close)

(fragment_dynamic
  "{{" @open
  "}}" @close)
