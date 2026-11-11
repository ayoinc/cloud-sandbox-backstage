"""CRUD routes of the items resource."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies import get_repository
from app.repository import ItemRepository
from app.schemas import Item, ItemIn

router = APIRouter(prefix="/items", tags=["items"])

Repository = Annotated[ItemRepository, Depends(get_repository)]


def _not_found(item_id: int) -> HTTPException:
    return HTTPException(status.HTTP_404_NOT_FOUND, detail=f"Item {item_id} not found")


@router.get("")
async def list_items(
    repository: Repository,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> list[Item]:
    return await repository.list_all(skip=skip, limit=limit)


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_item(data: ItemIn, repository: Repository) -> Item:
    return await repository.create(data)


@router.get("/{item_id}")
async def get_item(item_id: int, repository: Repository) -> Item:
    item = await repository.get(item_id)
    if item is None:
        raise _not_found(item_id)
    return item


@router.put("/{item_id}")
async def replace_item(item_id: int, data: ItemIn, repository: Repository) -> Item:
    item = await repository.replace(item_id, data)
    if item is None:
        raise _not_found(item_id)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_item(item_id: int, repository: Repository) -> None:
    if not await repository.delete(item_id):
        raise _not_found(item_id)
