# dot-prompt Specification
**Version 1.1 — Language Update**

A compiled domain-specific language for authoring structured LLM prompts.
dot-prompt compiles to a clean, flat prompt string. The LLM receives only
the resolved output — no syntax artifacts, no untaken branches, no dead weight.

dot-prompt never makes LLM calls. It returns a string. What the caller
does with that string is entirely their concern.

---

## What Changed in v1.1

Applied to the already implemented v1.0 codebase:

1. `@` means variable and only variable — structural keywords never use `@`
2. `init do / end init` — not `@init do / end @init`
3. `docs do / end docs` — not `@docs do / end @docs`
4. `vary` requires an enum variable — no unnamed vary blocks
5. `vary` closes with `end @variable` — consistent with all control flow
6. Named vary branches — `formal:` not `a:`
7. `vary` accepts single optional `seed:` — `seeds:` plural removed entirely
8. One seed drives all vary blocks — hashed against vary variable name internally
9. Default values on params using `=` — `@answer_depth: enum[shallow, medium, deep] = medium`
28. `matchRe: pattern` — compile-time regex, supports `@variable` interpolation (enum variables only)
10. Multiline `->` documentation using indented continuation
11. `@version` promoted to top level of `init` block — out of `def:`
12. No `@system` / `@user` blocks — caller decides how to split the string
14. No `@const` — model config is outside dot-prompt boundary
15. No reserved variable names — author names everything
16. No `@note` — covered by `#` and `docs`
17. No `when` — keep `if` and `case`
18. No `@include` — fragments cover all composition needs
19. No `seeds:` plural in API — only `seed:` singular
20. No `skills:` block in `_index.prompt` — folder structure is the registry
21. No select rules in `_index.prompt` — assembly rules live in calling prompt
22. No `order: random` in fragments — random selection belongs in `vary`
23. No dynamic regex matching — callers preprocess before calling dot-prompt
24. No trailing `/` on folder paths — compiler resolves file vs folder automatically
25. `list[...]` and `enum[...]` — members declared inline, no `list[str]` or `list[enum]`
26. `enum` single value → one fragment, `list` multiple values → composited fragments
27. `match: @variable` — exact match against fragment `def.match` field
28. `matchRe: pattern` — compile-time regex, supports `@variable` interpolation (enum variables only)
29. `match: all` — returns every fragment in folder
30. `limit: n`, `order: ascending / descending` — assembly rules in calling prompt only
31. `_index.prompt` declares folder metadata and params only — no assembly rules

---

## What It Is

dot-prompt is a deterministic structural reducer. It shapes one prompt for
one LLM call. It is not a workflow engine, state machine, or conversation
manager. dot-prompt never makes LLM calls — it returns a compiled string.
The caller decides what to do with it.

| Layer | Responsibility |
|-------|---------------|
| dot-prompt | Shape one prompt deterministically, return a string |
| State machine | Orchestrate multiple prompt calls and conversation flow |
| Caller | Make the LLM call, handle the response |

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
│       │       ├── api/
│       │       │   ├── router.ex
│       │       │   └── controllers/
│       │       │       ├── compile_controller.ex
│       │       │       ├── render_controller.ex
│       │       │       └── schema_controller.ex
│       │       ├── mcp/
│       │       │   ├── server.ex
│       │       │   └── tools/
│       │       │       ├── schema.ex
│       │       │       ├── compile.ex
│       │       │       └── list.ex
│       │       └── viewer/
│       │           ├── live/
│       │           │   ├── viewer_live.ex
│       │           │   └── stats_live.ex
│       │           └── router.ex
│       └── mix.exs
│
├── Dockerfile
├── docker-compose.yml
├── mix.exs
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
{:dot_prompt, "~> 1.1"}
```

```bash
# All other languages — container
docker run -v ./prompts:/prompts -p 4040:4040 -p 4041:4041 dotprompt/server
```

---

## Sigils — Final

| Sigil | Meaning | Example |
|-------|---------|---------|
| `@name` | Variable — always and only | `@skill_name`, `@pattern_step` |
| `{}` | Static fragment — cached | `{skill_context}` |
| `{{}}` | Dynamic fragment — fetched fresh | `{{user_history}}` |
| `#` | Comment — never reaches LLM | `# this is a note` |
| `->` | Documentation — surfaces via MCP | `@skill_name: str -> the NLP skill` |

