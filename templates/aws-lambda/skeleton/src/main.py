"""Lambda entry point for Python runtimes (handler: main.handler)."""

import json
import os


def handler(event, context):
    """Return a greeting and the environment the function runs in."""
    environment = os.environ.get("ENVIRONMENT", "unknown")

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "Hello from ${{ values.name }}",
                "environment": environment,
            }
        ),
    }
