package app;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executors;

/** HTTP service with a root and a health endpoint. */
public final class Main {

    public static final String SERVICE = "${{ values.name }}";
    private static final int DEFAULT_PORT = ${{ values.port }};

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

    private static void handle(HttpExchange exchange) throws IOException {
        String path = exchange.getRequestURI().getPath();
        if (!"GET".equals(exchange.getRequestMethod())) {
            send(exchange, 404, "{\"error\":\"Not Found\"}");
        } else if ("/".equals(path)) {
            send(exchange, 200,
                    "{\"service\":\"" + SERVICE + "\",\"message\":\"Hello from " + SERVICE + "\"}");
        } else if ("/health".equals(path)) {
            send(exchange, 200, "{\"status\":\"healthy\"}");
        } else {
            send(exchange, 404, "{\"error\":\"Not Found\"}");
        }
    }

    private static void send(HttpExchange exchange, int status, String body) throws IOException {
        byte[] payload = body.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, payload.length);
        try (OutputStream out = exchange.getResponseBody()) {
            out.write(payload);
        }
    }
}
