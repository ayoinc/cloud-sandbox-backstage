"""Adapter for the Anthropic Messages API."""

from collections.abc import AsyncIterator, Sequence
from typing import Any, cast

from anthropic import AsyncAnthropic
from anthropic.types import MessageParam, ToolParam

from agent.config import Settings
from agent.llm.base import LLMClient, Message, ModelTurn, ToolCall, ToolSpec, Usage


def to_anthropic_messages(messages: Sequence[Message]) -> list[dict[str, Any]]:
    """Translate the conversation to Messages API input."""
    converted: list[dict[str, Any]] = []
    for message in messages:
        if message.role == "user":
            converted.append({"role": "user", "content": message.text})
        elif message.role == "assistant":
            blocks: list[dict[str, Any]] = []
            if message.text:
                blocks.append({"type": "text", "text": message.text})
            blocks.extend(
                {"type": "tool_use", "id": call.id, "name": call.name, "input": call.arguments}
                for call in message.tool_calls
            )
            converted.append({"role": "assistant", "content": blocks})
        else:
            # Tool results travel in a user message, one block per tool call.
            converted.append(
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": result.call_id,
                            "content": result.content,
                            "is_error": result.is_error,
                        }
                        for result in message.tool_results
                    ],
                }
            )
    return converted


def to_anthropic_tools(tools: Sequence[ToolSpec]) -> list[dict[str, Any]]:
    converted: list[dict[str, Any]] = []
    for tool in tools:
        entry: dict[str, Any] = {
            "name": tool.name,
            "description": tool.description,
            "input_schema": tool.parameters,
        }
        if tool.strict:
            entry["strict"] = True
        converted.append(entry)
    return converted


class AnthropicClient:
    provider = "anthropic"

    def __init__(self, settings: Settings) -> None:
        self.model = settings.model
        self._max_tokens = settings.max_output_tokens
        # The SDK reads ANTHROPIC_API_KEY from the environment.
        self._client = AsyncAnthropic(timeout=settings.request_timeout_seconds, max_retries=2)

    async def stream(
        self, *, system: str, messages: Sequence[Message], tools: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        async with self._client.messages.stream(
            model=self.model,
            max_tokens=self._max_tokens,
            system=system,
            messages=cast(list[MessageParam], to_anthropic_messages(messages)),
            tools=cast(list[ToolParam], to_anthropic_tools(tools)),
        ) as stream:
            async for text in stream.text_stream:
                yield text
            final = await stream.get_final_message()

        yield ModelTurn(
            text="".join(block.text for block in final.content if block.type == "text"),
            tool_calls=tuple(
                ToolCall(id=block.id, name=block.name, arguments=dict(block.input))
                for block in final.content
                if block.type == "tool_use"
            ),
            usage=Usage(final.usage.input_tokens, final.usage.output_tokens),
            stop_reason=final.stop_reason or "",
        )


def build_client(settings: Settings) -> LLMClient:
    return AnthropicClient(settings)
