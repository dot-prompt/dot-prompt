# dot-prompt Specification
**Version 1.0 — Implementation Ready**

A compiled domain-specific language for authoring structured LLM prompts.
dot-prompt compiles to a clean, flat prompt string. The LLM receives only
the resolved output — no syntax artifacts, no untaken branches, no dead weight.

---

## What It Is

dot-prompt is a deterministic structural reducer. It shapes one prompt for
one LLM call. It is not a workflow engine, state machine, or conversation
manager. Those concerns belong to a separate layer.

| Layer | Responsibility |
|-------|---------------|
| dot-prompt | Shape one prompt deterministically |
| State machine | Orchestrate multiple prompt calls and conversation flow |
| Runtime | Inject variables, manage seeds, execute LLM call |

dot-prompt is about instruction shape, not execution logic. Separation of
concerns avoids token explosion, debugging nightmares, and mixing structure
with flow.

---

## Project Structure

Umbrella app — one repo, two apps, clean separation.

```
dot-prompt/
├── apps/
│   ├── dot_prompt/                    # core Hex library — published to Hex
│   │   ├── lib/
│   │   │   └── dot_prompt/
│   │   │       ├── parser/
│   │   │       │   ├── lexer.ex
│   │   │       │   ├── parser.ex
│   │   │       │   └── validator.ex
│   │   │       ├── compiler/
│   │   │       │   ├── if_resolver.ex
│   │   │       │   ├── case_resolver.ex
│   │   │       │   ├── fragment_expander/
│   │   │       │   │   ├── static.ex
│   │   │       │   │   ├── collection.ex
│   │   │       │   │   └── dynamic.ex
│   │   │       │   └── vary_compositor.ex
│   │   │       ├── cache/
│   │   │       │   ├── structural.ex
│   │   │       │   ├── fragment.ex
│   │   │       │   └── vary.ex
│   │   │       ├── injector.ex
│   │   │       └── telemetry.ex
│   │   └── mix.exs
│   │
│   └── dot_prompt_server/             # container app — HTTP API + MCP + viewer
│       ├── lib/
│       │   └── dot_prompt_server/
│       │       ├── api/               # HTTP API — all languages
│       │       │   ├── router.ex
│       │       │   └── controllers/
│       │       │       ├── compile_controller.ex
│       │       │       ├── render_controller.ex
│       │       │       └── schema_controller.ex
│       │       ├── mcp/               # MCP server — stdio mode
│       │       │   ├── server.ex
│       │       │   └── tools/
│       │       │       ├── schema.ex
│       │       │       ├── compile.ex
│       │       │       └── list.ex
│       │       └── viewer/            # Phoenix LiveView viewer
│       │           ├── live/
│       │           │   ├── viewer_live.ex
│       │           │   └── stats_live.ex
│       │           └── router.ex
│       └── mix.exs                    # depends on :dot_prompt
│
├── Dockerfile
├── docker-compose.yml
├── mix.exs                            # umbrella mix.exs
└── README.md
```

---

## Deployment Contexts

| Context | What runs |
|---------|-----------|
| Elixir production (TealSpeech) | `dot_prompt` Hex library — compiled into release, zero latency |
| All other languages | HTTP API via container |
| Local development | Container — viewer on :4040, API on :4041, MCP on stdio |
| CI | `dot_prompt` library tests only |

```elixir
# TealSpeech mix.exs — native, no HTTP
{:dot_prompt, "~> 1.0"}
```

```bash
# All other languages — container
docker run -v ./prompts:/prompts -p 4040:4040 -p 4041:4041 dotprompt/server
```

---

## HTTP API

The container exposes a REST API on port 4041. This is the integration
point for Python, TypeScript, Go, Ruby, and any other language.

### POST /api/compile

Resolves control flow. Returns a compiled template with runtime variables
still as placeholders. Cacheable by compile-time params.

**Request:**
```json
{
  "prompt": "concept_explanation",
  "params": {
    "pattern_step": 2,
    "variation": "b",
    "answer_depth": "medium",
    "if_input_mode_question": false,
    "skill_names": ["Milton Model", "Meta Model"]
  },
  "seed": 42
}
```

