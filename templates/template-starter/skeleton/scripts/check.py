#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Checks template.yaml, skeleton/ and sample-values.json against each other.

    uv run scripts/check.py

Lists every problem and exits 1 if there is one. It reads the files only: to
see what the template would write, use the portal's Template Editor.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
NAME = re.compile(r"^[a-z0-9]+(?:[-_.][a-z0-9]+)*$", re.IGNORECASE)
EXPRESSION = re.compile(r"\$\{\{(.*?)\}\}", re.DOTALL)
BLOCK = re.compile(r"\{%(.*?)%\}", re.DOTALL)


def references(text: str, root: str) -> set[str]:
    """The names read as `<root>.<name>` in the template expressions of `text`."""
    found: set[str] = set()
    for body in EXPRESSION.findall(text) + BLOCK.findall(text):
        found.update(re.findall(rf"\b{root}\.([A-Za-z_][A-Za-z0-9_]*)", body))
    return found


def main() -> int:
    problems: list[str] = []
    try:
        template = yaml.safe_load((ROOT / "template.yaml").read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        print(f"template.yaml is not valid YAML: {error}")
        return 1
    if not isinstance(template, dict) or template.get("kind") != "Template":
        print("template.yaml must describe a `kind: Template`.")
        return 1

    metadata = template.get("metadata") or {}
    spec = template.get("spec") or {}
    if not NAME.match(str(metadata.get("name") or "")) or len(str(metadata.get("name"))) > 63:
        problems.append("metadata.name must be letters, digits and - _ . (at most 63 characters).")
    for field in ("title", "description"):
        if not metadata.get(field):
            problems.append(f"metadata.{field} is missing.")
    for field in ("owner", "type"):
        if not spec.get(field):
            problems.append(f"spec.{field} is missing.")

    pages = spec.get("parameters") or []
    pages = pages if isinstance(pages, list) else [pages]
    fields: dict[str, dict] = {}
    required: set[str] = set()
    for page in pages:
        for name, schema in (page.get("properties") or {}).items():
            if name in fields:
                problems.append(f"The form has the field `{name}` twice.")
            fields[name] = schema or {}
        for name in page.get("required") or []:
            required.add(name)
            if name not in (page.get("properties") or {}):
                problems.append(f"The form requires `{name}`, which is not one of that page's fields.")

    steps = spec.get("steps") or []
    if not steps:
        problems.append("spec.steps is empty: the template would do nothing.")
    ids = [step.get("id") for step in steps]
    for step_id in sorted({i for i in ids if i and ids.count(i) > 1}):
        problems.append(f"Two steps have the id `{step_id}`.")
    passed: set[str] = set()
    for index, step in enumerate(steps, start=1):
        label = step.get("id") or f"number {index}"
        if not step.get("action"):
            problems.append(f"Step {label} has no action.")
        text = yaml.safe_dump(step)
        for name in sorted(references(text, "parameters") - set(fields)):
            problems.append(f"Step {label} reads `parameters.{name}`, which the form does not have.")
        for other in sorted(set(re.findall(r"steps\[['\"]([^'\"]+)['\"]\]", text)) | set(re.findall(r"steps\.([A-Za-z_][\w-]*)", text))):
            if other not in ids[: index - 1]:
                problems.append(f"Step {label} reads the output of `{other}`, which is not an earlier step.")
        if step.get("action") == "fetch:template":
            passed.update((step.get("input") or {}).get("values") or {})
    output_text = yaml.safe_dump(spec.get("output") or {})
    for name in sorted(references(output_text, "parameters") - set(fields)):
        problems.append(f"The output reads `parameters.{name}`, which the form does not have.")

    skeleton = ROOT / "skeleton"
    if not skeleton.is_dir():
        problems.append("There is no skeleton/ directory.")
    else:
        for file in sorted(path for path in skeleton.rglob("*") if path.is_file()):
            try:
                text = file.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue  # A binary file is copied as it is.
            for name in sorted(references(text, "values") - passed):
                problems.append(
                    f"{file.relative_to(ROOT)} uses `values.{name}`, which no fetch:template step passes."
                )

    try:
        sample = json.loads((ROOT / "sample-values.json").read_text(encoding="utf-8")).get("values")
    except (OSError, ValueError) as error:
        sample = None
        problems.append(f"sample-values.json could not be read: {error}")
    if isinstance(sample, dict):
        for name in sorted(required - set(sample)):
            problems.append(f"sample-values.json has no `{name}`, which the form requires.")
        for name in sorted(set(sample) - set(fields)):
            problems.append(f"sample-values.json has `{name}`, which the form does not have.")
        for name, value in sample.items():
            schema = fields.get(name) or {}
            if "enum" in schema and value not in schema["enum"]:
                problems.append(f"sample-values.json: `{name}` must be one of {schema['enum']}.")
            if "pattern" in schema and isinstance(value, str) and not re.search(schema["pattern"], value):
                problems.append(f"sample-values.json: `{name}` does not match {schema['pattern']}.")
    elif sample is not None:
        problems.append('sample-values.json must be {"values": {...}}.')

    if problems:
        print("The template has problems:")
        for problem in problems:
            print(f"  - {problem}")
        return 1
    print(f"{metadata['name']}: {len(fields)} form fields, {len(steps)} steps, template and skeleton agree.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
