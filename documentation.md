# Documentation: Packages and Docker Containers

This document provides comprehensive information about the dot-prompt TypeScript and Python client packages, as well as the Docker containers required to run the service.

---

## Table of Contents

1. [Overview](#overview)
2. [TypeScript Package](#typescript-package)
3. [Python Package](#python-package)
4. [Docker Containers](#docker-containers)
5. [Quick Start](#quick-start)

---

## Overview

dot-prompt provides client libraries in both TypeScript and Python for interacting with the dot-prompt prompt management service. These clients communicate with a backend service running in a Docker container.

---

## TypeScript Package

### Package Information

| Property | Value |
|----------|-------|
| **Package Name** | `@dotprompt/client` |
| **Version** | 0.1.0 |
| **Description** | TypeScript client for dotprompt - requires dotprompt/runtime or dotprompt/runtime-dev Docker container |
| **Website** | https://dotprompt.run |
| **Repository** | https://github.com/dot-prompt/dot-prompt |
| **License** | Apache-2.0 |
| **Node.js Version** | >=18.0.0 |

### Dependencies

#### Runtime Dependencies
- `zod` (^3.22.4) - TypeScript-first schema validation
- `eventsource-parser` (^1.1.2) - Server-Sent Events parsing

#### Development Dependencies
- `@types/node` (^18.19.0)
- `eslint` (^8.56.0)
- `prettier` (^3.1.1)
- `tsup` (^8.0.1)
- `typescript` (^5.3.3)
- `vitest` (^1.1.0)

### Build and Publish Scripts

The package uses the following npm scripts:

```bash
# Build the package
npm run build

# Run tests
npm run test

# Run tests in watch mode
npm run test:watch

# Lint code
npm run lint

# Format code
npm run format
```

### Exported Modules

The package exports the following:

```typescript
export { DotPromptAsyncClient, type DotPromptClientOptions } from "./asyncClient.js";
export { DotPromptClient } from "./client.js";
export { Transport, type RequestOptions } from "./transport.js";
export * from "./models.js";
export * from "./errors.js";
export { validateResponse } from "./utils.js";
export { createEventStream } from "./events.js";
```

### Key Classes

- **DotPromptClient**: Synchronous client for Node.js environments
- **DotPromptAsyncClient**: Async client for use with async/await
- **Transport**: HTTP transport layer for API communication

---

## Python Package

### Package Information

| Property | Value |
|----------|-------|
| **Package Name** | `dotprompt-client` |
| **Version** | 0.1.6 |
| **Description** | Python client for dotprompt - requires dotprompt/runtime or dotprompt/runtime-dev Docker container |
| **Website** | https://dotprompt.run |
| **Repository** | https://github.com/dot-prompt/dot-prompt |
| **License** | Apache-2.0 |
| **Python Version** | >=3.10 |

### Dependencies

#### Runtime Dependencies
- `httpx` (>=0.24.0) - HTTP client library
- `pydantic` (>=2.0.0) - Data validation using Python type annotations

#### Development Dependencies
- `pytest` (>=7.0.0)
- `pytest-asyncio`
- `pytest-mock`
- `ruff`
- `mypy`

### Build System
- Build Backend: setuptools (>=61.0)

### Code Quality Tools

#### Ruff Configuration
- Line length: 88 characters
- Target version: 0.1.6
- Enabled rules: E, F, I, N, W, UP

#### MyPy Configuration
- Python version: 0.1.6
- Strict mode: Enabled (disallows untyped defs)

### Exported Modules

```python
from dotprompt.async_client import DotPromptAsyncClient
from dotprompt.client import DotPromptClient
from dotprompt.events import Event
from dotprompt.exceptions import (
    APIClientError,
    ConnectionError,
    DotPromptError,
    MissingRequiredParamsError,
    PromptNotFoundError,
    ServerError,
    TimeoutError,
    ValidationError,
)
from dotprompt.models import (
    CompileResult,
    ContractField,
    FragmentSpec,
    InjectResult,
    ParamSpec,
    PromptSchema,
    RenderResult,
    ResponseContract,
)
```

### Key Classes

- **DotPromptClient**: Synchronous wrapper around the async client
- **DotPromptAsyncClient**: Async client using httpx

---

## Docker Containers

### Container Images

dot-prompt provides two Docker images:

1. **dot-prompt:headed** - Full Phoenix web UI + API
2. **dot-prompt:headless** - API only, no web UI

### Dockerfile Comparison

| Feature | headed (Dockerfile) | headless (Dockerfile.headless) |
|---------|---------------------|-------------------------------|
| **Base Image** | elixir:1.18-slim (build), debian:sid-slim (runtime) | elixir:1.18-slim (build), debian:sid-slim (runtime) |
| **Phoenix UI** | Enabled | Disabled |
| **Port** | 4000 | 4000 (internal) |
| **Node.js Assets** | Built in container | Not built (headless) |

### Build Stages

#### Headed Image (Dockerfile)
1. **Stage 1: Build Assets**
   - Base: `node:22-alpine`
   - Builds frontend assets using npm
   - Creates static files for Phoenix UI

2. **Stage 2: Build App**
   - Base: `elixir:1.18-slim`
   - Installs build tools (build-essential, git)
   - Compiles Elixir application with Mix

3. **Stage 3: Final Runtime**
   - Base: `debian:sid-slim`
   - Installs runtime dependencies (libssl3, ncurses-base, ca-certificates, locales, inotify-tools)
   - Sets up locale (en_US.UTF-8)
   - Creates non-root user (elixir)

#### Headless Image (Dockerfile.headless)
1. **Stage 1: Build App**
   - Base: `elixir:1.18-slim`
   - Installs build tools
   - Compiles Elixir application

2. **Stage 2: Final Runtime**
   - Base: `debian:sid-slim`
   - Same runtime dependencies as headed
   - Sets environment variables for headless operation

### Docker Compose Configurations

#### docker-compose.yml (Default/Headed)

```yaml
services:
  dot-prompt:
    build:
      context: .
      dockerfile: Dockerfile.headless
    image: dot-prompt:headless
    container_name: dot-prompt-server
    restart: unless-stopped
    ports:
      - "${PROMPT_SERVER_PORT:-4000}:4000"
    volumes:
      - "${PROMPT_DIR_HOST:-./prompts}:/app/prompts:ro"
    environment:
      - MIX_ENV=prod
      - PORT=4000
      - PROMPTS_DIR=/app/prompts
      - PHX_HOST=localhost
      - SECRET_KEY_BASE=dEvSeCrEtKeYBaSeFoRTeStInG12345678901234567890
      - LIVE_VIEW_SIGNING_SALT=DeVSiGnInGsAlT123456789
    healthcheck:
      test: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/4000'"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
```

#### docker-compose.headless.yml (Headless API)

```yaml
services:
  dot-prompt-headless:
    build:
      context: .
      dockerfile: Dockerfile.headless
    image: dot-prompt:headless
    container_name: dot-prompt-headless
    restart: unless-stopped
    ports:
      - "4001:4000"
    volumes:
      - "${PROMPT_DIR_HOST:-./prompts}:/app/prompts:ro"
    environment:
      - PORT=4000
      - DISABLE_UI=true
      - PROMPTS_DIR=/app/prompts
      - SECRET_KEY_BASE=${SECRET_KEY_BASE:-replace_with_secure_key}
      - LIVE_VIEW_SIGNING_SALT=${LIVE_VIEW_SIGNING_SALT:-replace_with_secure_salt}
      - PHX_HOST=${PHX_HOST:-localhost}
    healthcheck:
      test: ["CMD", "ps", "aux", "|", "grep", "dot_prompt_umbrella"]
      interval: 10s
      timeout: 5s
      retries: 5
```

#### docker-compose.headed.yml (Full UI)

```yaml
services:
  dot-prompt-headed:
    build:
      context: .
      dockerfile: Dockerfile.headed
    image: dot-prompt:headed
    container_name: dot-prompt-headed
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - "${PROMPT_DIR_HOST:-./prompts}:/app/prompts:ro"
    environment:
      - PORT=4000
      - PROMPTS_DIR=/app/prompts
      - SECRET_KEY_BASE=${SECRET_KEY_BASE:-replace_with_secure_key}
      - LIVE_VIEW_SIGNING_SALT=${LIVE_VIEW_SIGNING_SALT:-replace_with_secure_salt}
      - PHX_HOST=${PHX_HOST:-localhost}
    healthcheck:
      test: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/4000'"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 4000 | Container internal port |
| `PROMPTS_DIR` | /app/prompts | Directory where prompts are stored |
| `MIX_ENV` | prod | Elixir environment |
| `DISABLE_UI` | (not set) | Set to `true` to disable Phoenix web UI |
| `SECRET_KEY_BASE` | (required) | Phoenix secret key for sessions |
| `LIVE_VIEW_SIGNING_SALT` | (required) | Salt for LiveView signed payloads |
| `PHX_HOST` | localhost | Hostname for Phoenix endpoint |
| `PROMPT_SERVER_PORT` | 4000 | Host port mapping (compose only) |
| `PROMPT_DIR_HOST` | ./prompts | Host directory for prompts (compose only) |

### Runtime Dependencies (Installed in Container)

- `libssl3` - SSL/TLS library
- `ncurses-base` - Terminal handling
- `ca-certificates` - SSL certificates
- `locales` - Locale support
- `inotify-tools` - File system monitoring

---

## Quick Start

### 1. Start the Docker Container

```bash
# Start headless (API only)
docker compose -f docker-compose.headless.yml up -d

# Or start with UI
docker compose -f docker-compose.headed.yml up -d
```

### 2. Use the TypeScript Client

```bash
# Install
npm install @dotprompt/client

# Use
import { DotPromptClient } from '@dotprompt/client';

const client = new DotPromptClient({
  baseUrl: 'http://localhost:4000'
});

const prompts = await client.listPrompts();
```

### 3. Use the Python Client

```bash
# Install
pip install dotprompt-client

# Use
from dotprompt import DotPromptClient

with DotPromptClient() as client:
    prompts = client.list_prompts()
```

---

## Version Information

| Component | Current Version |
|-----------|-----------------|
| TypeScript Client | 0.1.0 |
| Python Client | 0.1.6 |
| Elixir/Phoenix | 1.18 |

---

## Additional Resources

- Website: https://dotprompt.run
- Repository: https://github.com/dot-prompt/dot-prompt
