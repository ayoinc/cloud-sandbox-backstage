"""Request rate limiting per client address."""

import math
import time

from limits import parse
from limits.aio.storage import MemoryStorage
from limits.aio.strategies import FixedWindowRateLimiter
from starlette.datastructures import MutableHeaders
from starlette.responses import JSONResponse
from starlette.types import ASGIApp, Message, Receive, Scope, Send

# Probes are called by the platform at a fixed pace and must never be refused.
EXEMPT_PATHS = frozenset({"/health", "/health/ready"})


class RateLimitMiddleware:
    """Answer 429 once a client address exceeds the limit, for example "100/minute".

    Counters are kept in the memory of the process, so the limit applies per replica.
    Behind a reverse proxy, start uvicorn with --forwarded-allow-ips so that the client
    address is the caller and not the proxy.
    """

    def __init__(self, app: ASGIApp, limit: str) -> None:
        self.app = app
        self.limit = parse(limit)
        self.limiter = FixedWindowRateLimiter(MemoryStorage())

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http" or scope["path"] in EXEMPT_PATHS:
            await self.app(scope, receive, send)
            return

        client = scope.get("client")
        address = client[0] if client else "unknown"
        allowed = await self.limiter.hit(self.limit, address)
        stats = await self.limiter.get_window_stats(self.limit, address)
        headers = {
            "X-RateLimit-Limit": str(self.limit.amount),
            "X-RateLimit-Remaining": str(stats.remaining),
        }

        if not allowed:
            headers["Retry-After"] = str(max(1, math.ceil(stats.reset_time - time.time())))
            response = JSONResponse(
                {"detail": f"Rate limit exceeded: {self.limit}"},
                status_code=429,
                headers=headers,
            )
            await response(scope, receive, send)
            return

        async def send_with_headers(message: Message) -> None:
            if message["type"] == "http.response.start":
                MutableHeaders(scope=message).update(headers)
            await send(message)

        await self.app(scope, receive, send_with_headers)