`@` means variable. Everywhere. Always. No exceptions.
Structural keywords — `init`, `docs`, `if`, `case`, `vary`, `else`, `elif`,
`end`, `def`, `params`, `fragments`, `select` — never use `@`.

---

## Keywords — Final

**Structural:**
| Keyword | Role |
|---------|------|
| `init` | File setup block |
| `docs` | Documentation block inside init |
| `def` | Metadata section inside init |
| `params` | Variable declarations inside init |
| `fragments` | Fragment declarations inside init |
| `select` | Collection selection rules inside _index |

**Control flow:**
| Keyword | Role |
|---------|------|
| `if` | Conditional block |
| `elif` | Chained condition |
| `else` | Fallback branch |
| `case` | Deterministic branch selection |
| `vary` | Seeded or random branch selection — requires enum variable |
| `end` | Closes any block |
| `do` | Opens any block |

**Condition operators:**
| Keyword | Meaning |
|---------|---------|
| `is` | Equality |
| `not` | Inequality |
| `above` | Greater than |
| `below` | Less than |
| `min` | Greater than or equal |
| `max` | Less than or equal |
| `between` | Range — used as `between x and y` |
| `and` | Range separator — only inside `between x and y` |

**Types:**
| Keyword | Domain | Lifecycle |
|---------|--------|-----------|
| `str` | Infinite | Runtime |
| `int` | Infinite | Runtime |
| `int[a..b]` | Finite | Compile-time |
| `bool` | Finite | Compile-time |
| `enum[...]` | Finite | Compile-time — single value |
| `list[...]` | Finite | Compile-time — multiple values |

**Fragment assembly:**
| Keyword | Role |
|---------|------|
| `static` | Fixed cacheable fragment |
| `dynamic` | Live fetched fragment |
| `from` | Fragment source path — file or folder |
| `match` | Exact match against fragment `def.match` field |
| `matchRe` | Compile-time regex match — enum variables only — supports `@variable` interpolation |
| `all` | Match every fragment in folder |
| `limit` | Cap number of matched fragments |
| `order` | `ascending` or `descending` |

---

## File Structure

Every `.prompt` file has two parts:

```
init do
  ...metadata, params, fragments, docs...
end init

...prompt body...
```

`init` uses the same `do / end name` convention as all other blocks.
No file separators required. Everything outside `init` is prompt body.
`init` must appear at the top of the file.

---

## Init Block

```
init do
  @version: 1

  def:
    mode: explanation
    description: Teacher mode — explanation phase with dynamic depth control.

  params:
    @skill_names: list[Milton Model, Meta Model, Anchoring, Reframing]
      -> skills to load — matched against skills collection
    @pattern_step: int[1..5] = 1 -> current step in the teaching sequence
    @variation: enum[analogy, recognition, story] = analogy
      -> teaching track
    @answer_depth: enum[shallow, medium, deep] = medium -> depth of question answers
    @if_input_mode_question: bool = false -> true when user has asked a question
    @user_input: str -> the user's current message
    @user_level: enum[beginner, intermediate, advanced] = intermediate
      -> user experience level

  fragments:
    {skill_context}: static from: skills
      match: @skill_names
      -> loads and composites all matching skill definitions
    {{user_history}}: dynamic -> recent conversation history for context

  docs do
    Teaches NLP skills using a structured multi-turn pattern.
    Variation track is selected once per session and held constant.
    Increment @pattern_step each turn.
    Set @if_input_mode_question true when user asks an off-pattern question.
    @skill_names must exist as .prompt files in the skills folder.
  end docs

end init
```

### @version

