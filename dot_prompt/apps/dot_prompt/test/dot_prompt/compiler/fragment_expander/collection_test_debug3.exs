defmodule DotPrompt.Compiler.FragmentExpander.CollectionTestDebug3 do
  use ExUnit.Case, async: true
  alias DotPrompt
  alias DotPrompt.Parser.Validator

  @prompts_dir Path.expand("test/fixtures/prompts", File.cwd!())

  setup_all do
    # Ensure fixtures exist
    File.mkdir_p!(Path.join(@prompts_dir, "skills"))

    File.write!(Path.join(@prompts_dir, "skills/_index.prompt"), """
    init do
      @version: 1
      def:
        mode: collection
    end init
    """)

    File.write!(Path.join(@prompts_dir, "skills/anchoring.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Anchoring
    end init
    Anchoring Content
    """)

    File.write!(Path.join(@prompts_dir, "skills/milton_model.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Milton Model
    end init
    Milton Model Content
    """)

    File.write!(Path.join(@prompts_dir, "skills/meta_model.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Meta Model
    end init
    Meta Model Content
    """)

    on_exit(fn ->
      :ok
    end)

    {:ok, %{dir: @prompts_dir}}
  end

  describe "debug schema parsing" do
    test "debug def block parsing" do
      IO.puts("\n=== DEBUG: Def Block Parsing ===")

      files = ["anchoring", "milton_model", "meta_model"]

      Enum.each(files, fn file ->
        prompt_path = "skills/#{file}"
        IO.puts("\n--- Testing #{prompt_path} ---")
        # Use the public schema function which internally calls load_prompt_file_with_meta
        case DotPrompt.schema(prompt_path) do
          {:ok, schema} ->
            # The schema doesn't contain the raw AST, so we need to get it another way
            # Let's just load the content directly for debugging
            {:ok, content, _mtime, _path} = DotPrompt.__load_prompt_file_with_meta__(prompt_path)
            IO.puts("Content: #{inspect(content)}")
            tokens = DotPrompt.Parser.Lexer.tokenize(content)
            IO.puts("Tokens: #{inspect(tokens)}")

            case DotPrompt.Parser.Parser.parse(tokens) do
              {:ok, ast} ->
                IO.puts("AST: #{inspect(ast)}")

                def_block = Validator.parse_def_block(ast.init)
                IO.puts("Def block: #{inspect(def_block)}")

                # Extract match from def_block
                match_val = Map.get(def_block, :match)
                IO.puts("Match from def_block: #{inspect(match_val)}")

              {:error, reason} ->
                IO.puts("Parse error: #{inspect(reason)}")
            end

          {:error, reason} ->
            IO.puts("Schema error: #{inspect(reason)}")
        end
      end)
    end
  end
end
