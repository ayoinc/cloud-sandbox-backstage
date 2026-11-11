{%- set password_auth = values.auth_type in ['jwt', 'basic-auth'] -%}
{%- set server_db = values.database_type in ['postgresql', 'mysql'] -%}
{%- set has_secrets = server_db or values.auth_type != 'none' -%}
"""Settings read from environment variables and an optional .env file."""

from typing import Literal{% if has_secrets %}, Self{% endif %}

{% if has_secrets -%}
from pydantic import {% if password_auth %}SecretStr, {% endif %}model_validator
{% endif -%}
from pydantic_settings import BaseSettings, SettingsConfigDict
{%- if has_secrets %}

# Settings whose default is public knowledge and must be replaced before production.
DEVELOPMENT_ONLY_DEFAULTS = [
{%- if server_db %}
    "database_url",
{%- endif %}
{%- if password_auth %}
    "auth_password",
{%- endif %}
{%- if values.auth_type == 'jwt' %}
    "jwt_secret",
{%- endif %}
{%- if values.auth_type == 'api-key' %}
    "api_keys",
{%- endif %}
]
{%- endif %}


class Settings(BaseSettings):
    """Every field is set by the environment variable of the same name in upper case."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "${{ values.name }}"
    app_env: Literal["development", "staging", "production"] = "development"
{%- if values.enable_logging %}
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
{%- endif %}
{%- if values.sql %}

    # SQLAlchemy URL of the database. The application connects on the first query.
{%- if values.database_type == 'postgresql' %}
    database_url: str = "postgresql+asyncpg://app:app@localhost:5432/app"
{%- elif values.database_type == 'mysql' %}
    database_url: str = "mysql+aiomysql://app:app@localhost:3306/app"
{%- else %}
    database_url: str = "sqlite+aiosqlite:///./app.db"
{%- endif %}
{%- endif %}
{%- if values.enable_caching %}

    # Without REDIS_URL items are cached in the memory of each process.
    redis_url: str | None = None
    cache_ttl_seconds: int = 60
{%- endif %}
{%- if password_auth %}

    auth_username: str = "admin"
    auth_password: SecretStr = SecretStr("change-me")
{%- endif %}
{%- if values.auth_type == 'jwt' %}
    jwt_secret: SecretStr = SecretStr("development-only-secret-replace-me-0123456789")
    jwt_expire_minutes: int = 30
{%- endif %}
{%- if values.auth_type == 'api-key' %}

    # JSON list, for example API_KEYS='["key-one","key-two"]'.
    api_keys: list[str] = ["dev-api-key"]
{%- endif %}
{%- if values.enable_rate_limiting %}

    # Requests allowed per client address, in the notation of the limits library.
    rate_limit: str = "100/minute"
{%- endif %}
{%- if values.enable_cors %}

    # JSON list, for example CORS_ORIGINS='["https://app.example.com"]'.
    cors_origins: list[str] = ["http://localhost:3000"]
{%- endif %}
{%- if has_secrets %}

    @model_validator(mode="after")
    def refuse_development_defaults_in_production(self) -> Self:
        if self.app_env == "production":
            unchanged = [
                name
                for name in DEVELOPMENT_ONLY_DEFAULTS
                if getattr(self, name) == type(self).model_fields[name].default
            ]
            if unchanged:
                variables = ", ".join(name.upper() for name in unchanged)
                raise ValueError(f"set {variables} before running with APP_ENV=production")
        return self
{%- endif %}