Top level field in `init`. Used in cache keys and telemetry.
Increment when the prompt changes to invalidate cached compiled templates.

```
init do
  @version: 3
  ...
end init
```

### def:

| Field | Purpose |
|-------|---------|
| `mode` | Prompt mode identifier — informational |
| `description` | Human readable description |

### params:

All variables declared here. Type determines lifecycle.
Default values use `=` after the type declaration. Parser reads string defaults to end of line, no quotes required.
Documentation uses `->` — inline or multiline with indented continuation.

```
params:
  @answer_depth: enum[shallow, medium, deep] = medium -> depth of question answers
  @skill_names: list[Milton Model, Meta Model]
    -> skills to load
       must exist in the skills collection
       matched exactly against fragment def.match fields
  @user_input: str -> the user's current message — no default, always required
```

### fragments:

Declares all external content. Assembly rules live here, not in `_index.prompt`.

```
fragments:
  # Single file — path resolves to a file
  {rules}: static from: shared/rules.prompt

  # Collection — path resolves to a folder with _index.prompt
  # enum single value — returns one fragment
  {primary_skill}: static from: skills
    match: @primary_skill

  # Collection — list multiple values — returns composited fragments
  {skill_context}: static from: skills
    match: @skill_names

  # Collection — regex match — compile-time only
  {milton_variants}: static from: skills
    matchRe: Milton.*
    limit: 3
    order: ascending

  # Collection — all fragments in folder
  {all_examples}: static from: examples
    match: all
    order: ascending

  # Dynamic — fetched fresh each request, not cached
  {{user_history}}: dynamic -> recent conversation history
```

### docs:

Free text documentation. Surfaces through MCP `prompt_schema` calls.

```
docs do
  Teaches NLP skills using a structured multi-turn pattern.
  Variation track selected once per session and held constant.
end docs
```

---

## Fragment Collections

Any folder with an `_index.prompt` is a collection.
The `_index.prompt` declares the folder metadata and params.
Assembly rules are declared in the calling prompt — not in `_index.prompt`.
 
| Rule | Syntax | Requirement |
|------|--------|-------------|
| Exact match | `match: @variable` | `enum` or `list` |
| Regex match | `matchRe: @variable` | `enum` only — compile-time check |
| All | `match: all` | none |
| Limit | `limit: n` | `integer` |
| Order | `order: ascending / descending` | — |

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
init do
  @version: 1

  def:
    mode: collection
    description: NLP skills collection

  docs do
    Each .prompt file in this folder declares its match field in def.
    Add new skills by dropping a file in with the correct match value.
    No code changes or registry updates needed.
  end docs

end init
```

No assembly rules. No skills registry. Just metadata and docs.

### Individual fragment file

```
init do
  @version: 1

  def:
    mode: fragment
    description: Milton Model skill definition
    match: Milton Model

  params:
    @skill_names: list[Milton Model] -> passed from parent prompt
end init

The Milton Model is a set of language patterns derived from...
```

The `match` field in `def:` is what the calling prompt matches against.
It is a plain string. The calling prompt's `match:` or `matchRe:` finds it.

---

## Prompt Body

Plain prose with inline variable references and control flow blocks.
Indentation has no semantic meaning. Maximum nesting depth is 3 levels.
Only finite domain variables can appear in control flow conditions.

### Comments

```
# This section handles question interruptions — stripped, never reaches LLM
if @if_input_mode_question is true do
...
end @if_input_mode_question
```

### Variable References

Runtime variables injected at call time — left as placeholders after compile:

```
You are teaching @user_level students about @skill_names.

@user_input
```

### Fragment References

```
# Static — compiled from another .prompt file, cached
{skill_context}

# Dynamic — fetched fresh each request
{{user_history}}
```

---

## Control Flow

All blocks open with `do` and close with `end @variable` or `end keyword`.
Indentation is optional. Maximum nesting depth is 3 levels.

### If

Evaluates a finite domain variable. Natural language conditions.

```
if @if_input_mode_question is true do
STOP TEACHING FLOW. Answer the user's question directly.

