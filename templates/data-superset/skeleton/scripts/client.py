"""Authenticated access to the Superset REST API."""

import os

import requests

REQUEST_TIMEOUT = 30


class SupersetError(RuntimeError):
    """Raised when Superset rejects a request."""


class SupersetClient:
    """Small wrapper around the Superset REST API (/api/v1)."""

    def __init__(self, base_url, session=None):
        self.base_url = base_url.rstrip("/")
        self.session = session or requests.Session()

    @classmethod
    def from_env(cls):
        """Build a client from SUPERSET_URL, SUPERSET_USERNAME and SUPERSET_PASSWORD."""
        missing = [
            name
            for name in ("SUPERSET_URL", "SUPERSET_USERNAME", "SUPERSET_PASSWORD")
            if not os.getenv(name)
        ]
        if missing:
            raise SupersetError(f"Missing environment variables: {', '.join(missing)}")
        client = cls(os.environ["SUPERSET_URL"])
        client.login(os.environ["SUPERSET_USERNAME"], os.environ["SUPERSET_PASSWORD"])
        return client

    def login(self, username, password):
        """Log in and attach the access and CSRF tokens to the session."""
        tokens = self.request(
            "POST",
            "/api/v1/security/login",
            json={
                "username": username,
                "password": password,
                "provider": os.getenv("SUPERSET_AUTH_PROVIDER", "db"),
                "refresh": True,
            },
        )
        self.session.headers["Authorization"] = f"Bearer {tokens['access_token']}"
        csrf = self.request("GET", "/api/v1/security/csrf_token/")
        self.session.headers["X-CSRFToken"] = csrf["result"]
        self.session.headers["Referer"] = self.base_url

    def request(self, method, path, **kwargs):
        """Send a request and return the decoded JSON body."""
        response = self.session.request(
            method, f"{self.base_url}{path}", timeout=REQUEST_TIMEOUT, **kwargs
        )
        if response.status_code >= 400:
            raise SupersetError(
                f"{method} {path} failed with {response.status_code}: {response.text}"
            )
        return response.json()

    def find(self, resource, column, value):
        """Return the first item of a resource whose column equals value, or None."""
        query = f"(filters:!((col:{column},opr:eq,value:'{value}')))"
        result = self.request("GET", f"/api/v1/{resource}/", params={"q": query})
        items = result.get("result", [])
        return items[0] if items else None

    def upsert(self, resource, column, value, payload):
        """Create the item, or update it when one with the same key exists."""
        existing = self.find(resource, column, value)
        if existing:
            self.request("PUT", f"/api/v1/{resource}/{existing['id']}", json=payload)
            return existing["id"]
        created = self.request("POST", f"/api/v1/{resource}/", json=payload)
        return created["id"]
