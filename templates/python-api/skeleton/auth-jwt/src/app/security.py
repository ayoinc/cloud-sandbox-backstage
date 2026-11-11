"""JWT bearer authentication for a single user configured in the settings."""

import secrets
from datetime import UTC, datetime, timedelta
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from app.config import Settings
from app.dependencies import get_settings

ALGORITHM = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")


def verify_credentials(username: str, password: str, settings: Settings) -> bool:
    """Compare both values in constant time, without stopping at the first mismatch."""
    expected_password = settings.auth_password.get_secret_value()
    username_matches = secrets.compare_digest(username.encode(), settings.auth_username.encode())
    password_matches = secrets.compare_digest(password.encode(), expected_password.encode())
    return username_matches and password_matches


def create_access_token(subject: str, settings: Settings) -> str:
    now = datetime.now(UTC)
    claims = {
        "sub": subject,
        "iat": now,
        "exp": now + timedelta(minutes=settings.jwt_expire_minutes),
    }
    return jwt.encode(claims, settings.jwt_secret.get_secret_value(), algorithm=ALGORITHM)


def require_auth(
    token: Annotated[str, Depends(oauth2_scheme)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> str:
    """Return the subject of a valid bearer token and answer 401 otherwise."""
    try:
        claims = jwt.decode(
            token,
            settings.jwt_secret.get_secret_value(),
            algorithms=[ALGORITHM],
            options={"require": ["exp", "sub"]},
        )
    except jwt.InvalidTokenError as error:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from error
    return str(claims["sub"])
