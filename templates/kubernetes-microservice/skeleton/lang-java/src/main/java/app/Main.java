package app;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicLong;

/** HTTP service with root, health, readiness and metrics endpoints. */
public final class Main {

    public static final String SERVICE = "${{ values.name }}";
    private static final int DEFAULT_PORT = 8080;
    private static final AtomicLong REQUESTS = new AtomicLong();

    private Main() {
    }

    public static void main(String[] args) throws IOException {
        String port = System.getenv("PORT");
        HttpServer server = start(port == null ? DEFAULT_PORT : Integer.parseInt(port));
        Runtime.getRuntime().addShutdownHook(new Thread(() -> server.stop(0)));
        System.out.println(SERVICE + " listening on port " + server.getAddress().getPort());
    }

    /** Starts the server; port 0 picks a free port. */
    public static HttpServer start(int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", Main::handle);
        server.setExecutor(Executors.newCachedThreadPool());
        server.start();
        return server;
    }

    /** Name of the environment the service runs in. */
    public static String environment() {
        String environment = System.getenv("ENVIRONMENT");
        return environment == null ? "local" : environment;
    }

    private static void handle(HttpExchange exchange) throws IOException {
        long handled = REQUESTS.incrementAndGet();
        String path = exchange.getRequestURI().getPath();
        if (!"GET".equals(exchange.getRequestMethod())) {
            json(exchange, 404, "{\"error\":\"Not Found\"}");
        } else if ("/".equals(path)) {
            json(exchange, 200,
                    "{\"service\":\"" + SERVICE + "\",\"environment\":\"" + environment() + "\"}");
        } else if ("/health".equals(path)) {
            json(exchange, 200, "{\"status\":\"healthy\"}");
        } else if ("/ready".equals(path)) {
            json(exchange, 200, "{\"status\":\"ready\"}");
        } else if ("/metrics".equals(path)) {
            // Prometheus text exposition format
            send(exchange, 200, "text/plain; version=0.0.4",
                    "# HELP http_requests_total Requests handled by the service.\n"
                            + "# TYPE http_requests_total counter\n"
                            + "http_requests_total " + handled + "\n");
        } else {
            json(exchange, 404, "{\"error\":\"Not Found\"}");
        }
    }

    private static void json(HttpExchange exchange, int status, String body) throws IOException {
        send(exchange, status, "application/json", body);
    }

    private static void send(HttpExchange exchange, int status, String contentType, String body)
            throws IOException {
        byte[] payload = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", contentType);
        exchange.sendResponseHeaders(status, payload.length);
        try (OutputStream out = exchange.getResponseBody()) {
            out.write(payload);
        }
    }
}
