from typing import Any

from agent.llm.base import Message, ToolCall, ToolResult, ToolSpec, Usage
from agent.llm.provider import StreamAccumulator, to_bedrock_messages, to_bedrock_tools


def test_conversation_is_translated_to_converse_messages() -> None:
    call = ToolCall(id="tooluse_1", name="calculate", arguments={"expression": "2+2"})
    messages = [
        Message(role="user", text="What is 2+2?"),
        Message(role="assistant", text="Let me calculate.", tool_calls=(call,)),
        Message(
            role="tool",
            tool_results=(
                ToolResult("tooluse_1", "calculate", "4"),
                ToolResult("tooluse_2", "calculate", "bad input", is_error=True),
            ),
        ),
    ]

    assert to_bedrock_messages(messages) == [
        {"role": "user", "content": [{"text": "What is 2+2?"}]},
        {
            "role": "assistant",
            "content": [
                {"text": "Let me calculate."},
                {
                    "toolUse": {
                        "toolUseId": "tooluse_1",
                        "name": "calculate",
                        "input": {"expression": "2+2"},
                    }
                },
            ],
        },
        {
            "role": "user",
            "content": [
                {
                    "toolResult": {
                        "toolUseId": "tooluse_1",
                        "content": [{"text": "4"}],
                        "status": "success",
                    }
                },
                {
                    "toolResult": {
                        "toolUseId": "tooluse_2",
                        "content": [{"text": "bad input"}],
                        "status": "error",
                    }
                },
            ],
        },
    ]


def test_tools_are_translated_to_a_tool_config() -> None:
    schema = {"type": "object", "properties": {}}
    assert to_bedrock_tools([ToolSpec("lookup", "Look up", schema)]) == {
        "tools": [
            {
                "toolSpec": {
                    "name": "lookup",
                    "description": "Look up",
                    "inputSchema": {"json": schema},
                }
            }
        ]
    }


def test_stream_events_are_accumulated_into_a_turn() -> None:
    accumulator = StreamAccumulator()
    events: list[dict[str, Any]] = [
        {"messageStart": {"role": "assistant"}},
        {"contentBlockDelta": {"contentBlockIndex": 0, "delta": {"text": "Let me "}}},
        {"contentBlockDelta": {"contentBlockIndex": 0, "delta": {"text": "check."}}},
        {"contentBlockStop": {"contentBlockIndex": 0}},
        {
            "contentBlockStart": {
                "contentBlockIndex": 1,
                "start": {"toolUse": {"toolUseId": "tooluse_1", "name": "calculate"}},
            }
        },
        {"contentBlockDelta": {"contentBlockIndex": 1, "delta": {"toolUse": {"input": '{"expr'}}}},
        {
            "contentBlockDelta": {
                "contentBlockIndex": 1,
                "delta": {"toolUse": {"input": 'ession": "2+2"}'}},
            }
        },
        {"contentBlockStop": {"contentBlockIndex": 1}},
        {"messageStop": {"stopReason": "tool_use"}},
        {"metadata": {"usage": {"inputTokens": 12, "outputTokens": 7, "totalTokens": 19}}},
    ]

    fragments = [text for event in events if (text := accumulator.feed(event))]
    turn = accumulator.turn()

    assert fragments == ["Let me ", "check."]
    assert turn.text == "Let me check."
    assert turn.tool_calls == (ToolCall("tooluse_1", "calculate", {"expression": "2+2"}),)
    assert turn.stop_reason == "tool_use"
    assert turn.usage == Usage(12, 7)


def test_a_tool_call_without_input_has_empty_arguments() -> None:
    accumulator = StreamAccumulator()
    accumulator.feed(
        {"contentBlockStart": {"start": {"toolUse": {"toolUseId": "tooluse_1", "name": "now"}}}}
    )
    accumulator.feed({"contentBlockStop": {}})
    assert accumulator.turn().tool_calls == (ToolCall("tooluse_1", "now", {}),)
