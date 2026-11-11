{%- set password_auth = values.auth_type in ['jwt', 'basic-auth'] -%}
{%- set server_db = values.database_type in ['postgresql', 'mysql'] -%}
{%- set has_secrets = server_db or values.auth_type != 'none' -%}
"""Settings are read from environment variables."""

import pytest
{%- if has_secrets %}
from pydantic import ValidationError
{%- endif %}

from app.config import {% if has_secrets %}DEVELOPMENT_ONLY_DEFAULTS, {% endif %}Settings


def test_defaults_describe_a_development_environment() -> None:
    settings = Settings(_env_file=None)

    assert settings.app_name == "${{ values.name }}"
    assert settings.app_env == "development"


def test_environment_variables_override_the_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_NAME", "renamed")
    monkeypatch.setenv("APP_ENV", "staging")

    settings = Settings(_env_file=None)

    assert (settings.app_name, settings.app_env) == ("renamed", "staging")
{%- if has_secrets %}


def test_production_refuses_the_development_defaults() -> None:
    with pytest.raises(ValidationError) as error:
        Settings(_env_file=None, app_env="production")

    for name in DEVELOPMENT_ONLY_DEFAULTS:
        assert name.upper() in str(error.value)


def test_production_accepts_replaced_values(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
{%- if values.database_type == 'postgresql' %}
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://service:s3cret@db.internal/app")
{%- elif values.database_type == 'mysql' %}
    monkeypatch.setenv("DATABASE_URL", "mysql+aiomysql://service:s3cret@db.internal/app")
{%- endif %}
{%- if password_auth %}
    monkeypatch.setenv("AUTH_PASSWORD", "a-password-set-for-production")
{%- endif %}
{%- if values.auth_type == 'jwt' %}
    monkeypatch.setenv("JWT_SECRET", "a-signing-secret-set-for-production-0123456789")
{%- endif %}
{%- if values.auth_type == 'api-key' %}
    monkeypatch.setenv("API_KEYS", '["a-key-set-for-production"]')
{%- endif %}

    settings = Settings(_env_file=None)

    assert settings.app_env == "production"
{%- endif %}
