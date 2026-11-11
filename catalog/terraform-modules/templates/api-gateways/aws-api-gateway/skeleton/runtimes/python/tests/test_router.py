import base64
import json

import pytest

from router import HttpError, json_response, not_implemented, parse_object, route


def event(method, resource, **extra):
    return {
        "httpMethod": method,
        "resource": resource,
        "pathParameters": None,
        "body": None,
        "isBase64Encoded": False,
        **extra,
    }


def test_calls_the_handler_registered_for_the_method_and_resource():
    routes = {"GET /things": lambda _event: json_response(200, {"ok": True})}
    response = route(routes, event("GET", "/things"))
    assert response["statusCode"] == 200
    assert response["headers"]["Content-Type"] == "application/json"
    assert json.loads(response["body"]) == {"ok": True}


def test_answers_404_for_a_route_that_is_not_registered():
    response = route({}, event("GET", "/missing"))
    assert response["statusCode"] == 404
    assert json.loads(response["body"]) == {"message": "Not found"}


def test_turns_an_http_error_into_its_status_and_message():
    def conflict(_event):
        raise HttpError(409, "Conflict")

    response = route({"GET /things": conflict}, event("GET", "/things"))
    assert response["statusCode"] == 409
    assert json.loads(response["body"]) == {"message": "Conflict"}


def test_answers_500_when_a_handler_fails_unexpectedly():
    def broken(_event):
        raise RuntimeError("boom")

    response = route({"GET /things": broken}, event("GET", "/things"))
    assert response["statusCode"] == 500
    assert json.loads(response["body"]) == {"message": "Internal server error"}


def test_a_stubbed_endpoint_answers_501_with_its_method_and_path():
    routes = {"POST /reports/{id}": not_implemented}
    response = route(routes, event("POST", "/reports/{id}"))
    assert response["statusCode"] == 501
    assert json.loads(response["body"]) == {
        "message": "POST /reports/{id} is not implemented"
    }


def test_parse_object_reads_plain_and_base64_bodies():
    assert parse_object(event("POST", "/x", body='{"a": 1}')) == {"a": 1}
    encoded = base64.b64encode(b'{"b": 2}').decode()
    assert parse_object(event("POST", "/x", body=encoded, isBase64Encoded=True)) == {
        "b": 2
    }


@pytest.mark.parametrize("body", [None, "", "not json", "[1]", '"text"', "3", "null"])
def test_parse_object_rejects_anything_that_is_not_a_json_object(body):
    with pytest.raises(HttpError) as raised:
        parse_object(event("POST", "/x", body=body))
    assert raised.value.status_code == 400
