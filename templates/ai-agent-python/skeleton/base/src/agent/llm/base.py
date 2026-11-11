"""The types the agent loop speaks, independent of any model provider.

The adapter in ``agent.llm.provider`` translates them to and from the wire
format of one provider. Nothing outside that module imports a provider SDK.
"""

from collections.abc import AsyncIterator, Sequence
from dataclasses import dataclass, field
from typing import Any, Literal, Protocol


@dataclass(frozen=True, slots=True)
class ToolSpec:
    """A tool as offered to the model: a name, a description and a JSON Schema."""

    name: str
    description: str
    parameters: dict[str, Any]
    # Ask the provider to guarantee that the arguments match the schema.
    strict: bool = False


@dataclass(frozen=True, slots=True)
class ToolCall:
    """A request by the model to run a tool."""

    id: str
    name: str
    arguments: dict[str, Any]


@dataclass(frozen=True, slots=True)
class ToolResult:
    """The outcome of a tool call, sent back to the model."""

    call_id: str
    name: str
    content: str
    is_error: bool = False


@dataclass(frozen=True, slots=True)
class Message:
    """One entry of the conversation.

    ``user`` messages carry text, ``assistant`` messages carry text and tool
    calls, ``tool`` messages carry the results of the preceding tool calls.
    """

    role: Literal["user", "assistant", "tool"]
    text: str = ""
    tool_calls: tuple[ToolCall, ...] = ()
    tool_results: tuple[ToolResult, ...] = ()


@dataclass(frozen=True, slots=True)
class Usage:
    input_tokens: int = 0
    output_tokens: int = 0

    def __add__(self, other: "Usage") -> "Usage":
        return Usage(
            self.input_tokens + other.input_tokens, self.output_tokens + other.output_tokens
        )


@dataclass(frozen=True, slots=True)
class ModelTurn:
    """A complete model response."""

    text: str = ""
    tool_calls: tuple[ToolCall, ...] = ()
    usage: Usage = field(default_factory=Usage)
    stop_reason: str = ""


class LLMClient(Protocol):
    """A chat model that can call tools."""

    provider: str
    model: str

    def stream(
        self, *, system: str, messages: Sequence[Message], tools: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        """Run one model turn.

        Yields text fragments as the model produces them, then exactly one
        ``ModelTurn`` with the complete response.
        """
        ...
