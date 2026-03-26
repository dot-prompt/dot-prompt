"""Private HTTP transport layer for dot-prompt client."""

import logging
from typing import Any

import httpx

from dotprompt.exceptions import (
    APIClientError,
    ConnectionError,
    MissingRequiredParamsError,
    PromptNotFoundError,
    ServerError,
    TimeoutError,
    ValidationError,
)

logger = logging.getLogger(__name__)


class _Transport:
    """Private transport layer for HTTP communication with dot-prompt container."""

    def __init__(
        self,
        base_url: str = "http://localhost:4041",
        timeout: float = 30.0,
        verify_ssl: bool = True,
        api_key: str | None = None,
        max_retries: int = 3,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries

        headers: dict[str, str] = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        if api_key:
            headers["Authorization"] = f"Bearer {api_key}"

        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=httpx.Timeout(timeout),
            verify=verify_ssl,
            headers=headers,
        )

    async def close(self) -> None:
        """Close the HTTP client."""
        await self._client.aclose()

    async def __aenter__(self) -> "_Transport":
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        await self.close()

    def _handle_error(self, response: httpx.Response) -> None:
        """Convert HTTP error responses to custom exceptions."""
        status = response.status_code
        data: dict | None = None
        try:
            data = response.json()
            message = data.get("message", data.get("error", "Unknown error"))
        except Exception:
            message = response.text or "Unknown error"

        if status == 404:
            raise PromptNotFoundError(message)
        elif status == 422:
            error_type = data.get("error", "")
            if error_type == "missing_required_params":
                raise MissingRequiredParamsError(message)
            elif error_type == "validation_error":
                raise ValidationError(message)
            else:
                raise APIClientError(status, message)
        elif status >= 500:
            raise ServerError(status, message)
        else:
            raise APIClientError(status, message)

    async def get(self, path: str) -> dict[str, Any]:
        """Make a GET request."""
        try:
            response = await self._client.get(path)
        except httpx.ConnectError as e:
            logger.error(f"Connection error: {e}")
            raise ConnectionError() from e
        except httpx.TimeoutException as e:
            logger.error(f"Timeout error: {e}")
            raise TimeoutError() from e

        if response.status_code >= 400:
            self._handle_error(response)

        return response.json()

    async def post(self, path: str, json: dict[str, Any]) -> dict[str, Any]:
        """Make a POST request."""
        try:
            response = await self._client.post(path, json=json)
        except httpx.ConnectError as e:
            logger.error(f"Connection error: {e}")
            raise ConnectionError() from e
        except httpx.TimeoutException as e:
            logger.error(f"Timeout error: {e}")
            raise TimeoutError() from e

        if response.status_code >= 400:
            self._handle_error(response)

        return response.json()

    async def stream_events(self) -> httpx.Response:
        """Stream SSE events from the container.

        Returns:
            Response object with streaming enabled for SSE events.
        """
        return await self._client.request("GET", "/api/events", stream=True)
