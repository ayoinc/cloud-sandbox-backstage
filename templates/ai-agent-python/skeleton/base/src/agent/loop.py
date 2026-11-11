"""The agent loop: call the model, run the tools it asks for, repeat.

A run ends when the model calls the ``final_answer`` tool with arguments that
validate as ``AgentAnswer``. That is how the structured output is obtained on
every provider: the answer schema is a tool schema, and an answer that does
not validate goes back to the model as a tool error to be corrected.
"""

from collections.abc import AsyncIterator, Sequence

from opentelemetry import trace
from opentelemetry.context import Context
from pydantic import ValidationError

from agent.llm.base import LLMClient, Message, ModelTurn, ToolCall, ToolResult, ToolSpec, Usage
from agent.schemas import (
    AgentAnswer,
    AgentEvent,
    ChatResponse,
    CompletedEvent,
    ErrorEvent,
    TextDeltaEvent,
    TokenUsage,
    ToolFinishedEvent,
    ToolInvocation,
    ToolStartedEvent,
)
from agent.tools import ToolRegistry, json_schema

FINAL_ANSWER = "final_answer"

SYSTEM_PROMPT = """\
You are a careful assistant that answers requests accurately and concisely.

Rules:
- Use the tools whenever they can give you a fact: never guess the current time and never \
calculate without the calculator.
- If a tool returns an error, correct the arguments and try again, or explain what is missing.
- When you are done, call the final_answer tool exactly once. Do not answer in plain text.
- If you cannot answer, say so in final_answer with low confidence. Do not invent facts.
"""

_FINAL_ANSWER_SPEC = ToolSpec(
    name=FINAL_ANSWER,
    description="Give the final answer to the user. Call this exactly once, as the last step.",
    parameters=json_schema(AgentAnswer),
    strict=True,
)

_tracer = trace.get_tracer("agent")


class Agent:
    def __init__(
        self,
        llm: LLMClient,
        tools: ToolRegistry,
        *,
        max_steps: int = 8,
        system_prompt: str = SYSTEM_PROMPT,
    ) -> None:
        self.llm = llm
        self.tools = tools
        self.max_steps = max_steps
        self.system_prompt = system_prompt

    async def run(self, message: str, history: Sequence[Message] = ()) -> AsyncIterator[AgentEvent]:
        """Run the agent on one request, yielding events as they happen.

        The last event is ``CompletedEvent`` or ``ErrorEvent``.
        """
        # The span is not made current: a generator can be resumed and closed from
        # different contexts. Child spans get it as their parent explicitly.
        span = _tracer.start_span(
            "invoke_agent",
            attributes={
                "gen_ai.operation.name": "invoke_agent",
                "gen_ai.provider.name": self.llm.provider,
                "gen_ai.request.model": self.llm.model,
            },
        )
        parent = trace.set_span_in_context(span)
        try:
            messages = [*history, Message(role="user", text=message)]
            specs = [*self.tools.specs(), _FINAL_ANSWER_SPEC]
            invocations: list[ToolInvocation] = []
            usage = Usage()

            for step in range(1, self.max_steps + 1):
                turn: ModelTurn | None = None
                async for item in self._model_turn(parent, messages, specs):
                    if isinstance(item, ModelTurn):
                        turn = item
                    else:
                        yield TextDeltaEvent(text=item)
                if turn is None:
                    raise RuntimeError("The model client ended a turn without a response")
                usage += turn.usage
                messages.append(
                    Message(role="assistant", text=turn.text, tool_calls=turn.tool_calls)
                )

                if not turn.tool_calls:
                    messages.append(
                        Message(
                            role="user",
                            text="Call the final_answer tool now to give your answer.",
                        )
                    )
                    continue

                answer: AgentAnswer | None = None
                results: list[ToolResult] = []
                for call in turn.tool_calls:
                    if call.name == FINAL_ANSWER:
                        answer, result = _parse_answer(call)
                    else:
                        yield ToolStartedEvent(name=call.name, arguments=call.arguments)
                        result = await self._execute(parent, call)
                        invocations.append(
                            ToolInvocation(
                                name=call.name,
                                arguments=call.arguments,
                                result=result.content,
                                is_error=result.is_error,
                            )
                        )
                        yield ToolFinishedEvent(
                            name=call.name, result=result.content, is_error=result.is_error
                        )
                    results.append(result)

                if answer is not None:
                    span.set_attribute("gen_ai.usage.input_tokens", usage.input_tokens)
                    span.set_attribute("gen_ai.usage.output_tokens", usage.output_tokens)
                    span.set_attribute("agent.steps", step)
                    yield CompletedEvent(
                        response=ChatResponse(
                            answer=answer,
                            tool_invocations=invocations,
                            usage=TokenUsage(
                                input_tokens=usage.input_tokens,
                                output_tokens=usage.output_tokens,
                            ),
                            steps=step,
                            model=self.llm.model,
                        )
                    )
                    return
                messages.append(Message(role="tool", tool_results=tuple(results)))

            span.set_status(trace.StatusCode.ERROR, "step limit reached")
            yield ErrorEvent(
                message=f"The agent did not reach an answer within {self.max_steps} steps."
            )
        finally:
            span.end()

    async def complete(self, message: str, history: Sequence[Message] = ()) -> ChatResponse:
        """Run the agent to the end and return the result, or raise ``AgentError``."""
        async for event in self.run(message, history):
            if isinstance(event, CompletedEvent):
                return event.response
            if isinstance(event, ErrorEvent):
                raise AgentError(event.message)
        raise AgentError("The agent ended without a result.")

    async def _model_turn(
        self, parent: Context, messages: Sequence[Message], specs: Sequence[ToolSpec]
    ) -> AsyncIterator[str | ModelTurn]:
        span = _tracer.start_span(
            f"chat {self.llm.model}",
            context=parent,
            kind=trace.SpanKind.CLIENT,
            attributes={
                "gen_ai.operation.name": "chat",
                "gen_ai.provider.name": self.llm.provider,
                "gen_ai.request.model": self.llm.model,
            },
        )
        try:
            async for item in self.llm.stream(
                system=self.system_prompt, messages=messages, tools=specs
            ):
                if isinstance(item, ModelTurn):
                    span.set_attribute("gen_ai.usage.input_tokens", item.usage.input_tokens)
                    span.set_attribute("gen_ai.usage.output_tokens", item.usage.output_tokens)
                    span.set_attribute("gen_ai.response.finish_reasons", [item.stop_reason])
                yield item
        except Exception as error:
            span.record_exception(error)
            span.set_status(trace.StatusCode.ERROR, type(error).__name__)
            raise
        finally:
            span.end()

    async def _execute(self, parent: Context, call: ToolCall) -> ToolResult:
        with _tracer.start_as_current_span(
            f"execute_tool {call.name}",
            context=parent,
            attributes={"gen_ai.operation.name": "execute_tool", "gen_ai.tool.name": call.name},
        ) as span:
            result = await self.tools.execute(call)
            if result.is_error:
                span.set_status(trace.StatusCode.ERROR, "tool error")
            return result


class AgentError(Exception):
    """The agent could not produce an answer."""


def _parse_answer(call: ToolCall) -> tuple[AgentAnswer | None, ToolResult]:
    try:
        answer = AgentAnswer.model_validate(call.arguments)
    except ValidationError as error:
        return None, ToolResult(
            call.id, call.name, f"The answer does not match the schema: {error}", is_error=True
        )
    return answer, ToolResult(call.id, call.name, "Answer accepted.")
