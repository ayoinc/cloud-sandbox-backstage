package com.example.api.items;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.example.api.Request;
import com.example.api.Response;
import com.example.api.Route;
import com.example.api.Router;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ItemsTest {
  private static final ObjectMapper MAPPER = new ObjectMapper();

  /** An {@link ItemStore} kept in memory. */
  private static final class MemoryStore implements ItemStore {
    private final Map<String, Map<String, Object>> items = new LinkedHashMap<>();

    @Override
    public List<Map<String, Object>> list() {
      return new ArrayList<>(items.values());
    }

    @Override
    public Optional<Map<String, Object>> get(String id) {
      return Optional.ofNullable(items.get(id));
    }

    @Override
    public void put(Map<String, Object> item) {
      items.put((String) item.get("id"), item);
    }

    @Override
    public boolean delete(String id) {
      return items.remove(id) != null;
    }
  }

  private Map<String, Route> routes;

  @BeforeEach
  void createRoutes() {
    routes = Items.routes(new MemoryStore());
  }

  private Response call(String method, String resource, String id, String body) {
    Map<String, String> pathParameters = id == null ? null : Map.of("id", id);
    return Router.route(routes, new Request(method, resource, pathParameters, body, false));
  }

  private static Map<String, Object> body(Response response) throws Exception {
    return MAPPER.readValue(response.body(), new TypeReference<Map<String, Object>>() {});
  }

  private Map<String, Object> create(String json) throws Exception {
    return body(call("POST", "/items", null, json));
  }

  @Test
  void postStoresTheBodyWithAnIdAndTimestamps() throws Exception {
    Response response = call("POST", "/items", null, "{\"name\":\"first\"}");
    assertEquals(201, response.statusCode());
    Map<String, Object> item = body(response);
    assertEquals("first", item.get("name"));
    assertTrue(((String) item.get("id")).matches("[0-9a-f-]{36}"));
    assertEquals(item.get("createdAt"), item.get("updatedAt"));
    assertTrue(((String) item.get("createdAt")).endsWith("Z"));
    Instant.parse((String) item.get("createdAt"));
  }

  @Test
  void postRejectsABodyThatIsNotAJsonObject() throws Exception {
    for (String json : new String[] {"[\"not\",\"an\",\"object\"]", "not json", null}) {
      Response response = call("POST", "/items", null, json);
      assertEquals(400, response.statusCode());
      assertEquals(Map.of("message", "The request body must be a JSON object"), body(response));
    }
  }

  @Test
  void getItemsListsWhatWasStored() throws Exception {
    Map<String, Object> first = create("{\"name\":\"first\"}");
    Map<String, Object> second = create("{\"name\":\"second\"}");
    Response response = call("GET", "/items", null, null);
    assertEquals(200, response.statusCode());
    assertEquals(Map.of("items", List.of(first, second)), body(response));
  }

  @Test
  void getItemReturnsTheItemOr404() throws Exception {
    Map<String, Object> item = create("{\"name\":\"first\"}");
    Response found = call("GET", "/items/{id}", (String) item.get("id"), null);
    assertEquals(200, found.statusCode());
    assertEquals(item, body(found));

    Response missing = call("GET", "/items/{id}", "unknown", null);
    assertEquals(404, missing.statusCode());
    assertEquals(Map.of("message", "Item not found"), body(missing));
  }

  @Test
  void putReplacesTheAttributesAndKeepsIdAndCreatedAt() throws Exception {
    Map<String, Object> item = create("{\"name\":\"first\",\"colour\":\"red\"}");
    String id = (String) item.get("id");
    Response response =
        call(
            "PUT",
            "/items/{id}",
            id,
            "{\"name\":\"renamed\",\"id\":\"ignored\",\"createdAt\":\"ignored\"}");
    assertEquals(200, response.statusCode());
    Map<String, Object> updated = body(response);
    assertEquals("renamed", updated.get("name"));
    assertFalse(updated.containsKey("colour"));
    assertEquals(id, updated.get("id"));
    assertEquals(item.get("createdAt"), updated.get("createdAt"));
    assertNotEquals("ignored", updated.get("updatedAt"));
    assertEquals(updated, body(call("GET", "/items/{id}", id, null)));
  }

  @Test
  void putAnswers404ForAnUnknownItemAnd400ForABadBody() throws Exception {
    Response missing = call("PUT", "/items/{id}", "unknown", "{\"name\":\"x\"}");
    assertEquals(404, missing.statusCode());
    assertEquals(Map.of("message", "Item not found"), body(missing));

    Map<String, Object> item = create("{\"name\":\"first\"}");
    Response invalid = call("PUT", "/items/{id}", (String) item.get("id"), "\"text\"");
    assertEquals(400, invalid.statusCode());
  }

  @Test
  void deleteRemovesTheItemOrAnswers404() throws Exception {
    Map<String, Object> item = create("{\"name\":\"first\"}");
    String id = (String) item.get("id");
    Response deleted = call("DELETE", "/items/{id}", id, null);
    assertEquals(204, deleted.statusCode());
    assertEquals("", deleted.body());

    assertEquals(404, call("GET", "/items/{id}", id, null).statusCode());
    Response again = call("DELETE", "/items/{id}", id, null);
    assertEquals(404, again.statusCode());
    assertEquals(Map.of("message", "Item not found"), body(again));
  }
}
