defmodule DotPrompt.Compiler.FragmentExpander.CollectionTestDebug do
  use ExUnit.Case, async: true
  alias DotPrompt.Compiler.FragmentExpander.Collection

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

  describe "expand/6" do
    test "debug matches specific fragments with match: @var" do
      IO.puts("\n=== DEBUG TEST: matches specific fragments with match: @var ===")
      rules = %{match: "@selected"}
      params = %{selected: ["Anchoring", "Meta Model"]}

      IO.inspect(rules, label: "rules")
      IO.inspect(params, label: "params")

      result = Collection.expand("{skills}", params, 0, %{}, 0, rules)
      IO.inspect(result, label: "Collection.expand result")

      {text, _, count} = result

      IO.puts("Text: #{inspect(text)}")
      IO.puts("Count: #{count}")

      assert count == 2
      assert text =~ "Anchoring Content"
      assert text =~ "Meta Model Content"
      refute text =~ "Milton Model Content"
    end

    test "debug matches with regex using matchRe" do
      IO.puts("\n=== DEBUG TEST: matches with regex using matchRe ===")
      rules = %{matchRe: "M.*", order: "ascending"}
      params = %{}

      IO.inspect(rules, label: "rules")
      IO.inspect(params, label: "params")

      result = Collection.expand("{skills}", params, 0, %{}, 0, rules)
      IO.inspect(result, label: "Collection.expand result")

      {text, _, count} = result

      IO.puts("Text: #{inspect(text)}")
      IO.puts("Count: #{count}")

      assert count == 2
      assert text =~ "Meta Model Content"
      assert text =~ "Milton Model Content"
      refute text =~ "Anchoring Content"
    end
  end
end
