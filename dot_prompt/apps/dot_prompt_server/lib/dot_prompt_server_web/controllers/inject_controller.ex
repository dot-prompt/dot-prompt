defmodule DotPromptServerWeb.InjectController do
  use DotPromptServerWeb, :controller

  def inject(conn, %{"template" => template, "runtime" => runtime}) do
    result = DotPrompt.inject(template, runtime)
    injected_tokens = count_tokens(result)

    json(conn, %{
      prompt: result,
      injected_tokens: injected_tokens
    })
  rescue
    e ->
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "inject_error", message: Exception.message(e)})
  end

  defp count_tokens(text) when is_binary(text) do
    words = String.split(String.trim(text))
    div(length(words) * 4, 3)
  end
end
