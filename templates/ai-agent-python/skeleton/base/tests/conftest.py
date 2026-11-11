from collections.abc import Callable, Iterator, Sequence

import pytest
from fastapi.testclient import TestClient

from agent.config import Settings
from agent.llm.base import ModelTurn
from agent.main import create_app
from tests.fakes import FakeLLM

TOKEN = "test-token-0123456789-0123456789-0123456789"

ClientFactory = Callable[..., TestClient]


@pytest.fixture
def make_client() -> Iterator[ClientFactory]:
    """Builds a test client around an application with a scripted model."""
    clients: list[TestClient] = []

    def build(
        turns: Sequence[ModelTurn] = (), *, llm: object | None = None, **settings: object
    ) -> TestClient:
        fake = llm or FakeLLM(turns)
        app = create_app(
            settings=Settings(**settings),  # type: ignore[arg-type]
            llm_factory=lambda _: fake,  # type: ignore[arg-type,return-value]
        )
        client = TestClient(app)
        client.__enter__()
        clients.append(client)
        return client

    yield build
    for client in clients:
        client.__exit__(None, None, None)
