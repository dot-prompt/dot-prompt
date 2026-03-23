defmodule DotPrompt.Compiler.FragmentExpander.Dynamic do
  @moduledoc """
  Expands dynamic fragments {{}}. These are fetched fresh and never cached.
  """

  @spec expand(String.t(), map()) :: {:ok, String.t(), map()} | {:error, String.t()}
  def expand(fragment_path, _params) do
    path = String.trim(fragment_path, "{") |> String.trim("}")

    case fetch_dynamic_content(path) do
      {:ok, content, meta} -> {:ok, content, meta}
      {:ok, content} -> {:ok, content, %{}}
      {:error, reason} -> {:error, "dynamic_fragment_error: #{reason}"}
    end
  end

  defp fetch_dynamic_content(path) do
    dir = DotPrompt.prompts_dir()

    if String.starts_with?(path, "http://") or String.starts_with?(path, "https://") do
      case fetch_from_url(path) do
        {:ok, content} -> {:ok, content, %{}}
        err -> err
      end
    else
      full_path = Path.join(dir, path)

      case fetch_from_file(full_path) do
        {:ok, content} ->
          {:ok, content, get_file_meta(full_path)}

        {:error, _} ->
          # Try with .prompt extension
          full_path_ext = full_path <> ".prompt"

          case fetch_from_file(full_path_ext) do
            {:ok, content} -> {:ok, content, get_file_meta(full_path_ext)}
            err -> err
          end
      end
    end
  end

  defp get_file_meta(path) do
    case File.stat(path) do
      {:ok, %{mtime: t}} -> %{path => t}
      _ -> %{}
    end
  end

  defp fetch_from_url(url) do
    case :httpc.request(:get, {String.to_charlist(url), []}, [], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, to_string(body)}

      {:ok, {{_, status, _}, _headers, _body}} ->
        {:error, "http #{status}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp fetch_from_file(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, _reason} -> {:error, "file not found: #{path}"}
    end
  end
end
