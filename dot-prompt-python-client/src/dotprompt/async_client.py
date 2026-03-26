"""Async client for dot-prompt container API."""

from collections.abc import AsyncIterator
from typing import Any

from dotprompt._transport import _Transport
from dotprompt.events import Event
from dotprompt.models import (
    CompileResult,
    InjectResult,
    PromptSchema,
    RenderResult,
)


class DotPromptAsyncClient:
    """Async client for interacting with the dot-prompt container API.

    Usage:
        async with DotPromptAsyncClient() as client:
            result = await client.compile("my_prompt", params={"name": "world"})
    """

    def __init__(
        self,
        base_url: str = "http://localhost:4041",
        timeout: float = 30.0,
        verify_ssl: bool = True,
        api_key: str | None = None,
        max_retries: int = 3,
    ) -> None:
        self.base_url = base_url
        self._transport = _Transport(
            base_url=base_url,
            timeout=timeout,
            verify_ssl=verify_ssl,
            api_key=api_key,
            max_retries=max_retries,
        )

    async def __aenter__(self) -> "DotPromptAsyncClient":
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        await self._transport.close()

    async def close(self) -> None:
        """Close the client and release resources."""
        await self._transport.close()

    async def list_prompts(self) -> list[str]:
        """List all available prompts including fragments.

        Returns:
            List of prompt names (relative paths without .prompt extension).
        """
        response = await self._transport.get("/api/prompts")
        return response.get("prompts", [])

    async def list_collections(self) -> list[str]:
        """List root-level prompt collections (directories).

        Returns:
            List of collection names.
        """
        response = await self._transport.get("/api/collections")
        return response.get("collections", [])

    async def get_schema(self, prompt: str, major: int | None = None) -> PromptSchema:
        """Get schema metadata for a prompt.

        Args:
            prompt: The prompt name/path (e.g., "my_prompt" or "collection/prompt").
            major: Optional major version. If not provided, returns latest version.

        Returns:
            PromptSchema with metadata including params, fragments, and docs.
        """
        if major is not None:
            path = f"/api/schema/{prompt}/{major}"
        else:
            path = f"/api/schema/{prompt}"

        data = await self._transport.get(path)
        return PromptSchema(**data)

    async def compile(
        self,
        prompt: str,
        params: dict[str, Any],
        seed: int | None = None,
        major: int | None = None,
    ) -> CompileResult:
        """Compile a prompt with given parameters.

        Args:
            prompt: The prompt name or inline prompt content.
            params: Parameters to pass to the prompt.
            seed: Optional seed for reproducible vary selections.
            major: Optional major version to compile.

        Returns:
            CompileResult with compiled template and metadata.
        """
        body: dict[str, Any] = {"prompt": prompt, "params": params}

        if seed is not None:
            body["seed"] = seed
        if major is not None:
            body["major"] = major

        data = await self._transport.post("/api/compile", body)
        return CompileResult(**data)

    async def render(
        self,
        prompt: str,
        params: dict[str, Any],
        runtime: dict[str, Any],
        seed: int | None = None,
        major: int | None = None,
    ) -> RenderResult:
        """Compile a prompt and inject runtime data.

        Args:
            prompt: The prompt name or inline prompt content.
            params: Parameters to pass to the prompt.
            runtime: Runtime variables to inject into the compiled template.
            seed: Optional seed for reproducible vary selections.
            major: Optional major version to render.

        Returns:
            RenderResult with rendered prompt and token counts.
        """
        body: dict[str, Any] = {
            "prompt": prompt,
            "params": params,
            "runtime": runtime,
        }

        if seed is not None:
            body["seed"] = seed
        if major is not None:
            body["major"] = major

        data = await self._transport.post("/api/render", body)
        return RenderResult(**data)

    async def inject(self, template: str, runtime: dict[str, Any]) -> InjectResult:
        """Inject runtime variables into a template string.

        Args:
            template: The template string with {variable} placeholders.
            runtime: Variables to inject into the template.

        Returns:
            InjectResult with injected prompt and token count.
        """
        body = {"template": template, "runtime": runtime}
        data = await self._transport.post("/api/inject", body)
        return InjectResult(**data)

    async def events(self) -> AsyncIterator[Event]:
        """Stream real-time container events.

        Yields:
            Event objects from the SSE stream.
        """
        response = await self._transport.stream_events()
        for line in response.iter_lines():
            if line.startswith("data: "):
                data = line[6:]
                if data == "[DONE]":
                    break
                event_data = eval(data)
                yield Event(**event_data)

    async def validate_response(self, response: dict, contract: dict) -> bool:
        """Validate LLM response against a response contract.

        Args:
            response: The LLM response to validate.
            contract: The response contract definition.

        Returns:
            True if the response matches the contract, False otherwise.
        """
        fields = contract.get("fields", {})
        for field_name, field_spec in fields.items():
            if field_name not in response:
                return False
            expected_type = field_spec.get("type")
            actual_value = response[field_name]
            if expected_type and not isinstance(actual_value, self._type_mapping(expected_type)):
                return False
        return True

    @staticmethod
    def _type_mapping(type_str: str) -> type:
        """Map type string to Python type."""
        mapping = {
            "string": str,
            "number": (int, float),
            "integer": int,
            "boolean": bool,
            "array": list,
            "object": dict,
        }
        return mapping.get(type_str, object)