**Response:**
```json
{
  "template": "You are teaching {{user_level}} students...",
  "cache_hit": true,
  "compiled_tokens": 312,
  "vary_selections": {"intro": "a", "closing": "b"}
}
```

### POST /api/inject

Fills runtime variable placeholders in a compiled template.

**Request:**
```json
{
  "template": "You are teaching {{user_level}} students...",
  "runtime": {
    "user_message": "Can you give me an example?",
    "user_level": "intermediate"
  }
}
```

**Response:**
```json
{
  "prompt": "You are teaching intermediate students...",
  "injected_tokens": 387
}
```

### POST /api/render

Compile and inject in one call.

**Request:**
```json
{
  "prompt": "concept_explanation",
  "params": {
    "pattern_step": 2,
    "variation": "b",
    "answer_depth": "medium",
    "if_input_mode_question": false,
    "skill_names": ["Milton Model"]
  },
  "runtime": {
    "user_message": "Can you give me an example?",
    "user_level": "intermediate"
  },
  "seed": 42
}
```

**Response:**
```json
{
  "prompt": "You are teaching intermediate students...",
  "cache_hit": true,
  "compiled_tokens": 312,
  "injected_tokens": 387,
  "vary_selections": {"intro": "a", "closing": "b"}
}
```

### GET /api/schema/:prompt

Returns parsed @init for a prompt or collection.

**Response:**
```json
{
  "name": "concept_explanation",
  "version": 1,
  "description": "Teacher mode — explanation phase with dynamic depth control.",
  "params": {
    "skill_names": {
      "type": "enum",
      "values": ["Milton Model", "Meta Model", "Anchoring", "Reframing"],
      "lifecycle": "compile",
      "doc": "skills to load, must match declared skills in skills collection"
    },
    "pattern_step": {
      "type": "int",
      "range": [1, 5],
      "lifecycle": "compile",
      "doc": "current step in the teaching sequence"
    },
    "variation": {
      "type": "enum",
      "values": ["a", "b", "c"],
      "lifecycle": "compile",
      "doc": "teaching track a=analogy b=recognition c=story"
    },
    "answer_depth": {
      "type": "enum",
      "values": ["shallow", "medium", "deep"],
      "lifecycle": "compile",
      "doc": "depth of question answers"
    },
    "if_input_mode_question": {
      "type": "bool",
      "lifecycle": "compile",
      "doc": "true when user has asked a question"
    },
    "user_message": {
      "type": "str",
      "lifecycle": "runtime",
      "doc": "the user's current message"
    },
    "user_level": {
      "type": "enum",
      "values": ["beginner", "intermediate", "advanced"],
      "lifecycle": "runtime",
      "doc": "user experience level"
    }
  },
  "fragments": {
    "skill_context": {
      "type": "static",
      "from": "skills/",
      "doc": "skill definition loaded from skills collection"
    },
    "user_history": {
      "type": "dynamic",
      "doc": "recent conversation history for context"
    }
  },
  "docs": "Teaches NLP skills using a structured multi-turn pattern..."
}
```

### GET /api/prompts

Lists all available prompt files.

### GET /api/collections

Lists all available collections.

---

## Python Client

Thin HTTP wrapper. No parser, no compiler — just API calls.

```python
from dot_prompt import Client

client = Client("http://localhost:4041")

# Render in one call
prompt = client.render(
    "concept_explanation",
    params={
        "pattern_step": 2,
        "variation": "b",
        "answer_depth": "medium",
        "if_input_mode_question": False,
        "skill_names": ["Milton Model"]
    },
    runtime={
        "user_message": "Can you give me an example?",
        "user_level": "intermediate"
    },
    seed=42
)

# Schema discovery
schema = client.schema("concept_explanation")
prompts = client.list_prompts()
```

---

## MCP Server

Runs in stdio mode inside the container. No persistent port needed.
The MCP client spawns the process on demand.

