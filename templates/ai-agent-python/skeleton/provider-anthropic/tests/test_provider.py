from agent.llm.base import Message, ToolCall, ToolResult, ToolSpec
from agent.llm.provider import to_anthropic_messages, to_anthropic_tools


def test_conversation_is_translated_to_messages_api_input() -> None:
    call = ToolCall(id="toolu_1", name="calculate", arguments={"expression": "2+2"})
    messages = [
        Message(role="user", text="What is 2+2?"),
        Message(role="assistant", text="Let me calculate.", tool_calls=(call,)),
        Message(role="tool", tool_results=(ToolResult("toolu_1", "calculate", "4"),)),
    ]

    assert to_anthropic_messages(messages) == [
        {"role": "user", "content": "What is 2+2?"},
        {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "Let me calculate."},
                {
                    "type": "tool_use",
                    "id": "toolu_1",
                    "name": "calculate",
                    "input": {"expression": "2+2"},
                },
            ],
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "tool_result",
                    "tool_use_id": "toolu_1",
                    "content": "4",
                    "is_error": False,
                }
            ],
        },
    ]


def test_assistant_message_without_text_has_only_tool_use_blocks() -> None:
    call = ToolCall(id="toolu_1", name="calculate", arguments={})
    [converted] = to_anthropic_messages([Message(role="assistant", tool_calls=(call,))])
    assert [block["type"] for block in converted["content"]] == ["tool_use"]


def test_tools_are_translated_and_strictness_is_passed_on() -> None:
    schema = {"type": "object", "properties": {}, "additionalProperties": False}
    tools = [ToolSpec("lookup", "Look up", schema), ToolSpec("final", "Finish", schema, True)]

    assert to_anthropic_tools(tools) == [
        {"name": "lookup", "description": "Look up", "input_schema": schema},
        {"name": "final", "description": "Finish", "input_schema": schema, "strict": True},
    ]
