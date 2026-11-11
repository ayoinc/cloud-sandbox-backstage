"""Create the tables of the service: python -m app.init_db"""

import asyncio

from app.config import Settings
from app.db import Base, Database


async def create_tables(database: Database) -> None:
    """Create every table that does not exist yet. Existing tables are left as they are."""
    async with database.engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)


async def _run(url: str) -> None:
    database = Database(url)
    try:
        await create_tables(database)
    finally:
        await database.dispose()


def main() -> None:
    asyncio.run(_run(Settings().database_url))


if __name__ == "__main__":
    main()
