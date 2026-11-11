"""HTTP Basic authentication for a single user configured in the settings."""

import secrets
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials

from app.config import Settings
from app.dependencies import get_settings

basic_scheme = HTTPBasic()


def require_auth(
    credentials: Annotated[HTTPBasicCredentials, Depends(basic_scheme)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> str:
    """Return the user name of valid credentials and answer 401 otherwise."""
    expected_password = settings.auth_password.get_secret_value()
    # Both values are compared in constant time, without stopping at the first mismatch.
    username_matches = secrets.compare_digest(
        credentials.username.encode(), settings.auth_username.encode()
    )
    password_matches = secrets.compare_digest(
        credentials.password.encode(), expected_password.encode()
    )
    if not (username_matches and password_matches):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username