```json
{
  "dot-prompt": {
    "command": "docker",
    "args": ["exec", "-i", "dot-prompt", "mix", "dot_prompt.mcp"]
  }
}
```

### MCP Tools

| Tool | Purpose |
|------|---------|
| `prompt_schema` | Returns params, fragments, and docs for a prompt |
| `collection_schema` | Returns params and select rules for a collection |
| `prompt_list` | Lists all available prompt files |
| `collection_list` | Lists all available collections |
| `prompt_compile` | Compiles a prompt with given params for preview |

---

## .prompt File Format

### File Structure

Every `.prompt` file has two parts:

```
@init do
  ...metadata, params, fragments, docs...
end @init

...prompt body...
```

`@init` uses the same `do / end @name` convention as all control flow blocks.
No separators required. Everything outside `@init` is prompt body.

### Init Block

```
@init do
  def:
    mode: explanation
    version: 1
    description: Teacher mode — explanation phase with dynamic depth control.

  params:
    @skill_names: enum[Milton Model, Meta Model, Anchoring, Reframing]
      -> skills to load, must match declared skills in skills collection
    @pattern_step: int[1..5] -> current step in the teaching sequence
    @variation: enum[a, b, c] -> teaching track a=analogy b=recognition c=story
    @answer_depth: enum[shallow, medium, deep] -> depth of question answers
    @if_input_mode_question: bool -> true when user has asked a question
    @user_message: str -> the user's current message
    @user_level: enum[beginner, intermediate, advanced] -> user experience level

  fragments:
    {skill_context}: static from: skills/
      @skill_names: @skill_names
      -> loads and composites all matching skill definitions
    {{user_history}}: dynamic -> recent conversation history for context

  @docs do
    Teaches NLP skills using a structured multi-turn pattern.
    Variation track is selected once per session and held constant.
    Increment @pattern_step each turn.
    Set @if_input_mode_question true when user asks an off-pattern question.
    @skill_names must match declared skills in the skills collection.
  end @docs

end @init
```

---

## Variable Lifecycle

Lifecycle is determined by type domain, not position or sigil.

| Type | Domain | Lifecycle | Control flow |
|------|--------|-----------|-------------|
| `str` | Infinite | Runtime | No |
| `int` | Infinite | Runtime | No |
| `list[str]` | Infinite | Runtime | No |
| `int[a..b]` | Finite | Compile-time | Yes |
| `bool` | Finite | Compile-time | Yes |
| `enum[...]` | Finite | Compile-time | Yes |
| `list[enum]` | Finite | Compile-time | Yes |

---

## Sigils

| Sigil | Name | Purpose |
|-------|------|---------|
| `@` | Variable / block | Variables, control flow, reserved blocks |
| `{}` | Static fragment | Fixed external content — cacheable |
| `{{}}` | Dynamic fragment | Live external content — fetched fresh |
| `#` | Comment | Author note — never reaches LLM |
| `->` | Documentation | Surfaces through MCP and schema calls |

---

## Control Flow

All blocks open with `do` and close with `end @variable` or `end vary`.
Indentation is optional and has no semantic meaning.
Maximum nesting depth is 3 levels.
Only finite domain variables can appear in conditions.

### If — Natural Language Conditions

| Syntax | Meaning | Types |
|--------|---------|-------|
| `if @var is x do` | equality | `bool`, `enum`, `int[a..b]` |
| `if @var not x do` | inequality | `enum`, `int[a..b]` |
| `if @var above x do` | greater than | `int[a..b]` |
| `if @var below x do` | less than | `int[a..b]` |
| `if @var min x do` | greater than or equal | `int[a..b]` |
| `if @var max x do` | less than or equal | `int[a..b]` |
| `if @var between x and y do` | inclusive range | `int[a..b]` |

Supports `elif` and `else`:

```
if @pattern_step is 1 do
Opening step content.

elif @pattern_step is 5 do
Closing step content.

else
Middle step content.
end @pattern_step
```

### Case

