"""Unit tests for the Python handler in src/main.py."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src"))

import main  # noqa: E402  (imported after src/ is put on the path)


def test_handler_returns_greeting(monkeypatch):
    monkeypatch.setenv("ENVIRONMENT", "test")

    response = main.handler({}, None)

    assert response["statusCode"] == 200
    assert json.loads(response["body"]) == {
        "message": "Hello from ${{ values.name }}",
        "environment": "test",
    }


def test_handler_without_environment(monkeypatch):
    monkeypatch.delenv("ENVIRONMENT", raising=False)

    body = json.loads(main.handler({}, None)["body"])

    assert body["environment"] == "unknown"
