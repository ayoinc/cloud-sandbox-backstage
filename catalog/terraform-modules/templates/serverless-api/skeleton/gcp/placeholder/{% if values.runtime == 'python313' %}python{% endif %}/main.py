"""Placeholder handler.

Terraform deploys it until a real function package is supplied (see
docs/infrastructure.md). It shows the contract between the infrastructure and
the function: the environment variables it reads and the headers it receives.
"""

import base64
import json
import os

import functions_framework
from flask import jsonify, make_response


def _list(value):
    return [item.strip() for item in (value or "").split(",") if item.strip()]


ALLOWED_ORIGINS = _list(os.environ.get("CORS_ALLOWED_ORIGINS"))
ALLOWED_CALLERS = _list(os.environ.get("ALLOWED_CALLERS"))


def _apply_cors(request, response):
    """The gateway forwards OPTIONS requests unauthenticated; CORS is answered here."""
    origin = request.headers.get("Origin")
    if not origin or not ALLOWED_ORIGINS:
        return response
    if "*" in ALLOWED_ORIGINS:
        response.headers["Access-Control-Allow-Origin"] = "*"
    elif origin in ALLOWED_ORIGINS:
        response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Vary"] = "Origin"
    else:
        return response
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = request.headers.get(
        "Access-Control-Request-Headers", "Authorization, Content-Type, x-api-key"
    )
    response.headers["Access-Control-Max-Age"] = "3600"
    return response


def _caller(request):
    """The gateway passes the verified token claims, base64url encoded, in X-Apigateway-Api-Userinfo."""
    header = request.headers.get("X-Apigateway-Api-Userinfo")
    if not header:
        return None
    try:
        padded = header + "=" * (-len(header) % 4)
        return json.loads(base64.urlsafe_b64decode(padded))
    except ValueError:
        return None


@functions_framework.http
def handler(request):
    if request.method == "OPTIONS":
        return _apply_cors(request, make_response("", 204))

    claims = _caller(request)
    if ALLOWED_CALLERS and not (claims and claims.get("email") in ALLOWED_CALLERS):
        return _apply_cors(request, make_response(jsonify(error="caller is not allowed"), 403))

    if os.environ.get("API_TYPE") == "graphql":
        body = {"errors": [{"message": "Placeholder function: no GraphQL schema is deployed yet."}]}
    else:
        body = {
            "message": "Placeholder function. Supply a function package to replace it.",
            "service": os.environ.get("K_SERVICE"),
            "revision": os.environ.get("K_REVISION"),
            "environment": os.environ.get("ENVIRONMENT"),
            "method": request.method,
            "path": request.path,
            "caller": (claims.get("email") or claims.get("sub")) if claims else None,
        }
    return _apply_cors(request, make_response(jsonify(body), 200))
