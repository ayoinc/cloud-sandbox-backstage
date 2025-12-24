"""Item CRUD routes (example)."""

from typing import Annotated
from uuid import UUID, uuid4

from fastapi import APIRouter, HTTPException, Path, Query

from ${{ values.name | replace('-', '_') }}.schemas.item import Item, ItemCreate, ItemUpdate

router = APIRouter()

# In-memory storage for example (replace with database)
_items: dict[UUID, Item] = {}


@router.get("/", response_model=list[Item])
async def list_items(
    skip: Annotated[int, Query(ge=0, description="Number of items to skip")] = 0,
    limit: Annotated[int, Query(ge=1, le=100, description="Number of items to return")] = 10,
) -> list[Item]:
    """List all items with pagination."""
    items = list(_items.values())
    return items[skip : skip + limit]


@router.get("/{item_id}", response_model=Item)
async def get_item(
    item_id: Annotated[UUID, Path(description="The ID of the item to retrieve")],
) -> Item:
    """Get a specific item by ID."""
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="Item not found")
    return _items[item_id]


@router.post("/", response_model=Item, status_code=201)
async def create_item(item_in: ItemCreate) -> Item:
    """Create a new item."""
    item_id = uuid4()
    item = Item(
        id=item_id,
        **item_in.model_dump(),
    )
    _items[item_id] = item
    return item


@router.put("/{item_id}", response_model=Item)
async def update_item(
    item_id: Annotated[UUID, Path(description="The ID of the item to update")],
    item_in: ItemUpdate,
) -> Item:
    """Update an existing item."""
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="Item not found")
    
    stored_item = _items[item_id]
    update_data = item_in.model_dump(exclude_unset=True)
    updated_item = stored_item.model_copy(update=update_data)
    _items[item_id] = updated_item
    return updated_item


@router.delete("/{item_id}", status_code=204)
async def delete_item(
    item_id: Annotated[UUID, Path(description="The ID of the item to delete")],
) -> None:
    """Delete an item."""
    if item_id not in _items:
        raise HTTPException(status_code=404, detail="Item not found")
    del _items[item_id]
