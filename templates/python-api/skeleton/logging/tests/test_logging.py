"""Requests are logged, and log events are written as JSON at the configured level."""

import json

import pytest
import structlog
from httpx import AsyncClient

from app.log import configure_logging


async def test_every_request_is_logged(client: AsyncClient) -> None:
    with structlog.testing.capture_logs() as events:
        await client.get("/health")
        await client.get("/no-such-path")

    requests = [event for event in events if event["event"] == "request"]
    assert [(event["method"], event["path"], event["status_code"]) for event in requests] == [
        ("GET", "/health", 200),
        ("GET", "/no-such-path", 404),
    ]
    assert all(event["duration_ms"] >= 0 for event in requests)


def test_events_are_written_as_json(capsys: pytest.CaptureFixture[str]) -> None:
    configure_logging("INFO")

    structlog.get_logger("test").info("something happened", item_id=7)

    event = json.loads(capsys.readouterr().out)
    assert event["event"] == "something happened"
    assert event["item_id"] == 7
    assert event["level"] == "info"
    assert "timestamp" in event


def test_events_below_the_configured_level_are_dropped(
    capsys: pytest.CaptureFixture[str],
) -> None:
    configure_logging("WARNING")

    structlog.get_logger("test").info("not written")
    structlog.get_logger("test").warning("written")

    lines = capsys.readouterr().out.splitlines()
    assert [json.loads(line)["event"] for line in lines] == ["written"]