elif @pattern_step is 1 do
This is the opening step. Introduce yourself briefly.

else
Continue the normal teaching flow.
end @if_input_mode_question
```

Full condition reference:

| Syntax | Meaning | Types |
|--------|---------|-------|
| `if @var is x do` | equality | `bool`, `enum`, `int[a..b]` |
| `if @var not x do` | inequality | `enum`, `int[a..b]` |
| `if @var above x do` | greater than | `int[a..b]` |
| `if @var below x do` | less than | `int[a..b]` |
| `if @var min x do` | greater than or equal | `int[a..b]` |
| `if @var max x do` | less than or equal | `int[a..b]` |
| `if @var between x and y do` | inclusive range | `int[a..b]` |

### Case

Deterministic branch selection. Caller always provides the value.
Optional title after `:` compiles through to LLM.
Prefix title with `#` to keep as author documentation only.

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

Non-deterministic branch selection. Requires an enum variable.
Runtime randomizes selection unless a seed is provided.
Caller never manages which branch was selected — dot-prompt handles it.
Named branches — descriptive words not single letters.

```
@intro_style: enum[formal, curious, story] = formal -> opening style, selected by runtime

vary @intro_style do
formal: Begin with a structured overview of what we will cover.
curious: Begin with a question that creates productive curiosity.
story: Begin with a brief story that illustrates the concept.
end @intro_style
```

**Seeding:**

One optional seed drives all vary blocks in the prompt.
The seed is hashed against each vary variable name to produce
independent selections per block from a single seed value.

```elixir
# No seed — runtime picks randomly for each vary block
DotPrompt.compile("concept_explanation", params)

# Single seed — deterministic, reproducible, cacheable
DotPrompt.compile("concept_explanation", params, seed: 42)
```

Via HTTP API:
```json
{ "seed": 42 }
```

### Nested Case — Variation Tracks

`case @variation` outside, `case @pattern_step` inside.
Each variation track is a coherent narrative arc.
Track titles prefixed with `#` are author docs only — do not compile through.
Step titles without `#` compile through to the LLM.

```
case @variation do
analogy: #Analogy Track
case @pattern_step do
1: Opening Anchor
Introduce @skill_names with a single real-world analogy.
Do not define it formally yet. Let the analogy do the work.

2: Deepening the Frame
Build on the analogy from step 1. Layer in the formal
definition of @skill_names without abandoning the analogy.

3: Concrete Examples
Give 2 examples of @skill_names in real conversation.
First obvious, second subtle. Ask which felt more natural.
end @pattern_step

recognition: #Recognition Track
case @pattern_step do
1: Opening Anchor
Open with a question that makes the user realise they
already use @skill_names without knowing it.

2: Deepening the Frame
Return to the user's own recognition from step 1.
Use their words to introduce the formal framing.

3: Concrete Examples
Ask the user to generate their own example first.
Then offer one refinement and one contrast.
end @pattern_step

story: #Story Track
case @pattern_step do
1: Opening Anchor
Start with a brief story where @skill_names changed
the outcome of a conversation.

2: Deepening the Frame
Extend the story. Show how @skill_names was operating
beneath the surface the whole time.

3: Concrete Examples
Show @skill_names being used poorly then well.
Ask what changed.
end @pattern_step

end @variation
```

**Compiled output** for `variation: recognition`, `pattern_step: 2`:

```
Deepening the Frame
Return to the user's own recognition from step 1.
Use their words to introduce the formal framing.
```

---

## Compilation Pipeline

Compilation is lazy — on demand per request, not pre-computed.
Three independent cache layers maximise reuse.

