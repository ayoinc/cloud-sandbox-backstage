"""Cache interface, its Redis and in-memory implementations and the cached item repository."""

import time
from collections.abc import Callable
from typing import Protocol

from redis.asyncio import Redis

from app.repository import ItemRepository
from app.schemas import Item, ItemIn


class Cache(Protocol):
    """String cache with a time to live per entry."""

    async def get(self, key: str) -> str | None: ...

    async def set(self, key: str, value: str, ttl_seconds: int) -> None: ...

    async def delete(self, key: str) -> None: ...

    async def ping(self) -> None: ...

    async def close(self) -> None: ...


class InMemoryCache:
    """Cache in the memory of the process, used when no Redis URL is configured."""

    def __init__(self, clock: Callable[[], float] = time.monotonic) -> None:
        self._entries: dict[str, tuple[float, str]] = {}
        self._clock = clock

    async def get(self, key: str) -> str | None:
        entry = self._entries.get(key)
        if entry is None:
            return None
        expires_at, value = entry
        if self._clock() >= expires_at:
            del self._entries[key]
            return None
        return value

    async def set(self, key: str, value: str, ttl_seconds: int) -> None:
        self._entries[key] = (self._clock() + ttl_seconds, value)

    async def delete(self, key: str) -> None:
        self._entries.pop(key, None)

    async def ping(self) -> None:
        return None

    async def close(self) -> None:
        self._entries.clear()


class RedisCache:
    """Cache stored in Redis. The client connects on the first command."""

    def __init__(self, client: Redis) -> None:
        self._client = client

    async def get(self, key: str) -> str | None:
        value = await self._client.get(key)
        return None if value is None else str(value)

    async def set(self, key: str, value: str, ttl_seconds: int) -> None:
        await self._client.set(key, value, ex=ttl_seconds)

    async def delete(self, key: str) -> None:
        await self._client.delete(key)

    async def ping(self) -> None:
        await self._client.ping()

    async def close(self) -> None:
        await self._client.aclose()


def create_cache(redis_url: str | None) -> Cache:
    if redis_url is None:
        return InMemoryCache()
    return RedisCache(Redis.from_url(redis_url, decode_responses=True))


class CachedItemRepository:
    """Cache-aside reads of single items in front of another repository.

    A read first asks the cache and stores what the repository returned on a miss.
    Replacing or deleting an item removes its cache entry. Lists are not cached.
    """

    def __init__(self, repository: ItemRepository, cache: Cache, ttl_seconds: int) -> None:
        self._repository = repository
        self._cache = cache
        self._ttl_seconds = ttl_seconds

    @staticmethod
    def _key(item_id: int) -> str:
        return f"item:{item_id}"

    async def list_all(self, *, skip: int, limit: int) -> list[Item]:
        return await self._repository.list_all(skip=skip, limit=limit)

    async def get(self, item_id: int) -> Item | None:
        cached = await self._cache.get(self._key(item_id))
        if cached is not None:
            return Item.model_validate_json(cached)
        item = await self._repository.get(item_id)
        if item is not None:
            await self._cache.set(self._key(item_id), item.model_dump_json(), self._ttl_seconds)
        return item

    async def create(self, data: ItemIn) -> Item:
        return await self._repository.create(data)

    async def replace(self, item_id: int, data: ItemIn) -> Item | None:
        item = await self._repository.replace(item_id, data)
        await self._cache.delete(self._key(item_id))
        return item

    async def delete(self, item_id: int) -> bool:
        deleted = await self._repository.delete(item_id)
        await self._cache.delete(self._key(item_id))
        return deleted
