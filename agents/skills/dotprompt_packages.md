# dot-prompt Packages Skill

Expertise in using the dot-prompt client packages and server.

## Clients
- **TypeScript (`@dotprompt/client`)**: Features `DotPromptClient` (sync) and `DotPromptAsyncClient` (async).
- **Python (`dotprompt-client`)**: Provides sync and async clients (`httpx`-based).
- **Go (`dot-prompt-go-client`)**: Native client in Go.

## Server
- **`dot-prompt:headed`**: Includes a Phoenix web UI and API.
- **`dot-prompt:headless`**: API-only image.
- **`docker-compose`**: Standard way to deploy and mount prompts.

## Key Concepts
- **`PROMPTS_DIR`**: Path to the folder containing `.prompt` files.
- **`SECRET_KEY_BASE`**: Necessary for Phoenix/LiveView sessions.
- **`PHX_HOST`**: Configures the host for the service.