```
Request arrives with compile-time params (+ optional seed)
      │
      ▼
  [Stage 1] Validate
            check all compile-time @params against declared types
            validate enum/list values against declared members
            check int[a..b] values within bounds
            apply defaults for any missing params with default values
            STOP on any error — never silent
            error includes: file, line, variable name, descriptive message

      │
      ▼
  [Stage 2] Resolve if/case control flow
            vary blocks left as named slots — not resolved yet
            ──────────────────────────────────────────────
            STRUCTURAL CACHE
            key   = prompt name + @version + compile-time params hash
            value = resolved skeleton with vary slots intact
            ──────────────────────────────────────────────

      │
      ▼
  [Stage 3] Expand fragments
            static {} — compile referenced .prompt files with passed params
            collections — resolve _index.prompt, apply calling prompt assembly rules
            match/matchRe/all → select files → compile each → composite in order
            ──────────────────────────────────────────────
            STATIC FRAGMENT CACHE
            key   = fragment path + @version + passed params hash
            value = compiled fragment content
            preloadable at application startup
            ──────────────────────────────────────────────
            dynamic {{}} — fetch fresh each request, not cached
            only fragments in surviving branch are fetched

      │
      ▼
  [Stage 4] Resolve vary slots
            for each vary slot in structural skeleton:
              if seed provided: hash(seed + vary_variable_name) → branch index
              if no seed: random branch selection
            composite selected branches into skeleton — pure string replacement
            ──────────────────────────────────────────────
            VARY BRANCH CACHE
            key   = prompt name + vary variable name + branch name
            value = branch content
            preloadable at application startup
            ──────────────────────────────────────────────

      │
      ▼
  [Stage 5] Inject runtime @variables
            fill runtime variable placeholders just before LLM call

      │
      ▼
  Final prompt string → caller → LLM call (caller's responsibility)
```

### Cache Summary

| Cache | Key | Cacheable | Preloadable |
|-------|-----|-----------|-------------|
| Structural | prompt + version + compile-time params | Always | No |
| Static fragment | fragment path + version + params | Always | Yes |
| Vary branch | prompt + vary variable + branch name | Always | Yes |
| Dynamic fragment | — | Never | No |

### Dev vs Prod Mode

```
Dev:   full parse → compile → inject on every request
       no caching — prompt files reloaded on every change via file watcher

Prod:  Stage 1 → check structural cache
       hit:  Stage 3 (dynamic only) → Stage 4 → Stage 5
       miss: Stage 2 → Stage 3 → Stage 4 → cache → Stage 5
```

---

## Error Handling

Compiler stops immediately on any error. Never silent.
Every error includes file name, line number, variable name, and message.

| Error | Example message |
|-------|----------------|
| `unknown_variable` | `@skill_level referenced but not declared — concept_explanation.prompt line 24` |
| `out_of_range` | `@pattern_step value 7 out of range int[1..5] — line 12` |
| `invalid_enum` | `@variation value fast not in enum[analogy, recognition, story] — line 8` |
| `invalid_list` | `@skill_names value Unknown Skill not in list — line 9` |
| `invalid_matchre_type`| `matchRe requires enum variable, but @var is str — line 24` |
| `missing_param` | `@answer_depth required but not provided — no default declared` |
| `unclosed_block` | `if @if_input_mode_question do opened at line 31 — no matching end` |
| `mismatched_end` | `end @answer_depth at line 45 — expected end @if_input_mode_question` |
| `nesting_exceeded` | `nesting depth 4 at line 67 — maximum is 3` |
| `unknown_vary` | `seed provided but no vary blocks found in prompt` |
| `missing_fragment` | `shared/rules.prompt not found` |
| `missing_index` | `skills folder has no _index.prompt` |
| `collection_no_match` | `no fragments matched Milton Modelx in skills` |

---

## HTTP API

Container exposes REST API on port 4041.

### POST /api/compile

```json
// Request
{
  "prompt": "concept_explanation",
  "params": {
    "pattern_step": 2,
    "variation": "recognition",
    "answer_depth": "medium",
    "if_input_mode_question": false,
    "skill_names": ["Milton Model", "Meta Model"]
  },
  "seed": 42
}

// Response
{
  "template": "You are teaching @user_level students...",
  "cache_hit": true,
  "compiled_tokens": 312,
  "vary_selections": {
    "intro_style": "curious",
    "closing_style": "exercise"
  }
}
```

