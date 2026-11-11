"""Cache implementations and the cache-aside behaviour of the item repository."""

import pytest
from fakeredis import FakeAsyncRedis
from httpx import ASGITransport, AsyncClient

from app.cache import Cache, CachedItemRepository, InMemoryCache, RedisCache, create_cache
from app.config import Settings
from app.main import create_app
from app.schemas import Item, ItemIn


class CountingRepository:
    """Repository holding one item that counts how often it is read."""

    def __init__(self) -> None:
        self.item: Item | None = Item(id=1, name="first")
        self.reads = 0

    async def list_all(self, *, skip: int, limit: int) -> list[Item]:
        return [self.item] if self.item else []

    async def get(self, item_id: int) -> Item | None:
        self.reads += 1
        return self.item

    async def create(self, data: ItemIn) -> Item:
        self.item = Item(id=1, **data.model_dump())
        return self.item

    async def replace(self, item_id: int, data: ItemIn) -> Item | None:
        self.item = Item(id=item_id, **data.model_dump())
        return self.item

    async def delete(self, item_id: int) -> bool:
        self.item = None
        return True


@pytest.fixture(params=["memory", "redis"])
def cache(request: pytest.FixtureRequest) -> Cache:
    if request.param == "redis":
        return RedisCache(FakeAsyncRedis(decode_responses=True))
    return InMemoryCache()


async def test_set_get_and_delete(cache: Cache) -> None:
    assert await cache.get("key") is None

    await cache.set("key", "value", ttl_seconds=60)
    assert await cache.get("key") == "value"

    await cache.delete("key")
    assert await cache.get("key") is None

    await cache.ping()
    await cache.close()


async def test_in_memory_entries_expire() -> None:
    now = 1000.0
    cache = InMemoryCache(clock=lambda: now)
    await cache.set("key", "value", ttl_seconds=30)

    now += 29
    assert await cache.get("key") == "value"

    now += 1
    assert await cache.get("key") is None


async def test_redis_entries_are_stored_with_a_time_to_live() -> None:
    client = FakeAsyncRedis(decode_responses=True)

    await RedisCache(client).set("key", "value", ttl_seconds=30)

    assert 0 < await client.ttl("key") <= 30


def test_create_cache_uses_redis_only_when_a_url_is_configured() -> None:
    assert isinstance(create_cache(None), InMemoryCache)
    assert isinstance(create_cache("redis://localhost:6379/0"), RedisCache)


async def test_second_read_is_served_from_the_cache(cache: Cache) -> None:
    repository = CountingRepository()
    cached = CachedItemRepository(repository, cache, ttl_seconds=60)

    first = await cached.get(1)
    second = await cached.get(1)

    assert first == second == Item(id=1, name="first")
    assert repository.reads == 1


async def test_missing_items_are_not_cached(cache: Cache) -> None:
    repository = CountingRepository()
    repository.item = None
    cached = CachedItemRepository(repository, cache, ttl_seconds=60)

    assert await cached.get(1) is None
    assert await cached.get(1) is None
    assert repository.reads == 2


async def test_replace_and_delete_invalidate_the_cached_item(cache: Cache) -> None:
    repository = CountingRepository()
    cached = CachedItemRepository(repository, cache, ttl_seconds=60)
    await cached.get(1)

    await cached.replace(1, ItemIn(name="renamed"))
    assert await cached.get(1) == Item(id=1, name="renamed")

    await cached.delete(1)
    assert await cached.get(1) is None


async def test_readiness_reports_the_cache(client: AsyncClient) -> None:
    response = await client.get("/health/ready")

    assert response.status_code == 200
    assert response.json()["checks"]["cache"] == "ok"


async def test_readiness_fails_when_redis_is_unreachable(settings: Settings) -> None:
    # Port 1 is reserved and nothing listens on it.
    app = create_app(settings.model_copy(update={"redis_url": "redis://127.0.0.1:1/0"}))

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["checks"]["cache"] == "failed"
