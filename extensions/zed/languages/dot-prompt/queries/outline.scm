; Outline structure
(param_declaration
  name: (param_name) @name) @item

(fragment_static_decl
  name: (identifier) @name) @item

(fragment_dynamic_decl
  name: (identifier) @name) @item

(if_block
  condition: (_) @name) @item

(case_block
  var: (param_name) @name) @item

(vary_block
  var: (param_name) @name) @item
