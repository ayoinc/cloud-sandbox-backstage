package com.example.api;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

/**
 * Helpers shared by every endpoint: responses, request parsing and routing of
 * API Gateway proxy events.
 */
public final class Router {
  static final ObjectMapper MAPPER =
      new ObjectMapper().enable(DeserializationFeature.FAIL_ON_TRAILING_TOKENS);

  private static final TypeReference<Map<String, Object>> OBJECT = new TypeReference<>() {};
  private static final Map<String, String> JSON_HEADERS = Map.of("Content-Type", "application/json");

  /** Stub of an endpoint that is routed but has no implementation yet. */
  public static final Route NOT_IMPLEMENTED =
      request ->
          json(
              501,
              Map.of(
                  "message",
                  request.httpMethod() + " " + request.resource() + " is not implemented"));

  private Router() {}

  /** A response with the given status and the body serialised as JSON. */
  public static Response json(int statusCode, Object body) {
    try {
      return new Response(statusCode, JSON_HEADERS, MAPPER.writeValueAsString(body));
    } catch (JsonProcessingException e) {
      throw new UncheckedIOException(e);
    }
  }

  public static Response noContent() {
    return new Response(204, Map.of(), "");
  }

  /** The request body as an object. Anything else is a client error. */
  public static Map<String, Object> parseObject(Request request) {
    try {
      String raw = request.body() == null ? "" : request.body();
      if (request.isBase64Encoded()) {
        raw = new String(Base64.getDecoder().decode(raw), StandardCharsets.UTF_8);
      }
      JsonNode node = MAPPER.readTree(raw);
      if (node.isObject()) {
        return MAPPER.convertValue(node, OBJECT);
      }
    } catch (JsonProcessingException | IllegalArgumentException e) {
      // Not Base64 or not JSON: answered like any other body that is not an object.
    }
    throw new HttpError(400, "The request body must be a JSON object");
  }

  /** Calls the handler registered for {@code "<METHOD> <resource path>"}. */
  public static Response route(Map<String, Route> routes, Request request) {
    Route handler = routes.get(request.httpMethod() + " " + request.resource());
    if (handler == null) {
      return json(404, Map.of("message", "Not found"));
    }
    try {
      return handler.handle(request);
    } catch (HttpError e) {
      return json(e.statusCode(), Map.of("message", e.getMessage()));
    } catch (Exception e) {
      // Standard error of a Lambda function goes to its CloudWatch log group.
      e.printStackTrace();
      return json(500, Map.of("message", "Internal server error"));
    }
  }
}
