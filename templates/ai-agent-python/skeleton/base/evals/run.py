"""Run the eval dataset against the configured model.

    uv run python -m evals.run
    uv run python -m evals.run --min-pass-rate 0.9 --report evals/reports/latest.json

This calls the real provider, so it needs credentials and costs tokens. It
exits with status 1 when the pass rate is below the threshold.
"""

import argparse
import asyncio
import json
import sys
import time
from collections.abc import Sequence
from pathlib import Path

from agent.config import get_settings
from agent.loop import Agent, AgentError
from agent.tools import default_registry
from evals.scoring import CaseResult, EvalCase, load_dataset, score

DEFAULT_DATASET = Path(__file__).parent / "dataset.jsonl"


async def run_case(agent: Agent, case: EvalCase) -> CaseResult:
    started = time.perf_counter()
    try:
        response = await agent.complete(case.input)
    except AgentError as error:
        return CaseResult(
            id=case.id,
            passed=False,
            failures=[str(error)],
            seconds=time.perf_counter() - started,
        )
    failures = score(case, response)
    return CaseResult(
        id=case.id,
        passed=not failures,
        failures=failures,
        steps=response.steps,
        input_tokens=response.usage.input_tokens,
        output_tokens=response.usage.output_tokens,
        seconds=time.perf_counter() - started,
    )


async def run_dataset(
    agent: Agent, cases: Sequence[EvalCase], *, concurrency: int = 4
) -> list[CaseResult]:
    limit = asyncio.Semaphore(concurrency)

    async def limited(case: EvalCase) -> CaseResult:
        async with limit:
            return await run_case(agent, case)

    return list(await asyncio.gather(*(limited(case) for case in cases)))


def summarise(results: Sequence[CaseResult], model: str) -> dict[str, object]:
    passed = sum(result.passed for result in results)
    return {
        "model": model,
        "cases": len(results),
        "passed": passed,
        "pass_rate": passed / len(results) if results else 0.0,
        "input_tokens": sum(result.input_tokens for result in results),
        "output_tokens": sum(result.output_tokens for result in results),
        "results": [result.model_dump() for result in results],
    }


def print_table(results: Sequence[CaseResult]) -> None:
    width = max((len(result.id) for result in results), default=4)
    for result in results:
        status = "pass" if result.passed else "FAIL"
        print(f"{status}  {result.id:<{width}}  {result.steps} steps  {result.seconds:5.1f}s")
        for failure in result.failures:
            print(f"      - {failure}")


async def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--dataset", type=Path, default=DEFAULT_DATASET)
    parser.add_argument("--min-pass-rate", type=float, default=0.8)
    parser.add_argument("--concurrency", type=int, default=4)
    parser.add_argument("--report", type=Path, help="Write the results to this JSON file")
    arguments = parser.parse_args(argv)

    from agent.llm.provider import build_client

    settings = get_settings()
    agent = Agent(
        build_client(settings),
        default_registry(timeout_seconds=settings.tool_timeout_seconds),
        max_steps=settings.max_steps,
    )
    results = await run_dataset(
        agent, load_dataset(arguments.dataset), concurrency=arguments.concurrency
    )
    summary = summarise(results, settings.model)

    print_table(results)
    print(
        f"\n{summary['passed']} of {summary['cases']} cases passed "
        f"({summary['pass_rate']:.0%}) with {settings.model}; "
        f"{summary['input_tokens']} input and {summary['output_tokens']} output tokens"
    )
    if arguments.report:
        arguments.report.parent.mkdir(parents=True, exist_ok=True)
        arguments.report.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

    rate = summary["pass_rate"]
    return 0 if isinstance(rate, float) and rate >= arguments.min_pass_rate else 1


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