Deterministic branch selection. Optional title after `:` compiles through
to LLM. Prefix with `#` to keep as author documentation only.

```
case @answer_depth do
shallow: Shallow Answer
1-2 sentences answering exactly what they asked.

medium: Medium Answer
Explanation + 1 relevant example from the context.

deep: Deep Answer
Full explanation with multiple examples from the context.
end @answer_depth
```

### Vary

Non-deterministic branch selection. Resolved last after structural caching.
Composited into cached template as cheap slot filling.

**Unnamed:**
```
vary do
a: Open with an analogy.
b: Open with a question.
end vary
```

**Named — space before name:**
```
vary intro do
a: Begin by grounding the user in what they are about to learn.
b: Begin with a question that creates productive curiosity.
end vary intro

vary closing do
a: End with a practical exercise.
b: End with a reflective question.
end vary closing
```

**Seeding via API:**
```json
{ "seed": 42 }
{ "seeds": { "intro": 3, "closing": 7 } }
```

### Nested Case — Variation Tracks

`case @variation` outside, `case @pattern_step` inside.
Each track is a coherent narrative arc.
Track titles prefixed with `#` are author docs only — do not compile through.
Step titles without `#` compile through to the LLM.

```
case @variation do
a: #Analogy Track
case @pattern_step do
1: Opening Anchor
Introduce @skill_names with a single real-world analogy.

2: Deepening the Frame
Build on the analogy from step 1.

3: Concrete Examples
Give 2 examples of @skill_names in real conversation.
end @pattern_step

b: #Recognition Track
case @pattern_step do
1: Opening Anchor
Open with a question that makes the user realise they already use @skill_names.

2: Deepening the Frame
Return to the user's own recognition from step 1.

3: Concrete Examples
Ask the user to generate their own example first.
end @pattern_step

end @variation
```

**Compiled output** for `variation: b`, `pattern_step: 2`:

```
Deepening the Frame
Return to the user's own recognition from step 1.
```

---

## Fragment Collections

A folder becomes a collection when it contains `_index.prompt`.

```
priv/prompts/skills/
  _index.prompt
  milton_model.prompt
  meta_model.prompt
  anchoring.prompt
  reframing.prompt
```

### _index.prompt

```
@init do
  def:
    mode: collection
    version: 1
    description: NLP skills collection

  params:
    @skill_names: list[str] -> skill names to load

  skills:
    Milton Model -> milton_model.prompt
    Meta Model -> meta_model.prompt
    Anchoring -> anchoring.prompt
    Reframing -> reframing.prompt

  select:
    match: @skill_names
    limit: all

  @docs do
    Returns compiled skill definitions for all requested skills.
    @skill_names values are validated against the skills registry.
    Add new skills by adding an entry to skills: and dropping
    the .prompt file into this folder. No code changes needed.
  end @docs

end @init
```

The `skills:` block is the registry. The compiler validates every value
in `@skill_names` against this registry at Stage 1 — unknown skill names
are a compile error before any file is touched.

### Collection select rules

| Field | Purpose | Example |
|-------|---------|---------|
| `limit` | Max fragments to return | `limit: 1` / `limit: all` |
| `match` | Match fragments by metadata | `match: @skill_names` |
| `order` | Selection order | `order: random` |
| `filter` | Filter by param value | `filter: @user_level` |

### Individual fragment file

```
@init do
  def:
    mode: fragment
    version: 1
    description: Milton Model skill definition
    match: Milton Model

  params:
    @skill_names: list[str]
end @init

The Milton Model is a set of language patterns derived from...
```

---

## Compilation Pipeline

