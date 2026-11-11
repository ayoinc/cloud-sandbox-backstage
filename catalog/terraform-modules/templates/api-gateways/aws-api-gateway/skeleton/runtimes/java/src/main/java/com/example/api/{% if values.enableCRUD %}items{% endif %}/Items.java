package com.example.api.items;

import com.example.api.HttpError;
import com.example.api.Request;
import com.example.api.Route;
import com.example.api.Router;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/** Handlers of the /items endpoints on top of an {@link ItemStore}. */
public final class Items {
  private Items() {}

  private static HttpError notFound() {
    return new HttpError(404, "Item not found");
  }

  private static String now() {
    return Instant.now().truncatedTo(ChronoUnit.MILLIS).toString();
  }

  private static Map<String, Object> find(ItemStore store, Request request) {
    String id = request.pathParameter("id");
    return (id == null ? null : store.get(id).orElse(null));
  }

  /** The entries to add to the route table. */
  public static Map<String, Route> routes(ItemStore store) {
    Map<String, Route> routes = new LinkedHashMap<>();

    routes.put("GET /items", request -> Router.json(200, Map.of("items", store.list())));

    routes.put(
        "POST /items",
        request -> {
          Map<String, Object> item = new LinkedHashMap<>(Router.parseObject(request));
          String now = now();
          item.put("id", UUID.randomUUID().toString());
          item.put("createdAt", now);
          item.put("updatedAt", now);
          store.put(item);
          return Router.json(201, item);
        });

    routes.put(
        "GET /items/{id}",
        request -> {
          Map<String, Object> item = find(store, request);
          if (item == null) {
            throw notFound();
          }
          return Router.json(200, item);
        });

    routes.put(
        "PUT /items/{id}",
        request -> {
          Map<String, Object> item = new LinkedHashMap<>(Router.parseObject(request));
          Map<String, Object> existing = find(store, request);
          if (existing == null) {
            throw notFound();
          }
          item.put("id", existing.get("id"));
          item.put("createdAt", existing.get("createdAt"));
          item.put("updatedAt", now());
          store.put(item);
          return Router.json(200, item);
        });

    routes.put(
        "DELETE /items/{id}",
        request -> {
          String id = request.pathParameter("id");
          if (id == null || !store.delete(id)) {
            throw notFound();
          }
          return Router.noContent();
        });

    return routes;
  }
}
