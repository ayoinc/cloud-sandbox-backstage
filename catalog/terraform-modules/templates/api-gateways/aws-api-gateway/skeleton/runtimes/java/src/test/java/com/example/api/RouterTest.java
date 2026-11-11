package com.example.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.fasterxml.jackson.core.type.TypeReference;
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.Map;
import org.junit.jupiter.api.Test;

class RouterTest {
  private static Request request(String method, String resource, String body, boolean base64) {
    return new Request(method, resource, null, body, base64);
  }

  private static Request request(String method, String resource) {
    return request(method, resource, null, false);
  }

  private static Map<String, Object> body(Response response) throws Exception {
    return Router.MAPPER.readValue(response.body(), new TypeReference<Map<String, Object>>() {});
  }

  @Test
  void callsTheHandlerRegisteredForTheMethodAndResource() throws Exception {
    Map<String, Route> routes = Map.of("GET /things", r -> Router.json(200, Map.of("ok", true)));
    Response response = Router.route(routes, request("GET", "/things"));
    assertEquals(200, response.statusCode());
    assertEquals("application/json", response.headers().get("Content-Type"));
    assertEquals(Map.of("ok", true), body(response));
  }

  @Test
  void answers404ForARouteThatIsNotRegistered() throws Exception {
    Response response = Router.route(Map.of(), request("GET", "/missing"));
    assertEquals(404, response.statusCode());
    assertEquals(Map.of("message", "Not found"), body(response));
  }

  @Test
  void turnsAnHttpErrorIntoItsStatusAndMessage() throws Exception {
    Map<String, Route> routes =
        Map.of(
            "GET /things",
            r -> {
              throw new HttpError(409, "Conflict");
            });
    Response response = Router.route(routes, request("GET", "/things"));
    assertEquals(409, response.statusCode());
    assertEquals(Map.of("message", "Conflict"), body(response));
  }

  @Test
  void answers500WhenAHandlerFailsUnexpectedly() throws Exception {
    Map<String, Route> routes =
        Map.of(
            "GET /things",
            r -> {
              throw new IllegalStateException("boom");
            });
    PrintStream standardError = System.err;
    ByteArrayOutputStream logged = new ByteArrayOutputStream();
    Response response;
    System.setErr(new PrintStream(logged, true, StandardCharsets.UTF_8));
    try {
      response = Router.route(routes, request("GET", "/things"));
    } finally {
      System.setErr(standardError);
    }
    assertEquals(500, response.statusCode());
    assertEquals(Map.of("message", "Internal server error"), body(response));
    assertEquals(true, logged.toString(StandardCharsets.UTF_8).contains("boom"));
  }

  @Test
  void aStubbedEndpointAnswers501WithItsMethodAndPath() throws Exception {
    Map<String, Route> routes = Map.of("POST /reports/{id}", Router.NOT_IMPLEMENTED);
    Response response = Router.route(routes, request("POST", "/reports/{id}"));
    assertEquals(501, response.statusCode());
    assertEquals(Map.of("message", "POST /reports/{id} is not implemented"), body(response));
  }

  @Test
  void parseObjectReadsPlainAndBase64Bodies() {
    assertEquals(
        Map.of("a", 1), Router.parseObject(request("POST", "/x", "{\"a\":1}", false)));
    String encoded =
        Base64.getEncoder().encodeToString("{\"b\":2}".getBytes(StandardCharsets.UTF_8));
    assertEquals(Map.of("b", 2), Router.parseObject(request("POST", "/x", encoded, true)));
  }

  @Test
  void parseObjectRejectsAnythingThatIsNotAJsonObject() {
    for (String body : Arrays.asList(null, "", "not json", "[1]", "\"text\"", "3", "null", "{} {}")) {
      HttpError error =
          assertThrows(
              HttpError.class, () -> Router.parseObject(request("POST", "/x", body, false)));
      assertEquals(400, error.statusCode());
      assertEquals("The request body must be a JSON object", error.getMessage());
    }
    assertThrows(
        HttpError.class, () -> Router.parseObject(request("POST", "/x", "not base64!", true)));
  }
}
