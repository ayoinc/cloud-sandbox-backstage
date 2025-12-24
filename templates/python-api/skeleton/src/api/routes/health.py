"""Health check routes."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def root() -> dict[str, str]:
    """Root endpoint."""
    return {"message": "Welcome to ${{ values.name }} API"}


@router.get("/version")
async def version() -> dict[str, str]:
    """Get API version."""
    from ${{ values.name | replace('-', '_') }}.config import settings
    
    return {
        "name": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }
