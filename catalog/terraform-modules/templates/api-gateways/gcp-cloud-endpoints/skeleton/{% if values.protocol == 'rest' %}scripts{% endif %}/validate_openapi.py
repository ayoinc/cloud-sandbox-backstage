"""Checks that the OpenAPI document is valid OpenAPI 2.0.

Terraform fills the ${name} placeholders of the document when it deploys the
API. This script fills them with sample values first, so the document can be
checked without Terraform.

Usage: python scripts/validate_openapi.py <path of the OpenAPI document>
"""

import re
import sys

import yaml
from openapi_spec_validator import OpenAPIV2SpecValidator

# Placeholders that need a value of a particular form. Every other
# placeholder stands for a URL or a free-form string.
SAMPLE_VALUES = {
    "host": "api.endpoints.example-project.cloud.goog",
    "project_id": "example-project",
    "quota_limit": "1000",
}
DEFAULT_SAMPLE_VALUE = "https://example.com"

# ${name}, but not the escaped form $${name}.
PLACEHOLDER = re.compile(r"(?<!\$)\$\{(\w+)\}")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    path = sys.argv[1]
    with open(path, encoding="utf-8") as file:
        text = file.read()
    filled = PLACEHOLDER.sub(
        lambda match: SAMPLE_VALUES.get(match.group(1), DEFAULT_SAMPLE_VALUE), text
    )
    document = yaml.safe_load(filled.replace("$${", "${"))

    errors = sorted(
        OpenAPIV2SpecValidator(document).iter_errors(),
        key=lambda error: list(error.absolute_path),
    )
    for error in errors:
        location = "/".join(str(part) for part in error.absolute_path) or "(document)"
        print(f"{path}: {location}: {error.message}", file=sys.stderr)
    if errors:
        return 1

    # Cloud Endpoints refuses an operation without an operationId.
    missing = [
        f"{method.upper()} {route}"
        for route, operations in document.get("paths", {}).items()
        for method, operation in operations.items()
        if isinstance(operation, dict)
        and method in {"get", "put", "post", "delete", "options", "head", "patch"}
        and not operation.get("operationId")
    ]
    for operation in missing:
        print(f"{path}: {operation} has no operationId", file=sys.stderr)
    if missing:
        return 1

    print(f"{path}: valid OpenAPI 2.0, {len(document.get('paths', {}))} paths")
    return 0


if __name__ == "__main__":
    sys.exit(main())
