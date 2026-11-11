import json
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

    def get(self, path: str) -> tuple[int, dict]:
        try:
            with urllib.request.urlopen(self.base_url + path) as response:
                return response.status, json.load(response)
        except urllib.error.HTTPError as error:
            return error.code, json.load(error)

    def test_root_returns_the_service_name(self) -> None:
        status, body = self.get("/")
        self.assertEqual(status, 200)
        self.assertEqual(body["service"], app.SERVICE)

    def test_health_reports_healthy(self) -> None:
        self.assertEqual(self.get("/health"), (200, {"status": "healthy"}))

    def test_unknown_paths_return_404(self) -> None:
        status, _ = self.get("/missing")
        self.assertEqual(status, 404)


if __name__ == "__main__":
    unittest.main()
