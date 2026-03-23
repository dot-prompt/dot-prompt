defmodule DebugSchema do
  use ExUnit.Case, async: true
  alias DotPrompt

  setup_all do
    :ok
  end

  test "debug schema for anchoring.prompt" do
    IO.puts("\n=== Debugging schema for skills/anchoring ===")

    case DotPrompt.schema("skills/anchoring") do
      {:ok, schema} ->
        IO.inspect(schema, label: "Full schema")
        IO.puts("Match field: #{inspect(Map.get(schema, :match))}")
        IO.puts("Mode field: #{inspect(Map.get(schema, :mode))}")
        IO.puts("Description field: #{inspect(Map.get(schema, :description))}")

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
    end
  end
end
