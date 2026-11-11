"""Liveness and readiness endpoints."""

import asyncio
from collections.abc import Awaitable, Callable
from typing import Annotated

from fastapi import APIRouter, Depends, Request, Response, status

from app.config import Settings
from app.dependencies import get_settings
from app.schemas import HealthStatus, ReadinessStatus

# A readiness check returns when its dependency answers and raises when it does not.
ReadinessCheck = Callable[[], Awaitable[None]]

CHECK_TIMEOUT_SECONDS = 2.0

router = APIRouter(tags=["health"])


@router.get("/health")
async def liveness(settings: Annotated[Settings, Depends(get_settings)]) -> HealthStatus:
    """Report that the process is running. Never calls an external dependency."""
    return HealthStatus(status="ok", environment=settings.app_env)


@router.get("/health/ready")
async def readiness(request: Request, response: Response) -> ReadinessStatus:
    """Run every registered readiness check and answer 503 when one fails."""
    readiness_checks: dict[str, ReadinessCheck] = request.app.state.readiness_checks
    checks: dict[str, str] = {}
    for name, check in readiness_checks.items():
        try:
            async with asyncio.timeout(CHECK_TIMEOUT_SECONDS):
                await check()
        except Exception:
            checks[name] = "failed"
        else:
            checks[name] = "ok"
    ready = all(result == "ok" for result in checks.values())
    if not ready:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return ReadinessStatus(status="ready" if ready else "not ready", checks=checks)
