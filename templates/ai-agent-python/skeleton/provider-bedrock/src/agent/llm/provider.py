"""Adapter for the Amazon Bedrock Converse API."""

import asyncio
import json
from collections.abc import AsyncIterator, Iterator, Sequence
from typing import Any

import boto3
from botocore.config import Config

from agent.config import Settings
from agent.llm.base import LLMClient, Message, ModelTurn, ToolCall, ToolSpec, Usage


def to_bedrock_messages(messages: Sequence[Message]) -> list[dict[str, Any]]:
    """Translate the conversation to Converse API messages."""
    converted: list[dict[str, Any]] = []
    for message in messages:
        if message.role == "user":
            converted.append({"role": "user", "content": [{"text": message.text}]})
        elif message.role == "assistant":
            blocks: list[dict[str, Any]] = []
            if message.text:
                blocks.append({"text": message.text})
            blocks.extend(
                {"toolUse": {"toolUseId": call.id, "name": call.name, "input": call.arguments}}
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
                            "toolResult": {
                                "toolUseId": result.call_id,
                                "content": [{"text": result.content}],
                                "status": "error" if result.is_error else "success",
                            }
                        }
                        for result in message.tool_results
                    ],
                }
            )
    return converted


def to_bedrock_tools(tools: Sequence[ToolSpec]) -> dict[str, Any]:
    return {
        "tools": [
            {
                "toolSpec": {
                    "name": tool.name,
                    "description": tool.description,
                    "inputSchema": {"json": tool.parameters},
                }
            }
            for tool in tools
        ]
    }


class StreamAccumulator:
    """Builds a ``ModelTurn`` from the events of a ConverseStream response."""

    def __init__(self) -> None:
        self._text: list[str] = []
        self._calls: list[ToolCall] = []
        self._tool: dict[str, str] | None = None
        self._tool_input: list[str] = []
        self._stop_reason = ""
        self._usage = Usage()

    def feed(self, event: dict[str, Any]) -> str | None:
        """Take one event. Returns the text fragment it carries, if any."""
        if "contentBlockStart" in event:
            tool = event["contentBlockStart"].get("start", {}).get("toolUse")
            if tool:
                self._tool = {"id": tool["toolUseId"], "name": tool["name"]}
                self._tool_input = []
        elif "contentBlockDelta" in event:
            delta = event["contentBlockDelta"]["delta"]
            if "text" in delta:
                self._text.append(delta["text"])
                return str(delta["text"])
            if "toolUse" in delta:
                self._tool_input.append(delta["toolUse"].get("input", ""))
        elif "contentBlockStop" in event and self._tool:
            arguments = json.loads("".join(self._tool_input) or "{}")
            self._calls.append(ToolCall(self._tool["id"], self._tool["name"], arguments))
            self._tool = None
        elif "messageStop" in event:
            self._stop_reason = event["messageStop"].get("stopReason", "")
        elif "metadata" in event:
            usage = event["metadata"].get("usage", {})
            self._usage = Usage(usage.get("inputTokens", 0), usage.get("outputTokens", 0))
        return None

    def turn(self) -> ModelTurn:
        return ModelTurn("".join(self._text), tuple(self._calls), self._usage, self._stop_reason)


class BedrockClient:
    provider = "aws.bedrock"

    def __init__(self, settings: Settings) -> None:
        self.model = settings.model
        self._max_tokens = settings.max_output_tokens
        # Credentials come from the default AWS chain: the role of the workload
        # in production, your profile or SSO session on a workstation.
        self._client = boto3.client(
            "bedrock-runtime",
            region_name=settings.aws_region,
            config=Config(
                read_timeout=settings.request_timeout_seconds,
                retries={"mode": "adaptive", "max_attempts": 3},
            ),
        )

    async def stream(
        self, *, system: str, messages: Sequence[Message], tools: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        # boto3 is synchronous: the call and each read of the event stream run
        # in a worker thread so that the event loop stays free.
        response = await asyncio.to_thread(
            self._client.converse_stream,
            modelId=self.model,
            system=[{"text": system}],
            messages=to_bedrock_messages(messages),
            toolConfig=to_bedrock_tools(tools),
            inferenceConfig={"maxTokens": self._max_tokens},
        )
        events: Iterator[dict[str, Any]] = iter(response["stream"])
        accumulator = StreamAccumulator()
        while (event := await asyncio.to_thread(next, events, None)) is not None:
            text = accumulator.feed(event)
            if text:
                yield text
        yield accumulator.turn()


def build_client(settings: Settings) -> LLMClient:
    return BedrockClient(settings)
