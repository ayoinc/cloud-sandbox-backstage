"""HTTP service with a root and a health endpoint."""

import json
import os
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SERVICE = "${{ values.name }}"
DEFAULT_PORT = ${{ values.port }}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._send(200, {"service": SERVICE, "message": f"Hello from {SERVICE}"})
        elif path == "/health":
            self._send(200, {"status": "healthy"})
        else:
            self._send(404, {"error": "Not Found"})

    def _send(self, status: int, body: dict) -> None:
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def create_server(port: int) -> ThreadingHTTPServer:
    return ThreadingHTTPServer(("0.0.0.0", port), Handler)


def main() -> None:
    server = create_server(int(os.environ.get("PORT", DEFAULT_PORT)))
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
