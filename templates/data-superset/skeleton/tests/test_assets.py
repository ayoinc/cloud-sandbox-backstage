"""Tests for the asset validation."""

import json
import shutil

from scripts.assets import ASSET_DIRS, ROOT, load_assets
from scripts.validate import validate


def copy_assets(tmp_path):
    for directory in ASSET_DIRS:
        shutil.copytree(ROOT / directory, tmp_path / directory)
    return tmp_path


def rewrite(path, change):
    asset = json.loads(path.read_text(encoding="utf-8"))
    change(asset)
    path.write_text(json.dumps(asset), encoding="utf-8")


def test_repository_assets_are_valid():
    assert validate() == []


def test_every_asset_directory_has_files():
    assets = load_assets()
    assert all(assets[directory] for directory in ASSET_DIRS)


def test_unknown_dataset_is_reported(tmp_path):
    root = copy_assets(tmp_path)
    chart = next((root / "charts").glob("*.json"))
    rewrite(chart, lambda asset: asset.update(datasource_name="missing_dataset"))

    errors = validate(root)

    assert any("missing_dataset" in error for error in errors)


def test_unknown_metric_is_reported(tmp_path):
    root = copy_assets(tmp_path)
    chart = next((root / "charts").glob("*.json"))
    rewrite(chart, lambda asset: asset["params"].update(metrics=["missing_metric"]))

    errors = validate(root)

    assert any("missing_metric" in error for error in errors)


def test_credentials_in_connection_string_are_reported(tmp_path):
    root = copy_assets(tmp_path)
    database = next((root / "databases").glob("*.json"))
    rewrite(
        database,
        lambda asset: asset.update(sqlalchemy_uri="postgresql://user:secret@host/db"),
    )

    errors = validate(root)

    assert any("credentials" in error for error in errors)


def test_invalid_json_is_reported(tmp_path):
    root = copy_assets(tmp_path)
    (root / "charts" / "broken.json").write_text("{", encoding="utf-8")

    errors = validate(root)

    assert any("invalid JSON" in error for error in errors)
