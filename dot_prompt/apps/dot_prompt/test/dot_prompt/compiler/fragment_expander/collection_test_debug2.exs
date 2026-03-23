defmodule DotPrompt.Compiler.FragmentExpander.CollectionTestDebug2 do
  use ExUnit.Case, async: true
  alias DotPrompt.Compiler.FragmentExpander.Collection
  alias DotPrompt

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

  describe "debug helpers" do
    test "debug schema loading" do
      IO.puts("\n=== DEBUG: Schema Loading ===")

      # Test loading schema for each file
      files = ["anchoring", "milton_model", "meta_model"]

      Enum.each(files, fn file ->
        prompt_path = "skills/#{file}"
        IO.puts("\n--- Testing #{prompt_path} ---")

        case DotPrompt.schema(prompt_path) do
          {:ok, schema} ->
            IO.inspect(schema, label: "Schema for #{prompt_path}")
            match_val = Map.get(schema, :match)
            IO.puts("Match value: #{inspect(match_val)}")

          {:error, reason} ->
            IO.puts("Error loading schema for #{prompt_path}: #{inspect(reason)}")
        end
      end)
    end

    test "debug prompts_dir" do
      IO.puts("\n=== DEBUG: Prompts Dir ===")
      dir = DotPrompt.prompts_dir()
      IO.puts("prompts_dir(): #{inspect(dir)}")
      IO.puts("File.exists?: #{File.exists?(dir)}")

      skills_dir = Path.join(dir, "skills")
      IO.puts("skills dir: #{inspect(skills_dir)}")
      IO.puts("File.exists?: #{File.exists?(skills_dir)}")

      if File.exists?(skills_dir) do
        files = File.ls!(skills_dir)
        IO.puts("Files in skills dir: #{inspect(files)}")

        prompt_files = Enum.filter(files, &String.ends_with?(&1, ".prompt"))
        IO.puts("Prompt files: #{inspect(prompt_files)}")

        Enum.each(prompt_files, fn file ->
          name_only = String.replace_suffix(file, ".prompt", "")
          prompt_path = "skills/#{name_only}"
          IO.puts("\n--- Checking #{prompt_path} ---")

          case DotPrompt.schema(prompt_path) do
            {:ok, schema} ->
              match_val = Map.get(schema, :match)
              IO.puts("Match: #{inspect(match_val)}")

            {:error, reason} ->
              IO.puts("Error: #{inspect(reason)}")
          end
        end)
      end
    end
  end
end
