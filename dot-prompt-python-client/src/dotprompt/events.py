"""Event model for SSE streaming."""

from pydantic import BaseModel


class Event(BaseModel):
    """Represents an event from the container SSE stream."""

    type: str
    timestamp: float
    payload: dict
