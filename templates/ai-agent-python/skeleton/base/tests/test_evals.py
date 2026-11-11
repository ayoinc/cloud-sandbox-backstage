"""The eval harness itself is tested offline, with a scripted model."""

from pathlib import Path

from agent.loop import Agent
from agent.tools import default_registry
from evals.run import DEFAULT_DATASET, run_case, run_dataset, summarise
from evals.scoring import EvalCase, Expectation, load_dataset
from tests.fakes import FakeLLM, answer_turn, tool_turn


def case(**expect: object) -> EvalCase:
    return EvalCase(
        id="case", input="What is 6 times 7?", expect=Expectation.model_validate(expect)
    )


def agent(*turns: object) -> Agent:
    return Agent(FakeLLM(list(turns)), default_registry(), max_steps=4)  # type: ignore[arg-type]


def test_the_dataset_is_valid_and_only_names_existing_tools() -> None:
    cases = load_dataset(DEFAULT_DATASET)
    assert len(cases) >= 5
    known = set(default_registry().names)
    for entry in cases:
        assert set(entry.expect.tools or []) <= known, entry.id
        assert set(entry.expect.tool_arguments) <= known, entry.id


def test_duplicate_case_ids_are_rejected(tmp_path: Path) -> None:
    line = '{"id": "same", "input": "Hello", "expect": {}}\n'
    dataset = tmp_path / "dataset.jsonl"
    dataset.write_text(line * 2)
    try:
        load_dataset(dataset)
    except ValueError as error:
        assert "not unique" in str(error)
    else:
        raise AssertionError("expected a ValueError")


async def test_a_case_passes_when_every_expectation_holds() -> None:
    result = await run_case(
        agent(tool_turn("calculate", {"expression": "6 * 7"}), answer_turn("It is 4,2.")),
        case(
            tools=["calculate"],
            tool_arguments={"calculate": {"expression": "6 * 7"}},
            answer_contains=["42"],
            confidence=["high"],
        ),
    )
    assert result.passed, result.failures
    assert (result.steps, result.input_tokens, result.output_tokens) == (2, 20, 10)


async def test_each_unmet_expectation_is_reported() -> None:
    result = await run_case(
        agent(answer_turn("About forty.", confidence="low")),
        case(
            tools=["calculate"],
            tool_arguments={"calculate": {"expression": "6 * 7"}},
            answer_contains=["42"],
            confidence=["high"],
            max_steps=0,
        ),
    )
    assert not result.passed
    assert len(result.failures) == 5


async def test_a_run_without_an_answer_fails_the_case() -> None:
    looping = [tool_turn("calculate", {"expression": "1"}) for _ in range(4)]
    result = await run_case(agent(*looping), case())
    assert not result.passed
    assert "4 steps" in result.failures[0]


async def test_the_summary_reports_the_pass_rate() -> None:
    results = await run_dataset(
        agent(answer_turn("42"), answer_turn("41")),
        [
            EvalCase(id="first", input="?", expect=Expectation(answer_contains=["42"])),
            EvalCase(id="second", input="?", expect=Expectation(answer_contains=["42"])),
        ],
        concurrency=1,
    )
    summary = summarise(results, "fake-model")
    assert (summary["cases"], summary["passed"], summary["pass_rate"]) == (2, 1, 0.5)
