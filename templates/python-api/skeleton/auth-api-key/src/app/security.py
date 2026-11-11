"""API key authentication: the X-API-Key header must hold one of the configured keys."""

import secrets
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader

from app.config import Settings
from app.dependencies import get_settings

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def require_auth(
    api_key: Annotated[str | None, Depends(api_key_header)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> None:
    """Answer 401 unless the header matches a configured key."""
    presented = (api_key or "").encode()
    # Every configured key is compared, in constant time, so the response time does not
    # reveal which key or how much of it matched.
    matches = [secrets.compare_digest(presented, key.encode()) for key in settings.api_keys]
    if not any(matches):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail="Invalid or missing API key")
