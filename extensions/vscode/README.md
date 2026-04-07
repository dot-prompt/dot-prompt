# .prompt — Structured Prompts for LLMs

Author `.prompt` files — a small domain-specific language for writing structured, reusable LLM prompts with variables, conditionals, and branches. The extension compiles them to clean, flat strings ready to send to any model.

---

## Requirements

This extension requires the **dot-prompt runtime** running locally. The runtime is a Phoenix server distributed as a Docker image.

**Start it before using the extension:**

```bash
docker run -d --name dotprompt -p 4040:4040 dotprompt/runtime-dev:latest
```

Or with docker-compose if you have the `dot_prompt` project cloned:

```bash
docker-compose up -d
```

The server runs on `http://localhost:4040`. The extension connects to it automatically.

> Don't have Docker? [Get Docker →](https://docs.docker.com/get-docker/)

---

## Getting Started

1. **Start the runtime** (see above)
2. **Install this extension** from the VS Code marketplace
3. **Create a file** with a `.prompt` extension
4. **Open the Command Palette** (`F1`) and run `.prompt: Compile`

That's it. The compiled output appears in a side panel.

---

## The .prompt Language

A `.prompt` file has two parts: an `init` block that declares your prompt's metadata and parameters, and a body that uses those parameters to produce text.

### A minimal example

```
init do
  @version: 1

  def:
    mode: assistant
    description: A greeting prompt

  params:
    @name: str = World        -> name to greet
    @style: enum[formal, casual] = casual  -> greeting style

end init

vary @style do
formal: Good day, @name.
casual: Hey @name!
end @style
```

Compiled with `@name: Alice`, `@style: casual` → `Hey Alice!`

---

## Language Features

### Parameters

Declare inputs in the `params` block. All variables are prefixed with `@`.

```
@name: str = World               # string with default
@count: int[1..10] = 5          # integer with range
@active: bool = true             # boolean
@role: enum[admin, user] = user  # enum
```

Parameters with no default are **required** at compile time.

### Conditionals

```
if @active is true do
Welcome back!
elif @role is admin do
Admin panel access granted.
else
Please log in.
end @active
```

### Case — deterministic branching

```
case @language do
en: Hello!
es: Hola!
fr: Bonjour!
end @language
```

### Vary — random branching

Use `vary` to randomise between options at runtime (requires an `enum` param):

```
vary @tone do
formal: I am pleased to assist you.
casual: Happy to help!
end @tone
```

### Fragments

Pull in content from other `.prompt` files:

```
{skills}: static from: skills    # cached, matched by name
  match: @skill_names
{{history}}: dynamic              # fetched fresh each request
```

### Comments

Lines starting with `#` are stripped at compile time and never sent to the model.

---

## Commands

| Command | Description |
|---|---|
| `.prompt: Compile` | Compile the current file |
| `.prompt: Open Compiled View` | Open the compiled output panel |

---

## Settings

| Setting | Default | Description |
|---|---|---|
| `dotPrompt.serverUrl` | `http://localhost:4040` | Runtime server URL |
| `dotPrompt.autoCompile` | `true` | Compile automatically on save |

---

## Troubleshooting

**Extension not connecting to the server**
- Confirm Docker is running: `docker ps`
- Test the runtime directly: `curl http://localhost:4040`
- If you're using a different port, update `dotPrompt.serverUrl` in settings

**Extension not activating**
- Make sure your file has a `.prompt` extension
- Reload VS Code: `F1` → *Developer: Reload Window*

---

## Learn More

- [Full Language Reference](https://dotprompt.run/docs) — complete syntax documentation
- [dotprompt.run](https://dotprompt.run) — project home
````
