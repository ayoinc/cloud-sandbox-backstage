"""HTTP service with root, health, readiness and metrics endpoints."""

import itertools
import json
import os
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SERVICE = "${{ values.name }}"

# next() on itertools.count is atomic, so handler threads can share it.
_requests = itertools.count(1)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        handled = next(_requests)
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._json(200, {"service": SERVICE, "environment": os.environ.get("ENVIRONMENT", "local")})
        elif path == "/health":
            self._json(200, {"status": "healthy"})
        elif path == "/ready":
            self._json(200, {"status": "ready"})
        elif path == "/metrics":
            # Prometheus text exposition format
            self._send(
                200,
                "text/plain; version=0.0.4",
                "# HELP http_requests_total Requests handled by the service.\n"
                "# TYPE http_requests_total counter\n"
                f"http_requests_total {handled}\n",
            )
        else:
            self._json(404, {"error": "Not Found"})

    def _json(self, status: int, body: dict) -> None:
        self._send(status, "application/json", json.dumps(body))

    def _send(self, status: int, content_type: str, body: str) -> None:
        payload = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def create_server(port: int) -> ThreadingHTTPServer:
    return ThreadingHTTPServer(("0.0.0.0", port), Handler)


def main() -> None:
    server = create_server(int(os.environ.get("PORT", "8080")))
    # A process started as PID 1 in a container gets no default signal
    # handling. shutdown() must be called from another thread than the one
    # serving requests.
    for signum in (signal.SIGINT, signal.SIGTERM):
        signal.signal(signum, lambda *_: threading.Thread(target=server.shutdown).start())
    print(f"{SERVICE} listening on port {server.server_port}", flush=True)
    server.serve_forever()
    server.server_close()


if __name__ == "__main__":
    main()
