package com.example.api.items;

import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Storage of the items, keyed by their {@code id} attribute. */
public interface ItemStore {
  /** One page of at most 100 items. */
  List<Map<String, Object>> list();

  Optional<Map<String, Object>> get(String id);

  /** Stores the item, replacing any item with the same id. */
  void put(Map<String, Object> item);

  /** Deletes the item. True when an item with this id existed. */
  boolean delete(String id);
}
