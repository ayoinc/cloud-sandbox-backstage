"""python -m app.init_db creates the tables in the configured database."""

import sqlite3
from contextlib import closing
from pathlib import Path

import pytest

from app.init_db import main


def table_names(path: Path) -> set[str]:
    with closing(sqlite3.connect(path)) as connection:
        rows = connection.execute("SELECT name FROM sqlite_master WHERE type = 'table'")
        return {name for (name,) in rows}


def test_main_creates_the_items_table(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    path = tmp_path / "app.db"
    monkeypatch.setenv("DATABASE_URL", f"sqlite+aiosqlite:///{path}")
    monkeypatch.setenv("APP_ENV", "development")

    main()
    main()

    assert table_names(path) == {"items"}
