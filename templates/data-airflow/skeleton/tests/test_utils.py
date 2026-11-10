"""Tests for the DAG utility functions."""

from datetime import datetime

from utils import chunk_list, format_date, get_connection_string, validate_data


def test_validate_data():
    assert validate_data({"id": 1, "name": "a"}, ["id", "name"])
    assert not validate_data({"id": 1}, ["id", "name"])


def test_format_date():
    assert format_date(datetime(2024, 1, 31)) == "2024-01-31"


def test_chunk_list():
    assert chunk_list([1, 2, 3, 4, 5], 2) == [[1, 2], [3, 4], [5]]


def test_get_connection_string():
    uri = get_connection_string("db.example.com", 5432, "warehouse", "etl", "secret")
    assert uri == "postgresql://etl:secret@db.example.com:5432/warehouse"
