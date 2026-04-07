# DotPrompt

A high-performance, native Elixir compiler for the DotPrompt language.

[![Hex](https://img.shields.io/hexpm/v/dot_prompt)](https://hex.pm/packages/dot_prompt)
[![Elixir Versions](https://img.shields.io/badge/elixir-%3E%3D%201.18-blue)](https://hex.pm/packages/dot_prompt)
[![License](https://img.shields.io/hexpm/l/dot_prompt)](https://github.com/dot-prompt/dot-prompt/blob/main/LICENSE)

---

## What This Is

DotPrompt compiles `.prompt` files — a domain-specific language where branching, fragments, and contracts resolve at compile time. Your LLM receives only the final, flat prompt string with zero logic residue.

Unlike the TypeScript and Python clients (which talk to a runtime container), this is the **native Elixir compiler** — it runs in-process with no network overhead.

**Website:** [dotprompt.run](https://dotprompt.run)  
**Documentation:** [dotprompt.run/docs](https://dotprompt.run/docs)  
**GitHub:** [github.com/dot-prompt/dot-prompt](https://github.com/dot-prompt/dot-prompt)

---

## Features

- **In-process compilation** — no network calls, compiles directly in your BEAM VM
- **Structural caching** — compiled prompts cached with automatic invalidation on file changes
- **Fragments** — reusable prompt snippets (static, dynamic, and collection-based)
- **Vary blocks** — A/B testing and randomized prompt variations with deterministic seeding
- **Conditional logic** — `if`/`elif`/`else` and `case` blocks resolved at compile time
- **Response contracts** — declare expected LLM response formats as JSON schemas
- **Telemetry integration** — built-in `:telemetry` events for monitoring compile times and token counts
- **Version management** — major version support with archive fallback

---

## Installation

The package can be installed by adding `dot_prompt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dot_prompt, "~> 1.0.0"}
  ]
end
```

---

## Prerequisites

Place your `.prompt` files in a `prompts/` directory at your project root, or configure a custom path:

```elixir
config :dot_prompt,
  prompts_dir: "priv/prompts"
```

---

## Quick Start

```elixir
# Compile a prompt with parameters
{:ok, result} = DotPrompt.compile("my_prompt", %{name: "World"})
IO.puts(result.prompt)
```

---

## Full Example: Compile + Render + Validate

```elixir
# Extract schema (parameters, types, contracts)
{:ok, schema} = DotPrompt.schema("teaching_prompt")
IO.inspect(schema.params)

# Compile: resolve branching, expand fragments, select variations
{:ok, compiled} = DotPrompt.compile("teaching_prompt", %{
  pattern_step: 2,
  variation: "recognition",
  answer_depth: "medium",
  skill_names: ["Milton Model"]
}, seed: 42) # deterministic variation selection

IO.puts("Template: #{compiled.prompt}")

# Render: inject runtime variables into the compiled template
{:ok, rendered} = DotPrompt.render("teaching_prompt",
  %{
    pattern_step: 2,
    variation: "recognition",
    answer_depth: "medium",
    skill_names: ["Milton Model"]
  },
  %{
    user_input: "Can you give me an example?",
    user_level: "intermediate"
  }
)

IO.puts("Final prompt: #{rendered.prompt}")

# Validate LLM response against the contract
response = Jason.encode!(%{score: 8, explanation: "Good answer"})
case DotPrompt.validate_output(response, compiled.response_contract) do
  :ok -> IO.puts("Valid response")
  {:error, reason} -> IO.puts("Invalid: #{reason}")
end
```

---

## API Reference

### Core Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `list_prompts()` | `[String.t()]` | All available prompts including fragments |
| `list_root_prompts()` | `[String.t()]` | Root-level prompts only (excludes fragments) |
| `list_fragment_prompts()` | `[String.t()]` | Fragment prompts only |
| `list_collections()` | `[String.t()]` | Root-level collections |
| `schema(prompt, major?)` | `{:ok, schema_info()} \| {:error, map()}` | Prompt metadata, params, fragments, contracts |
| `compile(prompt, params, opts?)` | `{:ok, Result.t()} \| {:error, map()}` | Resolve branching, expand fragments |
| `render(prompt, params, runtime, opts?)` | `{:ok, Result.t()} \| {:error, map()}` | Full compile + inject runtime variables |
| `inject(template, runtime)` | `String.t()` | Inject runtime vars into a raw template |
| `compile_string(content, params, opts?)` | `{:ok, Result.t()} \| {:error, map()}` | Compile inline prompt content |
| `validate_output(response_json, contract, opts?)` | `:ok \| {:error, String.t()}` | Validate LLM response against contract |

### Compile Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `seed` | `integer()` | — | Deterministic variation selection |
| `indent` | `integer()` | `0` | Indentation level |
| `annotated` | `boolean()` | `false` | Keep section annotations in output |
| `major` | `integer()` | `nil` | Request specific major version |

### DotPrompt.Result Struct

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | `String.t()` | The compiled/rendered prompt string |
| `response_contract` | `map() \| nil` | JSON schema for expected LLM output |
| `vary_selections` | `map()` | Which variation branches were selected |
| `compiled_tokens` | `integer()` | Estimated token count of compiled prompt |
| `injected_tokens` | `integer()` | Estimated token count after runtime injection |
| `cache_hit` | `boolean()` | Whether the result came from cache |
| `major` | `integer() \| nil` | Major version of the compiled prompt |
| `version` | `integer() \| String.t() \| nil` | Full version |
| `metadata` | `map()` | Additional metadata (used vars, files, warnings, params) |

### Cache Management

| Function | Returns | Description |
|----------|---------|-------------|
| `invalidate_cache(prompt)` | `:ok` | Invalidate cache for a specific prompt |
| `invalidate_all_cache()` | `:ok` | Clear all caches |
| `cache_stats()` | `map()` | Current cache usage statistics |

---

## Configuration

```elixir
config :dot_prompt,
  prompts_dir: "priv/prompts"
```

| Option | Default | Description |
|--------|---------|-------------|
| `prompts_dir` | `"prompts"` | Directory containing `.prompt` files |

---

## Telemetry

DotPrompt emits `:telemetry` events you can attach to:

```elixir
:telemetry.attach(
  "dot-prompt-render",
  [:dot_prompt, :render, :stop],
  fn _event, measurements, metadata, _config ->
    IO.puts("Rendered #{metadata.prompt_name} in #{measurements.duration}ms")
    IO.puts("Tokens: #{measurements.compiled_tokens}")
    IO.puts("Cache hit: #{measurements.cache_hit}")
  end,
  []
)
```

---

## Example `.prompt` File

This is what the compiler compiles from:

```prompt
init do
  @major: 1

  params:
    @name: str -> user's name
    @mode: enum[formal, casual] = casual -> communication style

  fragments:
    {greeting}: static from: greetings
      match: @mode

end init

case @mode do
formal: Dear @name, welcome to our service.
casual: Hey @name! Great to see you.
end @mode
```

Into this clean string for your LLM:

```
Dear Sarah, welcome to our service.
```

No branching logic. No fragment references. Just the instruction.

---

## Related Packages

| Package | Description |
|---------|-------------|
| [@dotprompt/client](https://www.npmjs.com/package/@dotprompt/client) | TypeScript client for the dotprompt runtime container |
| [dotprompt-client](https://pypi.org/project/dotprompt-client/) | Python client for the dotprompt runtime container |
| [dot_prompt_server](../../server/apps/dot_prompt_server/) | Phoenix web server and DevUI for the dotprompt runtime |

---

## License

Apache 2.0 — see [LICENSE](https://github.com/dot-prompt/dot-prompt/blob/main/LICENSE)
