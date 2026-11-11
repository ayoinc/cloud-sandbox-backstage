import pytest

from agent.llm.base import Message, ModelTurn, Usage
from agent.loop import FINAL_ANSWER, Agent, AgentError
from agent.schemas import (
    CompletedEvent,
    ErrorEvent,
    TextDeltaEvent,
    ToolFinishedEvent,
    ToolStartedEvent,
)
from agent.tools import default_registry
from tests.fakes import FakeLLM, answer_turn, tool_turn


def agent_with(llm: FakeLLM, *, max_steps: int = 8) -> Agent:
    return Agent(llm, default_registry(), max_steps=max_steps)


async def test_runs_a_tool_then_returns_the_structured_answer() -> None:
    llm = FakeLLM(
        [
            tool_turn("calculate", {"expression": "6 * 7"}, text="Let me calculate."),
            answer_turn("6 times 7 is 42."),
        ]
    )

    response = await agent_with(llm).complete("What is 6 times 7?")

    assert response.answer.answer == "6 times 7 is 42."
    assert response.answer.confidence == "high"
    assert [(i.name, i.result, i.is_error) for i in response.tool_invocations] == [
        ("calculate", "42", False)
    ]
    assert response.steps == 2
    assert response.usage.input_tokens == 20
    assert response.usage.output_tokens == 10
    assert response.model == "fake-model"


async def test_tool_results_are_sent_back_to_the_model() -> None:
    llm = FakeLLM([tool_turn("calculate", {"expression": "1 + 1"}), answer_turn("2")])

    await agent_with(llm).complete("Add one and one", [Message(role="user", text="Hello")])

    first, second = llm.requests
    assert [message.role for message in first] == ["user", "user"]
    assert [message.role for message in second] == ["user", "user", "assistant", "tool"]
    assert second[-1].tool_results[0].content == "2"
    assert second[-2].tool_calls[0].name == "calculate"


async def test_the_model_is_offered_the_tools_and_the_answer_schema() -> None:
    llm = FakeLLM([answer_turn("Hi")])

    await agent_with(llm).complete("Hello")

    assert [tool.name for tool in llm.tools] == ["get_current_time", "calculate", FINAL_ANSWER]
    final = llm.tools[-1]
    assert final.strict
    assert final.parameters["required"] == ["answer", "confidence", "follow_up_questions"]
    assert final.parameters["additionalProperties"] is False
    assert "final_answer" in llm.system


async def test_events_are_emitted_in_order() -> None:
    llm = FakeLLM(
        [tool_turn("calculate", {"expression": "2 + 2"}, text="One moment"), answer_turn("4")]
    )

    events = [event async for event in agent_with(llm).run("What is 2 + 2?")]

    assert [type(event) for event in events] == [
        TextDeltaEvent,
        TextDeltaEvent,
        ToolStartedEvent,
        ToolFinishedEvent,
        CompletedEvent,
    ]
    assert "".join(e.text for e in events if isinstance(e, TextDeltaEvent)) == "One moment "


async def test_a_tool_error_is_reported_to_the_model_which_can_recover() -> None:
    llm = FakeLLM(
        [
            tool_turn("calculate", {"expression": "1 / 0"}),
            tool_turn("calculate", {"expression": "1 / 1"}),
            answer_turn("1"),
        ]
    )

    response = await agent_with(llm).complete("Divide")

    assert [i.is_error for i in response.tool_invocations] == [True, False]
    assert llm.requests[1][-1].tool_results[0].is_error


async def test_an_answer_that_does_not_match_the_schema_is_sent_back() -> None:
    invalid = tool_turn(FINAL_ANSWER, {"answer": "42", "confidence": "certain"})
    llm = FakeLLM([invalid, answer_turn("42", confidence="medium")])

    response = await agent_with(llm).complete("What is the answer?")

    assert response.answer.confidence == "medium"
    rejection = llm.requests[1][-1].tool_results[0]
    assert rejection.is_error
    assert "does not match the schema" in rejection.content


async def test_plain_text_instead_of_an_answer_gets_a_reminder() -> None:
    prose = ModelTurn(text="The answer is 4.", usage=Usage(1, 1), stop_reason="end_turn")
    llm = FakeLLM([prose, answer_turn("4")])

    response = await agent_with(llm).complete("What is 2 + 2?")

    assert response.answer.answer == "4"
    assert "final_answer" in llm.requests[1][-1].text


async def test_the_step_limit_ends_the_run_with_an_error() -> None:
    llm = FakeLLM([tool_turn("calculate", {"expression": "1"}) for _ in range(3)])
    agent = agent_with(llm, max_steps=3)

    events = [event async for event in agent.run("Loop forever")]
    assert isinstance(events[-1], ErrorEvent)
    assert "3 steps" in events[-1].message

    llm = FakeLLM([tool_turn("calculate", {"expression": "1"}) for _ in range(3)])
    with pytest.raises(AgentError, match="3 steps"):
        await agent_with(llm, max_steps=3).complete("Loop forever")
