defmodule DotPrompt.Compiler.FragmentExpander.Static do
  @moduledoc """
  Expands static fragments by compiling them.
  """

  @spec expand(String.t(), map()) :: {:ok, iodata(), map()} | {:error, String.t()}
  def expand(fragment_path, params) do
    path = String.trim(fragment_path, "{") |> String.trim("}")

    try do
      case DotPrompt.compile_to_iodata(path, params) do
        {:ok, content, _vary, _used, files, _hit, _warnings} -> {:ok, content, files}
        {:error, reason} -> {:error, "fragment_compile_error: #{path} - #{inspect(reason)}"}
      end
    rescue
      _ -> {:error, "fragment_not_found: #{path}"}
    end
  end
end
