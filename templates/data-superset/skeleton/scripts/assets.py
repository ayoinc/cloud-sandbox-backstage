"""Loading of the asset files kept in this repository."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSET_DIRS = ("databases", "datasets", "charts", "dashboards")


def load_assets(root=ROOT):
    """Return {asset directory: {file path: parsed JSON}} for every asset file."""
    assets = {}
    for directory in ASSET_DIRS:
        assets[directory] = {
            path: json.loads(path.read_text(encoding="utf-8"))
            for path in sorted((Path(root) / directory).glob("*.json"))
        }
    return assets