### POST /api/inject

```json
// Request
{
  "template": "You are teaching @user_level students...",
  "runtime": {
    "user_input": "Can you give me an example?",
    "user_level": "intermediate"
  }
}

// Response
{
  "prompt": "You are teaching intermediate students...",
  "injected_tokens": 387
}
```

### POST /api/render

```json
// Request
{
  "prompt": "concept_explanation",
  "params": {
    "pattern_step": 2,
    "variation": "recognition",
    "answer_depth": "medium",
    "if_input_mode_question": false,
    "skill_names": ["Milton Model"]
  },
  "runtime": {
    "user_input": "Can you give me an example?",
    "user_level": "intermediate"
  },
  "seed": 42
}

// Response
{
  "prompt": "You are teaching intermediate students...",
  "cache_hit": true,
  "compiled_tokens": 312,
  "injected_tokens": 387,
  "vary_selections": {
    "intro_style": "curious"
  }
}
```

### GET /api/schema/:prompt

```json
{
  "name": "concept_explanation",
  "version": 1,
  "description": "Teacher mode — explanation phase with dynamic depth control.",
  "params": {
    "skill_names": {
      "type": "list",
      "members": ["Milton Model", "Meta Model", "Anchoring", "Reframing"],
      "lifecycle": "compile",
      "default": null,
      "doc": "skills to load — matched against skills collection"
    },
    "pattern_step": {
      "type": "int",
      "range": [1, 5],
      "lifecycle": "compile",
      "default": 1,
      "doc": "current step in the teaching sequence"
    },
    "variation": {
      "type": "enum",
      "members": ["analogy", "recognition", "story"],
      "lifecycle": "compile",
      "default": null,
      "doc": "teaching track"
    },
    "answer_depth": {
      "type": "enum",
      "members": ["shallow", "medium", "deep"],
      "lifecycle": "compile",
      "default": "medium",
      "doc": "depth of question answers"
    },
    "if_input_mode_question": {
      "type": "bool",
      "lifecycle": "compile",
      "default": false,
      "doc": "true when user has asked a question"
    },
    "user_input": {
      "type": "str",
      "lifecycle": "runtime",
      "default": null,
      "doc": "the user's current message"
    },
    "user_level": {
      "type": "enum",
      "members": ["beginner", "intermediate", "advanced"],
      "lifecycle": "runtime",
      "default": "intermediate",
      "doc": "user experience level"
    }
  },
  "fragments": {
    "skill_context": {
      "type": "static",
      "from": "skills",
      "match": "@skill_names",
      "doc": "loads and composites all matching skill definitions"
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

Lists all available `.prompt` files with name, version, description.

### GET /api/collections

Lists all folders with `_index.prompt` with name, version, description.

---

## Telemetry

Library emits events. Host application attaches handlers and stores.

```elixir
:telemetry.execute(
  [:dot_prompt, :render, :stop],
  %{compiled_tokens: 312, injected_tokens: 387, duration_ms: 12},
  %{
    prompt: "concept_explanation",
    version: 1,
    params: %{variation: :recognition, pattern_step: 2},
    vary_selections: %{intro_style: :curious},
    cache_hit: true
  }
)

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
DotPrompt.schema("skills")

# Compile
template = DotPrompt.compile("concept_explanation", %{
  pattern_step: 2,
  variation: :recognition,
  answer_depth: :medium,
  if_input_mode_question: false,
  skill_names: ["Milton Model", "Meta Model"]
}, seed: 42)

# Inject
prompt = DotPrompt.inject(template, %{
  user_input: "Can you give me an example?",
  user_level: "intermediate"
})

# Render — compile and inject in one call
prompt = DotPrompt.render("concept_explanation",
  %{
    pattern_step: 2,
    variation: :recognition,
    answer_depth: :medium,
    if_input_mode_question: false,
    skill_names: ["Milton Model"]
  },
  %{
    user_input: "Can you give me an example?",
    user_level: "intermediate"
  },
  seed: 42
)
```

---

## Python Client

Thin HTTP wrapper. No parser, no compiler.

```python
from dot_prompt import Client

