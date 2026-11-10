#!/usr/bin/env python3
"""
Validate the Superset asset files without a Superset instance.

Checks that every file is well formed, has the fields the import needs, and
that references between dashboards, charts, datasets and databases resolve.
"""

import json
import re
import sys
from pathlib import Path

from scripts.assets import ASSET_DIRS, ROOT

SUPPORTED_ENGINES = ("postgresql", "mysql", "snowflake", "bigquery", "redshift")
SLUG_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")
# user:password@ in a connection string
URI_CREDENTIALS = re.compile(r"://[^/@:]+:[^/@]+@")


def _require(asset, field, kind, errors, path):
    """Record an error unless asset[field] is a non-empty value of the given type."""
    value = asset.get(field)
    if not isinstance(value, kind) or (isinstance(value, str) and not value.strip()):
        errors.append(f"{path}: '{field}' must be a non-empty {kind.__name__}")
        return None
    return value


def _duplicates(names):
    return sorted({name for name in names if names.count(name) > 1})


def validate_database(path, asset, errors):
    name = _require(asset, "database_name", str, errors, path)
    engine = asset.get("engine")
    if engine not in SUPPORTED_ENGINES:
        errors.append(f"{path}: 'engine' must be one of {', '.join(SUPPORTED_ENGINES)}")
    uri = asset.get("sqlalchemy_uri", "")
    if not isinstance(uri, str):
        errors.append(f"{path}: 'sqlalchemy_uri' must be a string")
    elif URI_CREDENTIALS.search(uri):
        errors.append(
            f"{path}: 'sqlalchemy_uri' contains credentials; "
            "leave it empty and set the SUPERSET_DATABASE_URI secret instead"
        )
    for flag in ("expose_in_sqllab", "allow_ctas", "allow_cvas", "allow_dml"):
        if flag in asset and not isinstance(asset[flag], bool):
            errors.append(f"{path}: '{flag}' must be true or false")
    return name


def validate_dataset(path, asset, databases, errors):
    name = _require(asset, "table_name", str, errors, path)
    database = _require(asset, "database_name", str, errors, path)
    if database and database not in databases:
        errors.append(f"{path}: database '{database}' is not defined in databases/")

    columns = [c.get("column_name") for c in asset.get("columns", [])]
    metrics = [m.get("metric_name") for m in asset.get("metrics", [])]
    if not columns:
        errors.append(f"{path}: at least one column is required")
    for label, names in (("column", columns), ("metric", metrics)):
        if any(not isinstance(n, str) or not n for n in names):
            errors.append(f"{path}: every {label} needs a name")
        for duplicate in _duplicates([n for n in names if isinstance(n, str)]):
            errors.append(f"{path}: duplicate {label} '{duplicate}'")
    for metric in asset.get("metrics", []):
        if not metric.get("expression"):
            errors.append(f"{path}: metric '{metric.get('metric_name')}' needs an expression")
    return name, {"columns": set(columns), "metrics": set(metrics)}


def validate_chart(path, asset, datasets, errors):
    name = _require(asset, "slice_name", str, errors, path)
    _require(asset, "viz_type", str, errors, path)
    datasource = _require(asset, "datasource_name", str, errors, path)
    params = asset.get("params", {})
    if not isinstance(params, dict):
        errors.append(f"{path}: 'params' must be an object")
        return name
    if datasource and datasource not in datasets:
        errors.append(f"{path}: dataset '{datasource}' is not defined in datasets/")
        return name
    if datasource:
        dataset = datasets[datasource]
        for metric in params.get("metrics", []):
            # Ad-hoc metrics are objects; saved metrics are referenced by name.
            if isinstance(metric, str) and metric not in dataset["metrics"]:
                errors.append(f"{path}: metric '{metric}' is not defined in dataset '{datasource}'")
        referenced = list(params.get("groupby", []))
        if params.get("time_column"):
            referenced.append(params["time_column"])
        for column in referenced:
            if isinstance(column, str) and column not in dataset["columns"]:
                errors.append(f"{path}: column '{column}' is not defined in dataset '{datasource}'")
    return name


def validate_dashboard(path, asset, charts, errors):
    _require(asset, "dashboard_title", str, errors, path)
    slug = _require(asset, "slug", str, errors, path)
    if slug and not SLUG_PATTERN.match(slug):
        errors.append(f"{path}: slug '{slug}' may only contain a-z, 0-9, '-' and '_'")
    for field in ("position_json", "metadata"):
        if not isinstance(asset.get(field, {}), dict):
            errors.append(f"{path}: '{field}' must be an object")
    chart_names = asset.get("charts", [])
    if not isinstance(chart_names, list):
        errors.append(f"{path}: 'charts' must be a list of chart names")
        return
    for chart in chart_names:
        if chart not in charts:
            errors.append(f"{path}: chart '{chart}' is not defined in charts/")


def validate(root=ROOT):
    """Return a list of problems found in the asset files under root."""
    errors = []
    assets = {}
    for directory in ASSET_DIRS:
        assets[directory] = {}
        for path in sorted((Path(root) / directory).glob("*.json")):
            relative = path.relative_to(root)
            try:
                asset = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError as error:
                errors.append(f"{relative}: invalid JSON: {error}")
                continue
            if not isinstance(asset, dict):
                errors.append(f"{relative}: must contain a JSON object")
                continue
            assets[directory][relative] = asset

    databases = set()
    for path, asset in assets["databases"].items():
        databases.add(validate_database(path, asset, errors))

    datasets = {}
    for path, asset in assets["datasets"].items():
        name, fields = validate_dataset(path, asset, databases, errors)
        datasets[name] = fields

    charts = set()
    for path, asset in assets["charts"].items():
        charts.add(validate_chart(path, asset, datasets, errors))

    for path, asset in assets["dashboards"].items():
        validate_dashboard(path, asset, charts, errors)

    if not assets["dashboards"]:
        errors.append("dashboards/: no dashboard is defined")
    return errors


def main():
    errors = validate()
    for error in errors:
        print(f"ERROR {error}")
    if errors:
        print(f"\n{len(errors)} problem(s) found")
        return 1
    print("All Superset assets are valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
