"""SQLAlchemy model, connection pool and SQL implementation of the item repository."""

from sqlalchemy import String, select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

from app.schemas import Item, ItemIn


class Base(DeclarativeBase):
    """Base class whose metadata describes every table of the service."""


class ItemRow(Base):
    __tablename__ = "items"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(String(1000))


class Database:
    """Connection pool and session factory. Creating it does not connect."""

    def __init__(self, url: str) -> None:
        self.engine = create_async_engine(url, pool_pre_ping=True)
        self.sessions = async_sessionmaker(self.engine, expire_on_commit=False)

    async def ping(self) -> None:
        """Raise when the database does not answer a trivial query."""
        async with self.engine.connect() as connection:
            await connection.execute(text("SELECT 1"))

    async def dispose(self) -> None:
        await self.engine.dispose()


class SqlItemRepository:
    """Stores items in the items table, one short session per operation."""

    def __init__(self, sessions: async_sessionmaker[AsyncSession]) -> None:
        self._sessions = sessions

    async def list_all(self, *, skip: int, limit: int) -> list[Item]:
        query = select(ItemRow).order_by(ItemRow.id).offset(skip).limit(limit)
        async with self._sessions() as session:
            rows = await session.scalars(query)
            return [Item.model_validate(row) for row in rows]

    async def get(self, item_id: int) -> Item | None:
        async with self._sessions() as session:
            row = await session.get(ItemRow, item_id)
            return Item.model_validate(row) if row else None

    async def create(self, data: ItemIn) -> Item:
        async with self._sessions() as session:
            row = ItemRow(**data.model_dump())
            session.add(row)
            await session.commit()
            return Item.model_validate(row)

    async def replace(self, item_id: int, data: ItemIn) -> Item | None:
        async with self._sessions() as session:
            row = await session.get(ItemRow, item_id)
            if row is None:
                return None
            row.name = data.name
            row.description = data.description
            await session.commit()
            return Item.model_validate(row)

    async def delete(self, item_id: int) -> bool:
        async with self._sessions() as session:
            row = await session.get(ItemRow, item_id)
            if row is None:
                return False
            await session.delete(row)
            await session.commit()
            return True
