/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "dot_prompt",

  extras: $ => [
    /\s/,
    $.comment,
  ],

  conflicts: $ => [
    [$.fragment_static, $.fragment_dynamic],
  ],

  rules: {
    source: $ => repeat($._statement),

    _statement: $ => choice(
      $.init_block,
      $.docs_block,
      $.if_block,
      $.case_block,
      $.vary_block,
      $.fragment_usage,
      $.text,
    ),

    comment: $ => seq("#", /.*/),

    // init do ... end init
    init_block: $ => seq(
      field("keyword", "init"),
      field("do", "do"),
      repeat($._init_content),
      field("end", "end"),
      field("end_keyword", "init"),
    ),

    _init_content: $ => choice(
      $.param_declaration,
      $.fragment_declaration,
      $.select_from,
      $.version_directive,
      $.docs_block,
      $.comment,
    ),

    version_directive: $ => seq(
      "@version",
      ":",
      field("number", /\d+/),
    ),

    // @name: type = default -> doc
    param_declaration: $ => seq(
      field("name", $.param_name),
      ":",
      field("type", $.param_type),
      optional(seq(
        "=",
        field("default", $._param_value),
      )),
      optional(seq(
        "->",
        field("doc", /.*/),
      )),
    ),

    param_name: $ => /@\w+/,

    param_type: $ => choice(
      "str",
      "int",
      "bool",
      $.enum_type,
      $.list_type,
    ),

    enum_type: $ => seq("enum", "[", commaSep($.string_value), "]"),

    list_type: $ => seq("list", "[", commaSep($.string_value), "]"),

    string_value: $ => /[\w]+/,

    _param_value: $ => /[^#\n]+/,

    // docs do ... end docs
    docs_block: $ => seq(
      field("keyword", "docs"),
      field("do", "do"),
      field("content", repeat($._docs_line)),
      field("end", "end"),
      field("end_keyword", "docs"),
    ),

    _docs_line: $ => /.*/,

    // fragment declarations in init block
    fragment_declaration: $ => choice(
      $.fragment_static_decl,
      $.fragment_dynamic_decl,
      $.fragment_options,
    ),

    fragment_static_decl: $ => seq(
      "{",
      field("name", $.identifier),
      "}",
      ":",
      optional(field("mode", choice("static", "dynamic"))),
      optional($.fragment_from),
      optional($.fragment_arrow),
    ),

    fragment_dynamic_decl: $ => seq(
      "{{",
      field("name", $.identifier),
      "}}",
      ":",
      optional(field("mode", choice("static", "dynamic"))),
      optional($.fragment_arrow),
    ),

    fragment_from: $ => seq(
      "from",
      ":",
      field("path", /[\w\/\-]+/),
    ),

    fragment_arrow: $ => seq(
      "->",
      field("description", /.*/),
    ),

    fragment_options: $ => seq(
      field("option", choice("match", "matchRe", "limit", "order", "ascending", "descending", "all")),
      ":",
      field("value", optional(/.*/)),
    ),

    // select from
    select_from: $ => seq(
      "select",
      "from",
      ":",
      field("path", /[\w\/\-]+/),
    ),

    // if @var do ... elif @var do ... else ... end @var
    if_block: $ => seq(
      "if",
      field("condition", $._condition),
      "do",
      repeat($._block_content),
      repeat($.elif_clause),
      optional($.else_clause),
      "end",
      field("end_var", $.param_name),
    ),

    _condition: $ => seq(
      $.param_name,
      optional($._operator),
      optional($._operand),
    ),

    _operator: $ => choice("is", "not", "above", "below", "min", "max", "between", "and"),

    _operand: $ => choice(
      $.param_name,
      $.string_value,
      /\w+/,
    ),

    elif_clause: $ => seq(
      "elif",
      field("condition", $._condition),
      "do",
      repeat($._block_content),
    ),

    else_clause: $ => seq(
      "else",
      repeat($._block_content),
    ),

    // case @var do ... end @var
    case_block: $ => seq(
      "case",
      field("var", $.param_name),
      "do",
      repeat($._case_content),
      "end",
      field("end_var", $.param_name),
    ),

    _case_content: $ => choice(
      $.case_label,
      $._block_content,
    ),

    case_label: $ => seq(
      field("label", $.identifier),
      ":",
      optional(field("content", /.*/)),
    ),

    // vary @var do ... end @var
    vary_block: $ => seq(
      "vary",
      field("var", $.param_name),
      "do",
      repeat($._case_content),
      "end",
      field("end_var", $.param_name),
    ),

    // Fragment usage in body: {name} or {{name}}
    fragment_usage: $ => choice(
      $.fragment_static,
      $.fragment_dynamic,
    ),

    fragment_static: $ => seq(
      "{",
      field("name", $.identifier),
      "}",
    ),

    fragment_dynamic: $ => seq(
      "{{",
      field("name", $.identifier),
      "}}",
    ),

    // Plain text (everything else)
    text: $ => /[^{}\n#@\w][^\n]*/,

    identifier: $ => /\w+/,
  },
});

function commaSep(rule) {
  return optional(seq(rule, repeat(seq(",", rule))));
}
