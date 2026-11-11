"""Tools the model may call.

A tool is an async or plain function that takes one pydantic model and returns
text. The model's arguments are validated against that model before the
function runs; a validation error or an exception is returned to the model as
a tool error, so that it can correct itself.
"""

import ast
import asyncio
import inspect
import operator
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from datetime import datetime
from typing import Any, cast
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from pydantic import BaseModel, ConfigDict, Field, ValidationError

from agent.llm.base import ToolCall, ToolResult, ToolSpec

type ToolHandler[ArgsT: BaseModel] = Callable[[ArgsT], str | Awaitable[str]]


def json_schema(model: type[BaseModel]) -> dict[str, Any]:
    """The JSON Schema of a pydantic model without the titles pydantic adds."""

    def strip(node: Any) -> Any:
        if isinstance(node, dict):
            return {
                key: strip(value)
                for key, value in node.items()
                if not (key == "title" and isinstance(value, str))
            }
        if isinstance(node, list):
            return [strip(item) for item in node]
        return node

    return cast(dict[str, Any], strip(model.model_json_schema()))


@dataclass(frozen=True, slots=True)
class Tool:
    name: str
    description: str
    args_model: type[BaseModel]
    handler: Callable[[Any], str | Awaitable[str]]

    @property
    def spec(self) -> ToolSpec:
        return ToolSpec(self.name, self.description, json_schema(self.args_model))


class ToolRegistry:
    def __init__(self, *, timeout_seconds: float = 20) -> None:
        self._tools: dict[str, Tool] = {}
        self._timeout = timeout_seconds

    def tool[ArgsT: BaseModel](
        self, name: str, description: str, args_model: type[ArgsT]
    ) -> Callable[[ToolHandler[ArgsT]], ToolHandler[ArgsT]]:
        """Register the decorated function as a tool."""

        def register(handler: ToolHandler[ArgsT]) -> ToolHandler[ArgsT]:
            if name in self._tools:
                raise ValueError(f"The tool {name!r} is already registered")
            self._tools[name] = Tool(name, description, args_model, handler)
            return handler

        return register

    @property
    def names(self) -> list[str]:
        return list(self._tools)

    def specs(self) -> list[ToolSpec]:
        return [tool.spec for tool in self._tools.values()]

    async def execute(self, call: ToolCall) -> ToolResult:
        """Run a tool call. Never raises: failures become error results."""
        tool = self._tools.get(call.name)
        if tool is None:
            return self._error(call, f"Unknown tool {call.name!r}. Available: {self.names}")
        try:
            arguments = tool.args_model.model_validate(call.arguments)
        except ValidationError as error:
            return self._error(call, f"Invalid arguments: {error}")
        try:
            async with asyncio.timeout(self._timeout):
                outcome = tool.handler(arguments)
                content = await outcome if inspect.isawaitable(outcome) else outcome
        except TimeoutError:
            return self._error(call, f"The tool did not finish within {self._timeout:g} seconds")
        except Exception as error:
            return self._error(call, f"{type(error).__name__}: {error}")
        return ToolResult(call.id, call.name, content)

    @staticmethod
    def _error(call: ToolCall, message: str) -> ToolResult:
        return ToolResult(call.id, call.name, message, is_error=True)


# The sample tools. They are deterministic and need no network, which keeps the
# tests and the evals reproducible. Replace them with the tools of your domain.


class CurrentTimeArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")

    timezone: str = Field(description="IANA time zone name, for example Europe/London or UTC")


class CalculateArgs(BaseModel):
    model_config = ConfigDict(extra="forbid")

    expression: str = Field(
        max_length=200,
        description="Arithmetic expression with numbers, + - * / // % ** and parentheses",
    )


_BINARY_OPERATORS: dict[type[ast.operator], Callable[[Any, Any], Any]] = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod,
    ast.Pow: operator.pow,
}
_UNARY_OPERATORS: dict[type[ast.unaryop], Callable[[Any], Any]] = {
    ast.UAdd: operator.pos,
    ast.USub: operator.neg,
}


def evaluate(expression: str) -> int | float:
    """Evaluate arithmetic without ``eval``: only numbers and operators are accepted."""

    def visit(node: ast.AST) -> int | float:
        if (
            isinstance(node, ast.Constant)
            and isinstance(node.value, int | float)
            and not isinstance(node.value, bool)
        ):
            return node.value
        if isinstance(node, ast.BinOp) and type(node.op) in _BINARY_OPERATORS:
            left, right = visit(node.left), visit(node.right)
            if isinstance(node.op, ast.Pow) and (abs(left) > 1e6 or abs(right) > 100):
                raise ValueError("The power is too large")
            return cast(int | float, _BINARY_OPERATORS[type(node.op)](left, right))
        if isinstance(node, ast.UnaryOp) and type(node.op) in _UNARY_OPERATORS:
            return cast(int | float, _UNARY_OPERATORS[type(node.op)](visit(node.operand)))
        raise ValueError("Only numbers and the operators + - * / // % ** are supported")

    return visit(ast.parse(expression, mode="eval").body)


def default_registry(*, timeout_seconds: float = 20) -> ToolRegistry:
    registry = ToolRegistry(timeout_seconds=timeout_seconds)

    @registry.tool(
        "get_current_time",
        "Get the current date and time in a time zone. Use it whenever the answer depends on "
        "today's date or the time of day.",
        CurrentTimeArgs,
    )
    def get_current_time(args: CurrentTimeArgs) -> str:
        try:
            zone = ZoneInfo(args.timezone)
        except (ZoneInfoNotFoundError, ValueError) as error:
            raise ValueError(f"Unknown time zone {args.timezone!r}") from error
        return datetime.now(zone).isoformat(timespec="seconds")

    @registry.tool(
        "calculate",
        "Evaluate an arithmetic expression exactly. Use it for every calculation instead of "
        "computing in your head.",
        CalculateArgs,
    )
    def calculate(args: CalculateArgs) -> str:
        return str(evaluate(args.expression))

    return registry
