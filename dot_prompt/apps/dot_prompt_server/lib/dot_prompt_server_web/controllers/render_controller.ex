defmodule DotPromptServerWeb.RenderController do
  use DotPromptServerWeb, :controller

  def render(conn, %{"prompt" => prompt, "params" => params, "runtime" => runtime} = body) do
    opts =
      []
      |> maybe_put(:seed, body["seed"])
      |> maybe_put(:seeds, body["seeds"])

    with {:ok, result, vary_selections, injected_tokens, cache_hit} <-
           DotPrompt.render(prompt, params, runtime, opts) do
      json(conn, %{
        prompt: result,
        cache_hit: cache_hit,
        vary_selections: vary_selections,
        injected_tokens: injected_tokens
      })
    else
      {:error, details} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(details)

      _ ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "internal_error", message: "Unexpected render result"})
    end
  end

  defp maybe_put(list, _key, nil), do: list
  defp maybe_put(list, key, value), do: [{key, value} | list]
end
