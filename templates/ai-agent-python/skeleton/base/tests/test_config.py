import pytest
from pydantic import ValidationError

from agent.config import Settings
from agent.defaults import DEFAULT_MODEL, PROVIDER


def test_defaults() -> None:
    settings = Settings()
    assert settings.model == DEFAULT_MODEL
    assert settings.max_steps == 8
    assert settings.api_token is None
    assert PROVIDER in {"anthropic", "openai", "bedrock"}


def test_values_come_from_prefixed_environment_variables(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("AGENT_MODEL", "another-model")
    monkeypatch.setenv("AGENT_MAX_STEPS", "3")
    settings = Settings()
    assert (settings.model, settings.max_steps) == ("another-model", 3)


def test_the_api_token_is_secret_and_must_be_long(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("AGENT_API_TOKEN", "short")
    with pytest.raises(ValidationError):
        Settings()

    monkeypatch.setenv("AGENT_API_TOKEN", "t" * 40)
    settings = Settings()
    assert settings.api_token is not None
    assert "ttt" not in repr(settings)
