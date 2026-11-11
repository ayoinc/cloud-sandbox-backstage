"""Storage interface of the items resource."""

from typing import Protocol

from app.schemas import Item, ItemIn


class ItemRepository(Protocol):
    """Operations the items routes need from a store."""

    async def list_all(self, *, skip: int, limit: int) -> list[Item]: ...

    async def get(self, item_id: int) -> Item | None: ...

    async def create(self, data: ItemIn) -> Item: ...

    async def replace(self, item_id: int, data: ItemIn) -> Item | None: ...

    async def delete(self, item_id: int) -> bool: ...
