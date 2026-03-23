defmodule DotPromptServerWeb.CompileControllerTest do
  use DotPromptServerWeb.ConnCase, async: true

  test "POST /api/compile", %{conn: conn} do
    content = """
    init do
      params:
        @user_level: enum[beginner, advanced]
    end init
    You are a tutor teaching @user_level students.
    """

    body = %{
      "prompt" => content,
      "params" => %{"user_level" => "beginner"}
    }

    conn = post(conn, ~p"/api/compile", body)
    assert json_response(conn, 200)["template"] =~ "You are a tutor teaching beginner students"
  end
end