```
Request arrives (HTTP or native function call)
      │
      ▼
  [Stage 1] Validate
            check compile-time @params against declared types
            validate enum/list[enum] against declared values
            validate skill names against collection registry
            STOP on any error — never silent

      │
      ▼
  [Stage 2] Resolve if/case control flow
            vary blocks left as named slots
            ──────────────────────────────────────────
            STRUCTURAL CACHE
            key   = prompt name + version + compile-time params
            value = resolved skeleton with vary slots intact
            ──────────────────────────────────────────

      │
      ▼
  [Stage 3] Expand fragments
            static {} — compile referenced .prompt files with passed params
            collections — load _index.prompt, match registry, composite
            ──────────────────────────────────────────
            STATIC FRAGMENT CACHE
            key   = fragment path + version + passed params
            value = compiled fragment content
            ──────────────────────────────────────────
            dynamic {{}} — fetch fresh, not cached
            only fragments in surviving branch are fetched

      │
      ▼
  [Stage 4] Resolve vary slots
            select branch per seed, per-vary seed, or randomly
            composite into structural skeleton
            ──────────────────────────────────────────
            VARY BRANCH CACHE
            key   = prompt name + vary name + branch id
            value = branch content — preloadable at startup
            ──────────────────────────────────────────

      │
      ▼
  [Stage 5] Inject runtime @variables
            fill placeholders just before LLM call

      │
      ▼
  Final prompt string
```

### Cache Summary

| Cache | Key | Cacheable |
|-------|-----|-----------|
| Structural | prompt + version + compile-time params | Always |
| Static fragment | fragment path + version + params | Always |
| Vary branch | prompt + vary name + branch id | Always |
| Dynamic fragment | — | Never |

### Dev vs Prod Mode

```
Dev:   full parse → compile → inject on every request, no caching
Prod:  check structural cache → hit: inject only / miss: full pipeline → cache
```

---

## Error Handling

Compiler stops immediately on any error. Never silent.
Every error includes file name, line number, and descriptive message.

| Error | Example message |
|-------|----------------|
| `unknown_variable` | `@skill_level referenced but not declared — line 24` |
| `out_of_range` | `@pattern_step value 7 out of range int[1..5] — line 12` |
| `invalid_enum` | `@variation value d not in enum[a, b, c] — line 8` |
| `unknown_skill` | `Milton Modelx not found in skills registry` |
| `missing_param` | `@answer_depth required but not provided` |
| `unclosed_block` | `if @if_input_mode_question opened at line 31 — no matching end` |
| `mismatched_end` | `end @answer_depth at line 45 — expected end @if_input_mode_question` |
| `nesting_exceeded` | `nesting depth 4 exceeded at line 67 — maximum is 3` |
| `unknown_vary` | `seed provided for vary intro but no vary intro block found` |
| `missing_fragment` | `skills/milton_model.prompt not found` |
| `collection_no_match` | `no match for Milton Modelx in skills/` |

---

## Telemetry

Library emits telemetry events. Host application attaches handlers.
Same pattern as Ecto, Phoenix, Oban.

```elixir
# Emitted by library
:telemetry.execute(
  [:dot_prompt, :render, :stop],
  %{compiled_tokens: 312, injected_tokens: 387, duration_ms: 12},
  %{
    prompt: "concept_explanation",
    version: 1,
    params: %{variation: :b, pattern_step: 2},
    vary_selections: %{intro: :a, closing: :b},
    cache_hit: true
  }
)

# Attached by host application
:telemetry.attach(
  "dot-prompt-stats",
  [:dot_prompt, :render, :stop],
  &MyApp.PromptStats.handle/4,
  nil
)
```

---

## Elixir Native API

```elixir
# Schema
DotPrompt.schema("concept_explanation")
DotPrompt.schema("skills/")

# Compile — returns template with runtime vars as placeholders
template = DotPrompt.compile("concept_explanation", %{
  pattern_step: 2,
  variation: :b,
  answer_depth: :medium,
  if_input_mode_question: false,
  skill_names: ["Milton Model", "Meta Model"]
}, seed: 42)

# Inject runtime variables
prompt = DotPrompt.inject(template, %{
  user_message: "Can you give me an example?",
  user_level: "intermediate"
})

# Compile and inject in one call
prompt = DotPrompt.render("concept_explanation",
  %{
    pattern_step: 2,
    variation: :b,
    answer_depth: :medium,
    if_input_mode_question: false,
    skill_names: ["Milton Model"]
  },
  %{
    user_message: "Can you give me an example?",
    user_level: "intermediate"
  },
  seed: 42
)
```

