defmodule DotPrompt.Compiler.FragmentExpanderTest do
  use ExUnit.Case, async: false

  alias DotPrompt.Compiler.FragmentExpander.Static
  alias DotPrompt.Compiler.FragmentExpander.Dynamic
  alias DotPrompt.Compiler.FragmentExpander.Collection

  @prompts_dir Path.expand("test/fixtures/fragment_expander", File.cwd!())

  setup_all do
    Application.put_env(:dot_prompt, :prompts_dir, @prompts_dir)
    File.mkdir_p!(Path.join(@prompts_dir, "fragments/tips"))

    # Simple greeting fragment
    File.write!(Path.join(@prompts_dir, "fragments/simple_greeting.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
    end init
    Hello! Welcome to our service.
    """)

    # Personalized greeting fragment with variables
    File.write!(Path.join(@prompts_dir, "fragments/personalized_greeting.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
      params:
        @name: str
    end init
    Hello @name!
    """)

    # Collection for tips
    File.write!(Path.join(@prompts_dir, "fragments/tips/_index.prompt"), """
    init do
      @version: 1
      def:
        mode: collection
    end init
    """)

    File.write!(Path.join(@prompts_dir, "fragments/tips/tip_1.prompt"), """
    init do
      @version: 1
      def:
        mode: fragment
        match: Tip
    end init
    Tip 1 Content
    """)

    # Malformed fragment for error testing
    File.mkdir_p!(Path.join(@prompts_dir, "malformed"))
    File.write!(Path.join(@prompts_dir, "malformed/bad.prompt"), "if @nonexistent is true do")

    on_exit(fn ->
      File.rm_rf!(@prompts_dir)
    end)

    {:ok, %{prompts_dir: @prompts_dir}}
  end

  describe "Static fragment expansion" do
    test "expands a static fragment" do
      assert {:ok, iodata, _files_meta} = Static.expand("{fragments/simple_greeting}", %{})
      text = IO.iodata_to_binary(iodata)
      assert text =~ "Hello! Welcome to our service."
    end

    test "expands static fragment with variable interpolation" do
      params = %{name: "World"}

      assert {:ok, iodata, _files_meta} =
               Static.expand("{fragments/personalized_greeting}", params)

      text = IO.iodata_to_binary(iodata)
      assert text =~ "Hello World!"
    end
  end

  describe "Dynamic fragment expansion" do
    test "expands a dynamic fragment" do
      # Dynamic expand doesn't interpolate, it just returns raw content
      assert {:ok, iodata, _files_meta} =
               Dynamic.expand("{{fragments/personalized_greeting}}", %{})

      text = IO.iodata_to_binary(iodata)
      assert text =~ "Hello @name!"
    end
  end

  describe "Collection fragment expansion" do
    setup do
      # Add another tip that shouldn't match
      File.write!(Path.join(@prompts_dir, "fragments/tips/tip_2.prompt"), """
      init do
        @version: 1
        def:
          mode: fragment
          match: Other
      end init
      Tip 2 Content
      """)

      :ok
    end

    test "expands all fragments in a collection" do
      assert {:ok, iodata, _meta, count} =
               Collection.expand("{fragments/tips}", %{}, 0, %{}, 0, %{match: "all"})

      text = IO.iodata_to_binary(iodata)
      assert count == 2
      assert text =~ "Tip 1 Content"
      assert text =~ "Tip 2 Content"
    end

    test "respects match filter" do
      assert {:ok, iodata, _meta, count} =
               Collection.expand("{fragments/tips}", %{}, 0, %{}, 0, %{match: "Tip"})

      text = IO.iodata_to_binary(iodata)
      assert count == 1
      assert text =~ "Tip 1 Content"
      refute text =~ "Tip 2 Content"
    end

    test "handles missing match variable gracefully" do
      # If match refers to a missing @var, it now returns a "none" header per user request
      assert {:ok, iodata, _meta, count} =
               Collection.expand("{fragments/tips}", %{}, 0, %{}, 0, %{match: "@missing_skills"})

      text = IO.iodata_to_binary(iodata)
      assert count == 1
      assert text =~ "fragments/tips → none"
      assert text =~ "(none)"
    end
  end

  describe "Error handling" do
    test "handles missing fragment strictly" do
      assert {:error, _} = Static.expand("{nonexistent}", %{})
    end

    test "handles compilation errors strictly" do
      # Since we isolated setup, we know malformed/bad exists
      result = Static.expand("{malformed/bad}", %{})
      assert {:error, _} = result
    end
  end
end
