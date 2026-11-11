package app;

import com.sun.net.httpserver.HttpServer;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/**
 * Tests of the HTTP endpoints. The project has no build tool, so the tests
 * are plain assertions: run with assertions enabled (java -ea).
 */
public final class MainTest {

    private MainTest() {
    }

    public static void main(String[] args) throws Exception {
        HttpServer server = Main.start(0);
        String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
        try {
            HttpResponse<String> root = get(baseUrl + "/");
            assert root.statusCode() == 200 : "GET / returned " + root.statusCode();
            assert root.body().equals("{\"service\":\"" + Main.SERVICE + "\",\"environment\":\""
                    + Main.environment() + "\"}") : root.body();

            HttpResponse<String> health = get(baseUrl + "/health");
            assert health.statusCode() == 200 : "GET /health returned " + health.statusCode();
            assert health.body().equals("{\"status\":\"healthy\"}") : health.body();

            HttpResponse<String> ready = get(baseUrl + "/ready");
            assert ready.statusCode() == 200 : "GET /ready returned " + ready.statusCode();
            assert ready.body().equals("{\"status\":\"ready\"}") : ready.body();

            HttpResponse<String> metrics = get(baseUrl + "/metrics");
            assert metrics.statusCode() == 200 : "GET /metrics returned " + metrics.statusCode();
            assert metrics.body().lines().anyMatch(line -> line.matches("http_requests_total \\d+"))
                    : metrics.body();

            HttpResponse<String> missing = get(baseUrl + "/missing");
            assert missing.statusCode() == 404 : "GET /missing returned " + missing.statusCode();
        } finally {
            server.stop(0);
        }
        System.out.println("5 tests passed");
    }

    private static HttpResponse<String> get(String url) throws Exception {
        return HttpClient.newHttpClient()
                .send(HttpRequest.newBuilder(URI.create(url)).build(), HttpResponse.BodyHandlers.ofString());
    }
}
