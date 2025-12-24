"""Unit tests for item schemas."""

import pytest
from pydantic import ValidationError

from ${{ values.name | replace('-', '_') }}.schemas.item import Item, ItemCreate, ItemUpdate


class TestItemCreate:
    """Tests for ItemCreate schema."""

    def test_valid_item_create(self) -> None:
        """Test creating item with valid data."""
        item = ItemCreate(
            name="Test Item",
            description="A test description",
            price=19.99,
            is_active=True,
        )
        assert item.name == "Test Item"
        assert item.price == 19.99

    def test_item_create_without_description(self) -> None:
        """Test creating item without optional description."""
        item = ItemCreate(name="Test Item", price=9.99)
        assert item.description is None

    def test_item_create_invalid_price(self) -> None:
        """Test that negative price raises validation error."""
        with pytest.raises(ValidationError):
            ItemCreate(name="Test Item", price=-10.0)

    def test_item_create_empty_name(self) -> None:
        """Test that empty name raises validation error."""
        with pytest.raises(ValidationError):
            ItemCreate(name="", price=10.0)


class TestItemUpdate:
    """Tests for ItemUpdate schema."""

    def test_partial_update(self) -> None:
        """Test updating only some fields."""
        update = ItemUpdate(name="Updated Name")
        assert update.name == "Updated Name"
        assert update.price is None
        assert update.description is None

    def test_full_update(self) -> None:
        """Test updating all fields."""
        update = ItemUpdate(
            name="Updated",
            description="New description",
            price=29.99,
            is_active=False,
        )
        assert update.name == "Updated"
        assert update.is_active is False
