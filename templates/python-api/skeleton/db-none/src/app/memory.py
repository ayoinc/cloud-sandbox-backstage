"""Item repository that keeps items in the memory of the process."""

from app.schemas import Item, ItemIn


class InMemoryItemRepository:
    """Items live until the process stops and are not shared between processes."""

    def __init__(self) -> None:
        self._items: dict[int, Item] = {}
        self._next_id = 1

    async def list_all(self, *, skip: int, limit: int) -> list[Item]:
        return list(self._items.values())[skip : skip + limit]

    async def get(self, item_id: int) -> Item | None:
        return self._items.get(item_id)

    async def create(self, data: ItemIn) -> Item:
        item = Item(id=self._next_id, **data.model_dump())
        self._items[item.id] = item
        self._next_id += 1
        return item

    async def replace(self, item_id: int, data: ItemIn) -> Item | None:
        if item_id not in self._items:
            return None
        item = Item(id=item_id, **data.model_dump())
        self._items[item_id] = item
        return item

    async def delete(self, item_id: int) -> bool:
        return self._items.pop(item_id, None) is not None
