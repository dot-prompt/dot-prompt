---
name: dot-prompt
description: Skill for writing the dotprompt language. Use when working with .prompt files.
---

# dot-prompt Language Skill

Expert knowledge for writing and understanding the dot-prompt language.

## Language Overview
dot-prompt is a compiled language for writing LLM prompts. It uses an `init` block for metadata and a body for the prompt prose.

## Core Syntax
- `@variable`: All variables start with `@`.
- `init do ... end init`: Metadata block.
- `{fragment}`: Static fragment/skill inclusion.
- `{{fragment}}`: Dynamic fragment inclusion.

## Types

### Compile-time Types
These drive branching logic and are evaluated at compile time:
- `bool`: True/false conditions for branching.
- `enum[...]`: Fixed set of options (e.g., `enum[tone: formal, casual, playful]`).
- `int[a..b]`: Integer ranges.
- `list[...]`: Lists of values.

### Runtime Types
These are placeholders in the final output:
- `str`: String placeholder - use when the value is provided at runtime and inserted verbatim.
- `int`: Integer placeholder - use for numeric values provided at runtime.

## When to Use Each Feature

### Strings (`str`)
Use `str` for **short values** — runtime placeholders like names, messages, or any text provided at runtime. They are injected just before the LLM call and cannot drive branching.

Example: `@user_name: str` — a name provided at runtime, appears as placeholder in compiled output.

### Enums (`enum[...]`)
Use `enum` for **fixed options** — when the value must be one of a predefined set. Drives branching via `case`, `vary`, or `if`.

Example: `@tone: enum[tone: formal, casual, friendly]` — tone selected from predefined options.

### Fragments
Use fragments for **long content** — entire `.prompt` files or collections that get compiled into the calling prompt. They are NOT short strings.

- **{fragment}** (static): Long content from a file or collection. Cached at compile time.
- **{{fragment}}** (dynamic): Long content fetched fresh each request.

Fragments are declared in the `fragments:` section and referenced by name in the body.

```
fragments:
  {simple_greeting}: from: fragments/simple_greeting
  {skill_context}: static from: skills
    match: @skill_names
  {{user_history}}: dynamic -> recent conversation history
```

**Syntax:**
- `{name}: from: path` — static fragment from file
- `{name}: static from: path` — explicit static (same as above)
- `{{name}}: dynamic` — dynamic fragment fetched each request
- `match: @variable` — filter by enum/list variable value
- `matchRe: pattern` — regex filter (enum only, e.g., `matchRe: M.*`)
- `match: all` — include all fragments in collection
- `limit: n` — maximum fragments to include
- `order: ascending|descending` — sort order
- `set: child_param: @parent_var` — pass variable to fragment

## Init Block
The `init` block declares everything about the prompt — version, variables, fragments, and documentation. It opens with `init do` and closes with `end init`.

```
init do
  @version: 1.0

  def:
    mode: explanation
    description: Human readable description of this prompt.

  params:
    @variation: enum[analogy, recognition, story] = analogy
      -> teaching track — selected once per session
    @user_input: str -> the user's current message

  fragments:
    {skill_context}: static from: skills
      match: @variation
    {{user_history}}: dynamic -> recent conversation history

  docs do
    This prompt teaches NLP skills in a structured multi-turn sequence.
  end docs

end init
```

### Syntax
- `@name: type = default -> documentation`
- `@name: type -> documentation` (no default)
- `@name: type` (no default, no docs)

### Sections
- `@version: major.minor` — required, semantic versioning
- `def:` — `mode` and `description` fields. For fragments, `mode: fragment` and `match: value`
- `params:` — all variables used in the prompt
- `fragments:` — external `.prompt` files to include
- `docs do...end docs` — free text for MCP and agents

### Fragment Mode
Individual fragment files declare `mode: fragment` and a `match` value:

```
init do
  @version: 1
  def:
    mode: fragment
    match: My Skill Name
end init
```

Collection folders declare `mode: collection`:

```
init do
  @version: 1
  def:
    mode: collection
end init
```

## Response Block
The `response` block declares the expected JSON shape of the LLM's response. It sits in the prompt body and the compiler derives a typed contract from it.

### Syntax
```
response do
  {
    "field_name": "type",
    "nested": {
      "key": "type"
    }
  }
end response
```

### {response_contract}
Use `{response_contract}` in the prompt body to inject the derived schema:

```
Respond in exactly this JSON format:
{response_contract}
```

The compiler replaces `{response_contract}` with the actual JSON shape.

## Control Flow

### If Statements
Use for conditional branching based on compile-time types:

```
if @is_premium is true do
  You have premium access including exclusive features.
elif @is_trial is true do
  You have trial access for @remaining_days days.
else
  Upgrade to access premium features.
end @is_premium
```

**Condition operators:**
- `@var is x` — equals
- `@var not x` — does not equal (enum, int range only)
- `@var above x` — greater than (int range only)
- `@var below x` — less than (int range only)
- `@var between x and y` — inclusive range (int range only)

### Case Statements
Use when matching against enum values or specific values:

```
case @output_format do
  json do
    Format your response as valid JSON.
  xml do
    Wrap your response in XML tags.
  markdown do
    Use markdown formatting.
end @output_format
```

### Vary Statements
Use for conditional content that varies based on enum or bool values:

```
vary @tone do
  formal do
    Address the user with formal language and proper titles.
  casual do
    Use friendly, conversational tone.
  playful do
    Add humor and lighthearted expressions.
end @tone
```
