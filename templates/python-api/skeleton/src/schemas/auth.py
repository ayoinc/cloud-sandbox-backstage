"""Authentication schemas."""

from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    """JWT token response."""

    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    """Token payload data."""

    username: str | None = None


class UserBase(BaseModel):
    """Base user schema."""

    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr


class UserCreate(UserBase):
    """Schema for user registration."""

    password: str = Field(..., min_length=8, max_length=100)


class UserResponse(UserBase):
    """Schema for user response (no password)."""

    disabled: bool = False


class UserInDB(UserResponse):
    """User stored in database (with hashed password)."""

    hashed_password: str
