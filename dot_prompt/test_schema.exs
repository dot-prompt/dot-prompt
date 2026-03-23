# Test script
alias DotPrompt

IO.puts("Testing schema for concept_explanation...")
{:ok, schema} = DotPrompt.schema("concept_explanation")

IO.puts("\nParameters and their lifecycle:")

schema.params
|> Enum.each(fn {name, spec} ->
  IO.puts("  #{name}: type=#{spec.type}, lifecycle=#{spec.lifecycle}")
end)
