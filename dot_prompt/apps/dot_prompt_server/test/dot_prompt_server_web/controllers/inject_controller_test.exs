defmodule DotPromptServerWeb.InjectControllerTest do
  use DotPromptServerWeb.ConnCase, async: true

  test "POST /api/inject", %{conn: conn} do
    template = "Hello @user!"

    body = %{
      "template" => template,
      "runtime" => %{"user" => "Alice"}
    }

    conn = post(conn, ~p"/api/inject", body)
    assert json_response(conn, 200)["prompt"] == "Hello Alice!"
  end
end
