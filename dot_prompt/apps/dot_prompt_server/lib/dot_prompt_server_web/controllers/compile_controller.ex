defmodule DotPromptServerWeb.CompileController do
  use DotPromptServerWeb, :controller

  def compile(conn, %{"prompt" => prompt, "params" => params} = body) do
    opts =
      []
      |> maybe_put(:seed, body["seed"])

    case DotPrompt.compile(prompt, params, opts) do
      {:ok, template, vary_selections, _used, _files, cache_hit, warnings} ->
        json(conn, %{
          template: template,
          cache_hit: cache_hit,
          vary_selections: vary_selections,
          warnings: warnings
        })

      {:error, details} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(details)
    end
  rescue
    e ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "compile_error", message: Exception.message(e)})
  end

  defp maybe_put(list, _key, nil), do: list
  defp maybe_put(list, key, value), do: [{key, value} | list]
end
