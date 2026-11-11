"""A scripted model for tests and offline eval runs."""

from collections.abc import AsyncIterator, Sequence
from typing import Any

from agent.llm.base import Message, ModelTurn, ToolCall, ToolSpec, Usage


def tool_turn(name: str, arguments: dict[str, Any], *, text: str = "", id: str = "") -> ModelTurn:
    """A model turn that calls one tool."""
    call = ToolCall(id=id or f"call_{name}", name=name, arguments=arguments)
    return ModelTurn(text=text, tool_calls=(call,), usage=Usage(10, 5), stop_reason="tool_use")


def answer_turn(answer: str, *, confidence: str = "high") -> ModelTurn:
    """A model turn that gives the final answer."""
    return tool_turn(
        "final_answer",
        {"answer": answer, "confidence": confidence, "follow_up_questions": []},
    )


class FakeLLM:
    """Returns the scripted turns in order and records what it was sent."""

    provider = "fake"
    model = "fake-model"

    def __init__(self, turns: Sequence[ModelTurn]) -> None:
        self._turns = list(turns)
        self.requests: list[list[Message]] = []
        self.tools: list[ToolSpec] = []
        self.system = ""

    async def stream(
        self, *, system: str, messages: Sequence[Message], tools: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        self.system = system
        self.tools = list(tools)
        self.requests.append(list(messages))
        if not self._turns:
            raise AssertionError("The model was called more often than the script allows")
        turn = self._turns.pop(0)
        # Text arrives in fragments, as it does from a real provider.
        for word in turn.text.split(" ") if turn.text else []:
            yield word + " "
        yield turn
