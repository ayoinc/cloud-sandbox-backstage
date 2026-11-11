"""The HTTP API of the agent."""

import asyncio
import logging
import secrets
from collections.abc import AsyncIterator, Callable
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from agent import __version__
from agent.config import Settings, credentials_present, get_settings
from agent.defaults import PROVIDER
from agent.llm.base import LLMClient, Message
from agent.loop import Agent, AgentError
from agent.schemas import AgentEvent, ChatRequest, ChatResponse, ErrorEvent
from agent.telemetry import setup_telemetry
from agent.tools import ToolRegistry, default_registry

logger = logging.getLogger("agent")

_bearer = HTTPBearer(auto_error=False)


def _default_llm(settings: Settings) -> LLMClient:
    # Imported here so that tests can build the application without the
    # provider SDK being configured.
    from agent.llm.provider import build_client

    return build_client(settings)


def create_app(
    *,
    settings: Settings | None = None,
    llm_factory: Callable[[Settings], LLMClient] = _default_llm,
    tools: ToolRegistry | None = None,
) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        app.state.agent = Agent(
            llm_factory(settings),
            tools or default_registry(timeout_seconds=settings.tool_timeout_seconds),
            max_steps=settings.max_steps,
        )
        yield
        if provider is not None:
            provider.shutdown()

    app = FastAPI(
        title="${{ values.name }}",
        version=__version__,
        lifespan=lifespan,
    )
    provider = setup_telemetry(app)

    def require_token(
        credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    ) -> None:
        if settings.api_token is None:
            return
        expected = settings.api_token.get_secret_value()
        presented = credentials.credentials if credentials else ""
        if not secrets.compare_digest(presented.encode(), expected.encode()):
            raise HTTPException(
                status.HTTP_401_UNAUTHORIZED,
                "Missing or invalid bearer token",
                headers={"WWW-Authenticate": "Bearer"},
            )

    def get_agent(request: Request) -> Agent:
        agent: Agent = request.app.state.agent
        return agent

    @app.get("/healthz", include_in_schema=False)
    async def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/readyz", include_in_schema=False)
    async def readyz() -> JSONResponse:
        ready = credentials_present()
        return JSONResponse(
            {"status": "ok" if ready else "provider credentials are missing"},
            status_code=status.HTTP_200_OK if ready else status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    @app.get("/v1/info", dependencies=[Depends(require_token)])
    async def info(agent: Annotated[Agent, Depends(get_agent)]) -> dict[str, object]:
        return {
            "provider": PROVIDER,
            "model": agent.llm.model,
            "tools": agent.tools.names,
            "max_steps": agent.max_steps,
        }

    @app.post("/v1/chat", dependencies=[Depends(require_token)])
    async def chat(body: ChatRequest, agent: Annotated[Agent, Depends(get_agent)]) -> ChatResponse:
        """Run the agent and return its structured answer."""
        try:
            async with asyncio.timeout(settings.request_timeout_seconds):
                return await agent.complete(body.message, _history(body))
        except TimeoutError as error:
            raise HTTPException(status.HTTP_504_GATEWAY_TIMEOUT, "The agent timed out") from error
        except AgentError as error:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(error)) from error
        except Exception as error:
            logger.exception("The model provider call failed")
            raise HTTPException(
                status.HTTP_502_BAD_GATEWAY, "The model provider call failed"
            ) from error

    @app.post("/v1/chat/stream", dependencies=[Depends(require_token)])
    async def chat_stream(
        body: ChatRequest, agent: Annotated[Agent, Depends(get_agent)]
    ) -> StreamingResponse:
        """Run the agent and stream its progress as server-sent events.

        Events: ``text_delta``, ``tool_started``, ``tool_finished``, then
        ``completed`` with the same body as ``POST /v1/chat``, or ``error``.
        """

        async def events() -> AsyncIterator[str]:
            try:
                async with asyncio.timeout(settings.request_timeout_seconds):
                    async for event in agent.run(body.message, _history(body)):
                        yield _sse(event)
            except TimeoutError:
                yield _sse(ErrorEvent(message="The agent timed out"))
            except Exception:
                # The response has started, so the failure is reported in-band.
                logger.exception("The model provider call failed")
                yield _sse(ErrorEvent(message="The model provider call failed"))

        return StreamingResponse(
            events(),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    return app


def _history(body: ChatRequest) -> list[Message]:
    return [Message(role=entry.role, text=entry.content) for entry in body.history]


def _sse(event: AgentEvent) -> str:
    return f"event: {event.type}\ndata: {event.model_dump_json()}\n\n"


def app() -> FastAPI:
    """Application factory for ``uvicorn --factory agent.main:app``."""
    return create_app()
