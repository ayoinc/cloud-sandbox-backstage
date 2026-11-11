"""Dependencies that hand request handlers the objects built by create_app."""

from fastapi import Request

from app.config import Settings
from app.repository import ItemRepository


def get_settings(request: Request) -> Settings:
    settings: Settings = request.app.state.settings
    return settings


def get_repository(request: Request) -> ItemRepository:
    repository: ItemRepository = request.app.state.repository
    return repository
