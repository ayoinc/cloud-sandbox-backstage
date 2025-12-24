"""Database connection and session management."""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from ${{ values.name | replace('-', '_') }}.config import settings


class Base(DeclarativeBase):
    """SQLAlchemy declarative base."""
    pass


# Create async engine
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    echo=settings.DEBUG,
)

# Create async session factory
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def init_db() -> None:
    """Initialize database connection."""
    async with engine.begin() as conn:
        # Create tables if they don't exist (use Alembic migrations in production)
        if settings.DEBUG:
            await conn.run_sync(Base.metadata.create_all)


async def close_db() -> None:
    """Close database connection."""
    await engine.dispose()


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Get database session dependency."""
    async with async_session_maker() as session:
        try:
            yield session
        finally:
            await session.close()


async def check_db_connection() -> bool:
    """Check database connection health."""
    try:
        async with async_session_maker() as session:
            await session.execute("SELECT 1")
        return True
    except Exception:
        return False
