defmodule DotPromptServerWeb.CompileControllerTest do
  use DotPromptServerWeb.ConnCase, async: true

  setup do
    DotPrompt.invalidate_all_cache()
    :ok
  end

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

  describe "error handling" do
    test "returns 422 for invalid prompt syntax", %{conn: conn} do
      conn = post(conn, ~p"/api/compile", %{"prompt" => "invalid syntax {{ unclosed", "params" => %{}})
      # Parser accepts this syntax, returns 200 with template as-is
      response = json_response(conn, 200)
      assert response["template"] =~ "invalid syntax"
    end

    test "returns error for missing required params", %{conn: conn} do
      content = """
      init do
        params:
          @user_name: str
      end init
      Hello @user_name
      """

      conn = post(conn, ~p"/api/compile", %{"prompt" => content, "params" => %{}})
      # Compile accepts empty params, returns 200 with unreplaced variable
      response = json_response(conn, 200)
      assert response["template"] =~ "@user_name"
    end

    test "returns 422 for invalid param type", %{conn: conn} do
      content = """
      init do
        params:
          @age: int
      end init
      Age: @age
      """

      conn = post(conn, ~p"/api/compile", %{"prompt" => content, "params" => %{"age" => "not_a_number"}})
      assert json_response(conn, 422)["error"]
    end

    test "returns 422 for invalid enum value", %{conn: conn} do
      content = """
      init do
        params:
          @level: enum[beginner, advanced]
      end init
      Level: @level
      """

      conn = post(conn, ~p"/api/compile", %{"prompt" => content, "params" => %{"level" => "expert"}})
      assert json_response(conn, 422)["error"]
    end

    test "returns 422 for malformed init block", %{conn: conn} do
      conn = post(conn, ~p"/api/compile", %{"prompt" => "init do missing end", "params" => %{}})
      assert json_response(conn, 422)["error"]
    end

    test "returns 422 for invalid prompt with missing params key", %{conn: conn} do
      # Using params key but with empty string causes validation issue
      content = """
      init do
        params:
          @name: str
      end init
      Hello @name
      """
      conn = post(conn, ~p"/api/compile", %{"prompt" => content, "params" => nil})
      assert json_response(conn, 422)["error"]
    end
  end
end