---

## Docker

```dockerfile
FROM elixir:1.17-alpine
WORKDIR /app
COPY . .
RUN mix deps.get
RUN mix compile
EXPOSE 4040 4041
CMD ["mix", "phx.server"]
```

```yaml
# docker-compose.yml
version: "3.8"
services:
  dot-prompt:
    build: .
    ports:
      - "4040:4040"  # viewer
      - "4041:4041"  # HTTP API
    volumes:
      - ./prompts:/app/priv/prompts
    environment:
      - MIX_ENV=dev
```

---

## Full .prompt Example

```
@init do
  def:
    mode: explanation
    version: 1
    description: Teacher mode — explanation phase with dynamic depth control.

  params:
    @skill_names: enum[Milton Model, Meta Model, Anchoring, Reframing]
      -> skills to load, must match declared skills in skills collection
    @pattern_step: int[1..3] -> current step in the teaching sequence
    @variation: enum[a, b, c] -> teaching track a=analogy b=recognition c=story
    @answer_depth: enum[shallow, medium, deep] -> depth of question answers
    @if_input_mode_question: bool -> true when user has asked a question
    @user_message: str -> the user's current message
    @user_level: enum[beginner, intermediate, advanced] -> user experience level

  fragments:
    {skill_context}: static from: skills/
      @skill_names: @skill_names
      -> loads and composites all matching skill definitions
    {{user_history}}: dynamic -> recent conversation history for context

  @docs do
    Teaches NLP skills using a structured multi-turn pattern.
    Variation track is selected once per session and held constant.
    Increment @pattern_step each turn.
    Set @if_input_mode_question true when user asks an off-pattern question.
  end @docs

end @init

# ROLE
You are Milton, an expert NLP trainer teaching @user_level students.
Your job is to teach @skill_names efficiently using structured teaching patterns.

if @if_input_mode_question is true do

# Question mode — interrupts teaching flow
STOP TEACHING FLOW. Answer the user's question directly.

The user asked: @user_message

Skill context:
{skill_context}

User history:
{{user_history}}

HOW TO ANSWER:
case @answer_depth do
shallow: Shallow Answer
1-2 sentences answering exactly what they asked.

medium: Medium Answer
Explanation + 1 relevant example from the context.

deep: Deep Answer
Full explanation with multiple examples from the context.
end @answer_depth

Rules:
- Do not continue the teaching pattern.
- Answer naturally, acknowledging their question.

Response:
{
  "response_type": "question_answer",
  "content": "Acknowledge their question, then answer.",
  "ui_hints": {
    "show_answer_input": false,
    "show_success": false,
    "show_failure": false
  }
}

else

# Teaching mode — normal step progression
vary intro do
a: Begin by grounding the user in what they are about to learn.
b: Begin with a question that creates productive curiosity.
end vary intro

case @variation do
a: #Analogy Track
case @pattern_step do
1: Opening Anchor
Introduce @skill_names with a single real-world analogy.
Do not define it formally yet. Let the analogy do the work.
2: Deepening the Frame
Build on the analogy from step 1. Layer in the formal definition.
3: Concrete Examples
Give 2 examples of @skill_names. First obvious, second subtle.
end @pattern_step

b: #Recognition Track
case @pattern_step do
1: Opening Anchor
Open with a question that makes the user realise they already use @skill_names.
2: Deepening the Frame
Return to the user's own recognition. Use their words to introduce the formal framing.
3: Concrete Examples
Ask the user to generate their own example first. Then offer one refinement.
end @pattern_step

c: #Story Track
case @pattern_step do
1: Opening Anchor
Start with a brief story where @skill_names changed the outcome of a conversation.
2: Deepening the Frame
Extend the story. Show how @skill_names was operating beneath the surface.
3: Concrete Examples
Show @skill_names being used poorly then well. Ask what changed.
end @pattern_step

end @variation

@user_message

vary closing do
a: End with a practical exercise for the user to try.
b: End with a reflective question that deepens the learning.
end vary closing

Response:
{
  "response_type": "teaching",
  "content": "Your teaching response here.",
  "ui_hints": {
    "show_answer_input": true,
    "show_success": false,
    "show_failure": false
  }
}

end @if_input_mode_question
```

