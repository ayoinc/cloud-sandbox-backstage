"""Adapter for the OpenAI Responses API."""

import json
from collections.abc import AsyncIterator, Sequence
from typing import Any, cast

from openai import AsyncOpenAI
from openai.types.responses import ResponseInputParam, ToolParam

from agent.config import Settings
from agent.llm.base import LLMClient, Message, ModelTurn, ToolCall, ToolSpec, Usage


def to_openai_input(messages: Sequence[Message]) -> list[dict[str, Any]]:
    """Translate the conversation to Responses API input items."""
    items: list[dict[str, Any]] = []
    for message in messages:
        if message.role == "user":
            items.append({"role": "user", "content": message.text})
        elif message.role == "assistant":
            if message.text:
                items.append({"role": "assistant", "content": message.text})
            items.extend(
                {
                    "type": "function_call",
                    "call_id": call.id,
                    "name": call.name,
                    "arguments": json.dumps(call.arguments),
                }
                for call in message.tool_calls
            )
        else:
            items.extend(
                {
                    "type": "function_call_output",
                    "call_id": result.call_id,
                    # The API has no error flag; the text says what went wrong.
                    "output": f"Error: {result.content}" if result.is_error else result.content,
                }
                for result in message.tool_results
            )
    return items


def to_openai_tools(tools: Sequence[ToolSpec]) -> list[dict[str, Any]]:
    return [
        {
            "type": "function",
            "name": tool.name,
            "description": tool.description,
            "parameters": tool.parameters,
            "strict": tool.strict,
        }
        for tool in tools
    ]


class OpenAIClient:
    provider = "openai"

    def __init__(self, settings: Settings) -> None:
        self.model = settings.model
        self._max_tokens = settings.max_output_tokens
        # The SDK reads OPENAI_API_KEY from the environment.
        self._client = AsyncOpenAI(timeout=settings.request_timeout_seconds, max_retries=2)

    async def stream(
        self, *, system: str, messages: Sequence[Message], tools: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        async with self._client.responses.stream(
            model=self.model,
            instructions=system,
            input=cast(ResponseInputParam, to_openai_input(messages)),
            tools=cast(list[ToolParam], to_openai_tools(tools)),
            max_output_tokens=self._max_tokens,
            # The conversation is sent in full on every turn; nothing is kept by the API.
            store=False,
        ) as stream:
            async for event in stream:
                if event.type == "response.output_text.delta":
                    yield event.delta
            response = await stream.get_final_response()

        yield ModelTurn(
            text=response.output_text,
            tool_calls=tuple(
                ToolCall(
                    id=item.call_id, name=item.name, arguments=json.loads(item.arguments or "{}")
                )
                for item in response.output
                if item.type == "function_call"
            ),
            usage=Usage(
                response.usage.input_tokens if response.usage else 0,
                response.usage.output_tokens if response.usage else 0,
            ),
            stop_reason=response.status or "",
        )


def build_client(settings: Settings) -> LLMClient:
    return OpenAIClient(settings)
