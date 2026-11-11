import json
import os
import re
import threading
import unittest
import urllib.error
import urllib.request

import app


class AppTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.server = app.create_server(0)
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}"
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()

    def get(self, path: str) -> tuple[int, str]:
        try:
            with urllib.request.urlopen(self.base_url + path) as response:
                return response.status, response.read().decode()
        except urllib.error.HTTPError as error:
            return error.code, error.read().decode()

    def test_root_returns_the_service_name_and_environment(self) -> None:
        status, body = self.get("/")
        self.assertEqual(status, 200)
        self.assertEqual(
            json.loads(body),
            {"service": app.SERVICE, "environment": os.environ.get("ENVIRONMENT", "local")},
        )

    def test_health_reports_healthy(self) -> None:
        status, body = self.get("/health")
        self.assertEqual((status, json.loads(body)), (200, {"status": "healthy"}))

    def test_ready_reports_ready(self) -> None:
        status, body = self.get("/ready")
        self.assertEqual((status, json.loads(body)), (200, {"status": "ready"}))

    def test_metrics_counts_requests_in_the_prometheus_text_format(self) -> None:
        status, body = self.get("/metrics")
        self.assertEqual(status, 200)
        self.assertRegex(body, re.compile(r"^http_requests_total \d+$", re.MULTILINE))

    def test_unknown_paths_return_404(self) -> None:
        status, _ = self.get("/missing")
        self.assertEqual(status, 404)


if __name__ == "__main__":
    unittest.main()