client = Client("http://localhost:4041")

prompt = client.render(
    "concept_explanation",
    params={
        "pattern_step": 2,
        "variation": "recognition",
        "answer_depth": "medium",
        "if_input_mode_question": False,
        "skill_names": ["Milton Model"]
    },
    runtime={
        "user_input": "Can you give me an example?",
        "user_level": "intermediate"
    },
    seed=42
)

schema = client.schema("concept_explanation")
prompts = client.list_prompts()
collections = client.list_collections()
```

---

## MCP Server

Stdio mode — spawned on demand by MCP client, no persistent port.

```json
{
  "dot-prompt": {
    "command": "docker",
    "args": ["exec", "-i", "dot-prompt", "mix", "dot_prompt.mcp"]
  }
}
```

**Tools:**

| Tool | Purpose |
|------|---------|
| `prompt_schema` | Returns params, fragments, docs for a prompt |
| `collection_schema` | Returns metadata and params for a collection |
| `prompt_list` | Lists all available prompt files |
| `collection_list` | Lists all available collections |
| `prompt_compile` | Compiles a prompt with given params for preview |

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
init do
  @version: 1

  def:
    mode: explanation
    description: Teacher mode — explanation phase with dynamic depth control.

  params:
    @skill_names: list[Milton Model, Meta Model, Anchoring, Reframing]
      -> skills to load — matched against skills collection
    @pattern_step: int[1..3] = 1 -> current step in the teaching sequence
    @variation: enum[analogy, recognition, story] = analogy
      -> teaching track — selected once per session
    @answer_depth: enum[shallow, medium, deep] = medium -> depth of question answers
    @if_input_mode_question: bool = false -> true when user has asked a question
    @user_input: str -> the user's current message
    @user_level: enum[beginner, intermediate, advanced] = intermediate
      -> user experience level
    @intro_style: enum[formal, curious, story] = curious
      -> opening variation — selected by runtime
    @closing_style: enum[exercise, reflection] = exercise
      -> closing variation — selected by runtime

  fragments:
    {skill_context}: static from: skills
      match: @skill_names
      -> loads and composites all matching skill definitions
    {{user_history}}: dynamic -> recent conversation history for context

  docs do
    Teaches NLP skills using a structured multi-turn pattern.
    @variation and @intro_style selected once at session start and held constant.
    Increment @pattern_step each turn.
    Set @if_input_mode_question true when user asks an off-pattern question.
  end docs

end init

# ROLE
You are Milton, an expert NLP trainer teaching @user_level students.
Your job is to teach @skill_names efficiently using structured teaching patterns.

vary @intro_style do
formal: Begin with a structured overview of what we will cover today.
curious: Begin with a question that creates productive curiosity.
story: Begin with a brief story that illustrates why this skill matters.
end @intro_style

if @if_input_mode_question is true do

# Question mode — interrupts teaching flow
STOP TEACHING FLOW. Answer the user's question directly.

The user asked: @user_input

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

Respond with this JSON:
{
  "response_type": "question_answer",
  "content": "your response here",
  "ui_hints": {
    "show_answer_input": false,
    "show_success": false,
    "show_failure": false
  }
}

else

# Teaching mode — normal step progression
case @variation do
analogy: #Analogy Track
case @pattern_step do
1: Opening Anchor
Introduce @skill_names with a single real-world analogy.
Do not define it formally yet. Let the analogy do the work.
2: Deepening the Frame
Build on the analogy from step 1. Layer in the formal definition.
3: Concrete Examples
Give 2 examples of @skill_names. First obvious, second subtle.
end @pattern_step

recognition: #Recognition Track
case @pattern_step do
1: Opening Anchor
Open with a question that makes the user realise they already use @skill_names.
2: Deepening the Frame
Return to the user's own recognition. Use their words to introduce the formal framing.
3: Concrete Examples
Ask the user to generate their own example first. Then offer one refinement.
end @pattern_step

story: #Story Track
case @pattern_step do
1: Opening Anchor
Start with a brief story where @skill_names changed the outcome of a conversation.
2: Deepening the Frame
Extend the story. Show how @skill_names was operating beneath the surface.
3: Concrete Examples
Show @skill_names being used poorly then well. Ask what changed.
end @pattern_step

end @variation

@user_input

vary @closing_style do
exercise: End with a practical exercise for the user to try in their next conversation.
reflection: End with a reflective question that deepens the learning.
end @closing_style

Respond with this JSON:
{
  "response_type": "teaching",
  "content": "your response here",
  "ui_hints": {
    "show_answer_input": true,
    "show_success": false,
    "show_failure": false
  }
}

end @if_input_mode_question
```