---

## Control Flow Reference

| Keyword | Behaviour | Requirement | Closes with |
|---------|-----------|-------------|-------------|
| `@init do` | File setup block | Reserved | `end @init` |
| `@docs do` | Documentation inside @init | Reserved | `end @docs` |
| `if @var is x do` | Equality | `bool`, `enum`, `int[a..b]` | `end @var` |
| `if @var not x do` | Inequality | `enum`, `int[a..b]` | `end @var` |
| `if @var above x do` | Greater than | `int[a..b]` | `end @var` |
| `if @var below x do` | Less than | `int[a..b]` | `end @var` |
| `if @var min x do` | Greater than or equal | `int[a..b]` | `end @var` |
| `if @var max x do` | Less than or equal | `int[a..b]` | `end @var` |
| `if @var between x and y do` | Inclusive range | `int[a..b]` | `end @var` |
| `elif @var is x do` | Chained condition | same as if | — |
| `else` | Fallback branch | — | — |
| `case @var do` | Deterministic selection | `enum` or `int[a..b]` | `end @var` |
| `vary do` | Random or seeded — unnamed | None | `end vary` |
| `vary name do` | Random or seeded — named | None | `end vary name` |

---

## Implementation Notes for LLM

**Parser approach:**
Write a recursive descent parser in Elixir. The lexer tokenises the file
line by line. Tokens are: keyword, variable, fragment_static, fragment_dynamic,
comment, doc, text. The parser builds an AST from tokens. The validator
walks the AST checking types, bounds, and nesting depth.

**Key parsing rules:**
- `@init` block must be first in file
- Everything outside `@init` is prompt body — treated as text unless it starts with a keyword
- Keywords are: `if`, `elif`, `else`, `case`, `vary`, `end`
- `end` is always followed by the name of what it closes — `end @var` or `end vary` or `end vary name`
- Indentation is ignored — structure comes entirely from `do` and `end`
- `#` to end of line is a comment — strip before processing
- `->` to end of line on a param or fragment declaration is documentation — store separately

**Compiler approach:**
The compiler takes an AST and a params map and produces a string.
Walk the AST depth-first. For each node:
- `if` node — evaluate condition against params, recurse into matching branch only
- `case` node — find matching branch, recurse into it only
- `vary` node — leave as a named slot marker in the output string
- `text` node — emit as-is with runtime variable references left as placeholders
- `fragment_static` node — compile referenced file recursively, splice result
- `fragment_dynamic` node — leave as a named placeholder

**Cache implementation:**
Use ETS for all three caches. Structural cache key is a hash of prompt name
+ version + compile-time params map. Fragment cache key is fragment path +
version + params hash. Vary cache key is prompt name + vary name + branch id.

**Vary compositor:**
After structural compilation, scan output string for vary slot markers.
For each marker, look up branch content in vary cache using seed or random.
Replace marker with branch content. This is pure string replacement — no
parsing needed at this stage.

**File watcher:**
Use the `file_system` hex package. Watch the prompts directory. On any
`.prompt` file change, invalidate all cache entries whose key includes
that file path, then recompile and re-cache.

**HTTP API:**
Use Phoenix in `dot_prompt_server`. The API router lives at `/api`.
All endpoints accept and return JSON. Errors return HTTP 422 with an
error object containing `error`, `message`, `file`, and `line` fields.

**MCP server:**
Implement as a Mix task `mix dot_prompt.mcp`. Reads JSON-RPC from stdin,
writes responses to stdout. Register tools: `prompt_schema`,
`collection_schema`, `prompt_list`, `collection_list`, `prompt_compile`.
Each tool delegates to the `DotPrompt` module functions.
