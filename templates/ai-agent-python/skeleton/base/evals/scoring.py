"""Eval cases and the checks that score a response against them."""

import json
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

from agent.schemas import ChatResponse


class Expectation(BaseModel):
    model_config = ConfigDict(extra="forbid")

    tools: list[str] | None = Field(
        default=None, description="Exactly the tools that must be called, in any order"
    )
    tool_arguments: dict[str, dict[str, Any]] = Field(
        default_factory=dict, description="Arguments at least one call of a tool must include"
    )
    answer_contains: list[str] = Field(
        default_factory=list, description="Texts the answer must contain, ignoring case"
    )
    confidence: list[Literal["low", "medium", "high"]] | None = Field(
        default=None, description="Accepted confidence levels"
    )
    max_steps: int = Field(default=6, description="Model turns the run may take")


class EvalCase(BaseModel):
    model_config = ConfigDict(extra="forbid")

    id: str
    input: str
    expect: Expectation


class CaseResult(BaseModel):
    id: str
    passed: bool
    failures: list[str]
    steps: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    seconds: float = 0


def load_dataset(path: Path) -> list[EvalCase]:
    cases = [
        EvalCase.model_validate(json.loads(line))
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    ids = [case.id for case in cases]
    if len(ids) != len(set(ids)):
        raise ValueError(f"The case ids in {path} are not unique")
    return cases


def _normalise(text: str) -> str:
    """Lower case, without the separators models put into numbers."""
    return text.lower().replace(",", "").replace("\u202f", "").replace("\u00a0", "")


def score(case: EvalCase, response: ChatResponse) -> list[str]:
    """The reasons the response fails the case; empty when it passes."""
    expect = case.expect
    failures: list[str] = []
    called = [invocation.name for invocation in response.tool_invocations]

    if expect.tools is not None and set(called) != set(expect.tools):
        failures.append(f"called tools {sorted(set(called))}, expected {sorted(expect.tools)}")

    for tool, wanted in expect.tool_arguments.items():
        calls = [i.arguments for i in response.tool_invocations if i.name == tool]
        if not any(wanted.items() <= arguments.items() for arguments in calls):
            failures.append(f"no call of {tool} had the arguments {wanted}; got {calls}")

    answer = _normalise(response.answer.answer)
    failures.extend(
        f"the answer does not contain {text!r}"
        for text in expect.answer_contains
        if _normalise(text) not in answer
    )

    if expect.confidence is not None and response.answer.confidence not in expect.confidence:
        failures.append(
            f"confidence is {response.answer.confidence}, expected one of {expect.confidence}"
        )

    if response.steps > expect.max_steps:
        failures.append(f"took {response.steps} steps, at most {expect.max_steps} allowed")

    return failures
