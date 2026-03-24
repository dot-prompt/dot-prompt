defmodule DotPrompt.Parser.Lexer do
  @moduledoc """
  Tokenizes .prompt files line by line.
  """

  defmodule Token do
    @moduledoc """
    Represents a single token from the lexer.
    """
    defstruct [:type, :value, :line, :meta, :indent]
  end

  def tokenize(content) do
    content
    |> String.split(["\r\n", "\n"])
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} -> tokenize_line(line, line_no) end)
  end

  defp tokenize_line(line, line_no) do
    # Handle documentation split first to ensure 'text' is what we analyze for other rules
    {line, doc_token} =
      if String.contains?(line, "->") do
        [text, doc] = String.split(line, "->", parts: 2)
        {text, [%Token{type: :doc, value: String.trim(doc), line: line_no}]}
      else
        {line, []}
      end

    trimmed = String.trim_leading(line)
    indent = String.length(line) - String.length(trimmed)
    trimmed = String.trim_trailing(trimmed)

    tokens =
      cond do
        trimmed == "" ->
          if doc_token == [], do: [%Token{type: :text, value: "", line: line_no}], else: []

        # Comments
        String.starts_with?(trimmed, "#") ->
          []

        # Reserved Blocks
        String.starts_with?(trimmed, "init do") ->
          [%Token{type: :block_start, value: "init", line: line_no}]

        String.starts_with?(trimmed, "docs do") ->
          [%Token{type: :block_start, value: "docs", line: line_no}]

        String.starts_with?(trimmed, "response do") ->
          [%Token{type: :block_start, value: "response", line: line_no}]

        # End Block
        Regex.match?(~r/^end\s+(@?[\w\d_]+)$/, trimmed) ->
          [_, value] = Regex.run(~r/^end\s+(@?[\w\d_]+)$/, trimmed)
          [%Token{type: :block_end, value: String.trim(value), line: line_no}]

        trimmed == "end" ->
          [%Token{type: :block_end, value: nil, line: line_no}]

        Regex.match?(~r/^end\s+init$/, trimmed) ->
          [%Token{type: :block_end, value: "init", line: line_no}]

        Regex.match?(~r/^end\s+docs$/, trimmed) ->
          [%Token{type: :block_end, value: "docs", line: line_no}]

        Regex.match?(~r/^end\s+response$/, trimmed) ->
          [%Token{type: :block_end, value: "response", line: line_no}]

        # If / Elif / Else
        Regex.match?(~r/^(if|elif)\s+(@\w+).*?\sdo$/, trimmed) ->
          [_, kind, var, cond_str] = Regex.run(~r/^(if|elif)\s+(@\w+)\s*(.*?)\sdo$/, trimmed)

          [
            %Token{
              type: :condition,
              value: %{kind: kind, var: var, cond: String.trim(cond_str)},
              line: line_no
            }
          ]

        trimmed == "else" ->
          [%Token{type: :else, value: "else", line: line_no}]

        # Case
        Regex.match?(~r/^case @\w+ do/, trimmed) ->
          [_, var] = Regex.run(~r/^case (@\w+) do/, trimmed)
          [%Token{type: :case_start, value: var, line: line_no}]

        # Vary
        Regex.match?(~r/^vary\s+(@\w+)\s+do/, trimmed) ->
          [_, var] = Regex.run(~r/^vary\s+(@\w+) do/, trimmed)
          [%Token{type: :vary_start, value: var, line: line_no}]

        trimmed == "vary do" ->
          [%Token{type: :vary_start, value: nil, line: line_no}]

        # Fragments in body (Exclude reserved {response_contract})
        Regex.match?(~r/^\{[\w\-\.\/]+\}$/, trimmed) and trimmed != "{response_contract}" ->
          [%Token{type: :fragment_static, value: trimmed, line: line_no}]

        Regex.match?(~r/^\{\{[\w\-\.\/]+\}\}$/, trimmed) ->
          [%Token{type: :fragment_dynamic, value: trimmed, line: line_no}]

        # Parameter definitions (higher precedence than init_item)
        Regex.match?(~r/^@[\w\d_]+:\s*(.*)$/, trimmed) ->
          [_, name, type_info] = Regex.run(~r/^(@[\w\d_]+):\s*(.*)$/, trimmed)

          if name == "@major" do
            [
              %Token{
                type: :init_item,
                value: "major",
                meta: String.trim(type_info),
                line: line_no
              }
            ]
          else
            [%Token{type: :param_def, value: name, meta: String.trim(type_info), line: line_no}]
          end

        # Fragments in init
        Regex.match?(~r/^\{{1,2}[\w\-\.\/]+\}{1,2}: ?/, trimmed) ->
          [_, name, type_info] = Regex.run(~r/^(\{{1,2}[\w\-\.\/]+\}{1,2}):\s*(.*)$/, trimmed)
          [%Token{type: :fragment_def, value: name, meta: String.trim(type_info), line: line_no}]

        # Labels like def:, params:
        Regex.match?(~r/^(def|params|fragments):\s*(.*)$/, trimmed) ->
          [_, key, val] = Regex.run(~r/^(def|params|fragments):\s*(.*)$/, trimmed)

          if String.trim(val) == "" do
            [%Token{type: :case_label, value: key, line: line_no}]
          else
            [%Token{type: :init_item, value: key, meta: String.trim(val), line: line_no}]
          end

        # Generic Metadata or Case branches (e.g., mode: tutor, analogy: #Track, 1: Step, step-1: ...)
        Regex.match?(~r/^([a-zA-Z0-9_\-\.]+):\s*(.*)$/, trimmed) ->
          [_, key, meta] = Regex.run(~r/^([a-zA-Z0-9_\-\.]+):\s*(.*)$/, trimmed)
          [%Token{type: :init_item, value: key, meta: String.trim(meta), line: line_no}]

        # Default: Text
        true ->
          [%Token{type: :text, value: line, line: line_no, indent: indent}]
      end

    tokens = Enum.map(tokens, &%{&1 | indent: indent})
    tokens ++ Enum.map(doc_token, &%{&1 | indent: indent})
  end
end
