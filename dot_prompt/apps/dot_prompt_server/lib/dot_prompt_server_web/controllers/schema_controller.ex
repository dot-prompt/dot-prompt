defmodule DotPromptServerWeb.SchemaController do
  use DotPromptServerWeb, :controller

  def show(conn, %{"prompt" => prompt}) do
    case DotPrompt.schema(prompt) do
      {:ok, schema} ->
        json(conn, schema)

      {:error, details} ->
        conn
        |> put_status(:not_found)
        |> json(details)
    end
  rescue
    e ->
      conn
      |> put_status(:not_found)
      |> json(%{error: "not_found", message: Exception.message(e)})
  end
end
