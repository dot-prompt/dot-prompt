"""Sync client for dot-prompt container API."""

from collections.abc import Iterator
from typing import Any

from dotprompt.async_client import DotPromptAsyncClient
from dotprompt.events import Event
from dotprompt.models import (
    CompileResult,
    InjectResult,
    PromptSchema,
    RenderResult,
)


class DotPromptClient:
    """Synchronous wrapper around DotPromptAsyncClient.

    Usage:
        with DotPromptClient() as client:
            result = client.compile("my_prompt", params={"name": "world"})
    """

    def __init__(
        self,
        base_url: str = "http://localhost:4041",
        timeout: float = 30.0,
        verify_ssl: bool = True,
        api_key: str | None = None,
        max_retries: int = 3,
    ) -> None:
        self._async_client = DotPromptAsyncClient(
            base_url=base_url,
            timeout=timeout,
            verify_ssl=verify_ssl,
            api_key=api_key,
            max_retries=max_retries,
        )

    def __enter__(self) -> "DotPromptClient":
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        self.close()

    def close(self) -> None:
        """Close the client and release resources."""
        import asyncio
        asyncio.run(self._async_client.close())

    def list_prompts(self) -> list[str]:
        """List all available prompts including fragments."""
        import asyncio
        return asyncio.run(self._async_client.list_prompts())

    def list_collections(self) -> list[str]:
        """List root-level prompt collections (directories)."""
        import asyncio
        return asyncio.run(self._async_client.list_collections())

    def get_schema(self, prompt: str, major: int | None = None) -> PromptSchema:
        """Get schema metadata for a prompt."""
        import asyncio
        return asyncio.run(self._async_client.get_schema(prompt, major))

    def compile(
        self,
        prompt: str,
        params: dict[str, Any],
        seed: int | None = None,
        major: int | None = None,
    ) -> CompileResult:
        """Compile a prompt with given parameters."""
        import asyncio
        return asyncio.run(self._async_client.compile(prompt, params, seed, major))

    def render(
        self,
        prompt: str,
        params: dict[str, Any],
        runtime: dict[str, Any],
        seed: int | None = None,
        major: int | None = None,
    ) -> RenderResult:
        """Compile a prompt and inject runtime data."""
        import asyncio
        return asyncio.run(self._async_client.render(prompt, params, runtime, seed, major))

    def inject(self, template: str, runtime: dict[str, Any]) -> InjectResult:
        """Inject runtime variables into a template string."""
        import asyncio
        return asyncio.run(self._async_client.inject(template, runtime))

    def events(self) -> Iterator[Event]:
        """Stream real-time container events (sync iterator)."""
        import asyncio

        async def event_generator():
            async for event in self._async_client.events():
                yield event

        loop = asyncio.new_event_loop()
        try:
            async_gen = event_generator()
            while True:
                try:
                    event = loop.run_until_complete(async_gen.__anext__())
                    yield event
                except StopAsyncIteration:
                    break
        finally:
            loop.close()

    def validate_response(self, response: dict, contract: dict) -> bool:
        """Validate LLM response against a response contract."""
        import asyncio
        return asyncio.run(self._async_client.validate_response(response, contract))
