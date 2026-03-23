defmodule DotPrompt.Compiler.FragmentExpander.CollectionTest do
  use ExUnit.Case, async: false
  alias DotPrompt.Compiler.FragmentExpander.Collection

  @prompts_dir Path.expand("test/fixtures/prompts", File.cwd!())

  setup_all do
    Application.put_env(:dot_prompt, :prompts_dir, @prompts_dir)
    # Ensure fixtures exist
    File.mkdir_p!(Path.join(@prompts_dir, "skills"))

    test_skills = Path.join(@prompts_dir, "skills")

    File.write!(Path.join(test_skills, "_index.prompt"), """
    init do
      @version: 1
      def:
        mode: collection
    end init
    """)

    File.write!(Path.join(test_skills, "anchoring.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Anchoring
      params:
        @selected: list
    end init
    Anchoring Content
    """)

    File.write!(Path.join(test_skills, "milton_model.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Milton Model
      params:
        @selected: list
    end init
    Milton Model Content
    """)

    File.write!(Path.join(test_skills, "meta_model.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Meta Model
      params:
        @selected: list
    end init
    Meta Model Content
    """)

    on_exit(fn ->
      File.rm_rf!(test_skills)
    end)

    {:ok, %{dir: @prompts_dir}}
  end

  describe "expand/6" do
    test "matches all fragments with match: all" do
      rules = %{match: "all", order: "ascending"}
      assert {:ok, text, _, count} = Collection.expand("{skills}", %{}, 0, %{}, 0, rules)

      assert count == 3
      assert text =~ "Anchoring Content"
      assert text =~ "Meta Model Content"
      assert text =~ "Milton Model Content"
    end

    test "matches specific fragments with match: @var" do
      rules = %{match: "@selected"}
      params = %{selected: ["Anchoring", "Meta Model"]}
      assert {:ok, text, _, count} = Collection.expand("{skills}", params, 0, %{}, 0, rules)

      assert count == 2
      assert text =~ "Anchoring Content"
      assert text =~ "Meta Model Content"
      refute text =~ "Milton Model Content"
    end

    test "matches with regex using matchRe" do
      rules = %{matchRe: "M.*", order: "ascending"}
      assert {:ok, text, _, count} = Collection.expand("{skills}", %{}, 0, %{}, 0, rules)

      assert count == 2
      assert text =~ "Meta Model Content"
      assert text =~ "Milton Model Content"
      refute text =~ "Anchoring Content"
    end

    test "respects limit and order" do
      rules = %{match: "all", limit: "1", order: "descending"}
      assert {:ok, text, _, count} = Collection.expand("{skills}", %{}, 0, %{}, 0, rules)

      assert count == 1
      # descending alphabetic: milton, meta, anchoring -> first is milton
      assert text =~ "Milton Model Content"
      refute text =~ "Meta Model Content"
      refute text =~ "Anchoring Content"
    end
  end
end
