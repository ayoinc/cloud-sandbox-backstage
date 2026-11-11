"""Entry point of the Lambda function (handler "handler.handler")."""

from router import route
from routes import ROUTES


def handler(event, _context):
    return route(ROUTES, event)
