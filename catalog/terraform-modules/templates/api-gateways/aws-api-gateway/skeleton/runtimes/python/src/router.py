"""Helpers shared by every endpoint.

Responses, request parsing and routing of API Gateway proxy events.
"""

import base64
import json
import logging

logger = logging.getLogger(__name__)


class HttpError(Exception):
    """Raised by a handler to answer with a specific status and message."""

    def __init__(self, status_code, message):
        super().__init__(message)
        self.status_code = status_code
        self.message = message


def json_response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def no_content():
    return {"statusCode": 204, "headers": {}, "body": ""}


def parse_object(event):
    """Return the request body as a dict. Anything else is a client error."""
    raw = event.get("body") or ""
    try:
        if event.get("isBase64Encoded"):
            raw = base64.b64decode(raw).decode("utf-8")
        value = json.loads(raw)
    except ValueError:
        value = None
    if not isinstance(value, dict):
        raise HttpError(400, "The request body must be a JSON object")
    return value


def not_implemented(event):
    """Stub of an endpoint that is routed but has no implementation yet."""
    key = f"{event['httpMethod']} {event['resource']}"
    return json_response(501, {"message": f"{key} is not implemented"})


def route(routes, event):
    """Call the handler registered for "<METHOD> <resource path>"."""
    handler = routes.get(f"{event.get('httpMethod')} {event.get('resource')}")
    if handler is None:
        return json_response(404, {"message": "Not found"})
    try:
        return handler(event)
    except HttpError as error:
        return json_response(error.status_code, {"message": error.message})
    except Exception:
        logger.exception("Unhandled error")
        return json_response(500, {"message": "Internal server error"})
