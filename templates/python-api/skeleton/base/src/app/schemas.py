"""Request and response models."""

from pydantic import BaseModel, ConfigDict, Field


class ItemIn(BaseModel):
    """Fields a client sends to create or replace an item."""

    name: str = Field(min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=1000)


class Item(ItemIn):
    """An item as stored and returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: int


class HealthStatus(BaseModel):
    """Body of the liveness endpoint."""

    status: str
    environment: str


class ReadinessStatus(BaseModel):
    """Body of the readiness endpoint: one result per checked dependency."""

    status: str
    checks: dict[str, str]
