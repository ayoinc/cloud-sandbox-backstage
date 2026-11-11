from datetime import datetime

import pytest
from pydantic import BaseModel

from agent.llm.base import ToolCall
from agent.tools import ToolRegistry, default_registry, evaluate, json_schema


def call(name: str, **arguments: object) -> ToolCall:
    return ToolCall(id="call_1", name=name, arguments=arguments)


async def test_calculate_returns_the_exact_result() -> None:
    result = await default_registry().execute(call("calculate", expression="(17 + 4) * 12"))
    assert (result.content, result.is_error) == ("252", False)


async def test_current_time_is_in_the_requested_zone() -> None:
    result = await default_registry().execute(call("get_current_time", timezone="Asia/Tokyo"))
    assert not result.is_error
    assert datetime.fromisoformat(result.content).utcoffset() is not None
    assert result.content.endswith("+09:00")


@pytest.mark.parametrize(
    ("name", "arguments", "message"),
    [
        ("unknown_tool", {}, "Unknown tool"),
        ("calculate", {}, "Invalid arguments"),
        ("calculate", {"expression": "1", "extra": True}, "Invalid arguments"),
        ("calculate", {"expression": "1 / 0"}, "ZeroDivisionError"),
        ("calculate", {"expression": "__import__('os')"}, "Only numbers"),
        ("calculate", {"expression": "9 ** 9 ** 9"}, "too large"),
        ("get_current_time", {"timezone": "Mars/Olympus"}, "Unknown time zone"),
    ],
)
async def test_failures_are_returned_as_tool_errors(
    name: str, arguments: dict[str, object], message: str
) -> None:
    result = await default_registry().execute(call(name, **arguments))
    assert result.is_error
    assert message in result.content


@pytest.mark.parametrize(
    ("expression", "expected"),
    [("2 + 3 * 4", 14), ("-(2 ** 10)", -1024), ("7 // 2", 3), ("7 % 4", 3), ("1 / 4", 0.25)],
)
def test_evaluate(expression: str, expected: float) -> None:
    assert evaluate(expression) == expected


class EchoArgs(BaseModel):
    text: str


async def test_async_tools_and_timeouts() -> None:
    import asyncio

    registry = ToolRegistry(timeout_seconds=0.05)

    @registry.tool("echo", "Repeat the text", EchoArgs)
    async def echo(args: EchoArgs) -> str:
        return args.text

    @registry.tool("slow", "Never finishes in time", EchoArgs)
    async def slow(args: EchoArgs) -> str:
        await asyncio.sleep(5)
        return args.text

    assert (await registry.execute(call("echo", text="hello"))).content == "hello"
    timed_out = await registry.execute(call("slow", text="hello"))
    assert timed_out.is_error
    assert "did not finish" in timed_out.content


def test_a_tool_name_can_be_registered_once() -> None:
    registry = ToolRegistry()
    registry.tool("echo", "Repeat the text", EchoArgs)(lambda args: args.text)
    with pytest.raises(ValueError, match="already registered"):
        registry.tool("echo", "Repeat the text", EchoArgs)(lambda args: args.text)


def test_tool_specs_carry_a_json_schema_without_titles() -> None:
    specs = {spec.name: spec for spec in default_registry().specs()}
    assert set(specs) == {"get_current_time", "calculate"}
    schema = specs["calculate"].parameters
    assert schema["required"] == ["expression"]
    assert schema["additionalProperties"] is False
    assert "title" not in schema
    assert "title" not in schema["properties"]["expression"]
    assert json_schema(EchoArgs)["properties"] == {"text": {"type": "string"}}
