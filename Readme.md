<!-- fullWidth: false tocVisible: false tableWrap: true -->
# dot-prompt

A compiled language for LLM prompts. Define structure, branching, and contracts in `.prompt` files — ship clean prompts to your LLM.

---

## The Problem

Every team building with LLMs ends up in the same place. Prompts scattered across the codebase as f-strings, markdown files, or YAML configs. Branching logic tangled into application code. No versioning. No contracts. No tooling. Token waste invisible. The LLM receives everything — including all the logic you meant to resolve before the call.

```python
# What most teams end up with
prompt = f"""
You are a {role}.
{"Answer the question directly." if is_question else "Continue the lesson."}
{"Give a short answer." if depth == "shallow" else "Give a detailed answer."}
Here is the context: {context}
The user said: {user_message}
"""
```

This works until it doesn't. Then it's very hard to fix.

---

## The Solution

`.prompt` files are compiled before they reach the LLM. Branching resolves at compile time. The LLM receives a clean, flat string with zero logic residue.

```
init do
  @version: 1.0
  @major: 1

  def:
    mode: explanation
    description: Teacher mode — explanation phase.

  params:
    @pattern_step: int[1..5] = 1 -> current step in the teaching sequence
    @variation: enum[analogy, recognition, story]
      -> teaching track — required, selected once per session
    @answer_depth: enum[shallow, medium, deep] = medium -> depth of answers
    @if_input_mode_question: bool = false
      -> true when user has asked an off-pattern question
    @user_input: str -> the user's current message
    @user_level: enum[beginner, intermediate, advanced] = intermediate

  fragments:
    {skill_context}: static from: skills
      match: @skill_names

end init

if @if_input_mode_question is true do
STOP TEACHING. Answer the user's question directly.

The user asked: @user_input

case @answer_depth do
shallow: Shallow Answer
1-2 sentences answering exactly what they asked.

medium: Medium Answer
Explanation + 1 relevant example.

deep: Deep Answer
Full explanation with multiple examples.
end @answer_depth

response do
  {
    "response_type": "question_answer",
    "content": "your response here",
    "ui_hints": { "show_answer_input": false }
  }
end response

else

case @variation do
analogy: #Analogy Track
case @pattern_step do
1: Opening Anchor
Introduce the concept with a single real-world analogy.
2: Deepening the Frame
Build on the analogy. Layer in the formal definition.
3: Concrete Examples
Give 2 examples. First obvious, second subtle.
end @pattern_step

recognition: #Recognition Track
case @pattern_step do
1: Opening Anchor
Open with a question that makes the user realise they already use this concept.
2: Deepening the Frame
Return to their recognition. Use their words to introduce the formal framing.
3: Concrete Examples
Ask the user to generate their own example first.
end @pattern_step
end @variation

@user_input

response do
  {
    "response_type": "teaching",
    "content": "your response here",
    "ui_hints": { "show_answer_input": true }
  }
end response

end @if_input_mode_question
```

**What the LLM receives** for `variation: recognition`, `pattern_step: 2`, `answer_depth: medium`, `if_input_mode_question: false`:

```
Deepening the Frame
Return to their recognition. Use their words to introduce the formal framing.

[user message]

Respond with this JSON:
{
  "response_type": "teaching",
  "content": "your response here",
  "ui_hints": { "show_answer_input": true }
}
```

No branching. No logic. No dead weight. Just the instruction the LLM needs.

---

## Features

**Compiled language** — branching resolves before the LLM call. `if`, `case`, and `vary` blocks compile away entirely. The LLM never sees them.

**Input and output contracts** — params declare the input contract. `response` blocks declare the output contract. Both are versioned together. Breaking changes are detected automatically.

**Fragment composition** — `.prompt` files compose. Static fragments are cached. Dynamic fragments are fetched fresh. Collections load multiple fragments from a folder and composite them.

**Variation tracks** — `vary` blocks select branches randomly or by seed. One seed drives all vary blocks in a prompt deterministically.

**Semantic versioning** — `@major` pins the contract version. Callers pin to a major version and receive non-breaking updates automatically. Old major versions are served from `archive/` for callers that have not upgraded.

**Breaking change detection** — the container detects breaking contract changes on every save. Prompts the developer to version before committing. Hard warning at git commit if unversioned breaking changes exist.

**Snapshot safety** — the container snapshots every `.prompt` file before the first edit after a commit. LLM agents can edit freely — the pre-edit baseline is always preserved for archiving.

**MCP server** — LLM coding tools discover prompt schemas, params, and contracts via MCP without reading raw files.

**Works with any language** — Elixir gets a native library. Everyone else calls the container HTTP API.

---

## How It Works

```
.prompt file + params
        │
        ▼
  [Stage 1] Validate params against declared types
        │
        ▼
  [Stage 2] Resolve if/case — discard untaken branches
            ← structural cache by compile-time params
        │
        ▼
  [Stage 3] Expand fragments — compile static, fetch dynamic
            ← fragment cache by path + params
        │
        ▼
  [Stage 4] Resolve vary slots — seed or random selection
            ← vary branch cache preloaded at startup
        │
        ▼
  [Stage 5] Inject runtime variables
        │
        ▼
  DotPrompt.Result { prompt: "...", response_contract: %{...} }
```

Three independent cache layers. The structural skeleton is cached by compile-time params. Vary branches are preloaded at startup. Fragment content is cached by path and version. Runtime variables are injected fresh every call.

---

## Runs via container

### Container

```bash
docker run -v ./prompts:/app/priv/prompts \
  -p 4040:4040 -p 4041:4041 \
  dotprompt/server
```

```python
from dot_prompt import Client

client = Client("http://localhost:4041")

result = client.render(
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

result["prompt"]             # compiled string
result["response_contract"]  # derived schema
```

