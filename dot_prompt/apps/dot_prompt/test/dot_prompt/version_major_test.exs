defmodule DotPrompt.VersionMajorTest do
  use ExUnit.Case, async: false

  alias DotPrompt.Parser.{Lexer, Parser}

  describe "@major version field in init block" do
    test "parses @major field in init" do
      content = """
      init do
        @major: 1
        @version: 1
      end init

      Test prompt.
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)
      assert ast.init.def.major == 1
      assert ast.init.def.version == 1
    end

    test "parses @major and @version as major.minor" do
      content = """
      init do
        @major: 2
        @version: 2.3
      end init

      Test prompt.
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)

      assert ast.init.def.major == 2
      # @version stores major.minor format as string
      assert ast.init.def.version == "2.3"
    end

    test "defaults to major: 1 when not specified (backward compat)" do
      content = """
      init do
        @version: 1
      end init

      Test prompt.
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)
      # Should default to major: 1 for backward compatibility
      assert ast.init.def.version == 1
    end

    test "rejects major: 0" do
      content = """
      init do
        @major: 0
        @version: 1
      end init

      Test prompt.
      """

      tokens = Lexer.tokenize(content)
      assert {:error, _} = Parser.parse(tokens)
    end
  end

  describe "version format validation" do
    test "accepts major.minor version" do
      content = """
      init do
        @major: 1
        @version: 1.5
      end init
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)

      assert ast.init.def.version == "1.5"
    end

    test "accepts major.minor.patch version" do
      content = """
      init do
        @major: 1
        @version: 1.5.2
      end init
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)

      assert ast.init.def.version == "1.5.2"
    end

    test "accepts simple integer version" do
      content = """
      init do
        @major: 1
        @version: 3
      end init
      """

      tokens = Lexer.tokenize(content)
      assert {:ok, ast} = Parser.parse(tokens)

      assert ast.init.def.version == 3
    end
  end
end
