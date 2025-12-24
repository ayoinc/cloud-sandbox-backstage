"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import Annotated

from pydantic import AnyHttpUrl, BeforeValidator, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


def parse_cors(v: str | list[str]) -> list[str]:
    """Parse CORS origins from string or list."""
    if isinstance(v, str) and not v.startswith("["):
        return [i.strip() for i in v.split(",")]
    if isinstance(v, list):
        return v
    raise ValueError(v)


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Application
    PROJECT_NAME: str = "${{ values.name }}"
    DESCRIPTION: str = "${{ values.description }}"
    VERSION: str = "0.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "development"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # API
    API_V1_PREFIX: str = "/api/v1"
    OPENAPI_ENABLED: bool = True

{%- if values.enable_cors %}
    # CORS
    CORS_ORIGINS: Annotated[list[AnyHttpUrl], BeforeValidator(parse_cors)] = []
{%- endif %}

{%- if values.database_type == 'postgresql' %}
    # Database
    DATABASE_HOST: str = "localhost"
    DATABASE_PORT: int = 5432
    DATABASE_USER: str = "postgres"
    DATABASE_PASSWORD: str = ""
    DATABASE_NAME: str = "${{ values.name | replace('-', '_') }}"
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        """Construct async database URL."""
        return f"postgresql+asyncpg://{self.DATABASE_USER}:{self.DATABASE_PASSWORD}@{self.DATABASE_HOST}:{self.DATABASE_PORT}/{self.DATABASE_NAME}"
{%- elif values.database_type == 'mysql' %}
    # Database
    DATABASE_HOST: str = "localhost"
    DATABASE_PORT: int = 3306
    DATABASE_USER: str = "root"
    DATABASE_PASSWORD: str = ""
    DATABASE_NAME: str = "${{ values.name | replace('-', '_') }}"
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10

    @computed_field
    @property
    def DATABASE_URL(self) -> str:
        """Construct async database URL."""
        return f"mysql+aiomysql://{self.DATABASE_USER}:{self.DATABASE_PASSWORD}@{self.DATABASE_HOST}:{self.DATABASE_PORT}/{self.DATABASE_NAME}"
{%- elif values.database_type == 'mongodb' %}
    # MongoDB
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DATABASE: str = "${{ values.name | replace('-', '_') }}"
{%- endif %}

{%- if values.enable_caching or values.database_type == 'redis' %}
    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: str = ""
    REDIS_DB: int = 0

    @computed_field
    @property
    def REDIS_URL(self) -> str:
        """Construct Redis URL."""
        if self.REDIS_PASSWORD:
            return f"redis://:{self.REDIS_PASSWORD}@{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
{%- endif %}

{%- if values.auth_type == 'jwt' %}
    # JWT Authentication
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7
{%- elif values.auth_type == 'oauth2' %}
    # OAuth2 / OIDC
    OAUTH2_ISSUER: str = ""
    OAUTH2_CLIENT_ID: str = ""
    OAUTH2_CLIENT_SECRET: str = ""
    OAUTH2_REDIRECT_URI: str = "http://localhost:8000/api/v1/auth/callback"
{%- elif values.auth_type == 'api-key' %}
    # API Key
    API_KEY_HEADER: str = "X-API-Key"
    VALID_API_KEYS: list[str] = []
{%- endif %}

{%- if values.enable_rate_limiting %}
    # Rate Limiting
    RATE_LIMIT_REQUESTS: int = 100
    RATE_LIMIT_WINDOW_SECONDS: int = 60
{%- endif %}

{%- if values.enable_logging %}
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "json"  # json or console
{%- endif %}


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()


settings = get_settings()