---

## Development Container

The container gives you a full development environment for `.prompt` files:

```bash
# docker-compose.yml
services:
  dot-prompt:
    image: dotprompt/server
    ports:
      - "4040:4040"  # viewer
      - "4041:4041"  # HTTP API
    volumes:
      - .:/app/repo  # mount your app repo
    environment:
      - REPO_PATH=/app/repo
      - PROMPTS_PATH=/app/repo/priv/prompts
```

```bash
# Install post-commit hook once
echo 'curl -s -X POST http://localhost:4040/webhooks/commit' \
  > .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

**What you get:**

- **Viewer** at `localhost:4040` — select params, see compiled output in real time
- **Breaking change detection** — warned on save, notified in VS Code, hard warning on commit
- **Snapshot safety** — pre-edit baseline preserved before any LLM agent can overwrite it
- **Auto-versioning** — minor version bumped on commit, major versioning on your decision
- **Live reload** — file watcher recompiles and invalidates cache on every save
- **MCP server** — connect Kilo Code, Cursor, Claude etc to discover and work with your prompt schemas

---

## Language Reference

### The One Rule

`@` means variable. Always. Only. Everywhere.\
Structural keywords never use `@`.

### Init Block

```
init do
  @major: 1
  @version: 1.0

  def:
    mode: explanation
    description: Human readable description.

  params:
    @name: type = default -> documentation

  fragments:
    {name}: static from: folder_or_file
    {{name}}: dynamic -> fetched fresh each request

  docs do
    Free text documentation. Surfaces via MCP.
  end docs

end init
```

### Types

| Type          | Lifecycle    | Notes                  |
| ------------- | ------------ | ---------------------- |
| `str`         | Runtime      | Cannot drive branching |
| `int`         | Runtime      | Cannot drive branching |
| `int[a..b]`   | Compile-time | Bounded integer        |
| `bool`        | Compile-time |                        |
| `enum[a, b, c]` | Compile-time | Single value           |
| `list[a, b, c]` | Compile-time | Multiple values        |

### Control Flow

```
if @var is x do        # equality
if @var not x do       # inequality
if @var above x do     # greater than
if @var below x do     # less than
if @var min x do       # greater than or equal
if @var max x do       # less than or equal
if @var between x and y do  # inclusive range
elif @var is x do      # chained condition
else                   # fallback
end @var

case @var do           # deterministic branch selection
value: Title
content here
end @var

vary @var do           # random or seeded — enum required
branch_name: content here
end @var
```

### Fragments

```
fragments:
  {single}: static from: skills
    match: @skill           # enum — returns one
  {multi}: static from: skills
    match: @skill_names     # list — returns composited
  {pattern}: static from: skills
    matchRe: @skill_pattern # enum of regex patterns
  {all}: static from: skills
    match: all              # every file in folder
    limit: 10
    order: ascending
  {{live}}: dynamic         # fetched fresh each request
```

### Response Contract

```
response do
  {
    "field": "value",
    "nested": { "bool_field": true }
  }
end response
```

Compiler derives contract schema from JSON structure.\
Multiple response blocks compared across branches — warning if compatible, error if incompatible.

### Sigils

| Sigil    | Meaning                          |
| -------- | -------------------------------- |
| `@name`  | Variable                         |
| `{name}` | Static fragment                  |
| `{{name}}` | Dynamic fragment                 |
| `#`      | Comment — never reaches LLM      |
| `->`     | Documentation — surfaces via MCP |
| `=`      | Default value                    |

---

## Versioning

```
init do
  @major: 1      # contract version — callers pin to this
  @version: 1.3  # major.minor — managed by container
end init
```

**Breaking changes** — removing or renaming params, changing types, removing response fields — require `@major` to increment. The old version is archived. Callers pinned to the old major continue to be served.

**Non-breaking changes** — adding params with defaults, changing docs, internal prompt edits — auto-bump `@minor` on commit. Callers never notice.

**The container manages versioning.** You edit and commit. The container detects what changed, asks if you want to version on breaking changes, and handles archiving automatically.

---

## Folder Structure

```
priv/prompts/
  concept_explanation.prompt  # current — always latest
  practice.prompt
  skills/
    _index.prompt             # collection manifest
    milton_model.prompt
    meta_model.prompt
    archive/
      milton_model_v1.prompt  # old fragment versions
  archive/
    concept_explanation_v1.prompt  # old major — still served
  .snapshots/                 # gitignored — container working dir
```

---

## MCP Server

Connect your LLM coding tool to discover prompt schemas without reading raw files.

```json
{
  "dot-prompt": {
    "command": "docker",
    "args": ["exec", "-i", "dot-prompt", "mix", "dot_prompt.mcp"]
  }
}
```

Available tools: `prompt_schema`, `collection_schema`, `prompt_list`, `collection_list`, `prompt_compile`.

---

## HTTP API

| Method | Endpoint                   | Purpose                               |
| ------ | -------------------------- | ------------------------------------- |
| `POST` | `/api/compile`             | Resolve control flow, return template |
| `POST` | `/api/inject`              | Fill runtime variables into template  |
| `POST` | `/api/render`              | Compile and inject in one call        |
| `GET`  | `/api/schema/:prompt`      | Schema for latest major version       |
| `GET`  | `/api/schema/:prompt/:major` | Schema for specific major version     |
| `GET`  | `/api/prompts`             | List all prompt files                 |
| `GET`  | `/api/collections`         | List all collections                  |
| `GET`  | `/api/events`              | SSE stream for VS Code integration    |
| `POST` | `/api/version`             | Trigger version action                |
| `POST` | `/webhooks/commit`         | Post-commit hook receiver             |

---

## License

Apache 2.0