"""API routes configuration."""

from fastapi import APIRouter

from ${{ values.name | replace('-', '_') }}.api.routes import health, items
{%- if values.auth_type != 'none' %}
from ${{ values.name | replace('-', '_') }}.api.routes import auth
{%- endif %}

router = APIRouter()

# Health routes
router.include_router(health.router, tags=["Health"])

# Item routes (example CRUD)
router.include_router(items.router, prefix="/items", tags=["Items"])

{%- if values.auth_type != 'none' %}
# Authentication routes
router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
{%- endif %}
