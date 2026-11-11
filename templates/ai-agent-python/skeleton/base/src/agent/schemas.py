"""Request and response models of the HTTP API, and the agent's structured answer."""

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class AgentAnswer(BaseModel):
    """The structured result of a run.

    The model has to produce exactly this shape: it is offered as the schema
    of the ``final_answer`` tool and validated before it leaves the service.
    Change the fields to what your callers need. Keep every field required
    and avoid defaults, so that providers can enforce the schema strictly.
    """

    model_config = ConfigDict(extra="forbid")

    answer: str = Field(description="The answer to the user's request, in plain language")
    confidence: Literal["low", "medium", "high"] = Field(
        description="How well the answer is supported by tool results and given facts"
    )
    follow_up_questions: list[str] = Field(
        description="Up to three questions the user may want to ask next; may be empty"
    )


class HistoryMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=8000)


class ChatRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    message: str = Field(min_length=1, max_length=8000, description="The user's request")
    history: list[HistoryMessage] = Field(
        default_factory=list, max_length=40, description="Earlier turns of the conversation"
    )


class ToolInvocation(BaseModel):
    name: str
    arguments: dict[str, Any]
    result: str
    is_error: bool


class TokenUsage(BaseModel):
    input_tokens: int
    output_tokens: int


class ChatResponse(BaseModel):
    answer: AgentAnswer
    tool_invocations: list[ToolInvocation]
    usage: TokenUsage
    steps: int
    model: str


# Events of the streaming endpoint. Each is sent as one server-sent event whose
# name is the value of ``type``.


class TextDeltaEvent(BaseModel):
    type: Literal["text_delta"] = "text_delta"
    text: str


class ToolStartedEvent(BaseModel):
    type: Literal["tool_started"] = "tool_started"
    name: str
    arguments: dict[str, Any]


class ToolFinishedEvent(BaseModel):
    type: Literal["tool_finished"] = "tool_finished"
    name: str
    result: str
    is_error: bool


class CompletedEvent(BaseModel):
    type: Literal["completed"] = "completed"
    response: ChatResponse


class ErrorEvent(BaseModel):
    type: Literal["error"] = "error"
    message: str


AgentEvent = TextDeltaEvent | ToolStartedEvent | ToolFinishedEvent | CompletedEvent | ErrorEvent
