#!/usr/bin/env python3
"""
Import the Superset assets of this repository into a Superset instance.

Environment:
    SUPERSET_URL, SUPERSET_USERNAME, SUPERSET_PASSWORD   Superset account
    SUPERSET_DATABASE_URI   SQLAlchemy URI of the data source; required the
                            first time, when the database connection is created
"""

import json
import os
import sys

from scripts.assets import load_assets
from scripts.client import SupersetClient, SupersetError


def import_databases(client, databases):
    """Create or update database connections. Returns {database name: id}."""
    ids = {}
    uri = os.getenv("SUPERSET_DATABASE_URI", "")
    for config in databases.values():
        name = config["database_name"]
        print(f"Importing database: {name}")
        payload = {
            "database_name": name,
            "expose_in_sqllab": config.get("expose_in_sqllab", True),
            "allow_ctas": config.get("allow_ctas", False),
            "allow_cvas": config.get("allow_cvas", False),
            "allow_dml": config.get("allow_dml", False),
            "extra": json.dumps(config.get("extra", {})),
        }
        if uri:
            payload["sqlalchemy_uri"] = uri
        elif not client.find("database", "database_name", name):
            raise SupersetError(
                f"Database '{name}' does not exist yet: set SUPERSET_DATABASE_URI "
                "to its SQLAlchemy URI to create it"
            )
        ids[name] = client.upsert("database", "database_name", name, payload)
    return ids


def import_datasets(client, datasets, database_ids):
    """Create or update datasets. Returns {table name: id}."""
    ids = {}
    for config in datasets.values():
        name = config["table_name"]
        print(f"Importing dataset: {name}")
        existing = client.find("dataset", "table_name", name)
        if existing:
            dataset_id = existing["id"]
        else:
            created = client.request(
                "POST",
                "/api/v1/dataset/",
                json={
                    "database": database_ids[config["database_name"]],
                    "schema": config.get("schema"),
                    "table_name": name,
                    "sql": config.get("sql"),
                },
            )
            dataset_id = created["id"]
        client.request(
            "PUT",
            f"/api/v1/dataset/{dataset_id}",
            params={"override_columns": "true"},
            json={
                "columns": config.get("columns", []),
                "metrics": config.get("metrics", []),
            },
        )
        ids[name] = dataset_id
    return ids


def import_charts(client, charts, dataset_ids):
    """Create or update charts. Returns {chart name: id}."""
    ids = {}
    for config in charts.values():
        name = config["slice_name"]
        print(f"Importing chart: {name}")
        dataset_id = dataset_ids[config["datasource_name"]]
        params = dict(config.get("params", {}))
        params["datasource"] = f"{dataset_id}__table"
        payload = {
            "slice_name": name,
            "viz_type": config["viz_type"],
            "datasource_id": dataset_id,
            "datasource_type": "table",
            "params": json.dumps(params),
        }
        ids[name] = client.upsert("chart", "slice_name", name, payload)
    return ids


def import_dashboards(client, dashboards, chart_ids):
    """Create or update dashboards and attach their charts."""
    for config in dashboards.values():
        title = config["dashboard_title"]
        print(f"Importing dashboard: {title}")
        payload = {
            "dashboard_title": title,
            "slug": config["slug"],
            "position_json": json.dumps(config.get("position_json", {})),
            "json_metadata": json.dumps(config.get("metadata", {})),
        }
        dashboard_id = client.upsert("dashboard", "slug", config["slug"], payload)
        for chart in config.get("charts", []):
            client.request(
                "PUT",
                f"/api/v1/chart/{chart_ids[chart]}",
                json={"dashboards": [dashboard_id]},
            )


def run(client, assets):
    database_ids = import_databases(client, assets["databases"])
    dataset_ids = import_datasets(client, assets["datasets"], database_ids)
    chart_ids = import_charts(client, assets["charts"], dataset_ids)
    import_dashboards(client, assets["dashboards"], chart_ids)


def main():
    try:
        print("Connecting to Superset...")
        client = SupersetClient.from_env()
        print("Importing assets...")
        run(client, load_assets())
    except SupersetError as error:
        print(f"ERROR {error}", file=sys.stderr)
        return 1
    print("Import complete")
    return 0


if __name__ == "__main__":
    sys.exit(main())
