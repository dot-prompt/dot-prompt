# dotprompt-client

Python client for [dotprompt](https://dotprompt.run) — a compiled language for LLM prompts.

[![PyPI](https://img.shields.io/pypi/v/dotprompt-client)](https://pypi.org/project/dotprompt-client/)
[![Python Versions](https://img.shields.io/pypi/pyversions/dotprompt-client)](https://pypi.org/project/dotprompt-client/)
[![License](https://img.shields.io/pypi/l/dotprompt-client)](https://github.com/dot-prompt/dot-prompt/blob/main/LICENSE)

---

## What This Is

dotprompt-client connects your Python application to the dotprompt container. The container compiles `.prompt` files — a domain-specific language where branching, fragments, and contracts resolve at compile time. Your LLM receives only the final, flat prompt string with zero logic residue.

**Requires:** [dotprompt/runtime](https://hub.docker.com/r/dotprompt/runtime) or [dotprompt/runtime-dev](https://hub.docker.com/r/dotprompt/runtime-dev) Docker container.

**Website:** [dotprompt.run](https://dotprompt.run)  
**Documentation:** [dotprompt.run/docs](https://dotprompt.run/docs)  
**GitHub:** [github.com/dot-prompt/dot-prompt](https://github.com/dot-prompt/dot-prompt)

---

## Installation

```bash
pip install dotprompt-client
```

For development:

```bash
pip install dotprompt-client[dev]
```

---

## Prerequisites

Run the dotprompt container:

```bash
docker run -v ./prompts:/app/prompts \
  -p 4000:4000 \
  dotprompt/runtime
```

The API runs at `http://localhost:4000` by default.

---

## Quick Start

### Synchronous Client

```python
from dotprompt import DotPromptClient

with DotPromptClient() as client:
    # List all prompts
    prompts = client.list_prompts()
    print(prompts)

    # Compile a prompt with params
    result = client.compile("my_prompt", params={"name": "world"})
    print(result.template)
```

### Async Client

```python
import asyncio
from dotprompt import DotPromptAsyncClient

async def main():
    async with DotPromptAsyncClient() as client:
        prompts = await client.list_prompts()
        result = await client.compile("my_prompt", params={"name": "world"})
        print(result.template)

asyncio.run(main())
```

---

## Full Example: Compile + Render + Validate

```python
from dotprompt import DotPromptClient

with DotPromptClient() as client:
    # Get prompt schema (parameters, types, contracts)
    schema = client.get_schema("teaching_prompt")
    print(f"Params: {schema.params}")

    # Compile: resolve branching, expand fragments, select variations
    compiled = client.compile(
        "teaching_prompt",
        params={
            "pattern_step": 2,
            "variation": "recognition",
            "answer_depth": "medium",
            "skill_names": ["Milton Model"]
        },
        seed=42  # deterministic variation selection
    )
    print(f"Template: {compiled.template}")

    # Render: inject runtime variables into the template
    rendered = client.render(
        "teaching_prompt",
        params={...},  # compile-time params
        runtime={
            "user_input": "Can you give me an example?",
            "user_level": "intermediate"
        }
    )
    print(f"Final prompt: {rendered.prompt}")

    # Validate LLM response against the contract
    response = {"score": 8, "explanation": "Good answer"}
    is_valid = client.validate_response(response, schema.response_contract)
    print(f"Valid: {is_valid}")
```

---

## Configuration

```python
from dotprompt import DotPromptClient

client = DotPromptClient(
    base_url="http://localhost:4000",  # container URL
    timeout=30.0,                      # request timeout in seconds
    verify_ssl=True,                   # verify SSL certificates
    api_key="your-api-key",            # optional API key
    max_retries=3,                     # retry on transient failures
)
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTPROMPT_URL` | `http://localhost:4000` | Container URL |
| `DOTPROMPT_API_KEY` | — | Optional API key |
| `DOTPROMPT_TIMEOUT` | `30` | Request timeout in seconds |

---

## API Reference

### DotPromptClient (sync)

| Method | Returns | Description |
|--------|---------|-------------|
| `list_prompts()` | `list[PromptSchema]` | All available prompts |
| `list_collections()` | `list[Collection]` | Root-level collections |
| `get_schema(prompt)` | `PromptSchema` | Prompt metadata + params |
| `compile(prompt, params, seed, version)` | `CompileResult` | Resolve branching, expand fragments |
| `render(prompt, params, runtime, seed, version)` | `RenderResult` | Full compile + inject |
| `inject(template, runtime)` | `InjectResult` | Inject into raw template |
| `events()` | `generator` | SSE stream for real-time updates |
| `validate_response(response, contract)` | `bool` | Validate against contract |

### DotPromptAsyncClient (async)

Same API as sync client, but all methods are `async`/`await`.

---

## Models

| Model | Description |
|-------|-------------|
| `PromptSchema` | Prompt metadata, params, docs, version |
| `CompileResult` | Compiled template, response contract |
| `RenderResult` | Final prompt, response contract |
| `InjectResult` | Injected template |
| `ResponseContract` | Schema for expected LLM output |
| `CompilationError` | Raised when compilation fails |
| `ValidationError` | Raised when validation fails |

---

## Error Handling

```python
from dotprompt import (
    DotPromptClient,
    ConnectionError,
    TimeoutError,
    PromptNotFoundError,
    ValidationError,
    ServerError,
)

try:
    with DotPromptClient() as client:
        result = client.compile("my_prompt", params={...})
except PromptNotFoundError:
    print("Prompt doesn't exist")
except ValidationError as e:
    print(f"Contract mismatch: {e}")
except ConnectionError:
    print("Container unreachable")
except TimeoutError:
    print("Request timed out")
except ServerError as e:
    print(f"Server error: {e}")
```

---

## Example `.prompt` File

This is what the container compiles from:

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

## License

Apache 2.0 — see [LICENSE](https://github.com/dot-prompt/dot-prompt/blob/main/LICENSE)