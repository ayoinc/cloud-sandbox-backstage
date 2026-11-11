package com.example.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.JsonNode;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.junit.jupiter.api.Test;

class RoutesTest {
  // Calls the function the way Lambda does: proxy event in, proxy response out.
  private static JsonNode invoke(String method, String resource) throws Exception {
    String event =
        Router.MAPPER.writeValueAsString(
            Map.of(
                "httpMethod", method,
                "resource", resource,
                "path", resource,
                "headers", Map.of("Accept", "application/json"),
                "requestContext", Map.of("stage", "v1"),
                "isBase64Encoded", false));
    ByteArrayOutputStream output = new ByteArrayOutputStream();
    new Handler()
        .handleRequest(
            new ByteArrayInputStream(event.getBytes(StandardCharsets.UTF_8)), output, null);
    return Router.MAPPER.readTree(output.toString(StandardCharsets.UTF_8));
  }

  @Test
  void everyRouteKeyIsMethodAndPath() {
    Routes.table()
        .forEach(
            (key, handler) -> {
              assertTrue(key.matches("(GET|POST|PUT|DELETE) /\\S*"), key);
              assertNotNull(handler, key);
            });
  }

  @Test
  void healthReportsTheService() throws Exception {
    JsonNode response = invoke("GET", "/health");
    assertEquals(200, response.get("statusCode").asInt());
    assertEquals("application/json", response.get("headers").get("Content-Type").asText());
    JsonNode body = Router.MAPPER.readTree(response.get("body").asText());
    assertEquals("ok", body.get("status").asText());
    assertFalse(body.get("service").asText().isEmpty());
    assertFalse(body.get("version").asText().isEmpty());
  }

  @Test
  void anUnknownRouteAnswers404() throws Exception {
    JsonNode response = invoke("GET", "/unknown");
    assertEquals(404, response.get("statusCode").asInt());
    assertEquals("{\"message\":\"Not found\"}", response.get("body").asText());
  }

  @Test
  void endpointsWithoutAnImplementationAnswer501() throws Exception {
    for (Map.Entry<String, Route> entry : Routes.table().entrySet()) {
      if (entry.getValue() != Router.NOT_IMPLEMENTED) {
        continue;
      }
      String[] key = entry.getKey().split(" ");
      JsonNode response = invoke(key[0], key[1]);
      assertEquals(501, response.get("statusCode").asInt());
      assertEquals(
          Router.MAPPER.writeValueAsString(
              Map.of("message", entry.getKey() + " is not implemented")),
          response.get("body").asText());
    }
  }
}
