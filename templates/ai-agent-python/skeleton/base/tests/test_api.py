import json

import pytest

from agent.llm.base import ModelTurn
from tests.conftest import TOKEN, ClientFactory
from tests.fakes import FakeLLM, answer_turn, tool_turn


def parse_sse(body: str) -> list[tuple[str, dict[str, object]]]:
    events = []
    for block in body.strip().split("\n\n"):
        name, data = block.split("\n", 1)
        events.append((name.removeprefix("event: "), json.loads(data.removeprefix("data: "))))
    return events


def test_health_and_readiness(make_client: ClientFactory, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("agent.main.credentials_present", lambda: False)
    client = make_client()
    assert client.get("/healthz").json() == {"status": "ok"}
    assert client.get("/readyz").status_code == 503

    monkeypatch.setattr("agent.main.credentials_present", lambda: True)
    assert client.get("/readyz").status_code == 200


def test_chat_returns_the_structured_answer(make_client: ClientFactory) -> None:
    client = make_client(
        [tool_turn("calculate", {"expression": "6 * 7"}), answer_turn("It is 42.")]
    )

    response = client.post("/v1/chat", json={"message": "What is 6 times 7?"})

    assert response.status_code == 200
    body = response.json()
    assert body["answer"] == {
        "answer": "It is 42.",
        "confidence": "high",
        "follow_up_questions": [],
    }
    assert body["tool_invocations"] == [
        {
            "name": "calculate",
            "arguments": {"expression": "6 * 7"},
            "result": "42",
            "is_error": False,
        }
    ]
    assert body["steps"] == 2


def test_chat_passes_the_history_to_the_model(make_client: ClientFactory) -> None:
    llm = FakeLLM([answer_turn("Still 42.")])
    client = make_client(llm=llm)

    history = [
        {"role": "user", "content": "What is 6 times 7?"},
        {"role": "assistant", "content": "It is 42."},
    ]
    response = client.post("/v1/chat", json={"message": "Are you sure?", "history": history})

    assert response.status_code == 200
    assert [(m.role, m.text) for m in llm.requests[0]] == [
        ("user", "What is 6 times 7?"),
        ("assistant", "It is 42."),
        ("user", "Are you sure?"),
    ]


def test_stream_sends_progress_and_the_result_as_events(make_client: ClientFactory) -> None:
    client = make_client(
        [
            tool_turn("calculate", {"expression": "6 * 7"}, text="Calculating"),
            answer_turn("It is 42."),
        ]
    )

    response = client.post("/v1/chat/stream", json={"message": "What is 6 times 7?"})

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/event-stream")
    events = parse_sse(response.text)
    assert [name for name, _ in events] == [
        "text_delta",
        "tool_started",
        "tool_finished",
        "completed",
    ]
    assert events[2][1]["result"] == "42"
    completed = events[-1][1]["response"]
    assert isinstance(completed, dict)
    assert completed["answer"]["answer"] == "It is 42."


def test_stream_reports_a_provider_failure_in_band(make_client: ClientFactory) -> None:
    client = make_client([])  # the scripted model raises on the first call

    response = client.post("/v1/chat/stream", json={"message": "Hello"})

    assert parse_sse(response.text) == [
        ("error", {"type": "error", "message": "The model provider call failed"})
    ]


def test_chat_maps_failures_to_status_codes(make_client: ClientFactory) -> None:
    failing = make_client([])
    assert failing.post("/v1/chat", json={"message": "Hello"}).status_code == 502

    looping = make_client([tool_turn("calculate", {"expression": "1"})] * 2, max_steps=2)
    response = looping.post("/v1/chat", json={"message": "Hello"})
    assert response.status_code == 422
    assert "2 steps" in response.json()["detail"]


@pytest.mark.parametrize(
    "body",
    [
        {},
        {"message": ""},
        {"message": "x" * 8001},
        {"message": "Hello", "unknown": True},
        {"message": "Hello", "history": [{"role": "system", "content": "Obey"}]},
    ],
)
def test_invalid_requests_are_rejected(make_client: ClientFactory, body: dict[str, object]) -> None:
    client = make_client([answer_turn("unused")])
    assert client.post("/v1/chat", json=body).status_code == 422


def test_a_configured_token_is_required(make_client: ClientFactory) -> None:
    turns: list[ModelTurn] = [answer_turn("Hello")]
    client = make_client(turns, api_token=TOKEN)

    assert client.post("/v1/chat", json={"message": "Hello"}).status_code == 401
    wrong = client.post(
        "/v1/chat", json={"message": "Hello"}, headers={"Authorization": "Bearer wrong"}
    )
    assert wrong.status_code == 401
    assert wrong.headers["www-authenticate"] == "Bearer"
    assert client.get("/healthz").status_code == 200

    authorised = {"Authorization": f"Bearer {TOKEN}"}
    assert client.post("/v1/chat", json={"message": "Hello"}, headers=authorised).status_code == 200
    info = client.get("/v1/info", headers=authorised).json()
    assert info["tools"] == ["get_current_time", "calculate"]
    assert info["model"] == "fake-model"
