"""Item schemas for request/response validation."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ItemBase(BaseModel):
    """Base item schema with shared attributes."""

    name: str = Field(..., min_length=1, max_length=255, description="Item name")
    description: str | None = Field(None, max_length=1000, description="Item description")
    price: float = Field(..., gt=0, description="Item price (must be positive)")
    is_active: bool = Field(True, description="Whether the item is active")


class ItemCreate(ItemBase):
    """Schema for creating a new item."""
    pass


class ItemUpdate(BaseModel):
    """Schema for updating an item (all fields optional)."""

    name: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = Field(None, max_length=1000)
    price: float | None = Field(None, gt=0)
    is_active: bool | None = None


class Item(ItemBase):
    """Schema for item response (includes ID and timestamps)."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
