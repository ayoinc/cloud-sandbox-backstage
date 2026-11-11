"""Configuration, read from environment variables.

Provider credentials are deliberately absent: the provider SDK reads them from
the environment itself, so they never pass through this code or its logs.
"""

import os
from functools import lru_cache

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

{% if values.provider == 'bedrock' %}from agent.defaults import DEFAULT_AWS_REGION, DEFAULT_MODEL{% else %}from agent.defaults import DEFAULT_MODEL{% endif %}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="AGENT_", extra="ignore")

    model: str = Field(default=DEFAULT_MODEL, description="Model id sent to the provider")
    max_output_tokens: int = Field(default=2048, ge=256, le=64_000)
    max_steps: int = Field(
        default=8, ge=1, le=50, description="Model turns allowed for one request"
    )
    tool_timeout_seconds: float = Field(default=20, gt=0, le=600)
    request_timeout_seconds: float = Field(default=120, gt=0, le=900)
    api_token: SecretStr | None = Field(
        default=None,
        min_length=32,
        description="Bearer token callers must present. Unset: no authentication.",
    )
{%- if values.provider == 'bedrock' %}
    aws_region: str = Field(
        default_factory=lambda: (
            os.environ.get("AWS_REGION")
            or os.environ.get("AWS_DEFAULT_REGION")
            or DEFAULT_AWS_REGION
        ),
        description="Region of the Bedrock runtime endpoint",
    )
{%- endif %}


@lru_cache
def get_settings() -> Settings:
    return Settings()


def credentials_present() -> bool:
    """Whether the environment holds what the provider SDK needs to authenticate."""
{%- if values.provider == 'bedrock' %}
    # On AWS the credentials come from the workload's role, which the SDK
    # resolves when it makes the first call: there is nothing to check up front.
    return True
{%- elif values.provider == 'anthropic' %}
    return bool(os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("ANTHROPIC_AUTH_TOKEN"))
{%- else %}
    return bool(os.environ.get("OPENAI_API_KEY"))
{%- endif %}
