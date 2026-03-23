defmodule DotPromptServerWeb.RenderControllerTest do
  use DotPromptServerWeb.ConnCase, async: true

  setup do
    DotPrompt.invalidate_all_cache()
    :ok
  end

  test "POST /api/render", %{conn: conn} do
    content = """
    init do
      params:
        @user_level: enum[beginner, advanced]
        @user_input: str
    end init
    You are a tutor teaching @user_level students.
    Your input was: @user_input
    """

    body = %{
      "prompt" => content,
      "params" => %{"user_level" => "beginner"},
      "runtime" => %{"user_input" => "Hello"}
    }

    conn = post(conn, ~p"/api/render", body)
    response = json_response(conn, 200)
    assert response["prompt"] =~ "You are a tutor teaching beginner students"
    assert response["prompt"] =~ "Your input was: Hello"
    assert response["cache_hit"] == false
  end

  test "POST /api/render with seed", %{conn: conn} do
    content = """
    init do
      params:
        @style: enum[a, b]
    end init
    vary @style do
    a: Style A
    b: Style B
    end @style
    """

    body = %{
      "prompt" => content,
      "params" => %{},
      "runtime" => %{},
      "seed" => 42
    }

    conn = post(conn, ~p"/api/render", body)
    r1 = json_response(conn, 200)["prompt"]

    conn = post(conn, ~p"/api/render", body)
    r2 = json_response(conn, 200)["prompt"]

    assert r1 == r2
  end
end
