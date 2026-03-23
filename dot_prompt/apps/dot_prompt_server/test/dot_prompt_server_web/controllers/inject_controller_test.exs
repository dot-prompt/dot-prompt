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

  describe "error handling" do
    test "returns error when template key is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/inject", %{"runtime" => %{}})
      # Controller requires template key - pattern match will fail, returns 500
      response = json_response(conn, 500)
      assert response["error"] || Map.has_key?(response, "error")
    end

    test "returns error when runtime key is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/inject", %{"template" => "Hello @user!"})
      # Controller requires runtime key - pattern match will fail, returns 500
      response = json_response(conn, 500)
      assert response["error"] || Map.has_key?(response, "error")
    end

    test "returns 200 for template with undefined variables (injects as-is)", %{conn: conn} do
      # Injector doesn't validate undefined variables - it just leaves them as-is
      conn = post(conn, ~p"/api/inject", %{"template" => "Hello @undefined!", "runtime" => %{}})
      response = json_response(conn, 200)
      assert response["prompt"] == "Hello @undefined!"
    end

    test "returns 200 for malformed template syntax (injects as-is)", %{conn: conn} do
      # Injector doesn't validate template syntax - it just does string substitution
      conn = post(conn, ~p"/api/inject", %{"template" => "invalid {{ unclosed", "runtime" => %{}})
      response = json_response(conn, 200)
      assert response["prompt"] == "invalid {{ unclosed"
    end
  end
end
