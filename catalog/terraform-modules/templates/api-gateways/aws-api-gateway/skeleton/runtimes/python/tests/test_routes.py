import json
import re

from handler import handler
from router import not_implemented
from routes import ROUTES


def test_every_route_key_is_method_and_path():
    for key, route_handler in ROUTES.items():
        assert re.fullmatch(r"(GET|POST|PUT|DELETE) /\S*", key)
        assert callable(route_handler)


def test_health_reports_the_service():
    response = handler({"httpMethod": "GET", "resource": "/health"}, None)
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["status"] == "ok"
    assert body["service"]
    assert body["version"]


def test_endpoints_without_an_implementation_answer_501():
    stubbed = [key for key, value in ROUTES.items() if value is not_implemented]
    for key in stubbed:
        method, resource = key.split(" ", 1)
        response = handler({"httpMethod": method, "resource": resource}, None)
        assert response["statusCode"] == 501
        assert json.loads(response["body"]) == {"message": f"{key} is not implemented"}
