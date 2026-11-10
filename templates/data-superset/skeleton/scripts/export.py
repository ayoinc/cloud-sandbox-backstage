#!/usr/bin/env python3
"""
Export the dashboard definition from Superset into dashboards/.

Environment:
    SUPERSET_URL, SUPERSET_USERNAME, SUPERSET_PASSWORD   Superset account
    DASHBOARD_SLUG   Dashboard to export (default: ${{ values.name }})
"""

import json
import os
import sys

from scripts.assets import ROOT
from scripts.client import SupersetClient, SupersetError

DEFAULT_SLUG = "${{ values.name }}"


def export_dashboard(client, slug, root=ROOT):
    """Write the dashboard with the given slug to dashboards/<slug>.json."""
    print(f"Exporting dashboard: {slug}")
    found = client.find("dashboard", "slug", slug)
    if not found:
        raise SupersetError(f"Dashboard not found: {slug}")
    dashboard = client.request("GET", f"/api/v1/dashboard/{found['id']}")["result"]
    charts = client.request("GET", f"/api/v1/dashboard/{found['id']}/charts")["result"]
    exported = {
        "dashboard_title": dashboard["dashboard_title"],
        "description": dashboard.get("description") or "",
        "slug": dashboard["slug"],
        "position_json": json.loads(dashboard.get("position_json") or "{}"),
        "metadata": json.loads(dashboard.get("json_metadata") or "{}"),
        "charts": sorted(chart["slice_name"] for chart in charts),
    }
    target = root / "dashboards" / f"{slug}.json"
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(exported, indent=2) + "\n", encoding="utf-8")
    print(f"  Exported to {target.relative_to(root)}")
    return target


def main():
    try:
        print("Connecting to Superset...")
        client = SupersetClient.from_env()
        export_dashboard(client, os.getenv("DASHBOARD_SLUG", DEFAULT_SLUG))
    except SupersetError as error:
        print(f"ERROR {error}", file=sys.stderr)
        return 1
    print("Export complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