---

## Control Flow Reference — Final

| Syntax | Behaviour | Requirement | Closes with |
|--------|-----------|-------------|-------------|
| `init do` | File setup block | Must be first | `end init` |
| `docs do` | Documentation inside init | Inside init only | `end docs` |
| `if @var is x do` | Equality condition | `bool`, `enum`, `int[a..b]` | `end @var` |
| `if @var not x do` | Inequality | `enum`, `int[a..b]` | `end @var` |
| `if @var above x do` | Greater than | `int[a..b]` | `end @var` |
| `if @var below x do` | Less than | `int[a..b]` | `end @var` |
| `if @var min x do` | Greater than or equal | `int[a..b]` | `end @var` |
| `if @var max x do` | Less than or equal | `int[a..b]` | `end @var` |
| `if @var between x and y do` | Inclusive range | `int[a..b]` | `end @var` |
| `elif @var is x do` | Chained condition | same as if | — |
| `else` | Fallback branch | — | — |
| `case @var do` | Deterministic selection | `enum` or `int[a..b]` | `end @var` |
| `vary @var do` | Random or seeded selection | `enum` — required | `end @var` |

All blocks use `do` to open.
Indentation is optional and has no semantic meaning.
Maximum nesting depth is 3 levels.
`@` means variable — always and only.
Structural keywords never use `@`.

---

## Implementation Notes for LLM

**What changed from v1.0 — parser updates needed:**

1. `@init` → `init`, `@docs` → `docs` — update lexer keyword list
2. `vary` now always has a variable — `vary @var do / end @var` — update vary parser rule
3. Named vary branches — branch labels are words not single letters
4. `seeds:` removed from API and compile call — only `seed:` singular
5. Default values — parse `= value` after type declaration in params. String values read to end of line without quotes.
6. Multiline `->` — continuation lines indented under param declaration
7. Fragment assembly rules — `match`, `matchRe`, `match: all`, `limit`, `order` parsed from fragment declarations in init
8. `_index.prompt` — no longer has `skills:` or `select:` blocks — just `init` with `def` and `docs`
9. Fragment paths — no trailing `/` — compiler checks if path is file or directory
10. `@version` — top level field in init, not nested under `def:`
11. Collection assembly — rules come from calling prompt `fragments:` block, not from `_index.prompt`
12. `response` block removed — JSON written directly as prose in prompt body

**Vary compositor update:**
Vary variable name is now the slot identifier not a positional name.
Seed hashing: `hash(seed <> vary_variable_name)` → branch index within branch count.
Branch lookup uses branch name not letter index.

**Fragment expander update:**
When path resolves to directory: load `_index.prompt`, read its params,
then apply assembly rules from the calling prompt's fragment declaration.
`match: @var` — resolve var value, match against fragment `def.match` fields exactly.
12. `matchRe: pattern` — compile regex, interpolate `@var` references (enum variables only), match against `def.match` fields.
13. `match: all` — return all `.prompt` files in folder except `_index.prompt`.
Apply `limit` and `order` after matching.
Composite matched fragments in order — join with double newline.
```
