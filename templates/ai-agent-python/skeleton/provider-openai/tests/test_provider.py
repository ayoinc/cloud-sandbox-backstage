from agent.llm.base import Message, ToolCall, ToolResult, ToolSpec
from agent.llm.provider import to_openai_input, to_openai_tools


def test_conversation_is_translated_to_responses_api_input() -> None:
    call = ToolCall(id="call_1", name="calculate", arguments={"expression": "2+2"})
    messages = [
        Message(role="user", text="What is 2+2?"),
        Message(role="assistant", text="Let me calculate.", tool_calls=(call,)),
        Message(role="tool", tool_results=(ToolResult("call_1", "calculate", "4"),)),
    ]

    assert to_openai_input(messages) == [
        {"role": "user", "content": "What is 2+2?"},
        {"role": "assistant", "content": "Let me calculate."},
        {
            "type": "function_call",
            "call_id": "call_1",
            "name": "calculate",
            "arguments": '{"expression": "2+2"}',
        },
        {"type": "function_call_output", "call_id": "call_1", "output": "4"},
    ]


def test_tool_errors_are_marked_in_the_output_text() -> None:
    result = ToolResult("call_1", "calculate", "division by zero", is_error=True)
    [item] = to_openai_input([Message(role="tool", tool_results=(result,))])
    assert item["output"] == "Error: division by zero"


def test_tools_are_translated_and_strictness_is_passed_on() -> None:
    schema = {"type": "object", "properties": {}, "additionalProperties": False}
    tools = [ToolSpec("lookup", "Look up", schema), ToolSpec("final", "Finish", schema, True)]

    assert to_openai_tools(tools) == [
        {
            "type": "function",
            "name": "lookup",
            "description": "Look up",
            "parameters": schema,
            "strict": False,
        },
        {
            "type": "function",
            "name": "final",
            "description": "Finish",
            "parameters": schema,
            "strict": True,
        },
    ]
