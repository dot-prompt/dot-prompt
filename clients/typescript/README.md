# @dotprompt/client

TypeScript client for [dotprompt](https://dotprompt.run) — a compiled language for LLM prompts.

[![npm](https://img.shields.io/npm/v/@dotprompt/client)](https://www.npmjs.com/package/@dotprompt/client)
[![Node Versions](https://img.shields.io/node/v/@dotprompt/client)](https://www.npmjs.com/package/@dotprompt/client)
[![License](https://img.shields.io/npm/l/@dotprompt/client)](https://github.com/dot-prompt/dot-prompt/blob/main/LICENSE)

---

## What This Is

@dotprompt/client connects your TypeScript application to the dotprompt container. The container compiles `.prompt` files — a domain-specific language where branching, fragments, and contracts resolve at compile time. Your LLM receives only the final, flat prompt string with zero logic residue.

**Requires:** [dotprompt/runtime](https://hub.docker.com/r/dotprompt/runtime) or [dotprompt/runtime-dev](https://hub.docker.com/r/dotprompt/runtime-dev) Docker container.

**Website:** [dotprompt.run](https://dotprompt.run)  
**Documentation:** [dotprompt.run/docs](https://dotprompt.run/docs)  
**GitHub:** [github.com/dot-prompt/dot-prompt](https://github.com/dot-prompt/dot-prompt)

---

- **Async-first API** — designed for modern TypeScript/JavaScript environments
- **Full type safety** — every response validated with **Zod**
- **SSE streaming** — native async generator for real-time events
- **Contract validation** — validate LLM responses against prompt contracts
- **Zero dependencies** — Node.js 18+ with built-in fetch

---

## Installation

```bash
npm install @dotprompt/client
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

```typescript
import { DotPromptClient } from '@dotprompt/client';

const client = new DotPromptClient({
  baseUrl: 'http://localhost:4000',
  timeout: 5000,
});

const result = await client.compile('my_prompt', {
  name: 'World',
});

console.log(result.template);
```

---

## Full Example: Compile + Render + Validate

```typescript
import { DotPromptClient } from '@dotprompt/client';

const client = new DotPromptClient({ baseUrl: 'http://localhost:4041' });

// Get prompt schema (parameters, types, contracts)
const schema = await client.getSchema('teaching_prompt');
console.log('Params:', schema.params);

// Compile: resolve branching, expand fragments, select variations
const compiled = await client.compile('teaching_prompt', {
  pattern_step: 2,
  variation: 'recognition',
  answer_depth: 'medium',
  skill_names: ['Milton Model'],
}, { seed: 42 }); // deterministic variation selection

console.log('Template:', compiled.template);

// Render: inject runtime variables into the template
const rendered = await client.render('teaching_prompt',
  {
    pattern_step: 2,
    variation: 'recognition',
    answer_depth: 'medium',
    skill_names: ['Milton Model'],
  },
  {
    user_input: 'Can you give me an example?',
    user_level: 'intermediate',
  }
);

console.log('Final prompt:', rendered.prompt);

// Validate LLM response against the contract
const response = { score: 8, explanation: 'Good answer' };
const isValid = client.validateResponse(response, schema.responseContract);
console.log('Valid:', isValid);
```

---

## Configuration

```typescript
import { DotPromptClient } from '@dotprompt/client';

const client = new DotPromptClient({
  baseUrl: 'http://localhost:4041',  // container URL
  apiKey: 'your-api-key',            // optional API key
  timeout: 5000,                     // request timeout in ms
  maxRetries: 3,                    // retry on transient failures
});
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTPROMPT_URL` | `http://localhost:4000` | Container URL |
| `DOTPROMPT_API_KEY` | — | Optional API key |
| `DOTPROMPT_TIMEOUT` | `5000` | Request timeout in ms |

---

## API Reference

### Constructor Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseUrl` | `string` | `http://localhost:4041` | Container URL |
| `apiKey` | `string` | — | Optional API key |
| `timeout` | `number` | `5000` | Request timeout in ms |
| `maxRetries` | `number` | `3` | Retry attempts |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `listPrompts()` | `Promise<PromptSchema[]>` | All available prompts |
| `listCollections()` | `Promise<Collection[]>` | Root-level collections |
| `getSchema(prompt)` | `Promise<PromptSchema>` | Prompt metadata + params |
| `compile(prompt, params, options?)` | `Promise<CompileResult>` | Resolve branching, expand fragments |
| `render(prompt, params, runtime?, options?)` | `Promise<RenderResult>` | Full compile + inject |
| `inject(template, runtime)` | `InjectResult` | Inject into raw template |
| `events()` | `AsyncGenerator<ServerEvent>` | SSE stream for real-time updates |
| `validateResponse(response, contract)` | `boolean` | Validate against contract |

---

## Error Handling

```typescript
import {
  DotPromptClient,
  ConnectionError,
  TimeoutError,
  PromptNotFoundError,
  ValidationError,
  ServerError,
} from '@dotprompt/client';

try {
  const result = await client.compile('my_prompt', { ... });
} catch (error) {
  if (error instanceof PromptNotFoundError) {
    console.error("Prompt doesn't exist");
  } else if (error instanceof ValidationError) {
    console.error('Contract mismatch:', error.message);
  } else if (error instanceof ConnectionError) {
    console.error('Container unreachable');
  } else if (error instanceof TimeoutError) {
    console.error('Request timed out');
  } else if (error instanceof ServerError) {
    console.error('Server error:', error.message);
  }
}
```

### Error Types

| Error | Description |
|-------|-------------|
| `ConnectionError` | Network or server reachability issues |
| `TimeoutError` | Request timed out |
| `PromptNotFoundError` | 404 — prompt doesn't exist |
| `APIClientError` | Other 4xx client errors |
| `ServerError` | 5xx server errors |
| `ValidationError` | Zod or contract validation failures |

---

## Async Generator: SSE Events

```typescript
for await (const event of client.events()) {
  switch (event.type) {
    case 'committed':
      console.log('Prompt committed:', event.payload);
      break;
    case 'compiled':
      console.log('Prompt compiled:', event.payload);
      break;
    case 'error':
      console.error('Error:', event.payload);
      break;
  }
}
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