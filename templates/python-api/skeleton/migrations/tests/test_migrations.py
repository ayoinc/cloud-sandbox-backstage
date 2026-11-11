"""The Alembic migrations apply, match the models and roll back."""

import sqlite3
from contextlib import closing
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def table_names(path: Path) -> set[str]:
    with closing(sqlite3.connect(path)) as connection:
        rows = connection.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
        return {name for (name,) in rows}


@pytest.fixture
def database_path(tmp_path: Path) -> Path:
    return tmp_path / "app.db"


@pytest.fixture
def alembic_config(database_path: Path) -> Config:
    config = Config(str(PROJECT_ROOT / "alembic.ini"))
    config.set_main_option("sqlalchemy.url", f"sqlite+aiosqlite:///{database_path}")
    return config


def test_upgrade_creates_the_items_table(alembic_config: Config, database_path: Path) -> None:
    command.upgrade(alembic_config, "head")

    assert table_names(database_path) == {"items", "alembic_version"}


def test_migrations_match_the_models(alembic_config: Config) -> None:
    command.upgrade(alembic_config, "head")

    # Raises when the models declare something no migration creates.
    command.check(alembic_config)


def test_downgrade_removes_the_items_table(alembic_config: Config, database_path: Path) -> None:
    command.upgrade(alembic_config, "head")

    command.downgrade(alembic_config, "base")

    assert table_names(database_path) == {"alembic_version"}
